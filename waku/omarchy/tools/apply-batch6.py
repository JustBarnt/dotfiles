"""Batch 6: `"bash"` in a Process command resolves to C:\\Windows\\System32\\bash.exe (the WSL launcher),
because Windows searches System32 before PATH. WSL cannot read D:\\ paths. Every `"bash"` command
becomes Git for Windows' bash.exe. Idempotent.
"""
import glob

BASH = '"C:/Program Files/Git/usr/bin/bash.exe"'
SKIP = ("upstream-src", "bin", "reference", "logs", "state")
changed = 0
total = 0
for pattern in ("**/*.qml", "**/*.js"):
    for f in glob.glob(pattern, recursive=True):
        if f.startswith(SKIP):
            continue
        with open(f, encoding="utf8", newline="") as h:
            t = h.read()
        n = t.count('"bash"')
        if n:
            with open(f, "w", encoding="utf8", newline="") as h:
                h.write(t.replace('"bash"', BASH))
            changed += 1
            total += n
print("replaced", total, "in", changed, "files")
