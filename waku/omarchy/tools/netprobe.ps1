# Network probe for the Network panel. One long-lived process: every -IntervalMs it prints one line,
#   gateway=<ip> router_ping_ms=<ms|-1> internet_ping_ms=<ms|-1>
# (-1: no reply; the panel counts those as packet loss). The panel starts it when it opens and stops it
# when it closes, so nothing is spawned per sample. It also exits when its reader goes away.
# Plain .NET calls only: the NetTCPIP cmdlets take seconds to load.
param([int]$IntervalMs = 2000, [string]$Target = '1.1.1.1', [switch]$Once)
$ErrorActionPreference = 'SilentlyContinue'
$ping = New-Object System.Net.NetworkInformation.Ping
$out = [Console]::Out

function Get-Gateway {
  foreach ($nic in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
    if ($nic.OperationalStatus -ne 'Up' -or $nic.NetworkInterfaceType -in 'Loopback', 'Tunnel') { continue }
    $g = $nic.GetIPProperties().GatewayAddresses | Where-Object { $_.Address.AddressFamily -eq 'InterNetwork' -and $_.Address.ToString() -ne '0.0.0.0' } | Select-Object -First 1
    if ($g) { return $g.Address.ToString() }
  }
  $null
}
function Start-Probe($Ip) { $ping.SendPingAsync($Ip, 1000) }
function Read-Probe($Task) {
  try { $r = $Task.GetAwaiter().GetResult(); if ($r.Status -eq 'Success') { [int]$r.RoundtripTime } else { -1 } } catch { -1 }
}

$gateway = $null
$cycle = 0
while ($true) {
  $started = [Diagnostics.Stopwatch]::StartNew()
  if ($cycle % 5 -eq 0) { $gateway = Get-Gateway }   # the route rarely changes; look again every 5th sample
  $cycle++
  $p2 = New-Object System.Net.NetworkInformation.Ping   # one Ping object cannot run two sends at once
  $router = if ($gateway) { $p2.SendPingAsync($gateway, 1000) }
  $internet = $ping.SendPingAsync($Target, 1000)
  $line = ''
  if ($gateway) { $line = "gateway=$gateway router_ping_ms=$(Read-Probe $router) " }
  $line += "internet_ping_ms=$(Read-Probe $internet)"
  $p2.Dispose()
  try { $out.WriteLine($line); $out.Flush() } catch { break }
  if ($Once) { break }
  $wait = $IntervalMs - [int]$started.ElapsedMilliseconds
  if ($wait -gt 0) { Start-Sleep -Milliseconds $wait }
}
