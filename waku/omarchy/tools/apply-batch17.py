"""Batch 17: Windows-native replacements and removals. Idempotent.

- bar layout: only widgets that work here (menu, workspaces, clock, weather, tray, bluetooth, network,
  audio, power). Dropped: indicators, world clock (elsewhen), system-update, keyboard-layout, agents,
  monitor. They run omarchy-* / hyprctl / timedatectl commands that Windows does not have.
- plugins switched off: the dropped ones, plus the emoji, clipboard and reminders overlays (Windows has
  Win+. and Win+V), nightlight, remote-session, tailscale, dropbox.
- audio panel: default sink/source through the engine's Pipewire (preferredDefaultAudio*), no helper scripts
- bluetooth panel: power and device actions through the engine's Bluetooth objects
- menu: Trigger > Emoji, Clipboard history (tools/winkeys.ps1); hotkeys Ctrl+Alt+E and Ctrl+Alt+V
"""
import json
import re

# ---------------------------------------------------------------- config
KEEP = {
    "left": ["omarchy.menu", "omarchy.workspaces"],
    "centerBegin": [],
    "center": ["omarchy.clock"],
    "centerEnd": ["omarchy.weather"],
    "right": ["omarchy.tray", "omarchy.bluetooth", "omarchy.network", "omarchy.audio", "omarchy.power"],
}
OFF = [
    "omarchy.background", "omarchy.dock", "omarchy.idle",
    "omarchy.agents", "omarchy.monitor", "omarchy.elsewhen", "omarchy.system-update",
    "omarchy.keyboard-layout", "omarchy.indicators", "omarchy.emojis", "omarchy.clipboard",
    "omarchy.reminders", "omarchy.nightlight", "omarchy.remote-session", "omarchy.tailscale",
    "omarchy.dropbox", "omarchy.wifiqr", "omarchy.speedtest", "omarchy.disk-speedtest",
]
for p in ("config/omarchy/shell.json", "state/home/.config/omarchy/shell.json"):
    with open(p, encoding="utf8") as h:
        d = json.load(h)
    old = d["bar"]["layout"]
    new = {}
    for section, ids in KEEP.items():
        # keep each entry's own settings (the clock's format, for one)
        by_id = {e["id"]: e for e in old.get(section, [])}
        new[section] = [by_id.get(i, {"id": i}) for i in ids]
    d["bar"]["layout"] = new
    d["disabledPlugins"] = sorted(set(d.get("disabledPlugins", [])) | set(OFF))
    with open(p, "w", encoding="utf8", newline="\n") as h:
        json.dump(d, h, indent=2)
        h.write("\n")


# ---------------------------------------------------------------- panels
def patch(path, edits):
    with open(path, encoding="utf8", newline="") as h:
        t = h.read()
    nl = "\r\n" if "\r\n" in t else "\n"
    for old, new in edits:
        old, new = old.replace("\n", nl), new.replace("\n", nl)
        if new in t:
            continue
        assert old in t, path + ": not found: " + old[:70]
        t = t.replace(old, new, 1)
    with open(path, "w", encoding="utf8", newline="") as h:
        h.write(t)


NOOP = '["cmd.exe", "/c", "rem"]'

patch("plugins/panels/audio/Panel.qml", [
    # default output / input: the engine's Pipewire does it
    ("""    Pipewire.preferredDefaultAudioSink = node
    if (node.id !== undefined && node.name) {
      Quickshell.execDetached([
        "omarchy-audio-output-set-default",
        String(node.id),
        String(node.name)
      ])
    }
""", """    Pipewire.preferredDefaultAudioSink = node
"""),
    ("""    if (node.audio) Pipewire.preferredDefaultAudioSource = node
    if (node.id !== undefined && node.name) {
      Quickshell.execDetached([
        "omarchy-audio-input-set-default",
        String(node.id),
        String(node.name)
      ])
    }
""", """    if (node.audio) Pipewire.preferredDefaultAudioSource = node
"""),
    # a Windows output is its own volume sink; there are no DSP sinks to look through
    ("""    if (sink && String(sink.name).indexOf("alsa_output.") === 0) {
      volumeSinkName = String(sink.name)
      return
    }
""", """    if (!sink || String(sink.name) !== "") {
      volumeSinkName = sink ? String(sink.name) : ""
      return
    }
"""),
    ('    command: ["omarchy-audio-sink-availability"]', "    command: " + NOOP),
    ('    command: ["omarchy-audio-sink-availability", "sources"]', "    command: " + NOOP),
    ('    command: ["omarchy-audio-output-sink"]', "    command: " + NOOP),
])

patch("plugins/panels/bluetooth/Panel.qml", [
    ("""    Pipewire.preferredDefaultAudioSink = sink
    if (sink.id !== undefined && sink.name) {
      Quickshell.execDetached([
        "omarchy-audio-output-set-default",
        String(sink.id),
        String(sink.name)
      ])
    }
""", """    Pipewire.preferredDefaultAudioSink = sink
"""),
    ("""    Quickshell.execDetached(["omarchy-bluetooth-power", adapter.enabled ? "off" : "on"])""",
     """    adapter.enabled = !adapter.enabled"""),
    ("""    setPendingAction(device.address, pending)
    Quickshell.execDetached(deviceCommand(action, device.address))
""", """    setPendingAction(device.address, pending)
    // The engine's BluetoothDevice has connect/disconnect/pair/forget; anything else goes to Windows.
    if (typeof device[action] === "function") device[action]()
    else Quickshell.execDetached(["explorer.exe", "ms-settings:bluetooth"])
"""),
    ("""    if (device.disconnect) device.disconnect()
    Quickshell.execDetached(deviceCommand("disconnect", device.address))
""", """    if (device.disconnect) device.disconnect()
"""),
])

# ---------------------------------------------------------------- emoji + clipboard
patch("tools/winkeys.ps1", [
    ("param([Parameter(Mandatory)][ValidateSet('emoji', 'clipboard')][string]$Panel)",
     "param([Parameter(Mandatory)][ValidateSet('emoji', 'clipboard')][string]$Panel, [int]$DelayMs = 0)"),
    ("foreach ($m in $modifiers)", "if ($DelayMs -gt 0) { Start-Sleep -Milliseconds $DelayMs }   # lets the menu close and hand focus back\nforeach ($m in $modifiers)"),
])

with open("tools/build-menu.py", encoding="utf8", newline="") as h:
    b = h.read()
if "trigger.emoji" not in b:
    keys = ('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$OMARCHY_PATH/tools/winkeys.ps1" ')
    b = b.replace(
        '    ("setup", "Setup",',
        '    ("trigger", "Trigger", "\\U000f0e9e", None, {}),\n'
        '    ("trigger.emoji", "Emoji", "\\U000f0785", WINKEYS + "emoji 400", {"aliases": ["emoji"]}),\n'
        '    ("trigger.clipboard", "Clipboard history", "\\U000f0147", WINKEYS + "clipboard 400", {"aliases": ["clipboard"]}),\n'
        '    ("setup", "Setup",',
        1,
    )
    b = b.replace(
        "def summon(plugin",
        "WINKEYS = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$OMARCHY_PATH/tools/winkeys.ps1\" '\n\n\ndef summon(plugin",
        1,
    )
    with open("tools/build-menu.py", "w", encoding="utf8", newline="") as h:
        h.write(b)

with open("shell.qml", encoding="utf8", newline="") as h:
    s = h.read()
nl = "\r\n" if "\r\n" in s else "\n"
if "omarchy-emoji-key" not in s:
    marker = "  // The Unix-socket IPC server (SocketServer) is left out"
    add = nl.join([
        "  GlobalShortcut {",
        "    appid: \"omarchy\"",
        "    name: \"omarchy-emoji-key\"",
        "    description: \"Emoji picker (Windows)\"",
        "    keys: \"Ctrl+Alt+E\"",
        "    onPressed: Quickshell.execDetached([\"powershell.exe\", \"-NoProfile\", \"-ExecutionPolicy\", \"Bypass\", \"-File\", String(Quickshell.shellDir) + \"/tools/winkeys.ps1\", \"emoji\"])",
        "  }",
        "",
        "  GlobalShortcut {",
        "    appid: \"omarchy\"",
        "    name: \"omarchy-clipboard-key\"",
        "    description: \"Clipboard history (Windows)\"",
        "    keys: \"Ctrl+Alt+V\"",
        "    onPressed: Quickshell.execDetached([\"powershell.exe\", \"-NoProfile\", \"-ExecutionPolicy\", \"Bypass\", \"-File\", String(Quickshell.shellDir) + \"/tools/winkeys.ps1\", \"clipboard\"])",
        "  }",
        "",
        "",
    ])
    assert marker in s
    s = s.replace(marker, add + marker, 1)
    with open("shell.qml", "w", encoding="utf8", newline="") as h:
        h.write(s)
print("batch17 ok")
