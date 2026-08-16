import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

ShellRoot {
    id: root
    readonly property string home: Quickshell.env("HOME")

    Theme { id: theme }
    MonitorModel { id: monitorModel }
    WindowModel { id: windowModel }
    SettingsModel { id: settingsModel }
    OverviewModel {
        id: overviewModel
        windowModel: windowModel
        monitorModel: monitorModel
    }

    IpcHandler {
        target: "orbit-overview"

        function cycle() {
            overviewModel.cycleFromTrigger()
        }

        function close() {
            overviewModel.closeFromTrigger()
        }

        function open() {
            overviewModel.openFromTrigger()
        }
    }

    IpcHandler {
        target: "orbit-settings"

        function open() {
            settingsModel.open()
        }

        function close() {
            settingsModel.close()
        }

        function toggle() {
            if (settingsModel.settingsVisible)
                settingsModel.close()
            else
                settingsModel.open()
        }
    }
    XmbModel { id: xmbModel }
    ApplicationModel {
        id: applicationModel
        windowModel: windowModel
    }

    property bool xmbVisible: false

    FileView {
        id: xmbStateFile
        path: (Quickshell.env("XDG_CACHE_HOME") || (root.home + "/.cache")) + "/orbit/xmb-visible"
        watchChanges: true
        onLoaded: root.reloadXmbState()
        onFileChanged: reload()
    }

    function reloadXmbState() {
        xmbVisible = xmbStateFile.text().trim() === "1"
    }

    function moveXmbCategory(delta) {
        var categories = xmbModel.categories
        var index = categories.indexOf(xmbModel.category)
        if (index < 0)
            index = 0
        index = (index + delta + categories.length) % categories.length
        xmbModel.category = categories[index]
    }

    function launchXmbSelection() {
        xmb.launchXmbSelection()
    }

    function closeXmb() {
        xmbModel.query = ""
        Quickshell.execDetached([root.home + "/.local/bin/orbit-xmb", "close"])
    }

    onXmbVisibleChanged: if (!xmbVisible) xmbModel.query = ""

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dock
            required property var modelData
            screen: modelData
            anchors.bottom: true
            implicitWidth: dockContent.implicitWidth + 20
            implicitHeight: 50
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                anchors.margins: 6
                color: Qt.alpha(theme.colors.window_background || "#1a1b26", 0.94)
                border.color: theme.colors.border || "#3d4355"
                border.width: 1
                radius: 10

                Row {
                    id: dockContent
                    anchors.centerIn: parent
                    height: 32
                    spacing: 6

                    Repeater {
                        model: applicationModel.items()

                        delegate: Rectangle {
                            required property var modelData
                            width: 32
                            height: 32
                            radius: 8
                            color: itemMouse.containsMouse ? (theme.colors.surface_selected || "#333954") : "transparent"

                            Image {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                source: applicationModel.iconPath(modelData)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: applicationModel.activate(modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: xmb
            required property var modelData
            screen: modelData
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.xmbVisible && monitorModel.focusedName === modelData.name ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            visible: root.xmbVisible && monitorModel.focusedName === modelData.name
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"

            onVisibleChanged: if (visible) Qt.callLater(function() {
                appsGrid.currentIndex = appsGrid.currentIndex < 0 ? 0 : appsGrid.currentIndex
                search.forceActiveFocus()
            })

            function closeLocalXmb() {
                search.text = ""
                appsGrid.currentIndex = 0
                root.closeXmb()
            }

            function launchXmbSelection() {
                var apps = xmbModel.filteredApps()
                var index = appsGrid.currentIndex >= 0 ? appsGrid.currentIndex : 0
                if (index >= apps.length)
                    return
                closeLocalXmb()
                xmbModel.launch(apps[index])
            }

            function moveXmbSelection(delta) {
                var count = xmbModel.filteredApps().length
                if (count === 0)
                    return
                var next = appsGrid.currentIndex + delta
                if (next < 0)
                    next = count - 1
                if (next >= count)
                    next = 0
                appsGrid.currentIndex = next
                appsGrid.positionViewAtIndex(next, GridView.Contain)
            }

            FocusScope {
                id: xmbFocus
                anchors.fill: parent
                 focus: xmb.visible

                 Keys.priority: Keys.BeforeItem
                 Keys.onPressed: function(event) {
                     if (event.key === Qt.Key_Escape) {
                         xmb.closeLocalXmb()
                         event.accepted = true
                     }
                 }

                 Rectangle {
                     Rectangle {
                         id: closeButton
                         anchors.top: parent.top
                         anchors.right: parent.right
                         anchors.topMargin: 12
                         anchors.rightMargin: 12
                         width: 34
                         height: 34
                         radius: 8
                         color: closeMouse.containsMouse ? (theme.colors.error || "#f7768e") : (theme.colors.surface_selected || "#333954")
                         z: 10

                         Text {
                             anchors.centerIn: parent
                             text: "X"
                             color: theme.colors.text || "#c0caf5"
                             font.family: "JetBrains Mono"
                             font.pixelSize: 14
                             font.bold: true
                         }

                         MouseArea {
                             id: closeMouse
                             anchors.fill: parent
                             hoverEnabled: true
                              onClicked: xmb.closeLocalXmb()
                         }
                     }

                     anchors.centerIn: parent
                    width: xmbModel.fullscreen ? parent.width : Math.min(parent.width - 80, 760)
                    height: xmbModel.fullscreen ? parent.height : Math.min(parent.height - 80, 560)
                    color: Qt.alpha(theme.colors.window_background || "#1a1b26", 0.97)
                    border.color: theme.colors.border || "#3d4355"
                    border.width: 1
                    radius: xmbModel.fullscreen ? 0 : 16

                    Column {
                        anchors.fill: parent
                        anchors.margins: 28
                        spacing: 18

                        Row {
                            width: parent.width
                            spacing: 14

                            Text {
                                text: "XMB"
                                color: theme.colors.accent || "#7aa2f7"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 18
                                font.bold: true
                            }

                             Rectangle {
                                 width: 34
                                 height: 34
                                 radius: 8
                                 color: settingsMouse.containsMouse ? (theme.colors.accent || "#7aa2f7") : (theme.colors.surface_selected || "#333954")

                                 Text {
                                     anchors.centerIn: parent
                                     text: "S"
                                     color: theme.colors.text || "#c0caf5"
                                     font.pixelSize: 16
                                 }

                                 MouseArea {
                                     id: settingsMouse
                                     anchors.fill: parent
                                     hoverEnabled: true
                                     onClicked: {
                                         xmb.closeLocalXmb()
                                         settingsModel.open()
                                     }
                                 }
                             }

                             TextField {
                                 id: search
                                 width: parent.width - 120
                                color: theme.colors.text || "#c0caf5"
                                selectionColor: theme.colors.accent || "#7aa2f7"
                                font.family: "JetBrains Mono"
                                 font.pixelSize: 14
                                 clip: true
                                 focus: true
                                 placeholderText: "Search applications..."
                                 placeholderTextColor: theme.colors.text_muted || "#9aa5ce"
                                 background: null
                                 onTextChanged: xmbModel.query = text
                                 onActiveFocusChanged: if (activeFocus) appsGrid.currentIndex = appsGrid.currentIndex < 0 ? 0 : appsGrid.currentIndex
                                 Keys.priority: Keys.BeforeItem
                                 Keys.onPressed: function(event) {
                                     if (event.key === Qt.Key_Down) {
                                          xmb.moveXmbSelection(1)
                                         event.accepted = true
                                     } else if (event.key === Qt.Key_Up) {
                                         xmb.moveXmbSelection(-1)
                                         event.accepted = true
                                     } else if (event.key === Qt.Key_Left) {
                                         root.moveXmbCategory(-1)
                                         event.accepted = true
                                     } else if (event.key === Qt.Key_Right) {
                                         root.moveXmbCategory(1)
                                         event.accepted = true
                                     } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Select || event.text === "\n" || event.text === "\r") {
                                         xmb.launchXmbSelection()
                                         event.accepted = true
                                     }
                                 }
                                 Keys.onEscapePressed: xmb.closeLocalXmb()
                            }
                        }

                        Flickable {
                            width: parent.width
                            height: 34
                            contentWidth: categoryRow.width
                            clip: true

                             FocusScope {
                                 id: categoryFocus
                                  width: categoryRow.width
                                  height: categoryRow.height
                                  Keys.priority: Keys.BeforeItem
                                  Keys.onEscapePressed: xmb.closeLocalXmb()

                                 Keys.onPressed: function(event) {
                                     if (event.key === Qt.Key_Left) {
                                         root.moveXmbCategory(-1)
                                         event.accepted = true
                                     } else if (event.key === Qt.Key_Right) {
                                         root.moveXmbCategory(1)
                                         event.accepted = true
                                      }
                                 }

                                  Row {
                                      id: categoryRow
                                      height: 30
                                      spacing: 8

                                Repeater {
                                    model: xmbModel.categories
                                    delegate: Rectangle {
                                        required property string modelData
                                        width: categoryLabel.implicitWidth + 22
                                        height: 30
                                        radius: 8
                                        color: modelData === xmbModel.category ? (theme.colors.accent || "#7aa2f7") : (theme.colors.surface || "#24283b")

                                        Text {
                                            id: categoryLabel
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: modelData === xmbModel.category ? (theme.colors.accent_foreground || "#16161e") : (theme.colors.text || "#c0caf5")
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: 11
                                        }

                                         MouseArea {
                                             anchors.fill: parent
                                             onClicked: {
                                                 xmbModel.category = modelData
                                                 categoryFocus.forceActiveFocus()
                                             }
                                         }
                                     }
                                 }
                                 }
                             }
                        }

                         GridView {
                             id: appsGrid
                             width: parent.width
                             height: parent.height - 90
                             cellWidth: parent.width
                             cellHeight: 82
                             clip: true
                             model: xmbModel.filteredApps()
                             currentIndex: count > 0 ? 0 : -1
                             keyNavigationWraps: true
                             KeyNavigation.tab: categoryFocus

                             Keys.priority: Keys.BeforeItem
                             Keys.onReturnPressed: xmb.launchXmbSelection()
                             Keys.onEnterPressed: xmb.launchXmbSelection()
                             Keys.onEscapePressed: xmb.closeLocalXmb()

                            delegate: Rectangle {
                                required property var modelData
                                 width: appsGrid.width
                                height: 72
                                radius: 10
                                 color: appMouse.containsMouse || GridView.isCurrentItem ? (theme.colors.surface_selected || "#333954") : (theme.colors.surface || "#24283b")

                                Image {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 32
                                    height: 32
                                    source: Quickshell.iconPath(modelData.icon)
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 54
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    color: theme.colors.text || "#c0caf5"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    id: appMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        xmbModel.launch(modelData)
                                         xmb.closeLocalXmb()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Overview {
            screenData: modelData
            overviewData: overviewModel
            monitorData: monitorModel
            themeData: theme
        }
    }

    Settings {
        settingsData: settingsModel
        themeData: theme
        monitorData: monitorModel
    }
}
