"""Batch 1 mechanical fixes. Idempotent.
- adds `import qs.compat` to every file that uses IpcHandler
- QtQuick.Controls as QQC -> QtQuick.Controls.Basic as QQC
- renames the JS variable `native` (a reserved word in Qt's parser) to `nativeSz`
"""
import glob
import re

SKIP = ("upstream-src", "bin", "reference", "logs", "state")


def rd(p):
    with open(p, encoding="utf8", newline="") as h:
        return h.read()


def wr(p, t):
    with open(p, "w", encoding="utf8", newline="") as h:
        h.write(t)


files = [f for f in glob.glob("**/*.qml", recursive=True) if not f.startswith(SKIP)]
added = 0
for f in files:
    t = rd(f)
    orig = t
    parts = f.replace("\\", "/").split("/")
    if re.search(r"\bIpcHandler\b", t) and "compat" not in parts and not re.search(r"(?m)^import qs\.compat", t):
        m = list(re.finditer(r"(?m)^import [^\r\n]+\r?\n", t))
        last = m[-1]
        nl = "\r\n" if "\r\n" in t else "\n"
        t = t[: last.end()] + "import qs.compat" + nl + t[last.end():]
        added += 1
    t = t.replace("import QtQuick.Controls as QQC", "import QtQuick.Controls.Basic as QQC")
    if re.search(r"\bvar native\b", t):
        t = re.sub(r"\bnative\b", "nativeSz", t)
    if t != orig:
        wr(f, t)
print("compat import added to", added, "files")
