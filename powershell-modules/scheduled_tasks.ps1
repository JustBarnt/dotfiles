<#
  scheduled_tasks.ps1 - READ-ONLY audit of scheduled tasks.
  Uses only Get-* commands; it cannot create, change, disable or delete anything.

    Run (admin Windows PowerShell or PowerShell 7):
      & "$env:USERPROFILE\scheduled_tasks.ps1"

  Output: $env:USERPROFILE\scheduled_tasks.csv  (flagged tasks first)
#>
$ErrorActionPreference = 'SilentlyContinue'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Warning 'Not running as admin: some system tasks will be hidden from the list.' }

$sigCache = @{}
function Get-Signer([string]$path) {
    if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    if ($sigCache.ContainsKey($path)) { return $sigCache[$path] }
    $s = Get-AuthenticodeSignature -LiteralPath $path
    $r = if ($s.Status -eq 'Valid') { ($s.SignerCertificate.Subject -replace '^CN="?([^",]+)"?.*', '$1') }
         elseif ($s.Status -eq 'NotSigned') { 'UNSIGNED' }
         else { "INVALID ($($s.Status))" }
    $sigCache[$path] = $r; $r
}

function Resolve-Exe([string]$exe) {
    if (-not $exe) { return $null }
    $e = [Environment]::ExpandEnvironmentVariables($exe.Trim().Trim('"'))
    try { if ([IO.Path]::IsPathRooted($e)) { return $e } } catch { return $e }
    foreach ($dir in "$env:windir\System32", "$env:windir") {
        foreach ($cand in $e, "$e.exe") { $p = Join-Path $dir $cand; if (Test-Path -LiteralPath $p -PathType Leaf) { return $p } }
    }
    $c = Get-Command $e -CommandType Application | Select-Object -First 1
    if ($c) { return $c.Source }
    $e
}

function Describe-Trigger($t) {
    $kind = $t.CimClass.CimClassName -replace '^MSFT_Task', '' -replace 'Trigger$', ''
    if (-not $kind) { $kind = 'Custom' }
    $d = $kind
    if ($t.StartBoundary -and $kind -in 'Time', 'Daily', 'Weekly', 'Monthly', '') { $d += " @ $($t.StartBoundary)" }
    if ($t.Repetition.Interval) { $d += " every $($t.Repetition.Interval)" }
    if ($t.Enabled -eq $false) { $d += ' (off)' }
    $d
}

$scriptHosts = 'powershell.exe', 'pwsh.exe', 'cmd.exe', 'wscript.exe', 'cscript.exe', 'mshta.exe', 'rundll32.exe', 'regsvr32.exe', 'bitsadmin.exe', 'certutil.exe'
$suspiciousArgs = '(?i)(-enc(odedcommand)?\s|-e\s+[A-Za-z0-9+/=]{20,}|frombase64string|-w(indowstyle)?\s+hidden|\biex\b|invoke-expression|downloadstring|downloadfile|invoke-webrequest|\bhttps?://)'
$userWritable   = '(?i)\\(AppData|Temp|Downloads|ProgramData|Users\\Public)\\'

$rows = foreach ($task in Get-ScheduledTask) {
    $info = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath
    $triggers = ($task.Triggers | ForEach-Object { Describe-Trigger $_ }) -join '; '
    $runAs = if ($task.Principal.UserId) { $task.Principal.UserId } elseif ($task.Principal.GroupId) { $task.Principal.GroupId } else { '' }
    if ($task.Principal.RunLevel -eq 'Highest') { $runAs += ' (highest privileges)' }

    foreach ($a in @($task.Actions)) {
        $flags = New-Object System.Collections.Generic.List[string]
        if ($a.CimClass.CimClassName -eq 'MSFT_TaskExecAction') {
            $path = Resolve-Exe $a.Execute
            $cmd  = "$($a.Execute) $($a.Arguments)".Trim()
        } else {
            # COM handler action: look up the DLL behind the CLSID
            $clsid = $a.ClassId
            $path = (Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\CLSID\$clsid\InprocServer32").'(default)'
            if ($path) { $path = Resolve-Exe $path }
            $cmd = "COM handler $clsid $($a.Data)".Trim()
        }

        $exists = $path -and (Test-Path -LiteralPath $path -PathType Leaf)
        $signer = Get-Signer $path
        $msSigned = $signer -match 'Microsoft'

        if ($path -and -not $exists)                      { $flags.Add('FILE MISSING') }
        if ($signer -eq 'UNSIGNED')                       { $flags.Add('unsigned') }
        if ($signer -like 'INVALID*')                     { $flags.Add('bad signature') }
        if ($path -match $userWritable)                   { $flags.Add('user-writable folder') }
        if ($path -and (($path -split '\\')[-1].ToLower() -in $scriptHosts)) { $flags.Add('script/launcher tool') }
        if ($a.Arguments -match $suspiciousArgs)          { $flags.Add('suspicious arguments') }
        if ($task.TaskPath -like '\Microsoft\*' -and $exists -and -not $msSigned) { $flags.Add('in Microsoft folder, not Microsoft-signed') }
        if ($task.Settings.Hidden)                        { $flags.Add('hidden') }

        [pscustomobject]@{
            Flags       = $flags -join ', '
            FlagCount   = $flags.Count
            Task        = "$($task.TaskPath)$($task.TaskName)"
            State       = $task.State
            Author      = $task.Author
            Signer      = $signer
            Triggers    = $triggers
            RunAs       = $runAs
            LastRun     = $info.LastRunTime
            LastResult  = if ($null -ne $info.LastTaskResult) { '0x{0:X}' -f $info.LastTaskResult } else { '' }
            NextRun     = $info.NextRunTime
            Program     = $path
            CommandLine = $cmd
        }
    }
}

$out = "$env:USERPROFILE\scheduled_tasks.csv"
$rows | Sort-Object @{e = 'FlagCount'; Descending = $true}, @{e = { $_.Signer -match 'Microsoft' }}, Task |
    Export-Csv $out -NoTypeInformation -Encoding UTF8

$flagged = @($rows | Where-Object FlagCount)
$nonMs   = @($rows | Where-Object { $_.Signer -notmatch 'Microsoft' })
"Tasks/actions scanned : $(@($rows).Count)"
"Not Microsoft-signed  : $($nonMs.Count)"
"Flagged               : $($flagged.Count)"
"Saved to              : $out"
