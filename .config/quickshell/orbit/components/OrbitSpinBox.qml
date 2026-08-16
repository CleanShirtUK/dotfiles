import QtQuick
import QtQuick.Controls
import ".." as Orbit

SpinBox {
    id: root

    Orbit.Theme { id: localTheme }

    property var themeData
    implicitHeight: 36
    leftPadding: 11
    rightPadding: 30
    font.family: themeData ? themeData.uiFont : localTheme.uiFont
    font.pixelSize: 12
    contentItem: TextInput {
        text: root.textFromValue(root.value, root.locale)
        color: root.enabled ? root.textColor() : Qt.alpha(root.textColor(), 0.45)
        font: root.font
        horizontalAlignment: TextInput.AlignLeft
        verticalAlignment: TextInput.AlignVCenter
        readOnly: !root.editable
    }
    up.indicator: Rectangle {
        x: root.width - width - 5
        y: 5
        width: 22
        height: 12
        color: "transparent"
        Text { anchors.centerIn: parent; text: "+"; color: root.textColor(); font.pixelSize: 12 }
    }
    down.indicator: Rectangle {
        x: root.width - width - 5
        y: root.height - height - 5
        width: 22
        height: 12
        color: "transparent"
        Text { anchors.centerIn: parent; text: "-"; color: root.textColor(); font.pixelSize: 12 }
    }
    background: Rectangle {
        radius: themeData ? themeData.smallCornerRadius : 8
        color: Qt.alpha(root.colors().window_background || "#1a1b26", 0.5)
        border.width: root.activeFocus ? 2 : 1
        border.color: root.activeFocus ? (root.colors().accent || "#7aa2f7") : (root.colors().border || "#3d4355")
    }

    function colors() { return root.themeData ? root.themeData.colors : localTheme.colors }
    function textColor() { return colors().text || "#c0caf5" }
}
