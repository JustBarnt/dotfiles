import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import waku as W
import waku.services as S
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "ImagePickerModel.js" as ImagePickerModel

Item {
  id: root

  // Injected by omarchy-shell; defaults to the session OMARCHY_PATH.
  property string omarchyPath: (Quickshell.env("OMARCHY_PATH") || "")
  property string stateHome: (Quickshell.env("HOME") || "") + "/.local/state"
  property string userThemesPath: (Quickshell.env("HOME") || "") + "/.config/omarchy/themes"
  property string imageDirs: Quickshell.env("OMARCHY_IMAGE_SELECTOR_DIRS") || Quickshell.env("OMARCHY_IMAGE_SELECTOR_DIR") || Quickshell.env("OMARCHY_STOCK_BACKGROUNDS_DIR") || (stateHome + "/omarchy/current/theme/backgrounds")
  property string imageRows: ""
  property string loadedImageRows: ""
  property string selectionFile: Quickshell.env("OMARCHY_IMAGE_SELECTOR_SELECTION_FILE") || (Quickshell.env("OMARCHY_BACKGROUND_SELECTION_FILE") || "")
  property string selectedImage: (Quickshell.env("OMARCHY_IMAGE_SELECTOR_SELECTED") || "")
  property int selectedIndex: 0
  property bool imagesLoaded: false
  property bool opened: false
  property bool showLabels: false
  property bool filterable: false
  property bool layoutSettled: false
  property bool neighborImagesEnabled: false
  property int renderedFrames: 0
  property bool requestActive: false
  property int requestSerial: 0
  property int applySerial: 0
  property string doneFile: ""
  property string filterText: ""
  property var doneFilesToRelease: []
  // Themes open from rows the shell already holds, so the picker shows without
  // waiting on omarchy-theme-switcher; each open refreshes them behind it.
  property string themeRows: ""
  property bool themeMode: false
  property bool wallpaperMode: false
  readonly property string gitFind: "C:/Program Files/Git/usr/bin/find.exe"
  readonly property string home: String(Quickshell.env("HOME") || "").replace(/\\/g, "/")
  readonly property string portPath: String(root.omarchyPath).replace(/\\/g, "/")
  readonly property string previewsPath: root.home + "/.cache/omarchy/theme-selector/previews"
  property bool themeOpenPending: false
  property var extraThemeNames: []
  property var stockThemeNames: []
  property bool stockThemesKnown: false
  property bool awaitingDeleteRefresh: false
  property string pendingDeleteTheme: ""
  property string deleteSelectionPath: ""
  property bool deleteConfirmOpen: false
  // Bound to the central [image-picker] section in shell.toml via Commons.Color.qml.
  // `dimColor` tints unselected slices and text outlines against the desktop
  // behind the picker; it intentionally tracks the foundational background,
  // not a surface role.
  property color dimColor: Commons.Color.background
  property color foreground: Commons.Color.imagePicker.text
  property color selectedBorder: Commons.Color.imagePicker.selectedBorder
  property color unselectedBorder: Commons.Color.imagePicker.unselectedBorder
  property int expandedWidth: 768
  property int expandedHeight: 475
  property int sliceWidth: 108
  property int sliceHeight: 432
  property int sliceSpacing: -30
  property int skewOffset: 28
  property int bottomChromeHeight: showLabels ? (filterable ? 104 : 74) : (filterable ? 60 : 30)
  // Render only what fits on this display, plus one prefetch slice per side.
  readonly property int previewRadius: Math.max(1, Math.min(16, Math.ceil((panel.width - expandedWidth) / (2 * (sliceWidth + sliceSpacing))) + 1))
  onPreviewRadiusChanged: updateVisibleItems()

  onOpenedChanged: if (!opened) { layoutSettled = false; renderedFrames = 0; deleteConfirmOpen = false; pendingDeleteTheme = ""; deleteSelectionPath = ""; awaitingDeleteRefresh = false }

  PreviewHold {
    id: previewHold
    active: root.opened
    // The selected preview decodes first again on the next open.
    onHeldChanged: if (!held) root.neighborImagesEnabled = false
  }

  function scriptPath(name) {
    return omarchyPath + "/plugins/image-picker/" + name
  }

  function focusPicker() {
    if (root.opened && root.imagesLoaded && root.layoutSettled)
      carousel.forceActiveFocus()
  }

  function revealWhenSettled(serial) {
    Qt.callLater(function() {
      if (serial === root.requestSerial) root.maybeReveal()
    })
  }

  // The card renders at opacity 0 until every visible preview has decoded
  // and its masked layers have presented, so the picker lands in one
  // complete frame instead of flashing its images in as each asynchronous
  // decode and layer upload finishes.
  function allPreviewsSettled() {
    if (!opened || !imagesLoaded || layoutSettled || imageArray.length === 0 || imageCards.count === 0) return false
    for (var i = 0; i < imageCards.count; i++) {
      var item = imageCards.itemAt(i)
      if (!item || !item.previewSettled) return false
    }
    return true
  }

  function settleReveal() {
    if (!opened || !imagesLoaded || layoutSettled || imageArray.length === 0) return
    layoutSettled = true
    focusPicker()
  }

  function maybeReveal() {
    if (!allPreviewsSettled() || renderedFrames < 2) return
    // Confirm on the next tick: delegates inserted later in the same window
    // sync must not pop in after an early all-ready reading.
    Qt.callLater(function() {
      if (root.allPreviewsSettled() && root.renderedFrames >= 2) root.settleReveal()
    })
  }

  function currentPath() {
    if (imageArray.length === 0 || !itemMatches(selectedIndex)) return ""
    return imageArray[selectedIndex].filePath
  }

  function nameForPath(path) {
    return ImagePickerModel.nameForPath(path)
  }

  function labelForPath(path) {
    return ImagePickerModel.labelForPath(path)
  }

  function currentLabel() {
    var path = currentPath()
    if (!path) return filterText ? Commons.I18n.t("common.noMatches") : ""

    return labelForPath(path)
  }

  function itemMatches(index) {
    return ImagePickerModel.itemMatches(imageArray, index, filterText)
  }

  function firstMatchingIndex() {
    return ImagePickerModel.firstMatchingIndex(imageArray, filterText)
  }

  function select(index, immediate) {
    if (imageArray.length === 0) return
    if (index < 0) index = 0
    else if (index >= imageArray.length) index = imageArray.length - 1
    if (!itemMatches(index)) return
    if (index === selectedIndex && immediate !== true) return

    selectedIndex = index
  }

  function selectAdjacent(direction) {
    var count = imageArray.length
    if (count === 0) return

    var index = selectedIndex
    for (var i = 0; i < count; i++) {
      index = (index + direction + count) % count
      if (itemMatches(index)) {
        select(index)
        return
      }
    }
  }

  function updateFilter(nextFilterText) {
    filterText = nextFilterText

    if (!itemMatches(selectedIndex)) {
      var first = ImagePickerModel.nextSelectedIndexForFilter(imageArray, selectedIndex, filterText)
      if (first >= 0) selectedIndex = first
    }
  }

  function releaseNextDoneFile() {
    if (releaseProc.running || doneFilesToRelease.length === 0) return

    var path = doneFilesToRelease.shift()
    releaseProc.command = ["C:/Program Files/Git/usr/bin/bash.exe", "-c", ": > " + Util.shellQuote(path)]
    releaseProc.running = true
  }

  function finishDoneFile(path) {
    if (!path) return
    doneFilesToRelease.push(path)
    releaseNextDoneFile()
  }

  function applySelected() {
    if (themeMode && (deleteThemeProc.running || awaitingDeleteRefresh)) return
    var path = currentPath()

    if (themeMode) {
      themeMode = false
      root.opened = false
      if (path) root.applyTheme(nameForPath(path))
      return
    }

    if (wallpaperMode) {
      wallpaperMode = false
      root.opened = false
      if (path) root.setWallpaper(String(path))
      return
    }

    if (!path || !selectionFile) {
      cancel()
      return
    }

    var activeSelectionFile = selectionFile
    var activeDoneFile = doneFile
    applySerial = requestSerial
    requestActive = false
    selectionFile = ""
    doneFile = ""

    applyProc.command = ["C:/Program Files/Git/usr/bin/bash.exe", "-c", "printf '%s\\n' " + Util.shellQuote(path) + " > " + Util.shellQuote(activeSelectionFile) + "; : > " + Util.shellQuote(activeDoneFile)]
    applyProc.running = true
  }

  function cancel() {
    themeOpenPending = false

    if (requestActive)
      finishDoneFile(doneFile)

    requestActive = false
    selectionFile = ""
    doneFile = ""
    root.opened = false
  }

  function closeSelector(nextDoneFile) {
    requestSerial += 1
    themeOpenPending = false

    if (requestActive)
      finishDoneFile(doneFile)

    if (nextDoneFile && nextDoneFile !== doneFile)
      finishDoneFile(nextDoneFile)

    requestActive = false
    selectionFile = ""
    doneFile = ""
    filterText = ""
    root.opened = false
  }

  function loadRows(rows, reveal) {
    var newImages = ImagePickerModel.loadRows(rows)

    root.loadedImageRows = rows
    var nextIndex = root.indexForSelectedImage(newImages)
    root.selectedIndex = ImagePickerModel.nextSelectedIndexForFilter(newImages, nextIndex, root.filterText)
    root.neighborImagesEnabled = false
    root.imageArray = newImages
    root.imagesLoaded = true
    Qt.callLater(root.enableNeighborsWhenReady)

    if (reveal !== false) {
      root.opened = true
      root.revealWhenSettled(root.requestSerial)
    }
  }

  function openSelector(nextImageDirs, nextImageRows, nextSelectedImage, nextSelectionFile, nextDoneFile, nextShowLabels, nextFilterable) {
    deleteConfirmOpen = false
    pendingDeleteTheme = ""
    deleteSelectionPath = ""
    awaitingDeleteRefresh = false
    if (requestActive && doneFile && doneFile !== nextDoneFile)
      finishDoneFile(doneFile)

    requestSerial += 1
    themeMode = false
    wallpaperMode = false
    themeOpenPending = false

    imageDirs = nextImageDirs
    imageRows = nextImageRows
    selectedImage = nextSelectedImage
    selectionFile = nextSelectionFile
    doneFile = nextDoneFile
    requestActive = !!doneFile
    showLabels = nextShowLabels === true || nextShowLabels === "true"
    filterable = nextFilterable === true || nextFilterable === "true"
    filterText = ""
    layoutSettled = false

    if (imageRows && imageRows === loadedImageRows && imageArray.length > 0) {
      root.select(root.selectedImageIndex(), true)
      imagesLoaded = true
      opened = true
      root.revealWhenSettled(requestSerial)
      return
    }

    if (imageRows) {
      var rowsToLoad = imageRows
      var rowsSerial = requestSerial
      imageArray = []
      selectedIndex = 0
      imagesLoaded = true
      opened = true
      Qt.callLater(function() {
        if (rowsSerial === root.requestSerial)
          root.loadRows(rowsToLoad, true)
      })
      return
    }

    imageArray = []
    selectedIndex = 0
    imagesLoaded = false
    opened = false
    startImageScan(requestSerial, imageDirs)
  }

  property var imageArray: []
  readonly property var matchingImageIndices: ImagePickerModel.matchingIndices(imageArray, filterText)
  onMatchingImageIndicesChanged: updateVisibleItems()
  onSelectedIndexChanged: {
    updateVisibleItems()
    introPrepareTimer.restart()
  }
  onThemeModeChanged: if (themeMode) introPrepareTimer.restart()

  Timer {
    id: introPrepareTimer
    interval: 75
    onTriggered: {
      if (false) { // Windows port: omarchy-theme-bg-boot-intro does not exist
        introPrepare.theme = root.nameForPath(root.currentPath())
        introPrepare.command = ["omarchy-theme-bg-boot-intro", "--prepare-theme", root.nameForPath(root.currentPath())]
        introPrepare.running = true
      }
    }
  }

  Process {
    id: introPrepare
    property string theme: ""
    onExited: if (root.opened && root.themeMode && theme !== root.nameForPath(root.currentPath())) introPrepareTimer.restart()
  }

  function updateVisibleItems() {
    ImagePickerModel.syncWindow(visibleImages, ImagePickerModel.visibleWindow(matchingImageIndices, selectedIndex, previewRadius))
  }

  function enableNeighborsWhenReady() {
    for (var i = 0; i < imageCards.count; i++) {
      var item = imageCards.itemAt(i)
      if (item && item.selected && item.previewReady) neighborImagesEnabled = true
    }
  }

  ListModel { id: visibleImages }


  function currentThemePreview() {
    var name = String(themeNameFile.text() || "").trim()
    var images = ImagePickerModel.loadRows(themeRows)
    for (var i = 0; i < images.length; i++) {
      if (nameForPath(images[i].filePath) === name) return images[i].filePath
    }
    return ""
  }

  // Windows PowerShell ships with Windows; the script rewrites the files the shell watches.
  function applyTheme(name) {
    Quickshell.execDetached(["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", root.portPath + "/tools/theme-apply.ps1", String(name)])
  }

  // The images of the folder the current wallpaper lives in; the engine's own list stays empty
  // until something configures its folder.
  function wallpaperDir() {
    var env = String(Quickshell.env("OMARCHY_WALLPAPER_DIR") || "")
    if (env) return env.replace(/\\/g, "/")
    var current = String(S.Wallpapers.current || "").replace(/\\/g, "/")
    if (current.lastIndexOf("/") > 0) return current.slice(0, current.lastIndexOf("/"))
    return root.home + "/Pictures/Wallpapers"
  }

  property string wallpaperPending: ""

  // The engine ignores setWallpaper ("No image paths configured") until it has been told its folder,
  // so give it the folder of the picked image first. No hotkey, no auto-change: this shell owns those.
  function setWallpaper(path) {
    var file = path.replace(/\\/g, "/")
    var folder = file.lastIndexOf("/") > 0 ? file.slice(0, file.lastIndexOf("/")) : root.wallpaperDir()
    if (String(S.Wallpapers.imagePath).replace(/\\/g, "/") !== folder) S.Wallpapers.configure(folder, "", "primary", 0)
    S.Wallpapers.setWallpaper(file)
  }

  // Wallpapers are 4K files: decoding one per card is what made the picker slow. The engine's
  // image://thumb provider returns a downscaled copy from a memory and disk cache, decoded off the
  // GUI thread (the same provider the Caelestia port uses). The width fits the expanded card at
  // 2x; theme previews are small already and load as files.
  readonly property int thumbnailWidth: 1280

  function cardSource(path) {
    if (!path) return ""
    if (!wallpaperMode) return Util.fileUrl(path)
    return W.Thumbnails.url(String(path).replace(/\\/g, "/"), thumbnailWidth)
  }

  // Fills the thumbnail cache in the background, the current wallpaper first and then its
  // neighbours outward, so the picker opens on images that are ready.
  function prewarmWallpapers(paths, current) {
    var n = paths.length
    if (n === 0) return
    var start = Math.max(0, paths.indexOf(current))
    var order = [paths[start]]
    for (var d = 1; order.length < n; d++) {
      if (order.length < n) order.push(paths[(start + d) % n])
      if (order.length < n && 2 * d < n) order.push(paths[(start - d + n) % n])
    }
    W.Thumbnails.cancelPrewarm()
    W.Thumbnails.prewarm(order, thumbnailWidth)
  }

  // The scan takes a moment. Until its result arrives the picker may still show the theme layout
  // (the background hotkey pressed while the theme switcher is open), so the old cards go at once,
  // and a list from an earlier scan of the same folder opens without waiting.
  property var wallpaperCache: []
  property string wallpaperCacheDir: ""

  function openWallpapers() {
    wallpaperPending = String(S.Wallpapers.current || "").replace(/\\/g, "/")
    if (opened && !wallpaperMode) {
      imageArray = []
      selectedIndex = 0
      themeMode = false
    }
    if (wallpaperCache.length > 0 && wallpaperCacheDir === root.wallpaperDir()) {
      openWallpaperList(wallpaperCache)
      wallpaperWarmOnly = true // the rescan only refreshes the cache
    } else {
      wallpaperWarmOnly = false
    }
    scanWallpapers()
  }

  function openWallpaperList(list) {
    root.openSelector("", list.join("\n"), root.wallpaperPending, "", "", true, true)
    root.wallpaperMode = true
  }

  property bool wallpaperWarmOnly: false

  function scanWallpapers() {
    if (wallpaperRowsProc.running) return
    wallpaperRowsProc.command = [root.gitFind, root.wallpaperDir(), "-maxdepth", "2", "-type", "f", "(",
      "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", "-o", "-iname", "*.bmp", ")"]
    wallpaperRowsProc.running = true
  }

  // Warm the cache shortly after start, so even the first open shows images at once.
  Timer {
    interval: 6000; running: true; repeat: false
    onTriggered: { root.wallpaperWarmOnly = true; root.scanWallpapers() }
  }

  Process {
    id: wallpaperRowsProc
    stdout: StdioCollector {
      onStreamFinished: {
        var list = String(text || "").split("\n").map(function(l) { return l.trim().replace(/\\/g, "/") })
          .filter(function(l) { return l.length > 0 }).sort()
        if (list.length === 0) return
        var current = root.wallpaperPending || String(S.Wallpapers.current || "").replace(/\\/g, "/")
        root.wallpaperCache = list
        root.wallpaperCacheDir = root.wallpaperDir()
        root.prewarmWallpapers(list, current)
        if (root.wallpaperWarmOnly) return
        root.openWallpaperList(list)
      }
    }
  }

  function openThemes() {
    if (themeRows) {
      openThemeRows()
    } else {
      // First open before the startup refresh has landed.
      themeOpenPending = true
    }
    refreshThemeRows()
    refreshExtraThemes()
    refreshStockThemes()
  }

  function openThemeRows() {
    openSelector("", themeRows, currentThemePreview(), "", "", true, true)
    themeMode = true
  }

  // A refresh asked mid-refresh (a deletion finishing behind the open-time
  // one) queues a second pass instead of leaving the list stale.
  function refreshThemeRows() {
    if (themeRowsProc.running) { themeRowsProc.queued = true; return }
    themeRowsProc.running = true
  }

  function refreshExtraThemes() {
    if (extraThemesProc.running) { extraThemesProc.queued = true; return }
    extraThemesProc.running = true
  }

  function refreshStockThemes() {
    if (!stockThemesProc.running) stockThemesProc.running = true
  }

  function selectedThemeName() {
    return nameForPath(currentPath())
  }

  function canDeleteSelectedTheme() {
    return false // Windows port: omarchy-theme-remove does not exist
  }

  function canDeleteSelectedThemeUpstream() {
    return themeMode && !deleteThemeProc.running && !awaitingDeleteRefresh && stockThemesKnown && ImagePickerModel.canDeleteTheme(selectedThemeName(), extraThemeNames, stockThemeNames)
  }

  function requestDeleteSelectedTheme() {
    if (!canDeleteSelectedTheme()) return
    pendingDeleteTheme = selectedThemeName()
    deleteConfirm.selectedIndex = 1
    deleteConfirmOpen = true
  }

  function cancelDeleteTheme() {
    deleteConfirmOpen = false
    pendingDeleteTheme = ""
  }

  // Removal itself is omarchy-theme-remove's job (including its guards and
  // notification); the picker only refreshes its rows once it finishes.
  function confirmDeleteTheme() {
    var name = pendingDeleteTheme
    deleteConfirmOpen = false
    pendingDeleteTheme = ""
    if (!name || deleteThemeProc.running) return
    // Keep the user's place in the list once the deleted theme is gone.
    if (name === selectedThemeName()) deleteSelectionPath = ImagePickerModel.replacementSelectionPath(imageArray, selectedIndex, filterText)
    deleteThemeProc.command = ["omarchy-theme-remove", name]
    deleteThemeProc.running = true
  }

  function updateThemeRows(rows) {
    var changed = rows !== themeRows
    themeRows = rows

    if (themeOpenPending) {
      themeOpenPending = false
      if (rows) openThemeRows()
    } else if (changed && rows && themeMode && opened) {
      // A theme was added or removed since the rows were last read. Keep the
      // user's place in the carousel rather than jumping back to the current;
      // a just-deleted selection lands on the theme before it.
      selectedImage = deleteSelectionPath || currentPath() || currentThemePreview()
      deleteSelectionPath = ""
      awaitingDeleteRefresh = false
      imageRows = rows
      loadRows(rows, false)
    }
  }

  FileView {
    id: themeNameFile
    path: root.stateHome + "/omarchy/current/theme.name"
    watchChanges: true
    onFileChanged: reload()
  }

  Process {
    id: themeRowsProc
    property bool queued: false
    command: [root.gitFind, root.previewsPath, "-maxdepth", "1", "-type", "f", "-name", "*.png"]
    stdout: StdioCollector {
      onStreamFinished: root.updateThemeRows(String(text || "").split("\n").map(function(l) { return l.trim().replace(/\\/g, "/") })
        .filter(function(l) { return l.length > 0 }).sort().join("\n"))
    }
    onExited: {
      if (queued) {
        queued = false
        running = true
      }
    }
  }

  // The same listing omarchy-theme-remove offers interactively: real
  // directories under the user themes path, never symlinked working copies.
  Process {
    id: extraThemesProc
    property bool queued: false
    command: [root.gitFind, root.userThemesPath.replace(/\\/g, "/"), "-mindepth", "1", "-maxdepth", "1", "-type", "d", "-printf", "%f\n"]
    stdout: StdioCollector {
      onStreamFinished: root.extraThemeNames = ImagePickerModel.parseThemeNames(String(text || ""))
    }
    onExited: {
      if (queued) {
        queued = false
        running = true
      }
    }
  }

  Process {
    id: stockThemesProc
    command: [root.gitFind, root.portPath + "/themes", "-mindepth", "1", "-maxdepth", "1", "-type", "d", "-printf", "%f\n"]
    stdout: StdioCollector {
      onStreamFinished: root.stockThemeNames = ImagePickerModel.parseThemeNames(String(text || ""))
    }
    // Until this lands, stockThemeNames is empty and an override would look
    // deletable: deletion stays disabled unless the listing succeeded.
    onExited: function(exitCode) { if (exitCode === 0) root.stockThemesKnown = true }
  }

  Process {
    id: deleteThemeProc
    onExited: function(exitCode) {
      if (exitCode === 0) root.awaitingDeleteRefresh = true
      else root.deleteSelectionPath = ""
      root.refreshExtraThemes()
      root.refreshThemeRows()
    }
  }

  Component.onCompleted: {
    refreshThemeRows()
    refreshExtraThemes()
    refreshStockThemes()
  }

  function startImageScan(serial, dirs) {
    if (loadImagesProc.running) {
      loadImagesProc.queuedSerial = serial
      loadImagesProc.queuedDirs = dirs
      return
    }

    loadImagesProc.activeSerial = serial
    loadImagesProc.queuedSerial = 0
    loadImagesProc.queuedDirs = ""
    loadImagesProc.command = [root.scriptPath("list.sh"), dirs]
    loadImagesProc.running = true
  }

  function indexForSelectedImage(images) {
    return ImagePickerModel.indexForSelectedImage(images, selectedImage)
  }

  function selectedImageIndex() {
    return indexForSelectedImage(imageArray)
  }

  Process {
    id: loadImagesProc
    property int activeSerial: 0
    property int queuedSerial: 0
    property string queuedDirs: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (loadImagesProc.activeSerial === root.requestSerial)
          root.loadRows(String(text || ""), true)
      }
    }
    onExited: {
      var serial = queuedSerial
      var dirs = queuedDirs
      activeSerial = 0
      queuedSerial = 0
      queuedDirs = ""
      if (serial > 0 && serial === root.requestSerial)
        root.startImageScan(serial, dirs)
    }
  }

  // Lifecycle hooks invoked by omarchy-shell summon/hide. shell.summon(id,
  // payloadJson) hands the JSON to open() here; shell.hide(id) calls close().
  // The shell host owns the stable `image-selector` IPC target and forwards
  // those lower-level positional calls here.
  function open(payload) {
    var args = {}
    if (payload) {
      try { args = JSON.parse(payload) || {} } catch (e) { args = {} }
    }
    if (args.source === "themes") {
      openThemes()
      return
    }
    if (args.source === "wallpapers") {
      openWallpapers()
      return
    }
    var dirs = String(args.imageDirs || imageDirs)
    var rows = String(args.imageRows || "")
    var sel = String(args.selectedImage || selectedImage)
    var selFile = String(args.selectionFile || "")
    var doneF = String(args.doneFile || "")
    var labels = args.showLabels === true || args.showLabels === "true"
    var filter = args.filterable === true || args.filterable === "true"
    openSelector(dirs, rows, sel, selFile, doneF, labels, filter)
  }

  // PORTDBG: pick row `index` as Enter would, for `wakuc call shell call omarchy.image-picker debugApply 1`
  function debugApply(index) {
    selectedIndex = Number(index)
    var path = currentPath()
    applySelected()
    return String(path)
  }

  // PORTDBG: state dump for `wakuc call shell call omarchy.image-picker debugState x`
  function debugState() {
    var names = []
    for (var i = 0; i < Math.min(imageArray.length, 30); i++) names.push(nameForPath(imageArray[i].filePath))
    return JSON.stringify({ opened: opened, themeMode: themeMode, wallpaperMode: wallpaperMode, count: imageArray.length,
      selected: selectedIndex, names: names.join(","), themeRows: themeRows.split("
").length, wallDir: wallpaperDir() })
  }

  function close() {
    cancel()
  }

  function preloadRows(nextImageRows, nextSelectedImage, nextShowLabels, nextFilterable) {
    // Theme/background set hooks can warm selector rows after a picker was
    // dismissed. Ignore those preloads while a user-visible request is open;
    // otherwise the preload resets layoutSettled without revealing again,
    // leaving the picker invisible behind its own open overlay.
    if (opened || requestActive) return

    previewHold.warm()
    requestSerial += 1
    imageRows = nextImageRows
    selectedImage = nextSelectedImage
    showLabels = nextShowLabels === true || nextShowLabels === "true"
    filterable = nextFilterable === true || nextFilterable === "true"
    filterText = ""
    layoutSettled = false

    if (imageRows && imageRows === loadedImageRows && imageArray.length > 0) {
      selectedIndex = selectedImageIndex()
      imagesLoaded = true
    } else if (imageRows) {
      loadRows(imageRows, false)
    }
  }

  Process {
    id: applyProc
    onExited: {
      if (root.applySerial === root.requestSerial)
        root.opened = false
    }
  }

  Process {
    id: releaseProc
    onExited: root.releaseNextDoneFile()
  }

  OverlayWindow {
    id: panel
    shown: root.opened
    shownKeyboardFocus: root.imagesLoaded ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "omarchy-image-selector"

    MouseArea {
      anchors.fill: parent
      enabled: root.opened && root.imagesLoaded
      onClicked: root.cancel()
    }

    // Count presented frames while the card pre-renders below; two frames
    // prove its masked layers uploaded on this fresh surface.
    FrameAnimation {
      running: root.opened && !root.layoutSettled && root.renderedFrames < 2
      onTriggered: {
        root.renderedFrames += 1
        root.maybeReveal()
      }
    }

    // A preview stuck decoding (slow disk, huge original) must not hold an
    // invisible picker with the keyboard grabbed: reveal anyway shortly.
    Timer {
      interval: 400
      running: root.opened && root.imagesLoaded && !root.layoutSettled && root.imageArray.length > 0
      onTriggered: root.settleReveal()
    }

    Item {
      id: card
      visible: root.opened && root.imagesLoaded && root.imageArray.length > 0
      opacity: root.layoutSettled ? 1 : 0
      width: Math.min(parent.width - 80, root.expandedWidth + 13 * (root.sliceWidth + root.sliceSpacing) + 40)
      height: root.expandedHeight + Style.space(30) + root.bottomChromeHeight
      anchors.centerIn: parent

        MouseArea { anchors.fill: parent; enabled: root.layoutSettled; onClicked: {} }

        Item {
          id: carousel
          anchors.top: parent.top
          anchors.topMargin: Style.space(30)
          anchors.bottom: parent.bottom
          anchors.bottomMargin: root.bottomChromeHeight
          anchors.horizontalCenter: parent.horizontalCenter
          width: root.expandedWidth + 13 * (root.sliceWidth + root.sliceSpacing)
          clip: false
          focus: true

          readonly property real itemStep: root.sliceWidth + root.sliceSpacing
          readonly property real previewX: (width - root.expandedWidth) / 2
          readonly property bool mirrored: LayoutMirroring.enabled

          Keys.priority: Keys.BeforeItem
          Keys.onPressed: function(event) {
            if (root.deleteConfirmOpen) {
              if (deleteConfirm.handleKey(event)) event.accepted = true
              return
            }
            // Nothing is visible before the reveal: only let the user back
            // out, never filter into a dead end or apply an unseen pick.
            if (!root.layoutSettled) {
              if (event.key === Qt.Key_Escape) {
                root.cancel()
                event.accepted = true
              }
              return
            }
            if (event.key === Qt.Key_Escape) {
              if (root.filterText) {
                root.updateFilter("")
              } else {
                root.cancel()
              }
              event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              root.applySelected()
              event.accepted = true
            } else if (event.key === Qt.Key_Delete && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
              root.requestDeleteSelectedTheme()
              event.accepted = true
            } else if (root.filterable && Util.editsFilter(event, root.filterText)) {
              root.updateFilter(Util.editedFilter(event, root.filterText))
              event.accepted = true
            } else if (Util.readingKey(event) === Qt.Key_Left || (event.key === Qt.Key_Tab && event.modifiers & Qt.ShiftModifier) || event.key === Qt.Key_Backtab) {
              root.selectAdjacent(-1)
              event.accepted = true
            } else if (Util.readingKey(event) === Qt.Key_Right || event.key === Qt.Key_Tab) {
              root.selectAdjacent(1)
              event.accepted = true
            } else if (root.filterable && event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127 && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
              root.updateFilter(root.filterText + event.text)
              event.accepted = true
            }
          }

          Component.onCompleted: forceActiveFocus()

          Repeater {
            id: imageCards
            model: visibleImages
            onCountChanged: root.maybeReveal()

            delegate: Item {
              id: item
              required property int imageIndex
              required property int relativeIndex

              readonly property var imageData: root.imageArray[imageIndex]
              readonly property string filePath: imageData ? imageData.filePath : ""
              readonly property string fileName: imageData ? imageData.fileName : ""
              readonly property string thumbnailPath: imageData ? imageData.thumbnailPath : ""

              readonly property bool selected: imageIndex === root.selectedIndex
              readonly property bool previewReady: image.status === Image.Ready || image.status === Image.Error
              readonly property bool previewSettled: !thumbnailPath || previewReady
              onPreviewSettledChanged: if (previewSettled) root.maybeReveal()
              onSelectedChanged: if (selected && previewReady) root.neighborImagesEnabled = true

              readonly property real readingX: selected ? carousel.previewX : (relativeIndex < 0 ? carousel.previewX + relativeIndex * carousel.itemStep : carousel.previewX + root.expandedWidth + root.sliceSpacing + (relativeIndex - 1) * carousel.itemStep)
              // A mirrored (right-to-left) layout runs the carousel from the
              // right, so the next image sits where the reading continues.
              x: carousel.mirrored ? carousel.width - readingX - width : readingX
              width: selected ? root.expandedWidth : root.sliceWidth
              height: selected ? root.expandedHeight : root.sliceHeight
              y: selected ? 0 : (root.expandedHeight - root.sliceHeight) / 2
              z: selected ? 100 : 50 - Math.min(Math.abs(relativeIndex), 40)

              readonly property real skAbs: Math.abs(root.skewOffset)
              readonly property real topLeft: root.skewOffset >= 0 ? skAbs : 0
              readonly property real topRight: root.skewOffset >= 0 ? width : width - skAbs
              readonly property real bottomRight: root.skewOffset >= 0 ? width - skAbs : width
              readonly property real bottomLeft: root.skewOffset >= 0 ? 0 : skAbs

              Item {
                id: maskShape
                anchors.fill: parent
                visible: false
                layer.enabled: true

                Shape {
                  anchors.fill: parent
                  antialiasing: true
                  preferredRendererType: Shape.CurveRenderer
                  ShapePath {
                    fillColor: "white"
                    strokeColor: "transparent"
                    startX: item.topLeft; startY: 0
                    PathLine { x: item.topRight; y: 0 }
                    PathLine { x: item.bottomRight; y: item.height }
                    PathLine { x: item.bottomLeft; y: item.height }
                    PathLine { x: item.topLeft; y: 0 }
                  }
                }
              }

              Item {
                anchors.fill: parent
                layer.enabled: true
                layer.smooth: true
                layer.effect: MultiEffect {
                  maskEnabled: true
                  maskSource: maskShape
                  maskThresholdMin: 0.3
                  maskSpreadAtMin: 0.3
                }

                Rectangle { anchors.fill: parent; color: root.dimColor }

                Image {
                  id: image
                  anchors.fill: parent
                  // Decode at the expanded card's physical size, off the GUI
                  // thread. Keep that size during navigation to avoid reloads.
                  // Departing cards release their images instead of retaining
                  // every preview visited in a large collection.
                  // Queue the selected preview first; neighbors must not delay
                  // the image the user opened the picker to see.
                  source: previewHold.held && (item.selected || root.neighborImagesEnabled) && item.thumbnailPath ? root.cardSource(item.thumbnailPath) : ""
                  // The thumbnail is already small; theme previews decode at the card's size.
                  sourceSize.width: root.wallpaperMode ? 0 : Math.ceil(root.expandedWidth * Screen.devicePixelRatio)
                  sourceSize.height: root.wallpaperMode ? 0 : Math.ceil(root.expandedHeight * Screen.devicePixelRatio)
                  fillMode: Image.PreserveAspectCrop
                  asynchronous: true
                  cache: false
                  smooth: true
                  opacity: status === Image.Ready ? 1 : 0
                  onStatusChanged: if (item.selected && (status === Image.Ready || status === Image.Error)) root.neighborImagesEnabled = true
                }

                Rectangle {
                  anchors.fill: parent
                  color: Util.alpha(root.dimColor, item.selected ? 0 : 0.42)
                }
              }

              Shape {
                anchors.fill: parent
                antialiasing: true
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                  fillColor: "transparent"
                  strokeColor: item.selected ? root.selectedBorder : root.unselectedBorder
                  strokeWidth: item.selected ? 3 : 1
                  startX: item.topLeft; startY: 0
                  PathLine { x: item.topRight; y: 0 }
                  PathLine { x: item.bottomRight; y: item.height }
                  PathLine { x: item.bottomLeft; y: item.height }
                  PathLine { x: item.topLeft; y: 0 }
                }
              }

              MouseArea {
                anchors.fill: parent
                enabled: root.layoutSettled
                cursorShape: Qt.PointingHandCursor
                onClicked: item.selected ? root.applySelected() : root.select(item.imageIndex)
              }
            }
          }
        }

        Text {
          id: selectedLabel
          textFormat: Text.PlainText
          visible: root.showLabels
          anchors.top: carousel.bottom
          anchors.topMargin: Style.space(16)
          anchors.horizontalCenter: carousel.horizontalCenter
          width: root.expandedWidth
          text: root.currentLabel()
          color: root.foreground
          style: Text.Outline
          styleColor: Util.alpha(root.dimColor, 0.7)
          font.pixelSize: Style.font.display
          font.weight: Font.DemiBold
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
        }

        Text {
          textFormat: Text.PlainText
          visible: root.filterable && root.filterText
          anchors.top: selectedLabel.bottom
          anchors.topMargin: Style.space(8)
          anchors.horizontalCenter: carousel.horizontalCenter
          width: root.expandedWidth
          text: root.filterText
          color: root.foreground
          opacity: 0.85
          style: Text.Outline
          styleColor: Util.alpha(root.dimColor, 0.7)
          font.pixelSize: Style.font.title
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
        }
    }

    // Unlike the picker itself, the confirmation keeps the faded backdrop:
    // a destructive choice should take over the screen.
    ConfirmDialog {
      id: deleteConfirm
      anchors.fill: parent
      opened: root.deleteConfirmOpen
      z: 10
      message: Commons.I18n.t("imagePicker.deleteTheme").arg(root.pendingDeleteTheme ? root.labelForPath(root.pendingDeleteTheme) : "")
      confirmText: Commons.I18n.t("common.delete")
      background: root.dimColor
      foreground: root.foreground
      onCanceled: root.cancelDeleteTheme()
      onConfirmed: root.confirmDeleteTheme()
    }
  }
}
