import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Bluetooth

ShellRoot {
  PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
  Timer { interval: 4000; running: true; repeat: false; onTriggered: {
    var s = Pipewire.defaultAudioSink
    console.log("PROBE|AUDIO|sink=" + (s ? s.name + " desc=" + s.description + " vol=" + (s.audio ? s.audio.volume + " muted=" + s.audio.muted : "noaudio") : "none"))
    var src = Pipewire.defaultAudioSource
    console.log("PROBE|AUDIO|source=" + (src ? src.name : "none"))
    var nodes = Pipewire.nodes ? Pipewire.nodes.values : []
    console.log("PROBE|AUDIO|nodes=" + nodes.length)
    for (var i = 0; i < Math.min(5, nodes.length); i++) console.log("PROBE|NODE|" + nodes[i].name + " sink=" + nodes[i].isSink + " stream=" + nodes[i].isStream)
    var d = UPower.displayDevice
    console.log("PROBE|BATT|" + (d ? "pct=" + d.percentage + " state=" + d.state + " ready=" + d.ready : "none") + " onBattery=" + UPower.onBattery)
    var a = Bluetooth.defaultAdapter
    console.log("PROBE|BT|" + (a ? "adapter=" + a.name + " enabled=" + a.enabled + " devices=" + (a.devices ? a.devices.values.length : -1) : "no adapter"))
    console.log("PROBE|DONE")
  } }
}
