# Starts the shell, opens a menu route, and prints the menu's state (menu.debugState) as JSON, plus the
# first -Rows row labels. No screenshots: the desktop can hold private content.
#   .\tools\menu-state.ps1 -Menu apps -Rows 8
param([string]$Menu = 'root', [int]$Rows = 0, [int]$Wait = 10, [string]$Bin = (Join-Path $PSScriptRoot '..\bin'))
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$env:HOME = Join-Path $root 'state\home'; $env:OMARCHY_PATH = $root; $env:QT_FORCE_STDERR_LOGGING = '1'
$env:PATH = 'C:\Program Files\Git\usr\bin;' + $env:PATH + ';C:\Program Files\komorebi\bin'
$logs = Join-Path $root 'logs'; New-Item -ItemType Directory -Force $logs | Out-Null
$w = Join-Path $Bin 'wakuc.exe'
$p = Start-Process (Join-Path $Bin 'waku.exe') -PassThru -WindowStyle Hidden `
  -ArgumentList @('--config-home', $root, '--no-tray', '--font-engine=directwrite') `
  -RedirectStandardError (Join-Path $logs 'menu.err.txt') -RedirectStandardOutput (Join-Path $logs 'menu.out.txt')
try {
  Start-Sleep -Seconds $Wait
  $payload = '{"menu":"' + $Menu + '"}'
  & $w --config-home $root call shell call omarchy.menu open $payload | Out-Null
  Start-Sleep -Milliseconds 800
  (& $w --config-home $root call shell call omarchy.menu debugState x) -join '' -replace '\s+', ' '
  if ($Rows -gt 0) { (& $w --config-home $root call shell call omarchy.menu debugRows $Rows) -join '' }
} finally {
  & $w --config-home $root quit | Out-Null
  if (-not $p.WaitForExit(5000)) { Stop-Process -Id $p.Id -Force }
}
