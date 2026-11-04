# Runs a probe shell.qml (path in -Qml) in a throwaway home and prints its "PROBE|" log lines.
# The probe prints PROBE|DONE when finished. Never touches the real config home.
param([Parameter(Mandatory)][string]$Qml, [string]$Bin = (Join-Path $PSScriptRoot '..\bin'), [int]$MaxSeconds = 40)
$ErrorActionPreference = 'Stop'
$env:PATH += ';C:\Program Files\komorebi\bin'
$env:QT_FORCE_STDERR_LOGGING = '1'
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$home_ = Join-Path $port 'smoke\probe'
Copy-Item -LiteralPath $Qml -Destination (Join-Path $home_ 'shell.qml') -Force
$logs = Join-Path $port 'logs'; New-Item -ItemType Directory -Force $logs | Out-Null
$err = Join-Path $logs 'probe.err.txt'; $out = Join-Path $logs 'probe.out.txt'
$p = Start-Process -FilePath (Join-Path $Bin 'waku.exe') -PassThru -WindowStyle Hidden -RedirectStandardError $err -RedirectStandardOutput $out `
  -ArgumentList @('--config-home', $home_, '--no-tray', '--import-path', (Join-Path $port 'modules'))
$t0 = Get-Date
try {
  while (((Get-Date) - $t0).TotalSeconds -lt $MaxSeconds) {
    Start-Sleep -Milliseconds 700
    if ($p.HasExited) { break }
    if (Select-String -LiteralPath $err -Pattern 'PROBE\|DONE' -Quiet -ErrorAction SilentlyContinue) { break }
  }
} finally {
  & (Join-Path $Bin 'wakuc.exe') --config-home $home_ quit | Out-Null
  if (-not $p.WaitForExit(5000)) { Stop-Process -Id $p.Id -Force }
}
Get-Content $err, $out -ErrorAction SilentlyContinue | Where-Object { $_ -match 'PROBE\||waku: config errors|unavailable|not a type|not installed' } | ForEach-Object { $_ -replace '^qml: ', '' }
