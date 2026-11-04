"""Batch 12: load the Omarchy icon font (assets/fonts/omarchy.ttf) at start-up, and write theme.name.
The bar's menu button draws \\ue900 in the family "omarchy". Idempotent.
"""
p = "shell.qml"
with open(p, encoding="utf8", newline="") as h:
    t = h.read()
nl = "\r\n" if "\r\n" in t else "\n"
if "omarchy.ttf" not in t:
    marker = "ShellRoot {" + nl + "  id: shell" + nl
    assert marker in t, "ShellRoot header not found"
    add = (
        marker + nl
        + "  // Windows port: the Omarchy logo and its icons live in this font." + nl
        + "  FontLoader {" + nl
        + "    source: \"file:///\" + String(Quickshell.shellDir).replace(/\\\\/g, \"/\") + \"/assets/fonts/omarchy.ttf\"" + nl
        + "  }" + nl
    )
    t = t.replace(marker, add, 1)
    with open(p, "w", encoding="utf8", newline="") as h:
        h.write(t)
print("batch12 ok")
