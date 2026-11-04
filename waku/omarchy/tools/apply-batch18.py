"""Batch 18: start-up commands that exist only on Linux become no-ops (`cmd /c rem`), so the log shows
real problems only. Each one only fed a Linux feature: Hyprland option reads, fontconfig, the
omarchy hardware probe, the plugin file watcher, PowerProfiles over D-Bus, the Linux boot intro.
Idempotent.
"""
import glob
import re

NOOP = 'command: ["cmd.exe", "/c", "rem"]'
PATTERNS = [
    r'command: \["hyprctl"[^\]]*\]',
    r'command: \["fc-match".*?"monospace"\]',
    r'command: \["omarchy-hw-display"[^\]]*\]',
    r'command: \["omarchy-theme-bg-boot-intro"[^\]]*\]',
    r'command: \["busctl"[^\]]*\]',
]
total = 0
for f in glob.glob("**/*.qml", recursive=True):
    if f.startswith(("upstream-src", "bin", "state", "logs", "smoke")):
        continue
    with open(f, encoding="utf8", newline="") as h:
        t = h.read()
    orig = t
    for pat in PATTERNS:
        t, n = re.subn(pat, NOOP, t)
        total += n
    # the plugin watcher (hot reload while developing plugins): multi-line array, and it restarts itself
    t, n = re.subn(r'command: \[\s*"inotifywait",.*?\n    \]', NOOP, t, flags=re.S)
    total += n
    t = t.replace("onExited: localPluginWatcherRestart.restart()", "onExited: {} // Windows port: no inotifywait")
    if t != orig:
        with open(f, "w", encoding="utf8", newline="") as h:
            h.write(t)
print("silenced", total, "commands")
