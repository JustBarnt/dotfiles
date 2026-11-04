pragma Singleton
import QtQuick

// Quickshell.Networking.WifiSecurityType.
QtObject {
    enum Value {
        Unknown,
        Open,
        Wep,
        Wpa,
        WpaEap,
        Wpa2Eap,
        Sae,
        Owe
    }
}
