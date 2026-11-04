# Starts this port through the shared launcher, start.ps1 in the repo root. Kept so the old path works.
#   .\tools\start.ps1          live: your deployed engine, tray, app bar, Windows taskbar hidden
#   .\tools\start.ps1 -Dev     the bundled engine, hidden, no tray, no app bar, taskbar left alone
param([string]$Waku, [switch]$Dev, [switch]$DryRun)
$extra = @{}; if ($Waku) { $extra.Waku = $Waku }
& (Join-Path $PSScriptRoot '..\..\start.ps1') -Port omarchy @extra -Dev:$Dev -DryRun:$DryRun
