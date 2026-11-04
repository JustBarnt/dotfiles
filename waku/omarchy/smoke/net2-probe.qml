import QtQuick
import Quickshell
import qs.compat

ShellRoot {
  Timer { interval: 3500; running: true; repeat: false; onTriggered: {
    console.log("PROBE|ENUM|wifi=" + DeviceType.Wifi + " wired=" + DeviceType.Wired + " wpa=" + WifiSecurityType.Wpa + " full=" + NetworkConnectivity.Full + " nm=" + NetworkBackendType.NetworkManager + " noSecrets=" + ConnectionFailReason.NoSecrets)
    var d = Networking.devices.values
    console.log("PROBE|DEVICES|" + d.length + " wifiEnabled=" + Networking.wifiEnabled + " conn=" + Networking.connectivity)
    for (var i = 0; i < d.length; i++) console.log("PROBE|DEV|" + d[i].name + " type=" + d[i].type + " connected=" + d[i].connected + " nets=" + d[i].networks.values.length)
    console.log("PROBE|DONE")
  } }
}
