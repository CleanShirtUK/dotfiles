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
            width: Math.min(parent.width - 64, 1160)
            height: Math.min(parent.height - 80, 720)
            color: Qt.alpha(themeData.colors.window_background || "#1a1b26", 0.98)
            border.color: themeData.colors.border || "#3d4355"
            border.width: 1
            radius: 20

            Column {
                anchors.fill: parent
                anchors.margins: 32
                spacing: 20

                Row {
                    width: parent.width
                    spacing: 12
                    Text {
                        text: "Workspaces"
                        color: themeData.colors.accent || "#7aa2f7"
                        font.family: themeData.uiFont
                        font.pixelSize: 20
                        font.bold: true
                    }
                    Text {
                        text: "Alt+Tab to cycle, Enter to select, Esc to cancel"
                        color: themeData.colors.text_muted || "#9aa5ce"
                        font.family: themeData.uiFont
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
                                text: modelData.name + (workspaceDelegate.workspaceIndex === overviewData.selectedWorkspaceIndex ? "  (focused)" : "")
                                color: themeData.colors.accent_secondary || "#bb9af7"
                                font.family: themeData.uiFont
                                font.pixelSize: 13
                                font.bold: true
                            }
                            Text {
                                text: modelData.windows.length === 0 ? "Empty" : modelData.windows.length + " window" + (modelData.windows.length === 1 ? "" : "s")
                                color: themeData.colors.text_muted || "#9aa5ce"
                                font.family: themeData.uiFont
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
                                    radius: 12
                                    color: workspaceDelegate.workspaceIndex === overviewData.selectedWorkspaceIndex ? Qt.alpha(themeData.colors.accent || "#7aa2f7", 0.16) : Qt.alpha(themeData.colors.surface || "#24283b", 0.62)
                                    border.color: workspaceDelegate.workspaceIndex === overviewData.selectedWorkspaceIndex ? (themeData.colors.accent || "#7aa2f7") : "transparent"
                                    border.width: workspaceDelegate.workspaceIndex === overviewData.selectedWorkspaceIndex ? 1 : 0

                                     OrbitIcon {
                                         anchors.left: parent.left
                                         anchors.leftMargin: 12
                                         anchors.verticalCenter: parent.verticalCenter
                                         width: 32
                                         height: 32
                                         iconName: modelData.class
                                         iconSize: 48
                                     }
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 56
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.title || modelData.class
                                        color: themeData.colors.text || "#c0caf5"
                                         font.family: themeData.uiFont
                                         font.pixelSize: 12
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
