"""Batch 10: Quickshell.Networking shim for the network panel. Run once; the files it writes are in the port.
The engine's Quickshell.Networking has only wifiEnabled / wifiHardwareEnabled. The panel also reads
backend, devices, connectivity and five enums. Writes qs.compat singletons for them and points the
panel at qs.compat.
"""
import os

COMPAT = "modules/qs/compat"


def write(name, text):
    with open(os.path.join(COMPAT, name), "w", encoding="utf8", newline="\n") as h:
        h.write(text)


def enum_singleton(name, members, note):
    # A QML enum: property names cannot start with a capital, enum members must.
    body = ("pragma Singleton\nimport QtQuick\n\n// " + note + "\nQtObject {\n    enum Value {\n        "
            + ",\n        ".join(members) + "\n    }\n}\n")
    write(name + ".qml", body)


enum_singleton("DeviceType", ["None", "Wired", "Wifi"], "Quickshell.Networking.DeviceType.")
enum_singleton("NetworkConnectivity", ["Unknown", "None", "Portal", "Limited", "Full"],
               "Quickshell.Networking.NetworkConnectivity.")
enum_singleton("NetworkBackendType", ["None", "NetworkManager", "Iwd"], "Quickshell.Networking.NetworkBackendType.")
enum_singleton("WifiSecurityType", ["Unknown", "Open", "Wep", "Wpa", "WpaEap", "Sae", "Owe"],
               "Quickshell.Networking.WifiSecurityType.")
enum_singleton("ConnectionFailReason",
               ["Unknown", "NoSecrets", "WifiAuthTimeout", "WifiNetworkLost", "WifiClientDisconnected",
                "WifiClientFailed", "WifiAuthFailed", "WifiNotFound"],
               "Quickshell.Networking.ConnectionFailReason.")

write("Networking.qml", '''pragma Singleton
import QtQuick
import Quickshell
import waku.services

// Quickshell.Networking over the engine's `Network` service. Windows has no NetworkManager, so the
// backend reports NetworkManager (the panel needs one) and `devices` is built from `Network.adapters`.
// Each device is {type, connected, name, networks}; a field the adapter does not give stays empty.
Singleton {
    id: root

    readonly property int backend: NetworkBackendType.NetworkManager

    property bool wifiEnabled: Network.wifiEnabled
    onWifiEnabledChanged: if (wifiEnabled !== Network.wifiEnabled) Network.setWifiEnabled(wifiEnabled)
    Connections {
        target: Network
        function onWifiChanged() { root.wifiEnabled = Network.wifiEnabled }
    }
    readonly property bool wifiHardwareEnabled: Network.wifiAvailable

    readonly property int connectivity: Network.available && Network.kind !== "none"
        ? NetworkConnectivity.Full : NetworkConnectivity.None
    // Windows reports connectivity itself; there is nothing to probe.
    readonly property bool canCheckConnectivity: false
    property bool connectivityCheckEnabled: false
    function checkConnectivity() {}

    function buildDevices() {
        var list = Network.adapters || []
        var out = []
        for (var i = 0; i < list.length; ++i) {
            var a = list[i] || {}
            var kind = String(a.kind || a.type || "").toLowerCase()
            out.push({
                type: kind.indexOf("wi") === 0 || kind === "wlan" ? DeviceType.Wifi : DeviceType.Wired,
                connected: !!(a.connected || a.up || a.active),
                name: String(a.name || a.description || ""),
                networks: { values: [] }
            })
        }
        return out
    }

    readonly property var devices: ({ values: root.buildDevices() })
}
''')

qmldir = os.path.join(COMPAT, "qmldir")
with open(qmldir, encoding="utf8", newline="") as h:
    t = h.read()
for line in (
    "singleton Networking 1.0 Networking.qml",
    "singleton DeviceType 1.0 DeviceType.qml",
    "singleton NetworkConnectivity 1.0 NetworkConnectivity.qml",
    "singleton NetworkBackendType 1.0 NetworkBackendType.qml",
    "singleton WifiSecurityType 1.0 WifiSecurityType.qml",
    "singleton ConnectionFailReason 1.0 ConnectionFailReason.qml",
):
    if line not in t:
        t = t.rstrip("\r\n") + "\n" + line + "\n"
with open(qmldir, "w", encoding="utf8", newline="") as h:
    h.write(t)

# the panel: use qs.compat instead of the engine's partial module
p = "plugins/panels/network/Panel.qml"
with open(p, encoding="utf8", newline="") as h:
    t = h.read()
if "import Quickshell.Networking" in t:
    t = t.replace("import Quickshell.Networking", "import qs.compat", 1)
    with open(p, "w", encoding="utf8", newline="") as h:
        h.write(t)
print("batch10 ok")
