import QtQuick

// Quickshell.Services.Pipewire's PwNodePeakMonitor has no engine counterpart yet: the input level
// meter in the audio panel stays empty.
QtObject {
    property var node: null
    property bool enabled: false
    readonly property real peak: 0
}
