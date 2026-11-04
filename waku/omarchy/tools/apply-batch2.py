"""Batch 2: engine FINAL-property clashes and missing properties. Idempotent.
- KeyboardPanel `content` -> `panelContent` (PanelWindow in the engine has a FINAL `content`)
- notifications surface `margins` -> `edgeMargins` (PanelWindow FINAL `margins`)
- Background `updatesEnabled: true` removed (no such property; the default is already true)
- PopupCard `mask:` removed (PopupWindow has no mask)
"""
import re


def rd(p):
    with open(p, encoding="utf8", newline="") as h:
        return h.read()


def wr(p, t):
    with open(p, "w", encoding="utf8", newline="") as h:
        h.write(t)


# 1. content -> panelContent
panels = [
    "plugins/agents/Panel.qml", "plugins/panels/audio/Panel.qml", "plugins/panels/bluetooth/Panel.qml",
    "plugins/panels/clock/Panel.qml", "plugins/panels/dropbox/Panel.qml", "plugins/panels/elsewhen/Panel.qml",
    "plugins/panels/monitor/Panel.qml", "plugins/panels/network/Panel.qml", "plugins/panels/power/Panel.qml",
    "plugins/panels/tailscale/Panel.qml", "plugins/panels/weather/Panel.qml",
]
for p in panels:
    t = rd(p)
    t2 = re.sub(r"(?m)^(\s*)content: PanelKeyCatcher \{", r"\1panelContent: PanelKeyCatcher {", t)
    if t2 != t:
        wr(p, t2)
p = "modules/qs/Ui/KeyboardPanel.qml"
t = rd(p)
t = t.replace("property Component content: null", "property Component panelContent: null")
t = t.replace("!!root.content &&", "!!root.panelContent &&").replace("sourceComponent: root.content", "sourceComponent: root.panelContent")
wr(p, t)

# 2. notifications margins
p = "plugins/notifications/Service.qml"
t = rd(p)
t = t.replace("readonly property var margins: service.marginsFor(", "readonly property var edgeMargins: service.marginsFor(")
t = re.sub(r"\bsurface\.margins\b", "surface.edgeMargins", t)
wr(p, t)

# 3. Background updatesEnabled
p = "plugins/background/Background.qml"
t = rd(p)
t = re.sub(r"(?m)^\s*updatesEnabled: true\r?\n", "", t)
wr(p, t)

# 4. PopupCard mask
p = "modules/qs/Ui/PopupCard.qml"
t = rd(p)
t = re.sub(r"(?m)^\s*mask: Region \{ item: root\.open \? card : null \}\r?\n", "", t)
wr(p, t)
print("batch2 done")
