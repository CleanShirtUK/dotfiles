import QtQuick
import QtQuick.Controls
import ".." as Orbit

Button {
    id: root

    Orbit.Theme { id: localTheme }

    property var themeData
    property string iconText: ""
    property string iconSource: ""
    property string accessibleLabel: ""

    implicitWidth: 36
    implicitHeight: 36
    padding: 0
    Accessible.name: accessibleLabel || iconText
    display: AbstractButton.TextOnly

    contentItem: Item {
        Orbit.OrbitIcon {
            anchors.centerIn: parent
            width: 18
            height: 18
            visible: root.iconSource !== ""
            iconSource: root.iconSource
            iconSize: 32
            opacity: root.enabled ? 1 : 0.4
        }
        Text {
            anchors.centerIn: parent
            visible: root.iconSource === ""
            text: root.iconText
            color: root.enabled ? root.textColor() : Qt.alpha(root.textColor(), 0.4)
            font.family: root.themeData ? root.themeData.uiFont : localTheme.uiFont
            font.pixelSize: 15
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    background: Rectangle {
        radius: root.themeData ? root.themeData.smallCornerRadius : 8
        color: root.pressed ? root.accentColor() : root.hovered ? root.surfaceColor() : "transparent"
        border.width: root.activeFocus ? 2 : 0
        border.color: root.accentColor()
    }

    function colors() { return root.themeData ? root.themeData.colors : localTheme.colors }
    function textColor() { return colors().text || "#c0caf5" }
    function accentColor() { return colors().accent || "#7aa2f7" }
    function surfaceColor() { return Qt.alpha(colors().surface || "#24283b", 0.8) }
}
