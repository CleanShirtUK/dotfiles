import QtQuick
import QtQuick.Controls
import ".." as Orbit

ComboBox {
    id: root

    Orbit.Theme { id: localTheme }

    property var themeData
    implicitHeight: 36
    leftPadding: 11
    rightPadding: 30
    font.family: themeData ? themeData.uiFont : localTheme.uiFont
    font.pixelSize: 12
    contentItem: Text {
        text: root.displayText
        color: root.enabled ? root.textColor() : Qt.alpha(root.textColor(), 0.45)
        font: root.font
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    indicator: Text {
        x: root.width - width - 11
        y: (root.height - height) / 2
        text: "⌄"
        color: root.textColor()
        font.pixelSize: 14
    }
    background: Rectangle {
        radius: themeData ? themeData.smallCornerRadius : 8
        color: root.hovered ? root.surfaceColor(0.85) : root.surfaceColor(0.65)
        border.width: root.activeFocus ? 2 : 1
        border.color: root.activeFocus ? root.accentColor() : root.borderColor()
    }

    function colors() { return root.themeData ? root.themeData.colors : localTheme.colors }
    function textColor() { return colors().text || "#c0caf5" }
    function accentColor() { return colors().accent || "#7aa2f7" }
    function surfaceColor(alpha) { return Qt.alpha(colors().surface || "#24283b", alpha) }
    function borderColor() { return colors().border || "#3d4355" }
}
