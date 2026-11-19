<#
  remove_stale_registry.ps1 - removes the 7 stale registry entries found by registry_audit.ps1.
  DRY RUN by default. Each entry is removed ONLY if what it points to is still missing.
  Every entry is exported to a .reg file first: $env:USERPROFILE\registry_backup_<timestamp>\
  To undo: double-click the .reg file.

    Preview :  & "$env:USERPROFILE\remove_stale_registry.ps1"
    Remove  :  & "$env:USERPROFILE\remove_stale_registry.ps1" -Apply

  Run in an elevated (admin) PowerShell.
#>
param([switch]$Apply)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning 'Run this from an admin PowerShell.'; return
}

$stamp  = Get-Date -Format yyyyMMdd_HHmmss
$backup = Join-Path $env:USERPROFILE "registry_backup_$stamp"
$log    = Join-Path $env:USERPROFILE "remove_stale_registry_$stamp.log"
function Log([string]$m) { $l = "{0:HH:mm:ss}  {1}" -f (Get-Date), $m; Write-Host $l; Add-Content -Path $log -Value $l }
function Exe-Of([string]$cmd) { if (-not $cmd) { return $null }; $c = [Environment]::ExpandEnvironmentVariables($cmd.Trim()); if ($c -match '^"([^"]+)"') { $Matches[1] } else { ($c -split '\s')[0] } }
function Export-Reg([string]$regPath, [string]$file) {
    $out = Join-Path $backup $file
    reg.exe export $regPath $out /y | Out-Null
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $out)) { throw "backup of $regPath failed - not removing" }
}

Log ("Mode: " + $(if ($Apply) { "APPLY - backups go to $backup" } else { 'DRY RUN - nothing will change' }))
if ($Apply) { New-Item -ItemType Directory -Path $backup -Force | Out-Null }

# ---- 1-3. Ghost Steam entries in Settings > Apps ----
$steamLibs = @('C:\Program Files (x86)\Steam\steamapps', 'D:\SteamLibrary\steamapps')
foreach ($id in 2448970, 264710, 848450) {
    $key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App $id"
    $p = Get-ItemProperty $key -ErrorAction SilentlyContinue
    if (-not $p) { Log "[skip] Steam App $id - entry not found"; continue }
    $installed = ($p.InstallLocation -and (Test-Path -LiteralPath $p.InstallLocation)) -or @($steamLibs | Where-Object { Test-Path (Join-Path $_ "appmanifest_$id.acf") }).Count
    if ($installed) { Log "[skip] $($p.DisplayName) - game is installed, leaving it alone"; continue }
    if (-not $Apply) { Log "[would remove] Installed-apps entry '$($p.DisplayName)' (Steam App $id)"; continue }
    try {
        Export-Reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App $id" "uninstall_SteamApp_$id.reg"
        Remove-Item $key -Recurse -Force -ErrorAction Stop
        Log "[removed] Installed-apps entry '$($p.DisplayName)'  (backup: uninstall_SteamApp_$id.reg)"
    } catch { Log "[failed] Steam App $id - $($_.Exception.Message)" }
}

# ---- 4. CCleaner App Paths ----
$ap = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\ccleaner.exe'
if (-not (Test-Path $ap)) { Log '[skip] App Paths ccleaner.exe - not found' }
else {
    $target = Exe-Of (Get-ItemProperty $ap).'(default)'
    if ($target -and (Test-Path -LiteralPath $target)) { Log "[skip] App Paths ccleaner.exe - $target exists, leaving it alone" }
    elseif (-not $Apply) { Log "[would remove] App Paths ccleaner.exe (points to missing $target)" }
    else {
        try {
            Export-Reg 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\ccleaner.exe' 'apppaths_ccleaner.reg'
            Remove-Item $ap -Recurse -Force -ErrorAction Stop
            Log '[removed] App Paths ccleaner.exe  (backup: apppaths_ccleaner.reg)'
        } catch { Log "[failed] App Paths ccleaner.exe - $($_.Exception.Message)" }
    }
}

# ---- 5-7. Startup values (HKCU Run) ----
$run  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$appr = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
$runItem = Get-Item $run
$todo = @()
foreach ($n in 'AF_counter_4126040', 'AF_uuid_4126040') {
    $v = [string]$runItem.GetValue($n)
    if (-not $v) { Log "[skip] startup value $n - not found" }
    elseif ($v -match '\\') { Log "[skip] startup value $n - now looks like a program path ($v), leaving it alone" }
    else { $todo += [pscustomobject]@{ Name = $n; Why = "not a program (data: $v)" } }
}
$jb = [string]$runItem.GetValue('JetBrains Toolbox')
if (-not $jb) { Log "[skip] startup value JetBrains Toolbox - not found" }
else {
    $exe = Exe-Of $jb
    if ($exe -and (Test-Path -LiteralPath $exe)) { Log "[skip] JetBrains Toolbox - $exe exists, leaving it alone" }
    else { $todo += [pscustomobject]@{ Name = 'JetBrains Toolbox'; Why = "program missing ($exe)" } }
}

if ($todo.Count) {
    if (-not $Apply) { $todo | ForEach-Object { Log "[would remove] startup value '$($_.Name)' - $($_.Why)" } }
    else {
        try {
            Export-Reg 'HKCU\Software\Microsoft\Windows\CurrentVersion\Run' 'run_key_before.reg'
            if (Test-Path $appr) { Export-Reg 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' 'startupapproved_run_before.reg' }
            foreach ($t in $todo) {
                Remove-ItemProperty -Path $run -Name $t.Name -ErrorAction Stop
                Remove-ItemProperty -Path $appr -Name $t.Name -ErrorAction SilentlyContinue
                Log "[removed] startup value '$($t.Name)'  (backup: run_key_before.reg)"
            }
        } catch { Log "[failed] startup values - $($_.Exception.Message)" }
    }
}

Log "Log saved to $log"
