# Starts the shell like run.ps1, then saves each visible window of the waku process as its own PNG
# (PrintWindow with PW_RENDERFULLCONTENT), so other windows on top of it do not matter. Read only.
#   .\tools\winshot.ps1 -Seconds 12 -Prefix bar      -> shots\bar-0.png, bar-1.png ...
param([int]$Seconds = 12, [string]$Prefix = 'win', [string[]]$Call, [string]$Bin = (Join-Path $PSScriptRoot '..\bin'))
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$env:HOME = Join-Path $root 'state\home'; $env:OMARCHY_PATH = $root
$env:QT_FORCE_STDERR_LOGGING = '1'; $env:PATH = 'C:\Program Files\Git\usr\bin;' + $env:PATH + ';C:\Program Files\komorebi\bin' # Git's bash and find first: the shell runs bash scripts
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System; using System.Collections.Generic; using System.Runtime.InteropServices;
public static class WinCap {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc p, IntPtr l);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L,T,R,B; }
  // Visible windows of one process larger than 8x8: "handle,width,height"
  public static List<string> For(uint pid) {
    var o = new List<string>();
    EnumWindows((h,l) => { uint p; GetWindowThreadProcessId(h, out p); RECT r; GetWindowRect(h, out r);
      int w = r.R - r.L, hh = r.B - r.T;
      if (p == pid && IsWindowVisible(h) && w > 8 && hh > 8) o.Add(h.ToInt64() + "," + w + "," + hh);
      return true; }, IntPtr.Zero);
    return o;
  }
}
'@
function Save-Windows([uint32]$ProcId, [string]$Path) {
  [void][WinCap]::SetProcessDPIAware()
  $n = 0
  foreach ($e in [WinCap]::For($ProcId)) {
    $f = $e -split ','; $h = [IntPtr][int64]$f[0]; $w = [int]$f[1]; $hh = [int]$f[2]
    $bmp = New-Object Drawing.Bitmap $w, $hh; $g = [Drawing.Graphics]::FromImage($bmp)
    $dc = $g.GetHdc(); [void][WinCap]::PrintWindow($h, $dc, 2); $g.ReleaseHdc($dc); $g.Dispose()
    $bmp.Save("$Path-$n.png", [Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose(); $n++
  }
  $n
}
$logs = Join-Path $root 'logs'; $shots = Join-Path $root 'shots'
New-Item -ItemType Directory -Force $logs, $shots | Out-Null
$p = Start-Process (Join-Path $Bin 'waku.exe') -PassThru -WindowStyle Hidden `
  -ArgumentList @('--config-home', $root, '--no-tray', '--font-engine=directwrite') `
  -RedirectStandardError (Join-Path $logs 'win.err.txt') -RedirectStandardOutput (Join-Path $logs 'win.out.txt')
try {
  Start-Sleep -Seconds $Seconds
  foreach ($c in $Call) { Write-Host "call $c"; & (Join-Path $Bin 'wakuc.exe') --config-home $root call @($c -split ' '); Start-Sleep -Seconds 2 }
  $n = Save-Windows ([uint32]$p.Id) (Join-Path $shots $Prefix)
  Write-Host "saved $n window(s) as shots\$Prefix-N.png"
} finally {
  & (Join-Path $Bin 'wakuc.exe') --config-home $root quit | Out-Null
  if (-not $p.WaitForExit(5000)) { Stop-Process -Id $p.Id -Force; Write-Host 'killed' }
}
