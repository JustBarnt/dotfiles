"""Batch 11: Quickshell.env("X") returns undefined when X is unset, which QML refuses to assign to a
string ("Unable to assign [undefined] to QString"). Every unguarded call gets `|| ""`. Idempotent.
"""
import glob
import re

SKIP = ("upstream-src", "bin", "reference", "logs", "state", "smoke")
# not already guarded: preceded by `(` is fine only when followed by ||
PATTERN = re.compile(r'(?<!\()Quickshell\.env\("([A-Za-z0-9_]+)"\)(?!\s*(?:\|\||\?\?))')
total = 0
files = 0
for f in glob.glob("**/*.qml", recursive=True):
    if f.startswith(SKIP):
        continue
    with open(f, encoding="utf8", newline="") as h:
        t = h.read()
    t2, n = PATTERN.subn(r'(Quickshell.env("\1") || "")', t)
    if n:
        with open(f, "w", encoding="utf8", newline="") as h:
            h.write(t2)
        total += n
        files += 1
print("guarded", total, "calls in", files, "files")
