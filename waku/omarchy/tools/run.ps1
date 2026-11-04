# Starts waku on a config home, reports status and log problems, optionally fires a shortcut and a
# screenshot, then quits. Always passes --no-tray. Never use a real user config home.
param(
  [Alias('Home')][string]$ConfigHome = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [int]$Seconds = 8,
  [string[]]$Call, # `wakuc call` lines, e.g. 'shell summon omarchy.menu {}'
  [string[]]$Shortcut, # one or more, fired in order, 2 s apart
  [string]$Shot,
  [string]$Crop, # x,y,w,h of the screenshot
  [int]$Toast = 0, # raise this many test toasts (tools	oast.ps1) before the shortcut and shot
  [string]$Bin = $(if ($env:WAKU_BIN) { $env:WAKU_BIN } else { Join-Path $PSScriptRoot '..\bin' })
)
$ErrorActionPreference = 'Stop'
$env:PATH = 'C:\Program Files\Git\usr\bin;' + $env:PATH + ';C:\Program Files\komorebi\bin' # Git's bash and find first: the shell runs bash scripts
# Omarchy reads its config and cache dirs from these; keep them inside the port. HOME is only read
# (default wallpaper and video folders).
$portRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$env:OMARCHY_CONFIG_DIR = Join-Path $portRoot 'state\config'
$env:OMARCHY_CACHE_DIR = Join-Path $portRoot 'state\cache'
$env:HOME = Join-Path $portRoot 'state\home'
$env:OMARCHY_PATH = $portRoot
New-Item -ItemType Directory -Force $env:OMARCHY_CONFIG_DIR, $env:OMARCHY_CACHE_DIR | Out-Null
$env:QT_FORCE_STDERR_LOGGING = '1' # Qt writes qml: messages to stderr only with this
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$logs = Join-Path $port 'logs'
New-Item -ItemType Directory -Force $logs | Out-Null
$err = Join-Path $logs 'run.err.txt'; $out = Join-Path $logs 'run.out.txt'
$waku = Join-Path $Bin 'waku.exe'; $wakuc = Join-Path $Bin 'wakuc.exe'
$launch = @('--config-home', $ConfigHome, '--no-tray', '--font-engine=directwrite')
# A smoke shell has its own config home; the port's modules still resolve through --import-path.
if ((Resolve-Path $ConfigHome).Path.TrimEnd([char]92) -ne $port.TrimEnd([char]92)) { $launch += @('--import-path', (Join-Path $port 'modules')) }
$p = Start-Process -FilePath $waku -ArgumentList $launch -RedirectStandardError $err `
  -RedirectStandardOutput $out -PassThru -WindowStyle Hidden
try {
  Start-Sleep -Seconds $Seconds
  Write-Host "== status (pid $($p.Id), exited: $($p.HasExited))"
  & $wakuc --config-home $ConfigHome status
  if ($Toast -gt 0) { & (Join-Path $PSScriptRoot 'toast.ps1') -Count $Toast; Start-Sleep -Seconds 2 }
  foreach ($c in $Call) {
    Write-Host "== call $c"
    & $wakuc --config-home $ConfigHome call @($c -split ' ')
    Start-Sleep -Seconds 2
  }
  foreach ($sc in ($Shortcut -split ",")) {
    Write-Host "== shortcut $sc"
    & $wakuc --config-home $ConfigHome shortcut $sc
    Start-Sleep -Seconds 2
  }
  if ($Shot) { if ($Crop) { & (Join-Path $PSScriptRoot 'shot.ps1') -Out $Shot -Crop $Crop } else { & (Join-Path $PSScriptRoot 'shot.ps1') -Out $Shot } }
  Write-Host '== log problems (max 60)'
  $hits = @(Get-Content $err, $out -ErrorAction SilentlyContinue |
    Where-Object { $_ -match 'qml:|error|Error|warning' })
  $hits | Select-Object -First 60 | ForEach-Object { Write-Host $_ }
  Write-Host "($($hits.Count) matching lines)"
} finally {
  & $wakuc --config-home $ConfigHome quit
  if (-not $p.WaitForExit(5000)) { Stop-Process -Id $p.Id -Force; Write-Host 'killed' }
}
