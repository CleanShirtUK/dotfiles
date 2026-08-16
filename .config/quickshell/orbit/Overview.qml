import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

PanelWindow {
    id: root

    property var modelData
    required property var screenData
    required property var overviewData
    required property var monitorData
    required property var themeData
    screen: screenData
    visible: overviewData.overviewVisible && monitorData.focusedName === screenData.name
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onVisibleChanged: if (visible) Qt.callLater(function() { focusScope.forceActiveFocus() })

    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: root.visible

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                overviewData.close()
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                overviewData.activateSelected()
                event.accepted = true
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                overviewData.cycle(-1)
                event.accepted = true
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                overviewData.cycle(1)
                event.accepted = true
            }
        }
        Keys.onReleased: function(event) {
            if (event.key === Qt.Key_Alt)
                overviewData.close()
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 1100)
            height: Math.min(parent.height - 100, 680)
            color: Qt.alpha(themeData.colors.window_background || "#1a1b26", 0.98)
            border.color: themeData.colors.border || "#3d4355"
            border.width: 1
            radius: 16

            Column {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 18

                Row {
                    width: parent.width
                    spacing: 12
                    Text {
                        text: "WORKSPACES"
                        color: themeData.colors.accent || "#7aa2f7"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Text {
                        text: "Alt+Tab to cycle  |  Enter to select  |  Esc to cancel"
                        color: themeData.colors.text_muted || "#9aa5ce"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                ListView {
                    id: workspaceList
                    width: parent.width
                    height: parent.height - 48
                    spacing: 14
                    clip: true
                    model: overviewData.workspaceItems()

                    delegate: Column {
                        id: workspaceDelegate
                        required property var modelData
                        required property int index
                        readonly property int workspaceIndex: index
                        width: workspaceList.width
                        spacing: 8

                        Row {
                            spacing: 8
                            Text {
                                text: modelData.name + (workspaceDelegate.workspaceIndex === overviewData.selectedWorkspaceIndex ? "  < FOCUSED >" : "")
                                color: themeData.colors.accent_secondary || "#bb9af7"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 13
                                font.bold: true
                            }
                            Text {
                                text: modelData.windows.length === 0 ? "EMPTY" : modelData.windows.length + " WINDOW" + (modelData.windows.length === 1 ? "" : "S")
                                color: themeData.colors.text_muted || "#9aa5ce"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 10
                            }
                        }

                        Flow {
                            width: parent.width
                            spacing: 10

                            Repeater {
                                model: modelData.windows
                                delegate: Rectangle {
                                    required property var modelData
                                    width: Math.min(250, workspaceList.width - 10)
                                    height: 74
                                    radius: 10
                                    color: workspaceDelegate.workspaceIndex === overviewData.selectedWorkspaceIndex ? (themeData.colors.surface_selected || "#333954") : (themeData.colors.surface || "#24283b")
                                    border.color: workspaceDelegate.workspaceIndex === overviewData.selectedWorkspaceIndex ? (themeData.colors.accent || "#7aa2f7") : "transparent"
                                    border.width: 2

                                    Image {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 32
                                        height: 32
                                        source: Quickshell.iconPath(modelData.class)
                                        fillMode: Image.PreserveAspectFit
                                    }
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 56
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.title || modelData.class
                                        color: themeData.colors.text || "#c0caf5"
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: overviewData.selectWorkspace(workspaceDelegate.workspaceIndex)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
