pragma Singleton
import QtQuick
import Quickshell
import waku.services as S

// Quickshell.Networking over the engine's `Network` service. Windows has no NetworkManager, so the
// backend reports NetworkManager (the panel needs one). `devices` holds the Wi-Fi interface (when
// Windows reports a Wi-Fi radio) and each wired adapter.
Singleton {
    id: root

    readonly property int backend: NetworkBackendType.NetworkManager

    property bool wifiEnabled: S.Network.wifiEnabled
    onWifiEnabledChanged: if (wifiEnabled !== S.Network.wifiEnabled) S.Network.setWifiEnabled(wifiEnabled)
    Connections {
        target: S.Network
        function onWifiChanged() { root.wifiEnabled = S.Network.wifiEnabled }
    }
    readonly property bool wifiHardwareEnabled: S.Network.wifiAvailable

    // Windows reports connectivity itself; there is nothing to probe.
    readonly property int connectivity: S.Network.available && S.Network.kind !== "none"
        ? NetworkConnectivity.Full : NetworkConnectivity.None
    readonly property bool canCheckConnectivity: false
    property bool connectivityCheckEnabled: false
    function checkConnectivity() {}

    property WifiDeviceItem wifi: WifiDeviceItem {}

    property Instantiator wired: Instantiator {
        // Only the adapter carrying the connection: the rest are Wi-Fi Direct, Hyper-V and VPN virtuals.
        model: S.Network.kind !== "ethernet" ? [] : (S.Network.adapters || []).filter(function(a) {
            return !!a.isUp && !/wi-?fi|wlan|wireless|loopback|virtual|vethernet|bluetooth|local area connection|vswitch|vpn|tunnel/i.test(String(a.name || ""))
        }).slice(0, 1)
        delegate: WiredDeviceItem {
            required property var modelData
            name: String(modelData.name || "")
            connected: !!modelData.isUp && S.Network.kind === "ethernet"
        }
        onObjectAdded: Qt.callLater(root.collect)
        onObjectRemoved: Qt.callLater(root.collect)
    }

    // A binding, not a rebuild on a signal: the service reports wifiAvailable=false for the first second
    // after start, then true, and no signal the shell hears says so. `wired.count` makes it follow the
    // wired adapters too; collect() stays as the hook the Instantiator calls.
    readonly property var list: {
        var out = []
        if (S.Network.wifiAvailable) out.push(root.wifi)
        for (var i = 0; i < wired.count; ++i) out.push(wired.objectAt(i))
        return out
    }
    function collect() {}

    readonly property var devices: ({ values: root.list })
}
