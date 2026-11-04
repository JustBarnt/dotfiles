import QtQuick
import QtQuick.Layouts
import Quickshell
import waku as W
import waku.services as S
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Windows port: the running applications, one icon per program, right of the workspaces. The rows
// are the engine's `TaskbarModel` (every window the taskbar lists, on every komorebi workspace),
// grouped by executable in the order they first appeared. The program with the foreground window
// sits on a highlighted tile, one whose windows are all minimized is dimmed with a dash under the
// icon, and a program with several windows has a count badge. A click raises the window after the
// focused one (or the first), restoring a minimized window; a middle click raises the last one.
BarWidget {
  id: root
  moduleName: "omarchy.apps"

  readonly property real cell: Style.space(22)
  readonly property real gap: Style.space(2)
  // Past this many programs the list stops growing: the rest show as "+N".
  readonly property int maxVisible: Number(setting("maxVisible", 12))
  readonly property color ink: root.bar ? root.bar.barForeground : Commons.Color.foreground
  readonly property string family: root.bar ? root.bar.fontFamily : Style.font.family
  // The attached Window is only available on an Item, so it is read here and handed to the model.
  readonly property var hostWindow: Window.window

  // [{ key, exe, iconUrl, windows: [{ index, title, active, minimized }] }]
  property var groups: []
  // The programs in the order they first showed up, kept while rows come and go.
  property var known: []

  function rebuild() {
    var byExe = {}
    var order = []
    for (var i = 0; i < rows.count; i++) {
      var o = rows.objectAt(i)
      if (!o || o.key.indexOf("w:") !== 0) continue
      var exe = o.exe
      if (!byExe[exe]) {
        byExe[exe] = { key: exe, exe: exe, iconUrl: o.iconUrl, windows: [] }
        order.push(exe)
      }
      var g = byExe[exe]
      if (!g.iconUrl) g.iconUrl = o.iconUrl
      g.windows.push({ index: i, hwnd: Number(o.key.slice(2)) || 0, title: o.title, active: o.active, minimized: o.minimized })
    }
    var kept = []
    var seen = {}
    for (var k = 0; k < root.known.length; k++) {
      if (byExe[root.known[k]]) { kept.push(root.known[k]); seen[root.known[k]] = true }
    }
    for (var n = 0; n < order.length; n++) if (!seen[order[n]]) kept.push(order[n])
    root.known = kept
    var out = []
    for (var m = 0; m < kept.length; m++) out.push(byExe[kept[m]])
    root.groups = out
  }

  // Raise a program: the window after the focused one, else the first (the last for `last`). The
  // only window of a program that already has focus is left alone, as a click on a taskbar button
  // would minimize it.
  function clickGroup(g, last) {
    if (!g || g.windows.length === 0) return
    var target = g.windows[last ? g.windows.length - 1 : 0]
    var focusedAt = -1
    for (var i = 0; i < g.windows.length; i++) if (g.windows[i].active) focusedAt = i
    if (focusedAt >= 0 && g.windows.length === 1) return
    if (focusedAt >= 0 && !last) target = g.windows[(focusedAt + 1) % g.windows.length]
    taskbar.activate(target.index)
  }

  // The preview card of a program with several windows: opens on hover, stays while the pointer is
  // on the tile or the card, and lists the windows by title. `hoverItem` is the tile it hangs from.
  property var hoverGroup: null
  property Item hoverItem: null
  readonly property bool previewOpen: hoverGroup !== null && hoverItem !== null && hoverGroup.windows.length > 1

  function hoverEnter(group, item) {
    closeTimer.stop()
    root.hoverGroup = group
    root.hoverItem = item
  }
  function hoverLeave() { closeTimer.restart() }
  // PopupCard.close() calls this on its owner.
  function close() {
    closeTimer.stop()
    root.hoverGroup = null
    root.hoverItem = null
  }

  // The group as it is now: the preview follows windows opening, closing and changing title.
  readonly property var previewGroup: {
    if (!hoverGroup) return null
    for (var i = 0; i < groups.length; i++) if (groups[i].key === hoverGroup.key) return groups[i]
    return null
  }

  // Where the card opens: just below the bar strip, under the hovered tile. Without a rect the engine
  // anchors to the whole thickness of the bar's window, which spans the screen, and the card would
  // open at the bottom of it. The rect runs from the tile's top to the bottom of the strip.
  readonly property rect previewRect: {
    if (!hoverItem) return Qt.rect(0, 0, 0, 0)
    var top = hoverItem.mapToItem(root, 0, 0).y
    return Qt.rect(0, 0, hoverItem.width, Math.max(1, root.height - top))
  }

  Timer {
    id: closeTimer
    interval: 350
    onTriggered: if (!preview.containsMouse) root.close()
  }

  readonly property var shown: groups.length > maxVisible ? groups.slice(0, maxVisible) : groups
  readonly property int hidden: Math.max(0, groups.length - shown.length)

  visible: !vertical && groups.length > 0
  implicitWidth: visible ? row.implicitWidth + Style.space(8) : 0
  implicitHeight: barSize

  S.TaskbarModel {
    id: taskbar
    // The model has no service of its own: without this it never has a row.
    service: S.TaskbarService
    grouping: false
    // The engine starts its window tracker for a model that has a bar window.
    window: root.hostWindow
  }

  Instantiator {
    id: rows
    model: taskbar
    delegate: QtObject {
      required property string title
      required property bool active
      required property bool minimized
      required property string key
      required property string iconUrl
      required property string uniqueId
      readonly property string exe: uniqueId.split(/[\\/!]/).pop().replace(/\.exe$/i, "")

      onActiveChanged: Qt.callLater(root.rebuild)
      onMinimizedChanged: Qt.callLater(root.rebuild)
      onTitleChanged: Qt.callLater(root.rebuild)
      onIconUrlChanged: Qt.callLater(root.rebuild)
    }
    onObjectAdded: Qt.callLater(root.rebuild)
    onObjectRemoved: Qt.callLater(root.rebuild)
  }

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Style.space(4)
    spacing: root.gap

    Repeater {
      model: root.shown

      delegate: Item {
        id: app
        required property var modelData

        readonly property bool focused: modelData.windows.some(function(w) { return w.active })
        readonly property bool allMinimized: modelData.windows.length > 0 && modelData.windows.every(function(w) { return w.minimized })
        readonly property int count: modelData.windows.length
        readonly property bool hasImage: image.source.toString() !== "" && image.status !== Image.Error

        width: root.cell
        height: root.cell
        opacity: allMinimized && !focused ? 0.5 : 1

        Rectangle {
          anchors.fill: parent
          radius: Style.cornerRadius
          color: app.focused ? Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.18)
            : (area.containsMouse ? Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.08) : "transparent")
        }

        Image {
          id: image
          anchors.centerIn: parent
          width: Math.round(root.cell * 0.68)
          height: width
          visible: app.hasImage
          source: app.modelData.iconUrl
          sourceSize: Qt.size(width * 2, height * 2)
          fillMode: Image.PreserveAspectFit
          asynchronous: true
          smooth: true
          mipmap: true
        }

        // No icon from the engine: the first letter of the program.
        Text {
          anchors.centerIn: parent
          visible: !app.hasImage
          textFormat: Text.PlainText
          text: app.modelData.exe.length > 0 ? app.modelData.exe.charAt(0).toUpperCase() : "?"
          color: root.ink
          font.family: root.family
          font.pixelSize: Style.font.body
          font.bold: true
        }

        // The minimized mark: a short dash under the icon.
        Rectangle {
          visible: app.allMinimized
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 1
          width: Math.round(root.cell * 0.4)
          height: 2
          radius: 1
          color: root.ink
        }

        // The window count, at the icon's top-right corner.
        Rectangle {
          visible: app.count > 1
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.rightMargin: -2
          anchors.topMargin: -2
          width: Math.max(height, badge.implicitWidth + 6)
          height: badge.implicitHeight + 1
          radius: height / 2
          color: Commons.Color.accent

          Text {
            id: badge
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: app.count
            color: Commons.Color.background
            font.family: root.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }

        MouseArea {
          id: area
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton
          cursorShape: Qt.PointingHandCursor
          onClicked: function(mouse) { root.close(); root.clickGroup(app.modelData, mouse.button === Qt.MiddleButton) }
          onEntered: root.hoverEnter(app.modelData, app)
          onExited: root.hoverLeave()
        }
      }
    }

    // "+N": the programs that do not fit.
    Text {
      visible: root.hidden > 0
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: "+" + root.hidden
      color: root.ink
      font.family: root.family
      font.pixelSize: Style.font.bodySmall
      opacity: 0.7
    }
  }
  // The thumbnails are DWM windows drawn above the card, so they go live only once it has settled.
  property bool previewSettled: false
  onPreviewOpenChanged: if (!previewOpen) previewSettled = false
  Timer {
    interval: 220
    running: root.previewOpen && !root.previewSettled
    onTriggered: root.previewSettled = true
  }

  PopupCard {
    id: preview
    anchorItem: root.hoverItem ? root.hoverItem : root
    anchor.rect: root.previewRect
    owner: root
    bar: root.bar
    triggerMode: "hover"
    open: root.previewOpen && root.previewGroup !== null

    readonly property real boxW: Style.space(240)
    readonly property real boxH: Style.space(150)
    readonly property real cardPad: Style.space(6)
    readonly property real cardW: boxW + cardPad * 2
    readonly property real gap: Style.space(8)
    readonly property int count: root.previewGroup ? root.previewGroup.windows.length : 0
    // A single strip while it fits in 60% of the screen, then a wrapping grid.
    readonly property real maxW: Math.max(cardW, (preview.screenW > 0 ? preview.screenW : 1920) * 0.6 - preview.padding * 2)
    readonly property int cols: count <= 0 ? 1
      : (count * cardW + (count - 1) * gap <= maxW ? count : Math.max(1, Math.floor((maxW + gap) / (cardW + gap))))

    // The card pads and borders the content on both sides; the height already counts them.
    contentWidth: preview.fittedContentWidth(grid.implicitWidth + preview.padding * 2 + Border.left(preview.borderSpec) + Border.right(preview.borderSpec))
    contentHeight: preview.fittedContentHeight(grid.implicitHeight)

    GridLayout {
      id: grid
      anchors.fill: parent
      columns: preview.cols
      columnSpacing: preview.gap
      rowSpacing: preview.gap

      Repeater {
        model: root.previewGroup ? root.previewGroup.windows : []

        delegate: Item {
          id: card
          required property var modelData

          implicitWidth: preview.cardW
          implicitHeight: column.implicitHeight + preview.cardPad * 2

          // Omarchy's look: square tiles with no border of their own (the outline belongs to the
          // flyout). The focused window takes the fill a connected network or Bluetooth row has,
          // hover takes the hover fill, the rest a faint tile.
          Rectangle {
            anchors.fill: parent
            radius: 0
            color: card.modelData.active ? Style.selectedFillFor(root.ink, Commons.Color.accent)
              : (cardArea.containsMouse ? Style.hoverFillFor(root.ink, Commons.Color.accent)
              : Style.normalFillFor(root.ink, Commons.Color.accent))
          }

          ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: preview.cardPad
            spacing: Style.space(4)

            // The preview area: the window's live thumbnail, or the program icon when there is none
            // (a minimized window has no DWM thumbnail).
            Item {
              id: box
              Layout.preferredWidth: preview.boxW
              Layout.preferredHeight: preview.boxH

              Rectangle {
                anchors.fill: parent
                radius: 0
                color: Qt.rgba(0, 0, 0, 0.25)
              }

              Image {
                anchors.centerIn: parent
                visible: card.modelData.minimized || !thumb.available
                opacity: card.modelData.minimized ? 0.55 : 1
                width: Style.space(48)
                height: width
                source: root.previewGroup ? root.previewGroup.iconUrl : ""
                sourceSize: Qt.size(width * 2, height * 2)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
              }

              W.WindowThumbnail {
                id: thumb
                readonly property real inset: Style.space(4)
                readonly property real availW: box.width - inset * 2
                readonly property real availH: box.height - inset * 2
                readonly property real ratio: sourceWidth > 0 && sourceHeight > 0 ? sourceWidth / sourceHeight : availW / availH

                x: (box.width - width) / 2
                y: (box.height - height) / 2
                width: Math.min(availW, availH * ratio)
                height: width / ratio
                visible: !card.modelData.minimized
                hwnd: card.modelData.minimized ? 0 : card.modelData.hwnd
                active: root.previewSettled && card.modelData.hwnd !== 0 && !card.modelData.minimized
                fit: W.WindowThumbnail.PreserveAspectFit
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.space(6)

              Image {
                Layout.preferredWidth: Style.space(16)
                Layout.preferredHeight: Style.space(16)
                source: root.previewGroup ? root.previewGroup.iconUrl : ""
                sourceSize: Qt.size(width * 2, height * 2)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
              }

              Text {
                Layout.fillWidth: true
                textFormat: Text.PlainText
                text: card.modelData.title !== "" ? card.modelData.title : (root.previewGroup ? root.previewGroup.exe : "")
                elide: Text.ElideRight
                maximumLineCount: 1
                color: Commons.Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                font.bold: card.modelData.active
              }
            }
          }

          MouseArea {
            id: cardArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              taskbar.activate(card.modelData.index)
              root.close()
            }
          }
        }
      }
    }
  }
}
