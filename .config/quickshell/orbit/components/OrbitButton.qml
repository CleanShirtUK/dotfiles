import QtQuick
import QtQuick.Controls
import ".." as Orbit

Button {
    id: root

    Orbit.Theme { id: localTheme }

    property var themeData
    property bool destructive: false
    property bool subtle: false
    property bool compact: false

    implicitHeight: compact ? 32 : 36
    leftPadding: 14
    rightPadding: 14
    topPadding: 0
    bottomPadding: 0

    contentItem: Text {
        text: root.text
        color: !root.enabled ? Qt.alpha(root.textColor(), 0.45)
            : root.destructive ? root.errorColor()
            : root.highlighted ? root.foregroundColor() : root.textColor()
        font.family: root.themeData ? root.themeData.uiFont : localTheme.uiFont
        font.pixelSize: root.compact ? 11 : 12
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: root.themeData ? root.themeData.smallCornerRadius : 8
        color: !root.enabled ? root.surfaceColor(0.35)
            : root.pressed ? root.surfaceColor(0.95)
            : root.hovered ? root.surfaceColor(0.82)
            : root.highlighted ? root.accentColor()
            : root.subtle ? "transparent" : root.surfaceColor(0.68)
        border.width: root.activeFocus ? 2 : (root.subtle ? 0 : 1)
        border.color: root.activeFocus ? root.accentColor() : root.borderColor()
    }

    function colors() { return root.themeData ? root.themeData.colors : localTheme.colors }
    function textColor() { return colors().text || "#c0caf5" }
    function foregroundColor() { return colors().accent_foreground || "#16161e" }
    function accentColor() { return colors().accent || "#7aa2f7" }
    function errorColor() { return colors().error || "#f7768e" }
    function surfaceColor(alpha) { return Qt.alpha(colors().surface || "#24283b", alpha) }
    function borderColor() { return colors().border || "#3d4355" }
}
