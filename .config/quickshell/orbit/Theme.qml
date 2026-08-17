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
    property string palette: "tokyo-night"
    property real shellOpacity: 0.30

    // Keep typography and geometry centralized so the interface font can be
    // split into UI and technical branches without changing every page.
    readonly property string uiFont: "JetBrains Mono"
    readonly property string technicalFont: "JetBrains Mono"
    readonly property int bodySize: 12
    readonly property int smallSize: 11
    readonly property int titleSize: 20
    readonly property int controlHeight: 36
    readonly property int compactControlHeight: 32
    readonly property int cornerRadius: 10
    readonly property int smallCornerRadius: 8
    readonly property int pageSpacing: 16
    readonly property int rowSpacing: 8

    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/orbit/settings.toml"
        blockLoading: true
        watchChanges: true
        onLoaded: root.reloadPalette()
        onFileChanged: reloadPalette()
    }

    FileView {
        id: themeFile
        path: Quickshell.env("HOME") + "/.config/orbit/generated/" + root.palette + "/quickshell.json"
        blockLoading: true
        watchChanges: true
        onLoaded: root.reload()
        onFileChanged: reload()
    }

    function reloadPalette() {
        var match = settingsFile.text().match(/\[theme\][\s\S]*?^palette\s*=\s*"([^"]+)"/m)
        if (match && match[1] && match[1] !== palette)
            palette = match[1]
        var opacityMatch = settingsFile.text().match(/\[appearance\.transparency\][\s\S]*?^shell_opacity\s*=\s*([0-9.]+)/m)
        shellOpacity = opacityMatch ? Math.max(0, Math.min(1, Number(opacityMatch[1]))) : 0.30
        reload()
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
