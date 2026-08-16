import QtQuick
import QtQuick.Controls
import ".." as Orbit

CheckBox {
    id: root

    Orbit.Theme { id: localTheme }

    property var themeData
    implicitHeight: 36
    leftPadding: 29
    rightPadding: 0
    spacing: 9
    font.family: themeData ? themeData.uiFont : localTheme.uiFont
    font.pixelSize: 12
    contentItem: Text {
        text: root.text
        color: root.enabled ? root.textColor() : Qt.alpha(root.textColor(), 0.45)
        font: root.font
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    indicator: Rectangle {
        x: 0
        y: (root.height - height) / 2
        implicitWidth: 20
        implicitHeight: 20
        radius: 6
        color: root.checked ? root.accentColor() : "transparent"
        border.width: root.activeFocus ? 2 : 1
        border.color: root.checked ? root.accentColor() : root.borderColor()
        Text {
            anchors.centerIn: parent
            text: "✓"
            visible: root.checked
            color: root.foregroundColor()
            font.pixelSize: 13
            font.bold: true
        }
    }

    function colors() { return root.themeData ? root.themeData.colors : localTheme.colors }
    function textColor() { return colors().text || "#c0caf5" }
    function accentColor() { return colors().accent || "#7aa2f7" }
    function foregroundColor() { return colors().accent_foreground || "#16161e" }
    function borderColor() { return colors().border || "#3d4355" }
}
