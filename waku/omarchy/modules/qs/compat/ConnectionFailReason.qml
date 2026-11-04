pragma Singleton
import QtQuick

// Quickshell.Networking.ConnectionFailReason.
QtObject {
    enum Value {
        Unknown,
        NoSecrets,
        WifiAuthTimeout,
        WifiNetworkLost,
        WifiClientDisconnected,
        WifiClientFailed,
        WifiAuthFailed,
        WifiNotFound
    }
}
