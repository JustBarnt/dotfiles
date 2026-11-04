import QtQuick
import Quickshell
import waku.services

ShellRoot {
  Component.onCompleted: AppsService.refresh()
  Timer { interval: 8000; running: true; repeat: false; onTriggered: {
    console.log("PROBE|SVC|ready=" + AppsService.ready + " loading=" + AppsService.loading + " count=" + AppsService.count + " scanMs=" + AppsService.scanMs)
    var v = AppsService.applications.values || []
    console.log("PROBE|SVCVALUES|" + v.length)
    for (var i = 0; i < Math.min(6, v.length); i++) {
      var e = v[i]
      console.log("PROBE|APP|" + e.id + "|" + e.name + "|icon=" + e.icon + "|store=" + e.isStoreApp + "|cmd=" + (e.command ? e.command.join(" ") : ""))
    }
    var q = DesktopEntries.applications.values || []
    console.log("PROBE|DESKTOPENTRIES|" + q.length)
    console.log("PROBE|DONE")
  } }
}
