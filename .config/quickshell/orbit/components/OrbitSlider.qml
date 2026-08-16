import QtQuick
import QtQuick.Controls
import ".." as Orbit

Slider {
    id: root

    Orbit.Theme { id: localTheme }

    property var themeData
    implicitHeight: 28

    background: Rectangle {
        x: 0
        y: (root.height - height) / 2
        width: root.width
        height: 4
        radius: 2
        color: Qt.alpha(root.colors().border || "#3d4355", 0.8)
        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: root.colors().accent || "#7aa2f7"
        }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: (root.height - height) / 2
        width: 16
        height: 16
        radius: 8
        color: root.pressed || root.activeFocus ? root.colors().accent || "#7aa2f7" : root.colors().text || "#c0caf5"
        border.width: root.activeFocus ? 2 : 0
        border.color: root.colors().accent || "#7aa2f7"
    }

    function colors() { return root.themeData ? root.themeData.colors : localTheme.colors }
}
