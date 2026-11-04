import QtQuick
import Quickshell
import waku.services as S

// One scanned Wi-Fi network, with the surface of Quickshell.Networking's WifiNetwork that the panel uses.
QtObject {
    id: net

    property string name: ""
    property real signalStrength: 0
    property int security: WifiSecurityType.Open
    property bool connected: false
    property bool known: false
    readonly property bool stateChanging: false

    signal connectionFailed(int reason)

    // The engine joins a network that already has a Windows profile.
    function connect() {
        if (!net.known || !S.Network.connectTo(net.name))
            net.connectionFailed(ConnectionFailReason.NoSecrets)
    }

    // A password for a new network is Windows' business: open its Wi-Fi settings.
    function connectWithPsk(passphrase) {
        Quickshell.execDetached(["explorer.exe", "ms-settings:network-wifi"])
        net.connectionFailed(ConnectionFailReason.WifiClientFailed)
    }

    function disconnect() {
        Quickshell.execDetached(["netsh.exe", "wlan", "disconnect"])
    }

    function forget() {
        Quickshell.execDetached(["netsh.exe", "wlan", "delete", "profile", "name=" + net.name])
    }
}
