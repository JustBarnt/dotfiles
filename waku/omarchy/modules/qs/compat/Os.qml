pragma Singleton
import Quickshell

// What Noctalia does with `mkdir -p`, `rm`, `wl-copy` and `xdg-open`, on Windows. Paths may use
// either slash; cmd.exe needs backslashes.
Singleton {
    function win(path) {
        return String(path).replace(/\//g, "\\").replace(/\\+$/, "");
    }

    // Creates the folder and its parents (cmd's mkdir does), and does nothing when it exists.
    function mkdirp(path) {
        const p = win(path);
        Quickshell.execDetached(["cmd", "/c", "if", "not", "exist", p, "mkdir", p]);
    }

    // Deletes a file, or a folder with everything in it when `recursive`.
    function rm(path, recursive) {
        const p = win(path);
        if (recursive)
            Quickshell.execDetached(["cmd", "/c", "rmdir", "/s", "/q", p]);
        else
            Quickshell.execDetached(["cmd", "/c", "del", "/f", "/q", p]);
    }

    function copy(text) {
        Quickshell.clipboardText = String(text);
    }

    function open(url) {
        Qt.openUrlExternally(url);
    }
}
