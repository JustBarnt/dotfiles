import QtQuick
import Quickshell
import waku.services as S

// Logs the Wi-Fi list while a reconnect to the current network runs.
ShellRoot {
    property int tick: 0
    property bool sawEmpty: false
    property int maxSeen: 0

    Timer {
        interval: 250; running: true; repeat: true
        onTriggered: {
            tick++
            var n = (S.Network.networks || []).length
            if (n > maxSeen) maxSeen = n
            if (maxSeen > 0 && n === 0) sawEmpty = true
            console.log("PROBE|t=" + (tick * 0.25).toFixed(2) + " nets=" + n + " scanning=" + S.Network.scanning
                        + " kind=" + S.Network.kind + " ssid=" + S.Network.ssid)
            if (tick === 4) S.Network.refresh()
            if (tick === 20) console.log("PROBE|CONNECT|" + S.Network.connectTo(S.Network.ssid || "Jan 1337"))
            if (tick === 100) console.log("PROBE|RESULT|sawEmptyAfterList=" + sawEmpty + " max=" + maxSeen)
        }
    }
}
