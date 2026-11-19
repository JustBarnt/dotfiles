<#
  registry_audit.ps1 - READ-ONLY check for registry entries that point to files that no longer exist.
  Uses only read commands; it cannot change or delete anything.

  Checks:
    1. Installed-programs entries (Settings > Apps) whose uninstaller or install folder is gone
    2. Startup (Run/RunOnce) entries whose program is gone, or that aren't programs at all
    3. Services and drivers whose file is gone
    4. Right-click menu handlers whose DLL is gone (cause right-click lag)
    5. App Paths entries (Win+R shortcuts) whose program is gone

    Run (admin PowerShell):  & "$env:USERPROFILE\registry_audit.ps1"
    Output: $env:USERPROFILE\registry_audit.csv
#>
$ErrorActionPreference = 'SilentlyContinue'
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning 'Not admin: some system entries cannot be checked.'
}

# Pull the file path out of a command line: quoted path, rundll32 target, or longest existing prefix.
function Get-Target([string]$cmd) {
    if (-not $cmd) { return $null }
    $c = [Environment]::ExpandEnvironmentVariables($cmd.Trim())
    $c = $c -replace '^\\\?\?\\', '' -replace '^(?i)\\SystemRoot\\', "$env:windir\" -replace '^(?i)System32\\', "$env:windir\System32\"
    if ($c -match '^"([^"]+)"\s*(.*)$') { $exe = $Matches[1]; $rest = $Matches[2] }
    else {
        $parts = $c -split ' '; $exe = $parts[0]; $rest = ($parts | Select-Object -Skip 1) -join ' '
        for ($i = $parts.Count; $i -ge 1; $i--) {          # handle unquoted paths with spaces
            $cand = ($parts[0..($i - 1)] -join ' ')
            if ($cand -match '\.(exe|dll|sys|com|bat|cmd|cpl|ocx)$' -or (Test-Path -LiteralPath $cand -PathType Leaf)) { $exe = $cand; $rest = ($parts | Select-Object -Skip $i) -join ' '; break }
        }
    }
    if ($exe -match '(?i)(^|\\)rundll32(\.exe)?$' -and $rest) { $exe = (($rest.Trim().Trim('"')) -split ',')[0].Trim('"') }
    if ($exe -notmatch '\\') {                               # bare name like "msiexec" -> System32
        foreach ($d in "$env:windir\System32", $env:windir) { foreach ($n in $exe, "$exe.exe") { $p = Join-Path $d $n; if (Test-Path -LiteralPath $p) { return $p } } }
    }
    $exe
}
function Gone([string]$p) { $p -and $p -match '^[A-Za-z]:\\' -and -not (Test-Path -LiteralPath $p) }

$rows = New-Object System.Collections.Generic.List[object]
function Add($cat, $key, $name, $target, $problem, $owner) {
    $rows.Add([pscustomobject]@{ Category = $cat; Problem = $problem; Name = $name; Owner = $owner; PointsTo = $target; RegistryKey = $key })
}

# ---- 1. Installed-programs (uninstall) entries ----
$uninst = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
          'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
          'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall'
foreach ($root in $uninst) {
    foreach ($k in Get-ChildItem $root) {
        $p = Get-ItemProperty $k.PSPath
        if (-not $p.DisplayName -or $p.SystemComponent -eq 1) { continue }
        $un = $p.UninstallString
        if ($un -and $un -notmatch '(?i)msiexec' -and $un -notmatch '^[a-z]+://') {
            $t = Get-Target $un
            if (Gone $t) { Add 'Installed programs' $k.Name $p.DisplayName $t 'Uninstaller missing (ghost entry in Settings > Apps)' $p.Publisher; continue }
        }
        if ($p.InstallLocation -and (Gone ($p.InstallLocation.Trim('"').TrimEnd('\') + '\'))) {
            Add 'Installed programs' $k.Name $p.DisplayName $p.InstallLocation 'Install folder missing' $p.Publisher
        }
    }
}

# ---- 2. Startup entries ----
$runKeys = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
           'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
           'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce'
foreach ($rk in $runKeys) {
    $item = Get-Item $rk; if (-not $item) { continue }
    foreach ($n in $item.GetValueNames()) {
        $v = [string]$item.GetValue($n)
        $t = Get-Target $v
        if ($t -notmatch '\\|\.') { Add 'Startup' $item.Name $n $v 'Not a program (data stored in the startup key)' '' }
        elseif (Gone $t)         { Add 'Startup' $item.Name $n $t 'Program missing (fails at every login)' '' }
    }
}

# ---- 3. Services and drivers ----
foreach ($s in @(Get-CimInstance Win32_Service) + @(Get-CimInstance Win32_SystemDriver)) {
    $t = Get-Target $s.PathName
    if (Gone $t) {
        $kind = if ($s.CimClass.CimClassName -eq 'Win32_SystemDriver') { 'Driver' } else { 'Service' }
        Add "$kind" "HKLM\SYSTEM\CurrentControlSet\Services\$($s.Name)" "$($s.Name) ($($s.DisplayName))" $t "File missing (start type: $($s.StartMode))" ''
    }
}

# ---- 4. Right-click (context menu) handlers ----
$shellex = '*', 'AllFilesystemObjects', 'Directory', 'Directory\Background', 'Drive', 'Folder'
foreach ($cls in $shellex) {
    $base = "Registry::HKEY_CLASSES_ROOT\$cls\shellex\ContextMenuHandlers"
    foreach ($h in Get-ChildItem -LiteralPath $base) {
        $clsid = (Get-ItemProperty -LiteralPath $h.PSPath).'(default)'
        if ($clsid -notmatch '^\{') { $clsid = $h.PSChildName }
        if ($clsid -notmatch '^\{') { continue }
        $srvKey = "Registry::HKEY_CLASSES_ROOT\CLSID\$clsid\InprocServer32"
        if (-not (Test-Path -LiteralPath "Registry::HKEY_CLASSES_ROOT\CLSID\$clsid")) {
            Add 'Right-click handler' $h.Name $h.PSChildName $clsid 'Points to a COM class that no longer exists' ''; continue
        }
        $dll = (Get-ItemProperty -LiteralPath $srvKey).'(default)'
        $t = Get-Target $dll
        if (Gone $t) { Add 'Right-click handler' $h.Name $h.PSChildName $t 'Handler DLL missing (can slow right-click)' '' }
    }
}

# ---- 5. App Paths ----
foreach ($ap in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths') {
    foreach ($k in Get-ChildItem $ap) {
        $t = Get-Target ((Get-ItemProperty $k.PSPath).'(default)')
        if (Gone $t) { Add 'App Paths' $k.Name $k.PSChildName $t 'Program missing' '' }
    }
}

$out = "$env:USERPROFILE\registry_audit.csv"
$rows | Sort-Object Category, Name | Export-Csv $out -NoTypeInformation -Encoding UTF8
$rows | Group-Object Category | ForEach-Object { '{0,-22} {1}' -f $_.Name, $_.Count }
"Total stale entries: $($rows.Count)"
"Saved to: $out"
