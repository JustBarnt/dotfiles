import QtQuick
import QtQuick.Layouts
import Quickshell
import waku.services as S
import qs.Commons
import qs.Ui

// Windows port of the workspaces widget: komorebi's workspaces of this bar's monitor, through the
// engine's `Workspaces` service (the Hyprland version read hyprctl and a per-monitor block of ten).
// The active workspace shows a filled square, the others their number; one with no windows is dimmed.
BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  // At least this many buttons, so the bar looks the same before komorebi has reported anything.
  readonly property int minimumSlots: 5
  readonly property string komorebic: "C:/Program Files/komorebi/bin/komorebic.exe"

  readonly property string screenName: {
    var window = root.QsWindow.window
    var screen = window ? window.screen : null
    return screen ? String(screen.name) : ""
  }

  // The engine names a monitor "DISPLAY1"; a Quickshell screen is "\\.\DISPLAY1".
  readonly property var monitor: {
    var monitors = S.Workspaces.monitors || []
    var want = root.screenName.toLowerCase()
    for (var i = 0; i < monitors.length; i++) {
      var name = String(monitors[i].name).toLowerCase()
      if (want === name || want.endsWith("\\" + name)) return monitors[i]
    }
    return monitors.length > 0 ? monitors[0] : null
  }

  // [{ number, active, occupied, exists }]
  readonly property var slots: {
    var list = root.monitor ? (root.monitor.workspaces || []) : []
    var out = []
    for (var i = 0; i < list.length; i++) {
      out.push({
        number: i + 1,
        active: !!(list[i].active || list[i].focused),
        occupied: !!list[i].hasWindows,
        exists: true
      })
    }
    for (var n = out.length + 1; n <= root.minimumSlots; n++)
      out.push({ number: n, active: false, occupied: false, exists: false })
    return out
  }

  function focusWorkspace(number) {
    Quickshell.execDetached([root.komorebic, "focus-workspace", String(number - 1)])
  }

  // A wheel notch moves one entry along the row, and a touchpad adds up its smaller deltas.
  property real wheelAccumulator: 0

  function scrollWorkspaces(delta) {
    var wheel = Util.wheelSteps(root.wheelAccumulator, delta)
    root.wheelAccumulator = wheel.remainder
    if (wheel.steps === 0) return
    var current = -1
    for (var i = 0; i < root.slots.length; i++) if (root.slots[i].active) current = i
    if (current === -1) return
    var target = Util.clamp(current - wheel.steps, 0, root.slots.length - 1)
    if (target !== current && root.slots[target].exists) root.focusWorkspace(root.slots[target].number)
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.slots.length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.slots

      WidgetButton {
        required property var modelData

        bar: root.bar
        text: modelData.active ? "\uf0c8" : String(modelData.number)
        opacity: modelData.active || modelData.occupied ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() {
          if (modelData.exists && !modelData.active) root.focusWorkspace(modelData.number)
        }
        onWheelMoved: function(delta) { root.scrollWorkspaces(delta) }
      }
    }
  }
}
