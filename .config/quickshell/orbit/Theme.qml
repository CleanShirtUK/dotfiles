import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    readonly property var fallback: ({
        window_background: "#1a1b26",
        surface: "#24283b",
        surface_elevated: "#2c3148",
        surface_selected: "#333954",
        border: "#3d4355",
        text: "#c0caf5",
        text_muted: "#9aa5ce",
        accent: "#7aa2f7",
        accent_secondary: "#bb9af7"
    })
    property var colors: fallback

    FileView {
        id: themeFile
        path: Quickshell.env("HOME") + "/.config/orbit/generated/tokyo-night/quickshell.json"
        blockLoading: true
        watchChanges: true
        onLoaded: root.reload()
        onFileChanged: reload()
    }

    function reload() {
        try {
            colors = JSON.parse(themeFile.text())
        } catch (error) {
            colors = fallback
        }
    }

    Component.onCompleted: reload()
}
