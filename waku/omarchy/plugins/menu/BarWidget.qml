import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.menu"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // Windows port: the Windows logo replaces the Omarchy glyph, painted in the bar foreground.
    iconComponent: Component {
      Item {
        Image {
          id: logo
          anchors.fill: parent
          source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/windows.svg")
          sourceSize.width: width
          sourceSize.height: height
          fillMode: Image.PreserveAspectFit
          visible: false
          layer.enabled: true
        }
        Rectangle {
          anchors.fill: logo
          color: button.foreground
          layer.enabled: true
          layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: logo
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
          }
        }
      }
    }
    onPressed: function(button) {
      if (!root.bar) return
      // Windows port: the shell host is called directly (omarchy-shell and xdg-terminal-exec are Linux
      // programs), and a right click opens Windows Terminal.
      if (button === Qt.RightButton) Quickshell.execDetached(["wt.exe"])
      else if (root.bar.shell) root.bar.shell.toggle("omarchy.menu", "{\"menu\":\"root\"}")
    }
  }
}
