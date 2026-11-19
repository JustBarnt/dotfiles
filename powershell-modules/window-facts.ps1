# Prints what waku's tiler sees for one window, and the first reason it would skip it.
# Mirrors classify() in waku's src/features/tiling/tiling_rules.cpp (rules and cloaking left out).
#
#   .\tools\window-facts.ps1                    wait 5 s, then inspect the focused window (click the game)
#   .\tools\window-facts.ps1 -Delay 10          wait longer
#   .\tools\window-facts.ps1 -Process REPO      inspect the main window of a process by name, no waiting
param(
  [int]$Delay = 5,
  [string]$Process
)
$ErrorActionPreference = 'Stop'

Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class WakuWindowFacts {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [StructLayout(LayoutKind.Sequential)] public struct MONITORINFO { public int cbSize; public RECT rcMonitor; public RECT rcWork; public uint dwFlags; }
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll", EntryPoint = "GetWindowLongPtrW")] public static extern IntPtr GetWindowLongPtr(IntPtr h, int index);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr h, uint cmd);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern IntPtr MonitorFromWindow(IntPtr h, uint flags);
  [DllImport("user32.dll")] public static extern bool GetMonitorInfoW(IntPtr m, ref MONITORINFO info);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int max);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int max);
  [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint access, bool inherit, uint pid);
  [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
  [DllImport("advapi32.dll")] public static extern bool OpenProcessToken(IntPtr process, uint access, out IntPtr token);
  [DllImport("advapi32.dll")] public static extern bool GetTokenInformation(IntPtr token, int cls, out int info, int len, out int ret);

  // Elevated as waku counts it: a process that cannot be opened counts as elevated.
  public static bool Elevated(uint pid) {
    IntPtr process = OpenProcess(0x1000, false, pid);   // PROCESS_QUERY_LIMITED_INFORMATION
    if (process == IntPtr.Zero) return true;
    IntPtr token; bool elevated = true;
    if (OpenProcessToken(process, 0x0008, out token)) { // TOKEN_QUERY
      int value, ret;
      if (GetTokenInformation(token, 20, out value, 4, out ret)) elevated = value != 0;  // TokenElevation
      CloseHandle(token);
    }
    CloseHandle(process);
    return elevated;
  }
}
'@

if ($Process) {
  $name = $Process -replace '\.exe$', ''
  $proc = Get-Process -Name $name -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
  if (-not $proc) { throw "no process named '$name' with a window" }
  $hwnd = $proc.MainWindowHandle
} else {
  Write-Host "Click the window to inspect. Reading the focused window in $Delay s..."
  Start-Sleep -Seconds $Delay
  $hwnd = [WakuWindowFacts]::GetForegroundWindow()
}
if ($hwnd -eq [IntPtr]::Zero) { throw 'no window' }

$style = [WakuWindowFacts]::GetWindowLongPtr($hwnd, -16).ToInt64()
$exStyle = [WakuWindowFacts]::GetWindowLongPtr($hwnd, -20).ToInt64()
$class = [Text.StringBuilder]::new(256); [void][WakuWindowFacts]::GetClassNameW($hwnd, $class, 256)
$title = [Text.StringBuilder]::new(512); [void][WakuWindowFacts]::GetWindowTextW($hwnd, $title, 512)
[uint32]$windowPid = 0; [void][WakuWindowFacts]::GetWindowThreadProcessId($hwnd, [ref]$windowPid)
$owner = [WakuWindowFacts]::GetWindow($hwnd, 4)   # GW_OWNER
$rect = New-Object WakuWindowFacts+RECT; [void][WakuWindowFacts]::GetWindowRect($hwnd, [ref]$rect)
$info = New-Object WakuWindowFacts+MONITORINFO; $info.cbSize = 40
$monitor = [WakuWindowFacts]::MonitorFromWindow($hwnd, 2)   # MONITOR_DEFAULTTONEAREST
$iconic = [WakuWindowFacts]::IsIconic($hwnd)
$fullscreen = $false
if ([WakuWindowFacts]::GetMonitorInfoW($monitor, [ref]$info)) {
  $m = $info.rcMonitor
  $fullscreen = -not $iconic -and $rect.Left -le $m.Left -and $rect.Top -le $m.Top -and $rect.Right -ge $m.Right -and $rect.Bottom -ge $m.Bottom
}
$selfElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$facts = [ordered]@{
  process        = (Get-Process -Id $windowPid -ErrorAction SilentlyContinue).ProcessName
  title          = $title.ToString()
  class          = $class.ToString()
  size           = '{0}x{1} at {2},{3}' -f ($rect.Right - $rect.Left), ($rect.Bottom - $rect.Top), $rect.Left, $rect.Top
  visible        = [WakuWindowFacts]::IsWindowVisible($hwnd)
  minimized      = $iconic
  ownedByVisible = $owner -ne [IntPtr]::Zero -and [WakuWindowFacts]::IsWindowVisible($owner)
  toolWindow     = ($exStyle -band 0x80) -ne 0           # WS_EX_TOOLWINDOW
  resizable      = ($style -band 0x40000) -ne 0          # WS_THICKFRAME
  caption        = ($style -band 0xC00000) -eq 0xC00000  # WS_CAPTION
  maximized      = [WakuWindowFacts]::IsZoomed($hwnd)
  fullscreen     = $fullscreen
  elevated       = [WakuWindowFacts]::Elevated($windowPid)
}

# The same order as classify().
$reason =
  if (-not $facts.visible) { 'not visible' }
  elseif ($facts.minimized) { 'minimized (the tiler retries later)' }
  elseif (-not $facts.title) { 'untitled (the tiler retries later)' }
  elseif ($facts.ownedByVisible) { 'owned by a visible window' }
  elseif ($facts.toolWindow) { 'tool window' }
  elseif (-not $facts.resizable) { 'not resizable (no WS_THICKFRAME)' }
  elseif (-not $facts.caption) { 'no caption (no WS_CAPTION)' }
  elseif ($facts.maximized) { 'maximized' }
  elseif ($facts.fullscreen) { 'fullscreen (covers the whole monitor)' }
  elseif ($facts.elevated -and -not $selfElevated) { 'elevated (and this shell is not)' }
  else { $null }

[pscustomobject]$facts | Format-List
if ($reason) {
  Write-Host "waku's tiler skips this window: $reason" -ForegroundColor Yellow
} else {
  Write-Host "waku's tiler would manage this window (unless a rule, a built-in ignored class or cloaking applies)." -ForegroundColor Green
}
