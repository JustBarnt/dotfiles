"""Batch 14: plugins that have no job on Windows are switched off in the shipped defaults and in the
test home. omarchy.idle runs omarchy-launch-screensaver and the lock; omarchy.background draws a
wallpaper layer over the one Windows (or another shell) already draws; omarchy.dock is Linux-first.
Idempotent.
"""
import json

OFF = ["omarchy.idle", "omarchy.background", "omarchy.dock"]
for p in ("config/omarchy/shell.json", "state/home/.config/omarchy/shell.json"):
    with open(p, encoding="utf8") as h:
        d = json.load(h)
    d["disabledPlugins"] = sorted(set(d.get("disabledPlugins", [])) | set(OFF))
    with open(p, "w", encoding="utf8", newline="\n") as h:
        json.dump(d, h, indent=2)
        h.write("\n")
    print(p, "->", d["disabledPlugins"])
