"""Batch 8: OverlayWindow waits for a Hyprland monitor that never exists on Windows, so no overlay
(menu, pickers, clipboard) ever maps. A stand-in monitor is built from the screen. Idempotent.
"""
p = "modules/qs/Ui/OverlayWindow.qml"
with open(p, encoding="utf8", newline="") as h:
    t = h.read()
nl = "\r\n" if "\r\n" in t else "\n"

old = (
    "      if (targetScreen && monitors[i].name === targetScreen.name) return monitors[i]" + nl
    + "    }" + nl
    + "    return null" + nl
)
new = (
    "      if (targetScreen && monitors[i].name === targetScreen.name) return monitors[i]" + nl
    + "    }" + nl
    + "    // Windows port: Quickshell.Hyprland has no monitors, so the screen stands in for one." + nl
    + "    return targetScreen ? { name: targetScreen.name, scale: targetScreen.devicePixelRatio } : null" + nl
)
if "stands in for one" not in t:
    assert old in t, "targetMonitor block not found"
    t = t.replace(old, new, 1)

t = t.replace(
    "if (shown) Hyprland.refreshMonitors()",
    "if (shown && typeof Hyprland.refreshMonitors === \"function\") Hyprland.refreshMonitors()",
)
with open(p, "w", encoding="utf8", newline="") as h:
    h.write(t)
print("batch8 ok")
