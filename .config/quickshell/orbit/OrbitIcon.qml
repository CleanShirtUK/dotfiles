import Quickshell
import QtQuick

Image {
    id: root

    property string iconName: ""
    property string iconSource: ""
    property int iconSize: Math.max(width, height)

    source: iconSource || (iconName ? Quickshell.iconPath(iconName) : "")
    sourceSize: Qt.size(iconSize, iconSize)
    fillMode: Image.PreserveAspectFit
    smooth: true
    asynchronous: true
    mipmap: true
}
