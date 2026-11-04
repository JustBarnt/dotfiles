pragma Singleton
import Quickshell

// `Quickshell.shellDir` as a file URL. Qt reads a plain `D:\...` path as a URL with scheme `d`, so
// anything handed to Loader, Qt.createComponent, Qt.resolvedUrl or a `source:` needs this form.
Singleton {
    readonly property string dir: "file:///" + Quickshell.shellDir.replace(/\\/g, "/")
}
