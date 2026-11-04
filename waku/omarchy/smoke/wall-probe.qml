import QtQuick
import Quickshell
import waku.services

ShellRoot {
  Timer { interval: 3000; running: true; repeat: false; onTriggered: {
    console.log("PROBE|WALL|available=" + Wallpapers.available + " current=" + Wallpapers.current + " imagePath=" + Wallpapers.imagePath + " count=" + (Wallpapers.files ? Wallpapers.files.length : -1))
    var f = Wallpapers.files || []
    for (var i = 0; i < Math.min(3, f.length); i++) console.log("PROBE|FILE|" + JSON.stringify(f[i]))
    console.log("PROBE|DONE")
  } }
}
