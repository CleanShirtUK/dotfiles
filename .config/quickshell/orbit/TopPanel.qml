import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls as Controls

PanelWindow {
    id: root

    property var modelData
    required property var screenData
    required property var themeData
    required property bool shellVisible
    required property var applicationMenuData
    required property string monitorName
    signal launcherRequested()

    screen: screenData
    visible: shellVisible
    color: "transparent"
    surfaceFormat.opaque: false
    implicitWidth: 1
    implicitHeight: 42
    exclusiveZone: 42
    WlrLayershell.layer: WlrLayer.Overlay
    anchors {
        top: true
        left: true
        right: true
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    QsMenuAnchor {
        id: applicationMenuAnchor
        menu: applicationMenuData.menuFor(monitorName)
        anchor.item: appMenuButton
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.adjustment: PopupAdjustment.All
    }

    property bool applicationActionsVisible: false
    property bool dbusApplicationMenuVisible: false

    PopupWindow {
        id: applicationActions
        visible: root.applicationActionsVisible
        implicitWidth: 166
        implicitHeight: Math.max(72, fallbackMenuColumn.implicitHeight + 12)
        color: "transparent"
        grabFocus: true
        anchor.item: appMenuButton
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.adjustment: PopupAdjustment.All

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: themeData.colors.surface_elevated || "#2c3148"
            border.color: themeData.colors.border || "#3d4355"
            border.width: 1
            radius: 10

            Column {
                id: fallbackMenuColumn
                anchors.fill: parent
                anchors.margins: 6
            spacing: 2
                Repeater {
                model: applicationMenuData.fallbackRowsFor(monitorName)

                delegate: Rectangle {
                    required property var modelData
                    width: 152
                    height: 30
                    radius: 6
                    color: actionMouse.containsMouse ? Qt.alpha(themeData.colors.accent || "#7aa2f7", 0.2) : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: themeData.colors.text || "#c0caf5"
                        font.family: themeData.uiFont
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            applicationMenuData.activateFallback(monitorName, modelData.action)
                            root.applicationActionsVisible = false
                        }
                    }
                }
            }
        }
        }
    }

    PopupWindow {
        id: dbusApplicationMenu
        visible: root.dbusApplicationMenuVisible
        implicitWidth: 320
        implicitHeight: Math.min(520, Math.max(44, dbusMenuColumn.implicitHeight + 12))
        color: "transparent"
        grabFocus: true
        anchor.item: appMenuButton
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.adjustment: PopupAdjustment.All

        Rectangle {
            anchors.fill: parent
            color: themeData.colors.surface_elevated || "#2c3148"
            border.color: themeData.colors.border || "#3d4355"
            border.width: 1
            radius: 10

            Column {
                id: dbusMenuColumn
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2

                Repeater {
                    model: applicationMenuData.dbusRowsFor(monitorName)

                    delegate: Rectangle {
                        required property var modelData
                        width: 308
                        height: 28
                        radius: 6
                        color: dbusMenuMouse.containsMouse ? Qt.alpha(themeData.colors.accent || "#7aa2f7", 0.2) : "transparent"
                        opacity: modelData.enabled ? 1 : 0.45

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8 + (modelData.depth * 14)
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label || "(unnamed menu item)"
                            color: themeData.colors.text || "#c0caf5"
                            font.family: themeData.uiFont
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: dbusMenuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: modelData.enabled && !modelData.hasChildren
                            onClicked: applicationMenuData.activateDbus(monitorName, modelData)
                        }
                    }
                }
            }
        }
    }

    Row {
        id: panelContent
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        Item {
            width: appMenuButton.width
            height: parent.height

            Rectangle {
                id: appMenuButton
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(220, Math.max(112, appMenuLabel.implicitWidth + 24))
                height: 30
                radius: 8
                color: appMenuMouse.containsMouse ? Qt.alpha(themeData.colors.accent || "#7aa2f7", 0.22) : "transparent"

                Text {
                    id: appMenuLabel
                    anchors.centerIn: parent
                    text: applicationMenuData.titleFor(monitorName)
                    color: applicationMenuData.availableFor(monitorName) ? (themeData.colors.text || "#c0caf5") : (themeData.colors.text_muted || "#9aa5ce")
                    font.family: themeData.uiFont
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: appMenuMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: applicationMenuData.hasCandidateFor(monitorName)
                    onClicked: function(mouse) {
                        if (applicationMenuData.dbusMenuFor(monitorName)) {
                            root.applicationActionsVisible = false
                            root.dbusApplicationMenuVisible = true
                        } else if (applicationMenuData.availableFor(monitorName))
                            applicationMenuData.openFor(applicationMenuAnchor, monitorName)
                        else {
                            root.dbusApplicationMenuVisible = false
                            root.applicationActionsVisible = false
                            root.applicationActionsVisible = true
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width - launcherButton.width - trayRow.width - appMenuButton.width
            height: parent.height

            Text {
                anchors.centerIn: parent
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: themeData.colors.text || "#c0caf5"
                font.family: themeData.uiFont
                font.pixelSize: 13
                font.bold: true
            }
        }

        Rectangle {
            id: launcherButton
            width: 32
            height: 30
            anchors.verticalCenter: parent.verticalCenter
            radius: 8
            color: launcherMouse.containsMouse ? Qt.alpha(themeData.colors.accent || "#7aa2f7", 0.22) : "transparent"

            Text {
                anchors.centerIn: parent
                text: "⌕"
                color: themeData.colors.text || "#c0caf5"
                font.family: themeData.uiFont
                font.pixelSize: 24
            }

            MouseArea {
                id: launcherMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.launcherRequested()
            }
        }

        Row {
            id: trayRow
            width: implicitWidth
            height: parent.height
            spacing: 4

            Repeater {
                model: SystemTray.items

                delegate: Item {
                    required property var modelData
                    width: 30
                    height: parent.height

                    Image {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: modelData.icon
                        sourceSize: Qt.size(24, 24)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        mipmap: true
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: modelData.icon === ""
                        text: "•"
                        color: themeData.colors.text_muted || "#9aa5ce"
                        font.family: themeData.uiFont
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: trayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.LeftButton)
                                modelData.activate()
                            else if (mouse.button === Qt.MiddleButton)
                                modelData.secondaryActivate()
                            else if (modelData.hasMenu)
                                modelData.display(root, mouse.x, mouse.y)
                        }
                    }

                    Controls.ToolTip.visible: trayMouse.containsMouse && (modelData.tooltipTitle || modelData.title) !== ""
                    Controls.ToolTip.text: modelData.tooltipTitle || modelData.title
                }
            }
        }
    }
}
