# Stops every running waku, whichever port it runs. Each is asked to quit through the wakuc that sits
# next to its own waku.exe, with the config home it was started on, so the engine can put the Windows
# taskbar back. Only a waku that ignores the request for 10 seconds is killed.
#   .\stop.ps1
#   .\stop.ps1 -DryRun
param([switch]$DryRun)
$running = @(Get-CimInstance Win32_Process -Filter "Name='waku.exe'" -ErrorAction SilentlyContinue)
if ($running.Count -eq 0) { Write-Host 'no waku is running'; return }
foreach ($proc in $running) {
  $config = if ($proc.CommandLine -match '--config-home\s+(?:"([^"]+)"|(\S+))') { if ($Matches[1]) { $Matches[1] } else { $Matches[2] } } else { '' }
  $wakuc = Join-Path (Split-Path $proc.ExecutablePath) 'wakuc.exe'
  if ($DryRun) { Write-Host "would quit pid $($proc.ProcessId) (config home $config)"; continue }
  Write-Host "quitting pid $($proc.ProcessId) (config home $config)"
  if ($config -and (Test-Path $wakuc)) { & $wakuc --config-home $config quit | Out-Null }
  $p = Get-Process -Id $proc.ProcessId -ErrorAction SilentlyContinue
  if ($p -and -not $p.WaitForExit(10000)) {
    Write-Warning "pid $($proc.ProcessId) did not quit; killing it. The Windows taskbar may stay hidden until the next start."
    Stop-Process -Id $proc.ProcessId -Force
  }
}
