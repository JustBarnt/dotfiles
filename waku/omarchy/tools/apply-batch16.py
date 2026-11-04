"""Batch 16: Wi-Fi for the network panel, over the engine's `Network` service (waku.services).
Supersedes the Networking.qml that apply-batch10.py writes; run after it. Idempotent.

  compat/WifiNetworkItem.qml   one scanned network: name, signalStrength (0..1), security, connected, known,
                               connect(), disconnect(), forget(), connectWithPsk(); signal connectionFailed
  compat/Networking.qml        wifiEnabled, devices (a Wi-Fi device with its networks, wired adapters),
                               connectivity, backend
  plugins/panels/network/Panel.qml
                               status text from the engine instead of omarchy-network-status, no nmcli/ip/band/DNS
                               shell-outs on refresh, clipboard through Set-Clipboard

The engine connects only to networks Windows has a profile for. A new network or a password goes to
Windows' own Wi-Fi settings. Disconnect and forget use netsh (part of Windows).
"""
import os
import re

COMPAT = "modules/qs/compat"


def write(path, text):
    with open(path, "w", encoding="utf8", newline="\n") as h:
        h.write(text)


# the security values the panel compares against
write(os.path.join(COMPAT, "WifiSecurityType.qml"), """pragma Singleton
import QtQuick

// Quickshell.Networking.WifiSecurityType.
QtObject {
    enum Value {
        Unknown,
        Open,
        Wep,
        Wpa,
        WpaEap,
        Wpa2Eap,
        Sae,
        Owe
    }
}
""")

write(os.path.join(COMPAT, "WifiNetworkItem.qml"), r'''import QtQuick
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
''')

write(os.path.join(COMPAT, "WifiDeviceItem.qml"), r'''import QtQuick
import waku.services as S

// The Wi-Fi interface: its scan result as `networks.values`, and `scannerEnabled`, which asks the
// engine for a fresh scan.
QtObject {
    id: device

    property string name: "Wi-Fi"
    readonly property int type: DeviceType.Wifi
    readonly property bool connected: S.Network.kind === "wifi"
    property bool scannerEnabled: false
    onScannerEnabledChanged: if (scannerEnabled) S.Network.refresh()

    property var items: []
    readonly property var networks: ({ values: device.items })

    // Rebuilt from the engine's list; each record is {ssid, signal 0..100, secured, connected, known}.
    property Instantiator builder: Instantiator {
        model: S.Network.networks || []
        delegate: WifiNetworkItem {
            required property var modelData
            name: String(modelData.ssid || "")
            signalStrength: Number(modelData.signal || 0) / 100
            security: modelData.secured ? WifiSecurityType.Wpa : WifiSecurityType.Open
            connected: !!modelData.connected
            known: !!modelData.known
        }
        onObjectAdded: Qt.callLater(device.collect)
        onObjectRemoved: Qt.callLater(device.collect)
    }

    function collect() {
        var out = []
        for (var i = 0; i < builder.count; ++i) out.push(builder.objectAt(i))
        items = out
    }
}
''')

write(os.path.join(COMPAT, "WiredDeviceItem.qml"), r'''import QtQuick
import waku.services as S

// A wired adapter, as {name, type, connected}.
QtObject {
    property string name: ""
    readonly property int type: DeviceType.Wired
    property bool connected: false
    readonly property var networks: ({ values: [] })
    property bool scannerEnabled: false
}
''')

write(os.path.join(COMPAT, "Networking.qml"), r'''pragma Singleton
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

    property var list: []
    function collect() {
        var out = []
        if (S.Network.wifiAvailable) out.push(root.wifi)
        for (var i = 0; i < wired.count; ++i) out.push(wired.objectAt(i))
        list = out
    }
    Connections {
        target: S.Network
        function onWifiChanged() { root.collect() }
    }
    Component.onCompleted: collect()

    readonly property var devices: ({ values: root.list })
}
''')

qmldir = os.path.join(COMPAT, "qmldir")
with open(qmldir, encoding="utf8", newline="") as h:
    t = h.read()
for line in ("WifiNetworkItem 1.0 WifiNetworkItem.qml", "WifiDeviceItem 1.0 WifiDeviceItem.qml",
             "WiredDeviceItem 1.0 WiredDeviceItem.qml"):
    if line not in t:
        t = t.rstrip("\r\n") + "\n" + line + "\n"
with open(qmldir, "w", encoding="utf8", newline="") as h:
    h.write(t)

# ---- the panel
P = "plugins/panels/network/Panel.qml"
with open(P, encoding="utf8", newline="") as h:
    t = h.read()
nl = "\r\n" if "\r\n" in t else "\n"


def n(s):
    return s.replace("\n", nl)


def swap(old, new):
    global t
    old, new = n(old), n(new)
    if new in t:
        return
    assert old in t, "not found: " + old[:70]
    t = t.replace(old, new, 1)


if "import waku.services as S" not in t:
    t = t.replace("import qs.Ui" + nl, "import waku.services as S" + nl + "import qs.Ui" + nl, 1)

swap(
    "    if (!detailsProc.running) detailsProc.running = true\n"
    "    if (!dnsProc.running) {\n"
    "      dnsProc.command = [\"C:/Program Files/Git/usr/bin/bash.exe\", \"-c\", root.dnsCommand(\"\")]\n"
    "      dnsProc.running = true\n"
    "    }\n"
    "    if (!bandProc.running) {\n"
    "      bandProc.command = [\"omarchy-network-band\"]\n"
    "      bandProc.running = true\n"
    "    }\n",
    "    // Windows port: the engine's Network service replaces omarchy-network-status, and there is no\n"
    "    // resolvectl (DNS rows) or band switch.\n"
    "    root.updateDetails(root.windowsStatus())\n",
)

swap(
    "  function updateDetails(raw) {\n",
    "  // The text omarchy-network-status --verbose prints, from the engine: key=value lines.\n"
    "  function windowsStatus() {\n"
    "    var kind = String(S.Network.kind || \"none\")\n"
    "    if (kind !== \"wifi\" && kind !== \"ethernet\") return \"\"\n"
    "    var lines = []\n"
    "    var iface = kind === \"wifi\" ? \"Wi-Fi\" : \"Ethernet\"\n"
    "    var adapters = S.Network.adapters || []\n"
    "    if (kind === \"ethernet\") {\n"
    "      for (var i = 0; i < adapters.length; i++) {\n"
    "        if (adapters[i].isUp && !/wi-?fi|wlan|wireless|loopback|virtual|vethernet|bluetooth/i.test(String(adapters[i].name))) { iface = String(adapters[i].name); break }\n"
    "      }\n"
    "    }\n"
    "    lines.push(\"iface=\" + iface, \"type=\" + kind, \"ip=\" + (S.Network.ipAddress || \"\"))\n"
    "    lines.push(\"rx_bytes=\" + Math.round(S.Network.rxBytesTotal || 0), \"tx_bytes=\" + Math.round(S.Network.txBytesTotal || 0))\n"
    "    if (kind === \"wifi\") lines.push(\"ssid=\" + (S.Network.ssid || \"\"), \"signal=\" + (S.Network.signalPercent || 0))\n"
    "    return lines.join(\"\\n\")\n"
    "  }\n\n"
    "  function updateDetails(raw) {\n",
)

# shell-outs that do not exist here
t = t.replace('"printf %s " + Util.shellQuote(value) + " | wl-copy"', '"printf %s " + Util.shellQuote(value) + " | clip.exe"')
t = re.sub(
    r'command: \["nmcli", "-t", "-f", "IN-USE,SIGNAL", "device", "wifi", "list", "ifname", root\.wifiDevice \? root\.wifiDevice\.name : "", "--rescan", "no"\]',
    'command: ["cmd.exe", "/c", "rem"]',
    t,
)
with open(P, "w", encoding="utf8", newline="") as h:
    h.write(t)
print("batch16 ok")
