import QtQuick
import Quickshell
import waku.services

ShellRoot {
  Timer { interval: 4000; running: true; repeat: false; onTriggered: {
    console.log("PROBE|NET|available=" + Network.available + " kind=" + Network.kind + " ssid=" + Network.ssid + " wifiAvail=" + Network.wifiAvailable + " wifiEnabled=" + Network.wifiEnabled)
    console.log("PROBE|ADAPTERS|" + JSON.stringify(Network.adapters).slice(0, 700))
    console.log("PROBE|NETWORKS|" + JSON.stringify(Network.networks).slice(0, 700))
    console.log("PROBE|DONE")
  } }
}
