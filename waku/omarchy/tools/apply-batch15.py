"""Batch 15: the theme and background switchers on Windows. Idempotent.

plugins/image-picker/ImagePicker.qml
  - themes: rows are <home>/.cache/omarchy/theme-selector/previews/<name>.png (tools\\theme-apply.ps1 fills
    it); choosing one runs tools\\theme-apply.ps1 <name>; the Linux intro preview and deletion are off
  - wallpapers: new source "wallpapers"; rows are the images of the current wallpaper's folder; choosing
    one calls the engine's Wallpapers.setWallpaper (the same service Caelestia's port uses)
  - `find` is Git for Windows' find (System32's find.exe is a different program)
"""
import re

P = "plugins/image-picker/ImagePicker.qml"
with open(P, encoding="utf8", newline="") as h:
    t = h.read()
nl = "\r\n" if "\r\n" in t else "\n"


def n(s):
    return s.replace("\n", nl)


def swap(old, new, count=1):
    global t
    old, new = n(old), n(new)
    if new in t:
        return
    assert old in t, "not found: " + old[:70]
    t = t.replace(old, new, count)


swap("import QtQuick.Shapes\n", "import QtQuick.Shapes\nimport waku.services as S\n")

swap(
    "  property bool themeMode: false\n",
    "  property bool themeMode: false\n"
    "  property bool wallpaperMode: false\n"
    "  readonly property string gitFind: \"C:/Program Files/Git/usr/bin/find.exe\"\n"
    "  readonly property string home: String(Quickshell.env(\"HOME\") || \"\").replace(/\\\\/g, \"/\")\n"
    "  readonly property string portPath: String(root.omarchyPath).replace(/\\\\/g, \"/\")\n"
    "  readonly property string previewsPath: root.home + \"/.cache/omarchy/theme-selector/previews\"\n",
)

# open(): the new source
swap(
    "    if (args.source === \"themes\") {\n      openThemes()\n      return\n    }\n",
    "    if (args.source === \"themes\") {\n      openThemes()\n      return\n    }\n"
    "    if (args.source === \"wallpapers\") {\n      openWallpapers()\n      return\n    }\n",
)

# openSelector clears the mode
swap(
    "    themeMode = false\n    themeOpenPending = false\n\n    imageDirs = nextImageDirs",
    "    themeMode = false\n    wallpaperMode = false\n    themeOpenPending = false\n\n    imageDirs = nextImageDirs",
)

# apply
swap(
    "    if (themeMode) {\n      themeMode = false\n      root.opened = false\n      if (path) Util.execArgv([\"omarchy-theme-set\", nameForPath(path)])\n      return\n    }\n",
    "    if (themeMode) {\n      themeMode = false\n      root.opened = false\n      if (path) root.applyTheme(nameForPath(path))\n      return\n    }\n\n"
    "    if (wallpaperMode) {\n      wallpaperMode = false\n      root.opened = false\n      if (path) S.Wallpapers.setWallpaper(String(path).replace(/\\//g, \"\\\\\"))\n      return\n    }\n",
)

# new functions, placed before openThemes()
swap(
    "  function openThemes() {\n",
    "  // Windows PowerShell ships with Windows; the script rewrites the files the shell watches.\n"
    "  function applyTheme(name) {\n"
    "    Quickshell.execDetached([\"powershell.exe\", \"-NoProfile\", \"-ExecutionPolicy\", \"Bypass\", \"-File\", root.portPath + \"/tools/theme-apply.ps1\", String(name)])\n"
    "  }\n\n"
    "  // The images of the folder the current wallpaper lives in; the engine's own list stays empty\n"
    "  // until something configures its folder.\n"
    "  function wallpaperDir() {\n"
    "    var env = String(Quickshell.env(\"OMARCHY_WALLPAPER_DIR\") || \"\")\n"
    "    if (env) return env.replace(/\\\\/g, \"/\")\n"
    "    var current = String(S.Wallpapers.current || \"\").replace(/\\\\/g, \"/\")\n"
    "    if (current.lastIndexOf(\"/\") > 0) return current.slice(0, current.lastIndexOf(\"/\"))\n"
    "    return root.home + \"/Pictures/Wallpapers\"\n"
    "  }\n\n"
    "  property string wallpaperPending: \"\"\n\n"
    "  function openWallpapers() {\n"
    "    wallpaperPending = String(S.Wallpapers.current || \"\").replace(/\\\\/g, \"/\")\n"
    "    wallpaperRowsProc.command = [root.gitFind, root.wallpaperDir(), \"-maxdepth\", \"2\", \"-type\", \"f\", \"(\",\n"
    "      \"-iname\", \"*.jpg\", \"-o\", \"-iname\", \"*.jpeg\", \"-o\", \"-iname\", \"*.png\", \"-o\", \"-iname\", \"*.webp\", \"-o\", \"-iname\", \"*.bmp\", \")\"]\n"
    "    wallpaperRowsProc.running = true\n"
    "  }\n\n"
    "  Process {\n"
    "    id: wallpaperRowsProc\n"
    "    stdout: StdioCollector {\n"
    "      onStreamFinished: {\n"
    "        var rows = String(text || \"\").split(\"\\n\").map(function(l) { return l.trim().replace(/\\\\/g, \"/\") })\n"
    "          .filter(function(l) { return l.length > 0 }).sort().join(\"\\n\")\n"
    "        if (!rows) return\n"
    "        root.openSelector(\"\", rows, root.wallpaperPending, \"\", \"\", true, true)\n"
    "        root.wallpaperMode = true\n"
    "      }\n"
    "    }\n"
    "  }\n\n"
    "  function openThemes() {\n",
)

# theme rows: previews folder instead of omarchy-theme-switcher
swap(
    "    command: [root.omarchyPath + \"/bin/omarchy-theme-switcher\", \"--print-rows\"]\n    stdout: StdioCollector {\n      onStreamFinished: root.updateThemeRows(String(text || \"\").trim())\n    }",
    "    command: [root.gitFind, root.previewsPath, \"-maxdepth\", \"1\", \"-type\", \"f\", \"-name\", \"*.png\"]\n    stdout: StdioCollector {\n"
    "      onStreamFinished: root.updateThemeRows(String(text || \"\").split(\"\\n\").map(function(l) { return l.trim().replace(/\\\\/g, \"/\") })\n"
    "        .filter(function(l) { return l.length > 0 }).sort().join(\"\\n\"))\n    }",
)

# extra / stock theme listings
swap(
    "    command: [\"find\", root.userThemesPath, \"-mindepth\", \"1\", \"-maxdepth\", \"1\", \"-type\", \"d\", \"!\", \"-xtype\", \"l\", \"-printf\", \"%f\\n\"]",
    "    command: [root.gitFind, root.userThemesPath.replace(/\\\\/g, \"/\"), \"-mindepth\", \"1\", \"-maxdepth\", \"1\", \"-type\", \"d\", \"-printf\", \"%f\\n\"]",
)
swap(
    "    command: [\"find\", root.omarchyPath + \"/themes\", \"-mindepth\", \"1\", \"-maxdepth\", \"1\", \"-type\", \"d\", \"-printf\", \"%f\\n\"]",
    "    command: [root.gitFind, root.portPath + \"/themes\", \"-mindepth\", \"1\", \"-maxdepth\", \"1\", \"-type\", \"d\", \"-printf\", \"%f\\n\"]",
)

# no deleting themes (omarchy-theme-remove) and no intro preview (omarchy-theme-bg-boot-intro)
swap(
    "  function canDeleteSelectedTheme() {\n",
    "  function canDeleteSelectedTheme() {\n    return false // Windows port: omarchy-theme-remove does not exist\n  }\n\n  function canDeleteSelectedThemeUpstream() {\n",
)
swap(
    "      if (root.opened && root.themeMode && !introPrepare.running) {",
    "      if (false) { // Windows port: omarchy-theme-bg-boot-intro does not exist",
)

with open(P, "w", encoding="utf8", newline="") as h:
    h.write(t)

# --- the menu and its hotkeys
with open("tools/build-menu.py", encoding="utf8", newline="") as h:
    b = h.read()
if "appearance.theme" not in b:
    b = b.replace(
        'def summon(plugin):\n    return "omarchy-shell shell summon " + plugin + " \'{}\'"\n',
        'def summon(plugin, payload="{}"):\n    return "omarchy-shell shell summon " + plugin + " \'" + payload + "\'"\n',
    )
    b = b.replace(
        '    ("setup", "Setup",',
        '    ("appearance", "Style", "\\U000f0b2f", None, {"aliases": ["style"]}),\n'
        '    ("appearance.theme", "Theme", None, summon("omarchy.image-picker", \'{"source":"themes"}\'),\n'
        '     {"aliases": ["theme", "themes"]}),\n'
        '    ("appearance.background", "Background", None, summon("omarchy.image-picker", \'{"source":"wallpapers"}\'),\n'
        '     {"aliases": ["background", "wallpaper"]}),\n'
        '    ("setup", "Setup",',
        1,
    )
    with open("tools/build-menu.py", "w", encoding="utf8", newline="") as h:
        h.write(b)

with open("shell.qml", encoding="utf8", newline="") as h:
    s = h.read()
if "omarchy-theme-key" not in s:
    marker = "  // The Unix-socket IPC server (SocketServer) is left out"
    add = n(
        "  GlobalShortcut {\n    appid: \"omarchy\"\n    name: \"omarchy-theme-key\"\n    description: \"Theme switcher\"\n"
        "    keys: \"Ctrl+Alt+T\"\n    onPressed: shell.toggle(\"omarchy.image-picker\", \"{\\\"source\\\":\\\"themes\\\"}\")\n  }\n\n"
        "  GlobalShortcut {\n    appid: \"omarchy\"\n    name: \"omarchy-background-key\"\n    description: \"Background switcher\"\n"
        "    keys: \"Ctrl+Alt+B\"\n    onPressed: shell.toggle(\"omarchy.image-picker\", \"{\\\"source\\\":\\\"wallpapers\\\"}\")\n  }\n\n"
    )
    assert marker in s
    s = s.replace(marker, add + marker, 1)
    with open("shell.qml", "w", encoding="utf8", newline="") as h:
        h.write(s)
print("batch15 ok")
