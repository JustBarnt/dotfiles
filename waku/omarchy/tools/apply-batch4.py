"""Batch 4: the engine's PopupAnchor has `item`, `rect`, `edges`, `gravity` and no `window`,
`adjustment` or `onAnchoring`. It places a popup next to `anchor.item` by itself (below a top panel,
centred on the widget, kept on screen), so the hand-written positioning of batch 3 is dropped:
the anchor follows the trigger item. Idempotent.
"""
import re


def rd(p):
    with open(p, encoding="utf8", newline="") as h:
        return h.read()


def wr(p, t):
    with open(p, "w", encoding="utf8", newline="") as h:
        h.write(t)


def drop_function(t, name):
    m = re.search(r"(?m)^[ ]*function " + name + r"\(\) \{", t)
    if not m:
        return t
    j = t.index("{", m.start())
    depth, k = 0, j
    while True:
        c = t[k]
        depth += c == "{"
        depth -= c == "}"
        if depth == 0:
            break
        k += 1
    end = t.find("\n", k) + 1
    return t[: m.start()] + t[end:].lstrip("\r\n")


# PopupCard
p = "modules/qs/Ui/PopupCard.qml"
t = rd(p)
t = drop_function(t, "updateAnchor")
t = re.sub(r"(?m)^[ ]*onVisibleChanged: if \(visible\) updateAnchor\(\)\r?\n", "", t)
t = re.sub(r"(?m)^[ ]*onImplicit(Width|Height)Changed: updateAnchor\(\)\r?\n", "", t)
t = re.sub(r"(?m)^[ ]*Component\.onCompleted: updateAnchor\(\)\r?\n", "", t)
t = re.sub(
    r"  anchor \{\r?\n    id: popupAnchor\r?\n.*?\r?\n  \}\r?\n",
    "  anchor {\n    id: popupAnchor\n    item: root.anchorItem\n  }\n",
    t,
    flags=re.S,
)
wr(p, t)

# Bar tooltip
p = "plugins/bar/Bar.qml"
t = rd(p)
t = drop_function(t, "updateAnchor")
t = re.sub(r"(?m)^[ ]*onImplicit(Width|Height)Changed: updateAnchor\(\)\r?\n", "", t)
t = t.replace("onVisibleChanged: { if (!visible) revealed = false; else updateAnchor() }", "onVisibleChanged: if (!visible) revealed = false")
t = re.sub(
    r"      anchor \{\r?\n        id: tooltipAnchor\r?\n.*?\r?\n      \}\r?\n",
    "      anchor {\n        id: tooltipAnchor\n        item: root.tooltipTarget\n      }\n",
    t,
    count=1,
    flags=re.S,
)
wr(p, t)
print("batch4 done")
