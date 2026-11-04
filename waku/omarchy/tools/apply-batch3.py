"""Batch 3: PopupAnchor `onAnchoring` does not exist in the engine. Each handler body becomes a function
`updateAnchor()` on the popup window, run when the popup shows or changes size. Idempotent.
"""


def rd(p):
    with open(p, encoding="utf8", newline="") as h:
        return h.read()


def wr(p, t):
    with open(p, "w", encoding="utf8", newline="") as h:
        h.write(t)


def extract(t, marker):
    """Remove the `marker {` block; return (text without it, body, index where it was)."""
    i = t.index(marker)
    j = t.index("{", i)
    depth, k = 0, j
    while True:
        c = t[k]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                break
        k += 1
    body = t[j + 1:k]
    # drop the whole line(s) of the handler, including its leading indent
    start = t.rfind("\n", 0, i) + 1
    end = t.find("\n", k) + 1
    return t[:start] + t[end:], body, start


def fn(body, name, indent):
    lines = body.strip("\r\n").split("\n")
    pad = indent
    out = [f"{pad}function {name}() {{"]
    out += [("  " + l if l.strip() else l) for l in lines]
    out.append(f"{pad}}}")
    return "\n".join(out) + "\n"


# PopupCard
p = "modules/qs/Ui/PopupCard.qml"
t = rd(p)
if "onAnchoring" in t:
    t, body, _ = extract(t, "onAnchoring:")
    k = t.index("  onOpenChanged:")
    hooks = (
        "  onVisibleChanged: if (visible) updateAnchor()\n"
        "  onImplicitWidthChanged: updateAnchor()\n"
        "  onImplicitHeightChanged: updateAnchor()\n"
        "  Component.onCompleted: updateAnchor()\n\n"
    )
    t = t[:k] + fn(body, "updateAnchor", "  ") + "\n" + hooks + t[k:]
    wr(p, t)

# Bar tooltip
p = "plugins/bar/Bar.qml"
t = rd(p)
if "onAnchoring" in t:
    t, body, _ = extract(t, "onAnchoring:")
    k = t.index("      anchor {\n        id: tooltipAnchor")
    hooks = (
        "      onVisibleChanged: if (visible) updateAnchor()\n"
        "      onImplicitWidthChanged: updateAnchor()\n"
        "      onImplicitHeightChanged: updateAnchor()\n\n"
    )
    t = t[:k] + fn(body, "updateAnchor", "      ") + "\n" + hooks + t[k:]
    wr(p, t)
print("batch3 done")
