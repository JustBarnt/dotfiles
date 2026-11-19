# Collects what Windows recorded about waku crashes, RDP sessions and disk trouble in the last
# N days, into crash-report.txt beside this script. Read-only: changes nothing.
param([int]$Days = 30)
$ErrorActionPreference = 'SilentlyContinue'
$since = (Get-Date).AddDays(-$Days)
$out = Join-Path $PSScriptRoot 'crash-report.txt'

function Section($title, $events) {
  "===== $title =====" | Out-File $out -Append -Encoding utf8
  if (-not $events) { "(none)`n" | Out-File $out -Append -Encoding utf8; return }
  $events | Sort-Object TimeCreated | Format-List TimeCreated, Id, ProviderName, LevelDisplayName, Message |
    Out-File $out -Append -Encoding utf8 -Width 300
}

"waku crash report, $(Get-Date -Format s), last $Days days`n" | Out-File $out -Encoding utf8

# 1000 = crash (exception code, faulting module, offset), 1001 = WER bucket, 1002 = hang.
Section 'waku crashes and hangs (Application log)' (
  Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Id = 1000, 1001, 1002; StartTime = $since } |
    Where-Object { $_.Message -match 'waku' })

# 21 logon, 22 shell start, 24 disconnect, 25 reconnect, 39/40 session disconnected by another session.
Section 'Remote Desktop sessions (LocalSessionManager)' (
  Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id = 21, 22, 24, 25, 39, 40; StartTime = $since } |
    Select-Object -First 200)

# Warnings and errors from the storage stack: a volume that went away shows up here.
Section 'Disk and volume warnings/errors (System log)' (
  Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 1, 2, 3; StartTime = $since } |
    Where-Object { $_.ProviderName -match 'disk|Ntfs|volmgr|partmgr|stornvme|storahci|StorPort|Kernel-PnP|volsnap|iaStor' } |
    Select-Object -First 200)

# Where the waku that ran lives: a crash with code c0000006 means its code pages could not be read.
"===== waku.exe on PATH =====" | Out-File $out -Append -Encoding utf8
(Get-Command waku.exe).Source | Out-File $out -Append -Encoding utf8
Write-Host "Wrote $out"
