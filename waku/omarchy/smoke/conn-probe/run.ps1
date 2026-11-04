param([string]$Waku = $(if ($env:WAKU_EXE) { $env:WAKU_EXE } else { (Get-Command waku.exe).Source }), [int]$Seconds = 30)
$env:QT_FORCE_STDERR_LOGGING = '1'
$home_ = Split-Path -Parent $MyInvocation.MyCommand.Path
$err = Join-Path $home_ 'probe.err.txt'
$p = Start-Process -FilePath $Waku -ArgumentList @('--config-home', $home_, '--no-tray', '--font-engine=directwrite') `
  -RedirectStandardError $err -RedirectStandardOutput (Join-Path $home_ 'probe.out.txt') -PassThru -WindowStyle Hidden
Start-Sleep -Seconds $Seconds
if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }
Get-Content $err | Select-String 'PROBE' | ForEach-Object { $_.Line -replace '^.*PROBE\|', '' }
