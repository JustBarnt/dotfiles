# Compile-checks every .qml under modules\qs in a throwaway shell (Qt.createComponent) and writes
# one line per failing file to logs\loadcheck.txt. Never touches the real config home.
param([string]$Bin = (Join-Path $PSScriptRoot '..\bin'), [int]$MaxSeconds = 120, [string]$Filter = '')
$ErrorActionPreference = 'Stop'
$env:PATH = 'C:\Program Files\Git\usr\bin;' + $env:PATH + ';C:\Program Files\komorebi\bin' # Git's bash and find first: the shell runs bash scripts
$env:QT_FORCE_STDERR_LOGGING = '1'
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$modules = Join-Path $port 'modules'
# Outside the port: the live shell reloads, and breaks, when a file under its config home changes.
$home_ = Join-Path $env:TEMP 'omarchy-loadcheck'; New-Item -ItemType Directory -Force $home_ | Out-Null
$logs = Join-Path $port 'logs'; New-Item -ItemType Directory -Force $logs | Out-Null
$files = @('modules\qs','plugins','services') | ForEach-Object { Get-ChildItem (Join-Path $port $_) -Recurse -Filter *.qml } |
  Where-Object { $_.Name -cmatch '^[A-Z]' -and $_.FullName -match $Filter } | Sort-Object FullName
$urls = ($files | ForEach-Object { '"file:///' + $_.FullName.Replace('\', '/') + '"' }) -join ",`n"
$qml = @"
import QtQuick
import Quickshell
ShellRoot {
  property var files: [
$urls
  ]
  Timer { interval: 200; running: true; repeat: false; onTriggered: {
    var bad = 0;
    for (var i = 0; i < files.length; ++i) {
      var c = Qt.createComponent(files[i]);
      if (c.status === Component.Error) { bad++; console.log("LOADCHK|ERR|" + files[i] + "|" + c.errorString().replace(/\s*\n\s*/g, " ;; ")); }
      else if (c.status !== Component.Ready) { console.log("LOADCHK|PEND|" + files[i]); }
    }
    console.log("LOADCHK|DONE|" + files.length + "|" + bad);
  } }
}
"@
[IO.File]::WriteAllText((Join-Path $home_ 'shell.qml'), $qml, (New-Object Text.UTF8Encoding $false))
$err = Join-Path $logs 'loadcheck.err.txt'; $out = Join-Path $logs 'loadcheck.out.txt'
$waku = Join-Path $Bin 'waku.exe'; $wakuc = Join-Path $Bin 'wakuc.exe'
$p = Start-Process -FilePath $waku -PassThru -WindowStyle Hidden -RedirectStandardError $err -RedirectStandardOutput $out `
  -ArgumentList @('--config-home', $home_, '--no-tray', '--import-path', $modules)
$t0 = Get-Date
try {
  while (((Get-Date) - $t0).TotalSeconds -lt $MaxSeconds) {
    Start-Sleep -Seconds 2
    if ($p.HasExited) { break }
    if (Select-String -LiteralPath $err -Pattern 'LOADCHK\|DONE' -Quiet -ErrorAction SilentlyContinue) { break }
  }
} finally {
  & $wakuc --config-home $home_ quit | Out-Null
  if (-not $p.WaitForExit(5000)) { Stop-Process -Id $p.Id -Force }
}
$lines = @(Get-Content $err, $out -ErrorAction SilentlyContinue | Where-Object { $_ -match 'LOADCHK\|' })
$lines | Set-Content (Join-Path $logs 'loadcheck.txt')
$lines | Where-Object { $_ -match 'DONE' }
"errors: " + @($lines | Where-Object { $_ -match '\|ERR\|' }).Count
