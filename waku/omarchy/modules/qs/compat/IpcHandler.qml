import waku as W

// The engine's own IpcHandler (module `waku`, not `Quickshell.Io`). `wakuc call <target> <function>`
// reaches the `function` members declared on it; `qs ipc` does not exist on Windows.
W.IpcHandler { }
