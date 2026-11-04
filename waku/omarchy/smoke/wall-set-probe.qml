import QtQuick
import Quickshell
import waku.services

ShellRoot {
  Timer { interval: 2000; running: true; repeat: false; onTriggered: {
    var cur = Wallpapers.current
    console.log("PROBE|BEFORE|" + cur + " lock=" + Wallpapers.setLockScreen)
    Wallpapers.setLockScreen = false
    Wallpapers.setWallpaper(cur)
    console.log("PROBE|CALLED")
  } }
  Timer { interval: 6000; running: true; repeat: false; onTriggered: {
    console.log("PROBE|AFTER|" + Wallpapers.current)
    console.log("PROBE|DONE")
  } }
}
