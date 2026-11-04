"""Batch 13: hotkeys for the menu. On Linux Hyprland binds Super+Space; on Windows the engine registers
a GlobalShortcut that has `keys`. Ctrl+Alt+Space opens the menu, Ctrl+Alt+Shift+Space the app list.
Idempotent.
"""
p = "shell.qml"
with open(p, encoding="utf8", newline="") as h:
    t = h.read()
nl = "\r\n" if "\r\n" in t else "\n"
if "omarchy-menu-key" not in t:
    marker = "  // The Unix-socket IPC server (SocketServer) is left out"
    assert marker in t, "marker not found"
    add = nl.join([
        "  // Windows port: hotkeys the engine registers itself (Hyprland binds them on Linux).",
        "  GlobalShortcut {",
        "    appid: \"omarchy\"",
        "    name: \"omarchy-menu-key\"",
        "    description: \"Omarchy menu\"",
        "    keys: \"Ctrl+Alt+Space\"",
        "    onPressed: shell.toggle(\"omarchy.menu\", \"{\\\"menu\\\":\\\"root\\\"}\")",
        "  }",
        "",
        "  GlobalShortcut {",
        "    appid: \"omarchy\"",
        "    name: \"omarchy-apps-key\"",
        "    description: \"Omarchy apps\"",
        "    keys: \"Ctrl+Alt+Shift+Space\"",
        "    onPressed: shell.toggle(\"omarchy.menu\", \"{\\\"menu\\\":\\\"apps\\\"}\")",
        "  }",
        "",
        "",
    ])
    t = t.replace(marker, add + marker, 1)
    with open(p, "w", encoding="utf8", newline="") as h:
        h.write(t)
print("batch13 ok")
