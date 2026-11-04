"""Batch 9: AppLibrary on Windows. Idempotent.
- the engine scans the Start menu only on AppsService.refresh(); call it at start-up
- launch() runs the entry with DesktopEntry.execute() (gtk-launch / uwsm-app do not exist)
- the Linux-only icon index and hidden-entry scans are skipped
"""
p = "services/AppLibrary.qml"
with open(p, encoding="utf8", newline="") as h:
    t = h.read()
nl = "\r\n" if "\r\n" in t else "\n"


def swap(old, new):
    global t
    old = old.replace("\n", nl)
    new = new.replace("\n", nl)
    if new in t:
        return
    assert old in t, "block not found: " + old[:60]
    t = t.replace(old, new, 1)


swap("import qs.Commons\n", "import qs.Commons\nimport waku.services\n")

swap(
    '''    // A terminal app goes through Omarchy's TUI launcher''',
    '''    // Windows port: the engine's DesktopEntry knows how to start itself (exe, UWP, shortcut).
    var winEntry = DesktopEntries.byId(id)
    if (winEntry && typeof winEntry.execute === "function") {
      winEntry.execute()
      return
    }
    // A terminal app goes through Omarchy's TUI launcher''',
)

swap(
    '''  Component.onCompleted: {
    hiddenEntryScan.running = true
    iconIndexScan.running = true
  }''',
    '''  Component.onCompleted: {
    // Windows port: the Start-menu scan starts only on request; the hidden-entry and icon-index
    // scans read XDG folders that do not exist here.
    AppsService.refresh()
  }''',
)

# the values-changed handler also starts the two Linux scans
swap(
    '''      hiddenEntryScan.running = true
      iconIndexDebounce.restart()
      root.appsChanged()''',
    '''      root.appsChanged()''',
)
with open(p, "w", encoding="utf8", newline="") as h:
    h.write(t)
print("batch9 ok")
