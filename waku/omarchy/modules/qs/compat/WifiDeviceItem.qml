import QtQuick
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

    // S.Network.networks stays empty until the first refresh(), so ask once at start and again when
    // the radio first shows up (the service reports no Wi-Fi for its first second).
    property Connections radioWatch: Connections {
        target: S.Network
        function onWifiAvailableChanged() { if (S.Network.wifiAvailable) S.Network.refresh() }
    }

    property var items: []
    readonly property var networks: ({ values: device.items })

    // Rebuilt from the engine's list; each record is {ssid, signal 0..100, secured, connected, known}.
    // refresh() emits networksChanged when a scan starts, with the same list; feeding that to the
    // Instantiator would rebuild every row. The model only changes when the list does.
    property var scanned: []
    property string scannedSignature: ""
    function syncScanned() {
        var list = S.Network.networks || []
        var signature = JSON.stringify(list)
        if (signature === scannedSignature) return
        scannedSignature = signature
        scanned = list
    }
    Component.onCompleted: {
        Qt.callLater(function() { S.Network.refresh() })
        syncScanned()
    }
    property Connections listWatch: Connections {
        target: S.Network
        function onNetworksChanged() { device.syncScanned() }
    }

    property Instantiator builder: Instantiator {
        model: device.scanned
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
