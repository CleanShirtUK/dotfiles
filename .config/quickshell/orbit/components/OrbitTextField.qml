import QtQuick
import QtQuick.Controls
import ".." as Orbit

TextField {
    id: root

    Orbit.Theme { id: localTheme }

    property var themeData
    implicitHeight: 36
    leftPadding: 11
    rightPadding: 11
    font.family: themeData ? themeData.uiFont : localTheme.uiFont
    font.pixelSize: 12
    color: colors().text || "#c0caf5"
    placeholderTextColor: Qt.alpha(colors().text_muted || "#9aa5ce", 0.8)
    selectionColor: colors().accent || "#7aa2f7"
    selectedTextColor: colors().accent_foreground || "#16161e"

    background: Rectangle {
        radius: themeData ? themeData.smallCornerRadius : 8
        color: Qt.alpha(colors().window_background || "#1a1b26", 0.5)
        border.width: root.activeFocus ? 2 : 1
        border.color: root.activeFocus ? (colors().accent || "#7aa2f7") : (colors().border || "#3d4355")
    }

    function colors() { return root.themeData ? root.themeData.colors : localTheme.colors }
}
