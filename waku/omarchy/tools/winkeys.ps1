# Opens a built-in Windows panel by sending its Win-key shortcut.
#   .\tools\winkeys.ps1 emoji        Win+.   the emoji, GIF and symbol picker
#   .\tools\winkeys.ps1 clipboard    Win+V   the clipboard history
# The panel opens over the window that has focus and types into it, so run this from a hotkey or the
# menu. Our own hotkeys use Ctrl+Alt: those are released first, or Windows would see Ctrl+Alt+Win+.
param([Parameter(Mandatory)][ValidateSet('emoji', 'clipboard')][string]$Panel, [int]$DelayMs = 0)
$ErrorActionPreference = 'Stop'
Add-Type -Namespace W -Name K -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern void keybd_event(byte vk, byte scan, uint flags, System.UIntPtr extra);
'@
$KEYUP = 2
$modifiers = 0x11, 0x12, 0x10, 0xA2, 0xA3, 0xA4, 0xA5, 0xA0, 0xA1   # Ctrl, Alt, Shift and their left/right keys
if ($DelayMs -gt 0) { Start-Sleep -Milliseconds $DelayMs }   # lets the menu close and hand focus back
foreach ($m in $modifiers) { [W.K]::keybd_event($m, 0, $KEYUP, [UIntPtr]::Zero) }
Start-Sleep -Milliseconds 60
$key = if ($Panel -eq 'emoji') { 0xBE } else { 0x56 }   # VK_OEM_PERIOD, 'V'
[W.K]::keybd_event(0x5B, 0, 0, [UIntPtr]::Zero)          # Win down
[W.K]::keybd_event($key, 0, 0, [UIntPtr]::Zero)
[W.K]::keybd_event($key, 0, $KEYUP, [UIntPtr]::Zero)
[W.K]::keybd_event(0x5B, 0, $KEYUP, [UIntPtr]::Zero)     # Win up
