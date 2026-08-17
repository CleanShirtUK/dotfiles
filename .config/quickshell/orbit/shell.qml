import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Controls as Controls
import Qt5Compat.GraphicalEffects

ShellRoot {
    id: root
    readonly property string home: Quickshell.env("HOME")

    Theme { id: theme }
    HyprlandModel { id: hyprlandModel }
    MonitorModel { id: monitorModel; snapshot: hyprlandModel }
    WindowModel { id: windowModel; snapshot: hyprlandModel }
    ApplicationMenuModel {
        id: applicationMenuModel
        windowModel: windowModel
        monitorModel: monitorModel
    }
    SettingsModel { id: settingsModel; snapshot: hyprlandModel }
    OverviewModel {
        id: overviewModel
        windowModel: windowModel
        monitorModel: monitorModel
        snapshot: hyprlandModel
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
    XmbModel { id: xmbModel; monitorModel: monitorModel }
    ApplicationModel {
        id: applicationModel
        windowModel: windowModel
        monitorModel: monitorModel
    }

    property bool xmbVisible: false
    property bool shellVisible: true
    property bool dockMorphing: false
    property bool dockHandoff: false
    property real dockMorphProgress: 0
    property int categoryRailIndex: 0

    Connections {
        target: applicationModel
        function onLauncherActivated() {
            root.startDockMorph()
        }
    }

    NumberAnimation {
        id: dockMorphProgressAnimation
        target: root
        property: "dockMorphProgress"
        from: 0
        to: 1
        duration: 360
        easing.type: Easing.InOutCubic
        onFinished: root.finishDockMorph()
    }

    FileView {
        id: xmbStateFile
        path: (Quickshell.env("XDG_CACHE_HOME") || (root.home + "/.cache")) + "/orbit/xmb-visible"
        watchChanges: true
        onLoaded: root.reloadXmbState()
        onFileChanged: reload()
    }

    FileView {
        id: shellStateFile
        path: (Quickshell.env("XDG_CACHE_HOME") || (root.home + "/.cache")) + "/orbit/shell-visible"
        watchChanges: true
        onLoaded: root.reloadShellState()
        onFileChanged: reload()
    }

    function reloadXmbState() {
        xmbVisible = xmbStateFile.text().trim() === "1"
    }

    function reloadShellState() {
        shellVisible = shellStateFile.text().trim() !== "0"
    }

    function moveXmbCategory(delta) {
        var categories = xmbModel.categories
        var index = categories.indexOf(xmbModel.category)
        if (index < 0)
            index = 0
        root.categoryRailIndex += delta
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

    function startDockMorph() {
        if (root.dockMorphing || root.xmbVisible)
            return
        root.dockMorphing = true
        root.dockHandoff = false
        root.dockMorphProgress = 0
        Quickshell.execDetached([root.home + "/.local/bin/orbit-xmb", "open"])
    }

    function startDockMorphAnimation() {
        dockMorphProgressAnimation.restart()
    }

    function finishDockMorph() {
        if (!root.dockMorphing || root.dockHandoff)
            return
        root.dockHandoff = true
        // The launcher surface is ready at the handoff boundary. Release the
        // morphing state so the layer-shell window can claim exclusive
        // keyboard focus, matching the keybind-open path.
        root.dockMorphing = false
    }

    onXmbVisibleChanged: {
        if (xmbVisible)
            return
        xmbModel.query = ""
        dockMorphProgressAnimation.stop()
        dockMorphing = false
        dockHandoff = false
        dockMorphProgress = 0
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dock
            required property var modelData
            screen: modelData
            visible: root.shellVisible
            anchors.bottom: true
            exclusiveZone: 58
            implicitWidth: dockContent.implicitWidth + 100
            implicitHeight: dockMenu.visible ? Math.max(96, dockMenu.implicitHeight + 82) : 96
            color: "transparent"

            Controls.Popup {
                id: dockMenu
                property var selectedItem: null
                parent: dockSurface
                padding: 6
                z: 100
                closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
                x: Math.max(4, Math.min(dockSurface.width - width - 4, menuAnchorX))
                y: dockSurface.height - height - 74
                property real menuAnchorX: 0

                background: Rectangle {
                    color: theme.colors.surface_elevated || "#2c3148"
                    border.color: theme.colors.border || "#3d4355"
                    border.width: 1
                    radius: 10
                }

                contentItem: Column {
                    spacing: 2

                    Repeater {
                        model: [
                            { id: "pin", label: "Pin" },
                            { id: "unpin", label: "Unpin" },
                            { id: "new", label: "Open New Window" },
                            { id: "close", label: "Close" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: 148
                            height: 30
                            radius: 6
                            visible: {
                                if (!dockMenu.selectedItem)
                                    return false
                                if (modelData.id === "pin")
                                    return !dockMenu.selectedItem.pinned
                                if (modelData.id === "unpin")
                                    return dockMenu.selectedItem.pinned
                                if (modelData.id === "close")
                                    return dockMenu.selectedItem.running
                                return true
                            }
                            color: menuMouse.containsMouse ? Qt.alpha(theme.colors.accent || "#7aa2f7", 0.2) : "transparent"
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: theme.colors.text || "#c0caf5"
                                font.family: theme.uiFont
                                font.pixelSize: 11
                            }
                            MouseArea {
                                id: menuMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (modelData.id === "pin") applicationModel.setPinned(dockMenu.selectedItem, true)
                                    else if (modelData.id === "unpin") applicationModel.setPinned(dockMenu.selectedItem, false)
                                    else if (modelData.id === "new") applicationModel.launchNewWindow(dockMenu.selectedItem)
                                    else if (modelData.id === "close") applicationModel.close(dockMenu.selectedItem)
                                    dockMenu.close()
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: dockSurface
                anchors.fill: parent

                HoverHandler {
                    id: dockPointer
                    onHoveredChanged: dockContent.hoverAmount = hovered ? 1 : 0
                    onPointChanged: if (hovered) dockContent.hoverPointerX = point.position.x - dockContent.x
                }

                Rectangle {
                    id: dockBackground
                    property real morphRevealProgress: Math.max(0, Math.min(1, (root.dockMorphProgress - 0.08) / 0.28))
                    width: dockContent.implicitWidth + 20
                    height: 58
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                     color: Qt.alpha(theme.colors.window_background || "#1a1b26", theme.shellOpacity)
                    border.color: theme.colors.border || "#3d4355"
                    border.width: 1
                    radius: 16
                    opacity: root.dockMorphing ? 1 - morphRevealProgress : 1
                    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }

                Row {
                    id: dockContent
                    property real morphRevealProgress: Math.max(0, Math.min(1, (root.dockMorphProgress - 0.08) / 0.28))
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 19
                    height: 36
                    spacing: 0
                    z: 1
                    opacity: root.dockMorphing ? 1 - morphRevealProgress : 1
                    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                     property real hoverPointerX: -1
                     property real hoverAmount: 0
                     Behavior on hoverAmount { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                    function scaleAt(center) {
                        if (hoverPointerX < 0)
                            return 1
                        var distance = Math.abs(center - hoverPointerX)
                        var normalized = Math.min(1, distance / 132)
                        var influence = Math.pow(Math.cos(normalized * Math.PI / 2), 2)
                        return 1 + 0.34 * influence * hoverAmount
                    }

                    function offsetAt(itemIndex) {
                        if (hoverPointerX < 0)
                            return 0

                        var itemCenter = itemIndex * 36 + 18
                        var delta = itemCenter - hoverPointerX
                        var distance = Math.abs(delta)
                        if (distance < 0.1)
                            return 0

                        var steps = Math.max(1, Math.ceil(distance / 18))
                        var growth = 0
                        for (var step = 0; step <= steps; step++) {
                            var sample = itemCenter + delta * step / steps
                            growth += scaleAt(sample) - 1
                        }
                        growth /= steps + 1
                        var offset = (delta > 0 ? 1 : -1) * growth * distance * 0.95
                        return Math.max(-28, Math.min(28, offset))
                    }

                    Repeater {
                        model: applicationModel.items()

                        delegate: Rectangle {
                            id: dockItem
                            required property var modelData
                            width: 36
                            height: 36
                            radius: 10
                            property real itemCenter: x + width / 2
                            property real targetScale: dockContent.scaleAt(itemCenter)
                            property real targetOffsetX: dockContent.offsetAt(modelData.dockIndex)
                            color: "transparent"

                            Item {
                                id: dockVisual
                                anchors.fill: parent
                                scale: dockItem.targetScale
                                transformOrigin: Item.Bottom
                                Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                                transform: Translate {
                                    x: dockItem.targetOffsetX
                                    Behavior on x { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                                }

                                OrbitIcon {
                                    anchors.centerIn: parent
                                    width: 24
                                    height: 24
                                    iconSource: applicationModel.iconPath(modelData)
                                    iconSize: 40
                                }

                                Rectangle {
                                    visible: applicationModel.isLaunching(modelData)
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 12
                                    height: 3
                                    radius: 2
                                    color: theme.colors.accent_secondary || theme.colors.accent || "#bb9af7"
                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        running: visible
                                        NumberAnimation { to: 0.25; duration: 450; easing.type: Easing.InOutSine }
                                        NumberAnimation { to: 1; duration: 450; easing.type: Easing.InOutSine }
                                    }
                                }

                                Rectangle {
                                    visible: modelData.running
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 5
                                    height: 3
                                    radius: 2
                                    color: theme.colors.accent || "#7aa2f7"
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onPressed: function(mouse) {
                                    if (mouse.button === Qt.RightButton) {
                                        dockMenu.selectedItem = modelData
                                        dockMenu.menuAnchorX = dockContent.x + dockItem.x + dockItem.width / 2
                                        dockMenu.open()
                                        mouse.accepted = true
                                    }
                                }
                                onClicked: function(mouse) {
                                    if (mouse.button === Qt.LeftButton)
                                        applicationModel.activate(modelData)
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

        PanelWindow {
            id: xmb
            required property var modelData
            screen: modelData
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.xmbVisible && !root.dockMorphing && monitorModel.focusedName === modelData.name ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            visible: root.xmbVisible && monitorModel.focusedName === modelData.name
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"

            onVisibleChanged: if (visible) {
                 if (root.dockMorphing && !root.dockHandoff)
                     root.startDockMorphAnimation()
                 xmbModel.category = xmbModel.categories.indexOf("All") >= 0 ? "All" : (xmbModel.categories[0] || "")
                 root.categoryRailIndex = xmbModel.categories.length * 4 + Math.max(0, xmbModel.categories.indexOf(xmbModel.category))
                 Qt.callLater(function() {
                     appsGrid.currentIndex = appsGrid.currentIndex < 0 ? 0 : appsGrid.currentIndex
                     search.forceActiveFocus()
                 })
             }

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
                 appsGrid.selectionDirection = delta >= 0 ? 1 : -1
                 appsGrid.currentIndex = next
            }

            function openApplicationMenu(app, anchorX, anchorY) {
                xmbAppMenu.selectedApp = {
                    desktop: app.id,
                    label: app.name,
                    class: app.startupWMClass || app.id
                }
                xmbAppMenu.x = Math.max(8, Math.min(width - xmbAppMenu.width - 8, anchorX))
                xmbAppMenu.y = Math.max(8, Math.min(height - xmbAppMenu.height - 8, anchorY))
                xmbAppMenu.open()
            }

            Controls.Popup {
                id: xmbAppMenu
                parent: xmbFocus
                property var selectedApp: null
                padding: 6
                z: 50
                closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside

                background: Rectangle {
                    color: theme.colors.surface_elevated || "#2c3148"
                    border.color: theme.colors.border || "#3d4355"
                    border.width: 1
                    radius: 10
                }

                contentItem: Column {
                    spacing: 2

                    Repeater {
                        model: [
                            { id: "pin", label: "Pin to Dock" },
                            { id: "edit", label: "Edit Desktop File" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            width: 176
                            height: 30
                            radius: 6
                            color: menuMouse.containsMouse ? Qt.alpha(theme.colors.accent || "#7aa2f7", 0.2) : "transparent"

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: theme.colors.text || "#c0caf5"
                                font.family: theme.uiFont
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: menuMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (!xmbAppMenu.selectedApp)
                                        return
                                    if (modelData.id === "pin")
                                        applicationModel.setPinned(xmbAppMenu.selectedApp, true)
                                    else
                                        Quickshell.execDetached([root.home + "/.local/bin/orbit-edit-desktop", xmbAppMenu.selectedApp.desktop])
                                    xmbAppMenu.close()
                                }
                            }
                        }
                    }
                }
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

                  Item {
                      id: dockMorphSurface
                      anchors.fill: parent
                       // Keep the morph background alive through the handoff. The
                       // launcher surface is created by the same layer-shell window,
                       // so removing this surface at the exact handoff boundary can
                       // expose one compositor frame of transparent background.
                       visible: root.dockMorphing
                      z: 5

                      Rectangle {
                          id: morphSurface
                          property real morphProgress: root.dockMorphProgress
                          property real startWidth: applicationModel.items().length * 36 + 20
                          property real targetWidth: xmbModel.fullscreen ? parent.width : Math.min(parent.width - 80, 820)
                          property real targetHeight: xmbModel.fullscreen ? parent.height : Math.min(parent.height - 80, 560)
                          width: startWidth + (targetWidth - startWidth) * morphProgress
                          height: 58 + (targetHeight - 58) * morphProgress
                          x: (parent.width - width) / 2
                          y: (parent.height - 66) * (1 - morphProgress) + ((parent.height - height) / 2) * morphProgress
                          color: Qt.alpha(theme.colors.window_background || "#1a1b26", theme.shellOpacity)
                          border.color: theme.colors.border || "#3d4355"
                          border.width: 1
                          radius: xmbModel.fullscreen ? 16 * (1 - morphProgress) : 16 + 4 * morphProgress

                          Row {
                              id: morphIcons
                              anchors.horizontalCenter: parent.horizontalCenter
                              anchors.verticalCenter: parent.verticalCenter
                              height: 36 + 20 * morphSurface.morphProgress
                              spacing: 0
                              opacity: Math.max(0, 1 - morphSurface.morphProgress / 0.82)

                              Repeater {
                                  model: applicationModel.items()

                                  delegate: Item {
                                      required property var modelData
                                      width: 36 + 20 * morphSurface.morphProgress
                                      height: morphIcons.height

                                      OrbitIcon {
                                          anchors.centerIn: parent
                                          width: 24 + 16 * morphSurface.morphProgress
                                          height: width
                                          iconSource: applicationModel.iconPath(modelData)
                                          iconSize: 40 + 16 * morphSurface.morphProgress
                                      }
                                  }
                              }
                          }
                      }
                  }

                  Rectangle {
                      id: xmbLauncherSurface
                       visible: !root.dockMorphing || root.dockHandoff
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
                              text: "×"
                             color: theme.colors.text || "#c0caf5"
                              font.family: theme.uiFont
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

                      Rectangle {
                          id: settingsButton
                          anchors.top: parent.top
                          anchors.right: closeButton.left
                          anchors.topMargin: 12
                          anchors.rightMargin: 8
                          width: 34
                          height: 34
                          radius: 8
                          color: settingsMouse.containsMouse ? (theme.colors.accent || "#7aa2f7") : (theme.colors.surface_selected || "#333954")
                          z: 10

                           OrbitIcon {
                               anchors.centerIn: parent
                               width: 18
                               height: 18
                               iconName: "settings-symbolic"
                               iconSize: 24
                               layer.enabled: true
                               layer.effect: MultiEffect {
                                   colorization: 1
                                   colorizationColor: theme.colors.text || "#c0caf5"
                               }
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

                      anchors.centerIn: parent
                     width: xmbModel.fullscreen ? parent.width : Math.min(parent.width - 80, 820)
                       height: xmbModel.fullscreen ? parent.height : Math.min(parent.height - 80, 560)
                    color: Qt.alpha(theme.colors.window_background || "#1a1b26", theme.shellOpacity)
                    border.color: theme.colors.border || "#3d4355"
                    border.width: 1
                    radius: xmbModel.fullscreen ? 0 : 20

                    Column {
                        anchors.fill: parent
                         anchors.margins: 32
                         spacing: 20

                           Item {
                              id: categoryViewport
                              width: parent.width
                               height: 100
                              clip: true

                              FocusScope {
                                   id: categoryFocus
                                    anchors.fill: parent
                                    Keys.priority: Keys.BeforeItem
                                    Keys.onEscapePressed: xmb.closeLocalXmb()
                                    Keys.onLeftPressed: {
                                        root.moveXmbCategory(-1)
                                        event.accepted = true
                                    }
                                    Keys.onRightPressed: {
                                        root.moveXmbCategory(1)
                                        event.accepted = true
                                    }

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
                                        property int categoryCount: xmbModel.categories.length
                                        property int selectedIndex: xmbModel.categories.indexOf(xmbModel.category)
                                         property int selectedRailIndex: root.categoryRailIndex
                                         property int railRevision: 0
                                         property real selectedAnchorRatio: 0.20
                                         property real categoryItemWidth: 124
                                         property real categoryIconSize: 64
                                         height: 92
                                        width: implicitWidth
                                        spacing: 8
                                        x: categoryViewport.width * selectedAnchorRatio - selectedCategoryStart()
                                        anchors.verticalCenter: parent.verticalCenter

                                        function selectedCategoryStart() {
                                            railRevision
                                            var selected = categoryRepeater.itemAt(selectedRailIndex)
                                            return selected ? selected.x : 0
                                        }

                                        function selectedCategoryViewportX() {
                                            return x + selectedCategoryStart()
                                        }

                                        function selectedCategoryIconViewportX() {
                                            return selectedCategoryCenterViewportX() - 20
                                        }

                                        function selectedCategoryCenterViewportX() {
                                            return selectedCategoryViewportX() + categoryItemWidth / 2
                                        }

                                        function categoryOpacity(distance) {
                                            return Math.max(0, 1 - distance * 0.25)
                                        }

                                        function categoryBlur(distance) {
                                            return Math.min(0.8, distance * 0.16)
                                        }

                                        Behavior on x {
                                            NumberAnimation {
                                               duration: 220
                                               easing.type: Easing.OutCubic
                                           }
                                       }

                                  Repeater {
                                      id: categoryRepeater
                                       model: xmbModel.categories.length * 9
                                      onItemAdded: categoryRow.railRevision++
                                      delegate: Rectangle {
                                          required property int index
                                          property string categoryName: xmbModel.categories[index % xmbModel.categories.length]
                                          width: categoryRow.categoryItemWidth
                                           height: 92
                                          radius: 12
                                               property int distanceFromSelection: Math.abs(index - categoryRow.selectedRailIndex)
                                               property bool selected: index === categoryRow.selectedRailIndex
                                               color: "transparent"
                                              opacity: categoryRow.categoryOpacity(distanceFromSelection)
                                              scale: selected ? 1 : (distanceFromSelection === 1 ? 0.94 : 0.88)
                                              layer.enabled: distanceFromSelection > 0 && opacity > 0
                                               layer.effect: MultiEffect {
                                                   blurEnabled: true
                                                   blur: categoryRow.categoryBlur(distanceFromSelection)
                                                   colorization: 1
                                                   colorizationColor: theme.colors.text || "#c0caf5"
                                               }

                                             Behavior on opacity {
                                                 NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                             }

                                             Behavior on scale {
                                                 NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                             }

                                          Column {
                                              anchors.centerIn: parent
                                              spacing: 4

                                               OrbitIcon {
                                                   anchors.horizontalCenter: parent.horizontalCenter
                                                   width: categoryRow.categoryIconSize
                                                   height: categoryRow.categoryIconSize
                                                   iconName: xmbModel.categoryIcon(categoryName)
                                                   iconSize: 64
                                                   layer.enabled: true
                                                   layer.effect: MultiEffect {
                                                       colorization: 1
                                                       colorizationColor: theme.colors.text || "#c0caf5"
                                                   }
                                               }

                                              Text {
                                                  id: categoryLabel
                                                   width: categoryRow.categoryIconSize
                                                  text: categoryName
                                                   color: theme.colors.text || "#c0caf5"
                                                  font.family: theme.uiFont
                                                   font.pixelSize: 10
                                                  font.bold: selected
                                                  horizontalAlignment: Text.AlignHCenter
                                                   elide: Text.ElideRight
                                                  wrapMode: Text.NoWrap
                                              }
                                          }

                                         MouseArea {
                                             anchors.fill: parent
                                              onClicked: {
                                                  xmbModel.category = categoryName
                                                  categoryFocus.forceActiveFocus()
                                              }
                                         }
                                     }
                                 }
                                 }
                             }
                        }

                          Item {
                              id: searchSurface
                              x: categoryRow.selectedCategoryCenterViewportX() - 20
                              width: parent.width - x
                              height: 72

                              OrbitIcon {
                                  anchors.left: parent.left
                                  anchors.leftMargin: 0
                                  anchors.verticalCenter: parent.verticalCenter
                                  width: 40
                                  height: 40
                                  iconName: "system-search-symbolic"
                                  iconSize: 48
                              }

                              TextField {
                                  id: search
                                  anchors.fill: parent
                                  leftPadding: 64
                              color: theme.colors.text || "#c0caf5"
                              selectionColor: theme.colors.accent || "#7aa2f7"
                             font.family: "JetBrains Mono"
                             font.pixelSize: 14
                             clip: true
                             focus: true
                             placeholderText: "Search applications..."
                              placeholderTextColor: theme.colors.text || "#c0caf5"
                              font.bold: true
                             background: null
                             onTextChanged: xmbModel.query = text
                             onActiveFocusChanged: if (activeFocus) appsGrid.currentIndex = appsGrid.currentIndex < 0 ? 0 : appsGrid.currentIndex
                              Keys.priority: Keys.BeforeItem
                              Keys.onLeftPressed: {
                                  root.moveXmbCategory(-1)
                                  event.accepted = true
                              }
                              Keys.onRightPressed: {
                                  root.moveXmbCategory(1)
                                  event.accepted = true
                              }
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

                            Item {
                               id: appsGrid
                                x: categoryRow.selectedCategoryCenterViewportX() - 20
                               width: parent.width - x
                                  height: parent.height - 212
                               clip: true
                              property var appItems: xmbModel.filteredApps()
                              property int currentIndex: appItems.length > 0 ? 0 : -1
                              property real selectedEntryOffset: 0
                              property int selectionDirection: -1
                              property real selectionStep: 80
                               onAppItemsChanged: {
                                   currentIndex = appItems.length > 0 ? 0 : -1
                                   if (currentIndex >= 0)
                                       animateSelectedEntry()
                               }
                               onCurrentIndexChanged: {
                                   animateSelectedEntry()
                               }
                              KeyNavigation.tab: categoryFocus

                              NumberAnimation {
                                  id: selectedEntryAnimation
                                  target: appsGrid
                                  property: "selectedEntryOffset"
                                  from: -80
                                  to: 0
                                  duration: 220
                                  easing.type: Easing.OutCubic
                              }

                              function animateSelectedEntry() {
                                  selectedEntryOffset = selectionDirection > 0 ? selectionStep : -selectionStep
                                  selectedEntryAnimation.from = selectedEntryOffset
                                  selectedEntryAnimation.restart()
                              }

                              function entryHeight(index) {
                                   return index === currentIndex ? 72 : 42
                              }

                              function entryY(index) {
                                  if (currentIndex < 0)
                                      return 0

                                   var count = appItems.length
                                   var distance = index - currentIndex
                                   if (distance > count / 2)
                                       distance -= count
                                   else if (distance < -count / 2)
                                       distance += count

                                   var y = 0
                                   if (distance >= 0) {
                                       for (var below = 0; below < distance; below++)
                                           y += entryHeight((currentIndex + below) % count) + 8
                                   } else {
                                       for (var above = 0; above > distance; above--)
                                           y -= entryHeight((currentIndex + above + count) % count) + 8
                                  }
                                  return y
                              }

                              function entryOpacity(index) {
                                  return Math.max(0, 1 - Math.abs(index - currentIndex) * 0.2)
                              }

                              function entryBlur(index) {
                                  return Math.min(0.8, Math.abs(index - currentIndex) * 0.14)
                              }

                              Keys.priority: Keys.BeforeItem
                              Keys.onReturnPressed: xmb.launchXmbSelection()
                              Keys.onEnterPressed: xmb.launchXmbSelection()
                              Keys.onEscapePressed: xmb.closeLocalXmb()

                               Item {
                                   id: appContent
                                   anchors.fill: parent
                                   layer.enabled: true
                                   layer.effect: OpacityMask {
                                       maskSource: appEdgeMask
                                   }

                                   Repeater {
                                       model: appsGrid.appItems

                                  delegate: Rectangle {
                                      required property var modelData
                                      required property int index
                                      property bool selected: index === appsGrid.currentIndex
                                      property real entranceOpacity: selected && appsGrid.selectedEntryOffset < 0 ? Math.max(0, 1 + appsGrid.selectedEntryOffset / appsGrid.selectionStep) : 1
                                      x: 0
                                      y: appsGrid.entryY(index) + (selected ? appsGrid.selectedEntryOffset : 0)
                                      width: appsGrid.width
                                      height: appsGrid.entryHeight(index)
                                       visible: y + height >= 0 && y + height <= appsGrid.height - 8
                                      radius: 12
                                      color: "transparent"
                                      opacity: appsGrid.entryOpacity(index) * entranceOpacity
                                      border.width: 0
                                      layer.enabled: !selected && opacity > 0
                                      layer.effect: MultiEffect {
                                          blurEnabled: true
                                          blur: appsGrid.entryBlur(index)
                                      }

                                      Behavior on y {
                                           enabled: !selected
                                          NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                                      }

                                      OrbitIcon {
                                          id: appIcon
                                          x: 20 - width / 2
                                          anchors.verticalCenter: parent.verticalCenter
                                          width: parent.selected ? 40 : 28
                                          height: parent.selected ? 40 : 28
                                          iconName: modelData.icon
                                          iconSize: 48
                                      }

                                      Text {
                                          x: appIcon.x + appIcon.width + 24
                                          width: parent.width - x - 8
                                          anchors.verticalCenter: parent.verticalCenter
                                          text: modelData.name
                                          color: theme.colors.text || "#c0caf5"
                                          font.family: theme.uiFont
                                          font.pixelSize: parent.selected ? 14 : 12
                                          font.bold: parent.selected
                                          elide: Text.ElideRight
                                      }

                                       MouseArea {
                                           id: appMouse
                                           anchors.fill: parent
                                           hoverEnabled: true
                                           acceptedButtons: Qt.LeftButton | Qt.RightButton
                                           onPressed: function(mouse) {
                                                if (mouse.button === Qt.RightButton) {
                                                    xmb.openApplicationMenu(modelData, appsGrid.x + parent.x, appsGrid.y + parent.y + parent.height)
                                                    mouse.accepted = true
                                                 }
                                             }
                                             onClicked: {
                                               if (mouse.button === Qt.LeftButton) {
                                                   appsGrid.currentIndex = index
                                                   xmbModel.launch(modelData)
                                                   xmb.closeLocalXmb()
                                               }
                                           }
                                       }
                                   }
                               }

                               Rectangle {
                                   id: appEdgeMask
                                   visible: false
                                   width: appsGrid.width
                                   height: appsGrid.height
                                   gradient: Gradient {
                                       GradientStop { position: 0.0; color: "#00000000" }
                                       GradientStop { position: 0.18; color: "#ffffffff" }
                                       GradientStop { position: 1.0; color: "#ffffffff" }
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

      Variants {
          model: Quickshell.screens

           TopPanel {
               screenData: modelData
               themeData: theme
               shellVisible: root.shellVisible
               applicationMenuData: applicationMenuModel
               monitorName: modelData.name
               onLauncherRequested: Quickshell.execDetached([root.home + "/.local/bin/orbit-xmb", "open"])
           }
      }

    Settings {
        settingsData: settingsModel
        themeData: theme
        monitorData: monitorModel
    }
}
