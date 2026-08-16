import Quickshell
import QtQuick
import QtQuick.Controls

Window {
    id: root

    required property var settingsData
    required property var themeData
    required property var monitorData

    title: "Orbit Settings"
    width: 1120
    height: 720
    visible: settingsData.settingsVisible
    color: themeData.colors.window_background || "#1a1b26"
    flags: Qt.Window

    onVisibleChanged: if (visible) Qt.callLater(function() {
        requestActivate()
        settingsFocus.forceActiveFocus()
    })

    onClosing: function(event) {
        event.accepted = false
        settingsData.requestClose()
    }

    function textColor() { return themeData.colors.text || "#c0caf5" }
    function mutedColor() { return themeData.colors.text_muted || "#9aa5ce" }
    function surfaceColor() { return themeData.colors.surface || "#24283b" }
    function selectedColor() { return themeData.colors.surface_selected || "#333954" }
    function accentColor() { return themeData.colors.accent || "#7aa2f7" }

    FocusScope {
        id: settingsFocus
        anchors.fill: parent
        focus: root.visible
        Keys.priority: Keys.BeforeItem
        Keys.onEscapePressed: settingsData.requestClose()

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 44, 1120)
            height: Math.min(parent.height - 44, 720)
            color: Qt.alpha(themeData.colors.window_background || "#1a1b26", 0.98)
            border.color: themeData.colors.border || "#3d4355"
            border.width: 1
            radius: 16

            Row {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 18

                Rectangle {
                    width: 238
                    height: parent.height
                    color: Qt.alpha(surfaceColor(), 0.72)
                    radius: 12

                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Text {
                            text: "ORBIT SETTINGS"
                            color: accentColor()
                            font.family: "JetBrains Mono"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Text {
                            text: "Shell and system control"
                            color: mutedColor()
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                        }

                        ListView {
                            id: menuList
                            width: parent.width
                            height: parent.height - 62
                            spacing: 4
                            clip: true
                            model: settingsData.menu
                            currentIndex: 0

                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: menuList.width
                                height: 38
                                radius: 8
                                color: index === menuList.currentIndex ? selectedColor() : "transparent"

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label || modelData.id
                                    color: index === menuList.currentIndex ? textColor() : mutedColor()
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: menuList.currentIndex = index
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width - 256
                    height: parent.height
                    spacing: 12

                    Row {
                        width: parent.width
                        height: 34
                        spacing: 12

                        Text {
                            text: settingsData.menu.length > menuList.currentIndex ? (settingsData.menu[menuList.currentIndex].label || "Settings") : "Settings"
                            color: textColor()
                            font.family: "JetBrains Mono"
                            font.pixelSize: 18
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item { width: parent.width - 170; height: 1 }

                        Rectangle {
                            width: 34
                            height: 34
                            radius: 8
                            color: closeMouse.containsMouse ? (themeData.colors.error || "#f7768e") : selectedColor()
                            Text { anchors.centerIn: parent; text: "X"; color: textColor(); font.bold: true }
                            MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; onClicked: settingsData.requestClose() }
                        }
                    }

                    Loader {
                        id: moduleLoader
                        width: parent.width
                        height: parent.height - 96
                        sourceComponent: {
                            if (!settingsData.menu.length)
                                return diagnosticsPage
                            var id = settingsData.menu[menuList.currentIndex].id
                            if (id === "appearance") return appearancePage
                            if (id === "shell") return shellPage
                            if (id === "displays") return displaysPage
                            if (id === "applications") return applicationsNewPage
                            if (id === "audio") return audioPage
                            if (id === "network") return networkPage
                            if (id === "bluetooth") return bluetoothPage
                            if (id === "power") return powerPage
                            if (id === "diagnostics") return diagnosticsPage
                            return unavailablePage
                        }
                    }

                    Row {
                        width: parent.width
                        height: 38
                        spacing: 10

                        Text {
                            width: parent.width - 220
                            text: settingsData.status
                            color: settingsData.status.indexOf("failed") >= 0 ? (themeData.colors.error || "#f7768e") : mutedColor()
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Button {
                            text: "Cancel"
                            enabled: settingsData.dirty
                            onClicked: settingsData.cancel()
                        }
                        Button {
                            text: "Apply"
                            enabled: settingsData.dirty
                            onClicked: settingsData.requestApply()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: appearancePage
        Flickable {
            contentWidth: width
            contentHeight: appearanceColumn.height
            clip: true
            Column {
                id: appearanceColumn
                width: moduleLoader.width
                spacing: 12
                Text { text: "Palette"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
                Text { text: "Orbit generates the shared semantic and toolkit artifacts from this palette."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
                ComboBox {
                    width: Math.min(parent.width, 360)
                    model: settingsData.palettes
                    currentIndex: Math.max(0, settingsData.palettes.indexOf(settingsData.draft.theme ? settingsData.draft.theme.palette : ""))
                    onActivated: settingsData.setThemePalette(currentText)
                }
                Rectangle { width: parent.width; height: 1; color: themeData.colors.border || "#3d4355" }
                Text { text: "The palette change is staged until Apply."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }
            }
        }
    }

    Component {
        id: shellPage
        Column {
            spacing: 14
            Text { text: "Shell behavior"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
            CheckBox {
                text: "Use fullscreen XMB overlay"
                checked: Boolean(settingsData.draft.shell && settingsData.draft.shell.xmb_fullscreen)
                onToggled: settingsData.setXmbFullscreen(checked)
            }
            Text { text: "The XMB normally opens as a widget-sized focused-monitor overlay."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
        }
    }

    Component {
        id: displaysPage
        Item {
            id: displaysFlickable
            property var settingsModel: settingsData
            property var profiles: settingsData.draft.display_profiles || settingsData.displayProfiles
            property real minX: {
                if (!profiles.length) return 0
                var value = profiles[0].x || 0
                for (var index = 1; index < profiles.length; index++) value = Math.min(value, profiles[index].x || 0)
                return value
            }
            property real minY: {
                if (!profiles.length) return 0
                var value = profiles[0].y || 0
                for (var index = 1; index < profiles.length; index++) value = Math.min(value, profiles[index].y || 0)
                return value
            }
            property real maxX: {
                if (!profiles.length) return 1
                var value = (profiles[0].x || 0) + (profiles[0].width || 1)
                for (var index = 1; index < profiles.length; index++) value = Math.max(value, (profiles[index].x || 0) + (profiles[index].width || 1))
                return value
            }
            property real maxY: {
                if (!profiles.length) return 1
                var value = (profiles[0].y || 0) + (profiles[0].height || 1)
                for (var index = 1; index < profiles.length; index++) value = Math.max(value, (profiles[index].y || 0) + (profiles[index].height || 1))
                return value
            }
            // Keep the representations smaller than the available topology
            // area so there is room to reposition them along each edge.
            property real topologyScale: Math.min((topology.width - 40) / Math.max(1, maxX - minX), (topology.height - 40) / Math.max(1, maxY - minY)) * 0.72
            property var selectedProfile: settingsData.selectedProfile()

            function cardX(profile) { return 20 + ((profile.x || 0) - minX) * topologyScale }
            function cardY(profile) { return 20 + ((profile.y || 0) - minY) * topologyScale }
            function cardWidth(profile) { return Math.max(96, (profile.width || 1) * topologyScale) }
            function cardHeight(profile) { return Math.max(64, (profile.height || 1) * topologyScale) }
            function overlaps(index, x, y, otherIndex) {
                var profile = profiles[index]
                var other = profiles[otherIndex]
                var right = x + cardWidth(profile)
                var bottom = y + cardHeight(profile)
                var otherX = cardX(other)
                var otherY = cardY(other)
                var otherRight = otherX + cardWidth(other)
                var otherBottom = otherY + cardHeight(other)
                return x < otherRight && right > otherX && y < otherBottom && bottom > otherY
            }
            function constrainDrag(index, proposedX, proposedY, previousX, previousY) {
                var profile = profiles[index]
                var width = cardWidth(profile)
                var height = cardHeight(profile)
                var x = proposedX
                var y = proposedY

                // Resolve each axis independently. This lets a card slide
                // around a corner instead of getting trapped by the axis with
                // the largest instantaneous mouse delta.
                var horizontalMotion = x - previousX
                if (Math.abs(horizontalMotion) > 2) {
                    for (var otherIndex = 0; otherIndex < profiles.length; otherIndex++) {
                        if (otherIndex === index || !overlaps(index, x, previousY, otherIndex))
                            continue
                        var other = profiles[otherIndex]
                        var otherX = cardX(other)
                        if (horizontalMotion > 0)
                            x = otherX - width
                        else if (horizontalMotion < 0)
                            x = otherX + cardWidth(other)
                    }
                }

                var verticalMotion = y - previousY
                if (Math.abs(verticalMotion) > 2) {
                    for (var otherIndex = 0; otherIndex < profiles.length; otherIndex++) {
                        if (otherIndex === index || !overlaps(index, x, y, otherIndex))
                            continue
                        var other = profiles[otherIndex]
                        var otherY = cardY(other)
                        if (verticalMotion > 0)
                            y = otherY + cardHeight(other)
                        else if (verticalMotion < 0)
                            y = otherY - height
                    }
                }
                return { x: x, y: y }
            }
            function roleEnabled(role) {
                var config = settingsData.draft.displays ? settingsData.draft.displays[role] : null
                return Boolean(config && config.connector === selectedProfile.connector)
            }
            function resolutions(profile) {
                var result = []
                for (var index = 0; index < (profile.available_modes || []).length; index++) {
                    var resolution = String(profile.available_modes[index]).split("@")[0]
                    if (result.indexOf(resolution) < 0) result.push(resolution)
                }
                return result
            }
            function refreshRates(profile, resolution) {
                var result = []
                for (var index = 0; index < (profile.available_modes || []).length; index++) {
                    var mode = String(profile.available_modes[index])
                    if (mode.indexOf(resolution + "@") !== 0) continue
                    var refresh = mode.substring(mode.indexOf("@") + 1).replace("Hz", "")
                    if (result.indexOf(refresh) < 0) result.push(refresh)
                }
                return result
            }

            Column {
                anchors.fill: parent
                spacing: 12

                Text { text: "Display layout"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
                Text { text: "Select a monitor to edit it. Drag a monitor to stage its position."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }

                Rectangle {
                    id: topology
                    width: parent.width
                    height: 250
                    color: Qt.alpha(surfaceColor(), 0.72)
                    border.color: themeData.colors.border || "#3d4355"
                    border.width: 1
                    radius: 10
                    clip: true

                    Repeater {
                        model: displaysFlickable.profiles
                        delegate: Rectangle {
                            id: monitorCard
                            required property var modelData
                            required property int index
                            property var displayState: displaysFlickable
                            x: displaysFlickable.cardX(modelData)
                            y: displaysFlickable.cardY(modelData)
                            width: displaysFlickable.cardWidth(modelData)
                            height: displaysFlickable.cardHeight(modelData)
                            radius: 9
                            color: index === displaysFlickable.settingsModel.selectedMonitorIndex ? selectedColor() : surfaceColor()
                            border.color: index === displaysFlickable.settingsModel.selectedMonitorIndex ? accentColor() : (modelData.active ? themeData.colors.border || "#3d4355" : mutedColor())
                            border.width: index === displaysFlickable.settingsModel.selectedMonitorIndex ? 2 : 1
                            opacity: modelData.active ? 1.0 : 0.48
                            z: index === displaysFlickable.settingsModel.selectedMonitorIndex ? 2 : 1

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 4
                                Text { text: modelData.connector || "Unknown display"; color: accentColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                                Text { text: modelData.model || modelData.description || "Unknown model"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
                                Text { text: (modelData.width || 0) + "x" + (modelData.height || 0) + " @ " + Number(modelData.refresh_rate || 0).toFixed(2) + " Hz"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 9 }
                                Text { text: (modelData.active ? "ACTIVE" : "INACTIVE") + (modelData.adaptive_sync ? "  VRR" : ""); color: modelData.active ? (themeData.colors.success || "#9ece6a") : mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 9 }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.SizeAllCursor
                                drag.target: monitorCard
                                property real lastAcceptedX: 0
                                property real lastAcceptedY: 0
                                onPressed: {
                                    monitorCard.displayState.settingsModel.selectMonitor(index)
                                    lastAcceptedX = monitorCard.x
                                    lastAcceptedY = monitorCard.y
                                }
                                onPositionChanged: if (pressed) {
                                    var constrained = monitorCard.displayState.constrainDrag(index, monitorCard.x, monitorCard.y, lastAcceptedX, lastAcceptedY)
                                    monitorCard.x = constrained.x
                                    monitorCard.y = constrained.y
                                    lastAcceptedX = constrained.x
                                    lastAcceptedY = constrained.y
                                }
                                onReleased: {
                                    var positionX = Math.round((monitorCard.x - 20) / monitorCard.displayState.topologyScale + monitorCard.displayState.minX)
                                    var positionY = Math.round((monitorCard.y - 20) / monitorCard.displayState.topologyScale + monitorCard.displayState.minY)
                                    monitorCard.displayState.settingsModel.setProfileField("x", positionX)
                                    monitorCard.displayState.settingsModel.setProfileField("y", positionY)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: parent.height - topology.height - 62
                    color: surfaceColor()
                    radius: 10
                    border.color: themeData.colors.border || "#3d4355"
                    border.width: 1

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 16
                        contentWidth: width
                        contentHeight: inspectorColumn.height
                        clip: true

                        Column {
                            id: inspectorColumn
                            width: parent.width
                            spacing: 10

                            Text { text: selectedProfile.connector + "  " + (selectedProfile.model || "Unknown model"); color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
                            Text { text: selectedProfile.description || "No monitor selected"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }

                            Column {
                                spacing: 8

                                Row {
                                    spacing: 8
                                    CheckBox { text: "Monitor active"; checked: selectedProfile.active !== false; onToggled: settingsData.setProfileField("active", checked) }
                                }
                                Row {
                                    spacing: 8
                                    CheckBox { text: "Adaptive Sync"; checked: selectedProfile.adaptive_sync === true; onToggled: settingsData.setProfileField("adaptive_sync", checked) }
                                }
                                Row {
                                    spacing: 8
                                    CheckBox { text: "Home Monitor"; checked: displaysFlickable.roleEnabled("home"); onToggled: settingsData.setProfileRole("home", checked) }
                                    Button { text: "?"; width: 28; height: 28; onClicked: {} }
                                }
                                Row {
                                    spacing: 8
                                    CheckBox { text: "Gaming Monitor"; checked: displaysFlickable.roleEnabled("gaming"); onToggled: settingsData.setProfileRole("gaming", checked) }
                                    Button { text: "?"; width: 28; height: 28; onClicked: {} }
                                }

                                Text { text: "Resolution"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }
                                ComboBox {
                                    id: resolutionSelect
                                    width: 240
                                    model: displaysFlickable.resolutions(selectedProfile)
                                    currentIndex: Math.max(0, model.indexOf((selectedProfile.width || 0) + "x" + (selectedProfile.height || 0)))
                                    onActivated: {
                                        var dimensions = currentText.split("x")
                                        settingsData.setProfileField("width", Number(dimensions[0]))
                                        settingsData.setProfileField("height", Number(dimensions[1]))
                                    }
                                }

                                Text { text: "Refresh rate"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }
                                ComboBox {
                                    width: 240
                                    model: displaysFlickable.refreshRates(selectedProfile, resolutionSelect.currentText)
                                    currentIndex: Math.max(0, model.indexOf(Number(selectedProfile.refresh_rate || 0).toFixed(2)))
                                    onActivated: settingsData.setProfileField("refresh_rate", Number(currentText))
                                }
                            }

                            Text { text: "Position: " + (selectedProfile.x || 0) + " x " + (selectedProfile.y || 0) + " px"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }
                            Text { text: "Serial: " + (selectedProfile.serial || "Unavailable"); color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: applicationsPage
        Flickable {
            id: applicationsView
            contentWidth: width
            contentHeight: applicationsColumn.height
            clip: true

            function policies() {
                return settingsData.draft.application_policies || { defaults: {}, rules: [] }
            }
            function defaults() { return policies().defaults || {} }
            function rules() { return policies().rules || [] }
            function choiceIndex(value, choices) {
                var index = choices.indexOf(value || "")
                return index < 0 ? 0 : index
            }
            function overrideChoices(values) { return ["(inherit)"].concat(values) }
            function overrideValue(index, values) { return index === 0 ? "" : values[index - 1] }

            Column {
                id: applicationsColumn
                width: moduleLoader.width
                spacing: 12

                Text { text: "Window and application policies"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
                Text {
                    text: "Rules are checked from top to bottom. Match the Hyprland window class, with an optional title pattern, then choose the workspace behavior."
                    color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width
                }

                Rectangle {
                    width: parent.width
                    height: defaultsColumn.height + 24
                    color: Qt.alpha(surfaceColor(), 0.72)
                    radius: 10
                    border.color: themeData.colors.border || "#3d4355"
                    border.width: 1

                    Column {
                        id: defaultsColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 8
                        Text { text: "Default behavior"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                        Row {
                            spacing: 10
                            Text { text: "Monitor"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; width: 84; anchors.verticalCenter: parent.verticalCenter }
                            ComboBox {
                                width: 150
                                model: ["focused", "home", "gaming"]
                                currentIndex: applicationsView.choiceIndex(applicationsView.defaults().monitor_role, model)
                                onActivated: settingsData.setApplicationDefaults("monitor_role", currentText)
                            }
                            Text { text: "Workspace"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; width: 84; anchors.verticalCenter: parent.verticalCenter }
                            ComboBox {
                                width: 150
                                model: ["dedicated", "inherit", "transient", "floating", "ignore"]
                                currentIndex: applicationsView.choiceIndex(applicationsView.defaults().workspace_policy, model)
                                onActivated: settingsData.setApplicationDefaults("workspace_policy", currentText)
                            }
                        }
                        Row {
                            spacing: 10
                            Text { text: "Children"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; width: 84; anchors.verticalCenter: parent.verticalCenter }
                            ComboBox {
                                width: 150
                                model: ["inherit", "dedicated", "ignore"]
                                currentIndex: applicationsView.choiceIndex(applicationsView.defaults().children, model)
                                onActivated: settingsData.setApplicationDefaults("children", currentText)
                            }
                            Text { text: "Exclude pattern"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; width: 84; anchors.verticalCenter: parent.verticalCenter }
                            TextField {
                                width: 250
                                text: applicationsView.defaults().inherit_exclude || ""
                                placeholderText: "optional class regex"
                                onEditingFinished: settingsData.setApplicationDefaults("inherit_exclude", text)
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 30
                    Text { text: "Application rules"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    Item { width: parent.width - 150; height: 1 }
                    Button { text: "Add rule"; onClicked: settingsData.addApplicationRule() }
                }

                Repeater {
                    model: applicationsView.rules()
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: applicationsColumn.width
                        height: ruleColumn.height + 24
                        color: surfaceColor()
                        radius: 10
                        border.color: themeData.colors.border || "#3d4355"
                        border.width: 1

                        Column {
                            id: ruleColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 8

                            Row {
                                width: parent.width
                                spacing: 8
                                TextField { width: parent.width - 92; text: modelData.name || ""; placeholderText: "Rule name"; onEditingFinished: settingsData.setApplicationRule(index, "name", text) }
                                Button { text: "Remove"; onClicked: settingsData.removeApplicationRule(index) }
                            }
                            Row {
                                spacing: 8
                                Text { text: "Class regex"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; width: 84; anchors.verticalCenter: parent.verticalCenter }
                                TextField { width: 300; text: modelData.class_pattern || ""; placeholderText: ".*"; onEditingFinished: settingsData.setApplicationRule(index, "class_pattern", text) }
                                Text { text: "Title regex"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; width: 70; anchors.verticalCenter: parent.verticalCenter }
                                TextField { width: 240; text: modelData.title_pattern || ""; placeholderText: "optional"; onEditingFinished: settingsData.setApplicationRule(index, "title_pattern", text) }
                            }
                            Row {
                                spacing: 8
                                Text { text: "Monitor"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; width: 84; anchors.verticalCenter: parent.verticalCenter }
                                ComboBox {
                                    width: 130
                                    model: applicationsView.overrideChoices(["focused", "home", "gaming"])
                                    currentIndex: applicationsView.choiceIndex(modelData.monitor_role, model)
                                    onActivated: settingsData.setApplicationRule(index, "monitor_role", applicationsView.overrideValue(currentIndex, ["focused", "home", "gaming"]))
                                }
                                Text { text: "Workspace"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; width: 84; anchors.verticalCenter: parent.verticalCenter }
                                ComboBox {
                                    width: 140
                                    model: applicationsView.overrideChoices(["dedicated", "inherit", "transient", "floating", "ignore"])
                                    currentIndex: applicationsView.choiceIndex(modelData.workspace_policy, model)
                                    onActivated: settingsData.setApplicationRule(index, "workspace_policy", applicationsView.overrideValue(currentIndex, ["dedicated", "inherit", "transient", "floating", "ignore"]))
                                }
                                Text { text: "Children"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; width: 55; anchors.verticalCenter: parent.verticalCenter }
                                ComboBox {
                                    width: 120
                                    model: applicationsView.overrideChoices(["inherit", "dedicated", "ignore"])
                                    currentIndex: applicationsView.choiceIndex(modelData.children, model)
                                    onActivated: settingsData.setApplicationRule(index, "children", applicationsView.overrideValue(currentIndex, ["inherit", "dedicated", "ignore"]))
                                }
                            }
                            Row {
                                spacing: 8
                                Text { text: "Inherited child exclusion"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; width: 170; anchors.verticalCenter: parent.verticalCenter }
                                TextField { width: 380; text: modelData.inherit_exclude || ""; placeholderText: "optional class regex"; onEditingFinished: settingsData.setApplicationRule(index, "inherit_exclude", text) }
                            }
                        }
                    }
                }

                Text {
                    visible: applicationsView.rules().length === 0
                    text: "No custom rules. Applications use the defaults above."
                    color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10
                }
            }
        }
    }

    Component {
        id: applicationsNewPage
        Item {
            id: applicationView
            property var policyData: settingsData.draft.application_policies || { defaults: {}, rules: [] }
            property var rules: policyData.rules || []
            property int selectedRule: -1
            property bool addDialogVisible: false
            property bool deleteConfirmVisible: false
            property string newRuleKind: "simple"
            property string newApplicationId: ""

            function app(id) {
                for (var index = 0; index < settingsData.applications.length; index++)
                    if (settingsData.applications[index].id === id) return settingsData.applications[index]
                return null
            }
            function appName(id) { var entry = app(id); return entry ? entry.name : (id || "Unknown application") }
            function appIcon(id) { var entry = app(id); return entry ? Quickshell.iconPath(entry.icon) : "" }
            function installedApplications() {
                var result = settingsData.applications.slice()
                result.sort(function(left, right) { return String(left.name).localeCompare(String(right.name)) })
                return result
            }
            function selected() { return selectedRule >= 0 && selectedRule < rules.length ? rules[selectedRule] : {} }
            function indexOf(value, choices) { var index = choices.indexOf(value || ""); return index < 0 ? 0 : index }
            function titlePattern(mode, value) {
                var escaped = String(value || "").replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
                if (mode === "exact") return "^" + escaped + "$"
                if (mode === "starts") return "^" + escaped
                if (mode === "ends") return escaped + "$"
                if (mode === "contains") return ".*" + escaped + ".*"
                return String(value || "")
            }
            function createRule() {
                if (!newApplicationId) return
                var applicationId = newApplicationId
                settingsData.addApplicationRuleFor(applicationId, newRuleKind)
                addDialogVisible = false
                Qt.callLater(function() { selectedRule = applicationView.rules.length - 1 })
            }
            function deleteSelected() {
                if (selectedRule < 0) return
                settingsData.removeApplicationRule(selectedRule)
                selectedRule = -1
                deleteConfirmVisible = false
            }

            Flickable {
                id: applicationScroller
                anchors.fill: applicationView
                contentWidth: width
                contentHeight: applicationColumn.height
                clip: true

                Column {
                id: applicationColumn
                width: applicationScroller.width
                spacing: 12
                Text { text: "Windows and Applications"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
                Text { text: "Each row is a rule. Applications may have multiple rules with different match types. Class matching is more reliable than title matching."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }

                Repeater {
                    model: applicationView.rules
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: applicationColumn.width
                        height: 58
                        radius: 9
                        color: index === applicationView.selectedRule ? selectedColor() : surfaceColor()
                        border.color: index === applicationView.selectedRule ? accentColor() : (themeData.colors.border || "#3d4355")
                        border.width: index === applicationView.selectedRule ? 2 : 1
                        MouseArea { anchors.fill: parent; onClicked: applicationView.selectedRule = index }
                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10
                            Image { width: 32; height: 32; source: applicationView.appIcon(modelData.application); sourceSize: Qt.size(32, 32); anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                width: parent.width - 120
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: applicationView.appName(modelData.application); color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                                Text { text: (modelData.match_type || "custom") + "  " + (modelData.match_value || modelData.name || "custom Lua rule"); color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 9; elide: Text.ElideRight; width: parent.width }
                            }
                            Text { text: "P" + (modelData.priority || 100); color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
                            Button { text: "Edit"; onClicked: applicationView.selectedRule = index }
                        }
                    }
                }

                Text { visible: applicationView.rules.length === 0; text: "No application rules configured."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }
                Row {
                    spacing: 8
                    Button { text: "New Simple Rule"; onClicked: { applicationView.newRuleKind = "simple"; applicationView.newApplicationId = ""; applicationView.addDialogVisible = true } }
                    Button { text: "New Custom Rule"; onClicked: { applicationView.newRuleKind = "custom"; applicationView.newApplicationId = ""; applicationView.addDialogVisible = true } }
                    Button { text: "Delete Rule"; enabled: applicationView.selectedRule >= 0; onClicked: applicationView.deleteConfirmVisible = true }
                }

                Rectangle {
                    visible: applicationView.selectedRule >= 0
                    width: parent.width
                    height: editorColumn.height + 24
                    color: Qt.alpha(surfaceColor(), 0.72)
                    radius: 10
                    border.color: themeData.colors.border || "#3d4355"
                    border.width: 1
                    Column {
                        id: editorColumn
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12; spacing: 9
                        property var rule: applicationView.selected()
                        property bool classReady: Boolean(editorColumn.rule.application && settingsData.knownClasses(editorColumn.rule.application).length > 0)
                        Text { text: applicationView.appName(editorColumn.rule.application); color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 12; font.bold: true }
                        Row {
                            spacing: 8
                            Text { text: "Rule name"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; width: 90; anchors.verticalCenter: parent.verticalCenter }
                            TextField { width: 280; text: editorColumn.rule.name || ""; onEditingFinished: settingsData.setApplicationRule(applicationView.selectedRule, "name", text) }
                            Text { text: "Priority"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                            SpinBox { from: 0; to: 9999; value: editorColumn.rule.priority || 100; onValueModified: settingsData.setApplicationRule(applicationView.selectedRule, "priority", value) }
                            Button { text: "Done"; onClicked: applicationView.selectedRule = -1 }
                        }
                        Text { visible: editorColumn.rule.kind === "custom"; text: "Custom Lua source"; color: accentColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true }
                        TextArea { visible: editorColumn.rule.kind === "custom"; width: parent.width; height: 170; text: editorColumn.rule.custom_source || "hl.window_rule({})"; wrapMode: TextEdit.Wrap; onEditingFinished: settingsData.setApplicationRule(applicationView.selectedRule, "custom_source", text) }
                        Column {
                            visible: editorColumn.rule.kind !== "custom"
                            spacing: 8
                            Text {
                                visible: editorColumn.rule.match_type === "class"
                                text: editorColumn.classReady
                                    ? "Class already exists: " + settingsData.knownClasses(editorColumn.rule.application).join(", ") + ". Launch the application to choose a different window or class alias."
                                    : "Launch the application to identify its window class before editing this class rule."
                                color: editorColumn.classReady ? accentColor() : (themeData.colors.warning || "#e0af68")
                                font.family: "JetBrains Mono"
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                            Row {
                                spacing: 8
                                Text { text: "Match type"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; width: 90; anchors.verticalCenter: parent.verticalCenter }
                                ComboBox { width: 160; model: ["class", "title", "xwayland", "floating", "fullscreen", "pin", "workspace"]; currentIndex: applicationView.indexOf(editorColumn.rule.match_type, model); onActivated: settingsData.setApplicationRule(applicationView.selectedRule, "match_type", currentText) }
                                TextField { enabled: editorColumn.rule.match_type !== "class" || editorColumn.classReady; width: 360; text: editorColumn.rule.match_value || (editorColumn.classReady ? settingsData.classPattern(settingsData.knownClasses(editorColumn.rule.application)[0]) : ""); placeholderText: "match value or regex"; onEditingFinished: { settingsData.setApplicationRule(applicationView.selectedRule, "match_value", text); if (editorColumn.rule.match_type === "title") settingsData.setApplicationRule(applicationView.selectedRule, "match_pattern", applicationView.titlePattern(editorColumn.rule.match_mode, text)) } }
                            }
                            Row {
                                visible: editorColumn.rule.match_type === "title"
                                spacing: 8
                                Text { text: "Title helper"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; width: 90; anchors.verticalCenter: parent.verticalCenter }
                                ComboBox { enabled: editorColumn.rule.match_type !== "class" || editorColumn.classReady; width: 150; model: ["regex", "exact", "contains", "starts", "ends"]; currentIndex: applicationView.indexOf(editorColumn.rule.match_mode, model); onActivated: { settingsData.setApplicationRule(applicationView.selectedRule, "match_mode", currentText); settingsData.setApplicationRule(applicationView.selectedRule, "match_pattern", applicationView.titlePattern(currentText, editorColumn.rule.match_value)) } }
                                Text { text: "Generated regex: " + (editorColumn.rule.match_pattern || ""); color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 9; elide: Text.ElideRight; width: 300 }
                            }
                            Row {
                                spacing: 8
                                Text { text: "Behavior"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; width: 90; anchors.verticalCenter: parent.verticalCenter }
                                ComboBox { enabled: editorColumn.rule.match_type !== "class" || editorColumn.classReady; width: 150; model: ["(inherit)", "floating", "tiled"]; currentIndex: editorColumn.rule.floating === null || editorColumn.rule.floating === undefined ? 0 : (editorColumn.rule.floating ? 1 : 2); onActivated: settingsData.setApplicationRule(applicationView.selectedRule, "floating", currentIndex === 0 ? null : currentIndex === 1) }
                                ComboBox { enabled: editorColumn.rule.match_type !== "class" || editorColumn.classReady; width: 170; model: ["(inherit)", "dedicated workspace", "existing workspace"]; currentIndex: applicationView.indexOf(editorColumn.rule.workspace_policy, ["", "dedicated", "inherit"]); onActivated: settingsData.setApplicationRule(applicationView.selectedRule, "workspace_policy", ["", "dedicated", "inherit"][currentIndex]) }
                            }
                            Row {
                                spacing: 10
                                CheckBox { enabled: editorColumn.rule.match_type !== "class" || editorColumn.classReady; text: "No animation"; checked: editorColumn.rule.no_anim === true; onToggled: settingsData.setApplicationRule(applicationView.selectedRule, "no_anim", checked) }
                                CheckBox { enabled: editorColumn.rule.match_type !== "class" || editorColumn.classReady; text: "No blur"; checked: editorColumn.rule.no_blur === true; onToggled: settingsData.setApplicationRule(applicationView.selectedRule, "no_blur", checked) }
                                CheckBox { enabled: editorColumn.rule.match_type !== "class" || editorColumn.classReady; text: "No shadow"; checked: editorColumn.rule.no_shadow === true; onToggled: settingsData.setApplicationRule(applicationView.selectedRule, "no_shadow", checked) }
                                CheckBox { enabled: editorColumn.rule.match_type !== "class" || editorColumn.classReady; text: "Center"; checked: editorColumn.rule.center === true; onToggled: settingsData.setApplicationRule(applicationView.selectedRule, "center", checked) }
                            }
                            Row {
                                spacing: 8
                                Button { text: editorColumn.classReady ? "Choose another window/class" : "Launch app to match"; onClicked: settingsData.beginApplicationMatch(editorColumn.rule.application, applicationView.selectedRule) }
                                TextField { id: manualClassField; width: 260; placeholderText: "manually add class alias" }
                                Button { text: "Add class"; onClicked: { settingsData.addApplicationClass(editorColumn.rule.application, manualClassField.text, "confirmed"); if (editorColumn.rule.match_type === "class") settingsData.setApplicationRule(applicationView.selectedRule, "match_value", settingsData.classPattern(manualClassField.text)); manualClassField.clear() } }
                            }
                        }
                    }
                }
                }
            }

            Rectangle {
                visible: applicationView.addDialogVisible
                anchors.fill: applicationView
                z: 100
                color: Qt.alpha("#000000", 0.65)
                MouseArea { anchors.fill: parent }
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 20
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width - 32, 620)
                    height: Math.min(parent.height - 40, 390)
                    radius: 12
                    color: surfaceColor()
                    border.color: accentColor()
                    border.width: 1
                    Column {
                        anchors.fill: parent; anchors.margins: 20; spacing: 14
                        Text { text: applicationView.newRuleKind === "custom" ? "New custom rule" : "New simple rule"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 14; font.bold: true }
                        Text { text: "Select an installed desktop application."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }
                        GridView {
                            id: newApplicationSelect
                            width: parent.width
                            height: 220
                            clip: true
                            cellWidth: width / 2
                            cellHeight: 44
                            model: applicationView.installedApplications()
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOn }
                            delegate: Rectangle {
                                required property var modelData
                                width: newApplicationSelect.cellWidth - 4
                                height: newApplicationSelect.cellHeight - 4
                                color: modelData.id === applicationView.newApplicationId ? selectedColor() : Qt.alpha(surfaceColor(), 0.55)
                                border.color: modelData.id === applicationView.newApplicationId ? accentColor() : (themeData.colors.border || "#3d4355")
                                border.width: 1
                                radius: 5
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name + "  [" + modelData.id + "]"
                                    color: textColor()
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    width: parent.width - 20
                                }
                                MouseArea { anchors.fill: parent; onClicked: applicationView.newApplicationId = modelData.id }
                            }
                        }
                        Row {
                            spacing: 10
                            Button { text: "Cancel"; onClicked: applicationView.addDialogVisible = false }
                            Button { text: "Create"; enabled: applicationView.newApplicationId !== ""; onClicked: applicationView.createRule() }
                        }
                    }
                }
            }

            Rectangle {
                visible: settingsData.matchDialogVisible
                anchors.fill: applicationView
                z: 100
                color: Qt.alpha("#000000", 0.7)
                MouseArea { anchors.fill: parent }
                Rectangle {
                    anchors.centerIn: parent; width: 560; height: Math.min(parent.height - 40, 430); radius: 12; color: surfaceColor(); border.color: accentColor(); border.width: 1
                    Column {
                        anchors.fill: parent; anchors.margins: 20; spacing: 12
                        Text { text: "Match application window"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 14; font.bold: true }
                        Text { text: "Select the window created or found for " + applicationView.appName(settingsData.matchApplication) + "."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
                        Repeater { model: settingsData.matchCandidates; delegate: Button { required property var modelData; text: modelData.class + "  |  " + (modelData.title || "(untitled)"); width: parent.width; onClicked: settingsData.selectApplicationMatch(modelData) } }
                        Text { visible: settingsData.matchError !== ""; text: settingsData.matchError; color: themeData.colors.error || "#f7768e"; font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
                        Text { visible: settingsData.matchCandidates.length === 0 && settingsData.matchError === ""; text: "Waiting for a new window..."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }
                        Button { text: "Cancel"; onClicked: settingsData.cancelApplicationMatch() }
                    }
                }
            }

            Rectangle {
                visible: applicationView.deleteConfirmVisible
                anchors.fill: applicationView
                z: 100
                color: Qt.alpha("#000000", 0.7)
                MouseArea { anchors.fill: parent }
                Rectangle {
                    anchors.centerIn: parent; width: 430; height: 190; radius: 12; color: surfaceColor(); border.color: themeData.colors.warning || "#e0af68"; border.width: 2
                    Column {
                        anchors.fill: parent; anchors.margins: 22; spacing: 14
                        Text { text: "Delete rule?"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 15; font.bold: true }
                        Text { text: "This removes the staged rule. The application's identity aliases will be kept."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
                        Row {
                            spacing: 10
                            Button { text: "Keep Rule"; onClicked: applicationView.deleteConfirmVisible = false }
                            Button { text: "Delete Rule"; onClicked: applicationView.deleteSelected() }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: audioPage
        Column {
            spacing: 14
            Text { text: "Default output"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
            Slider {
                width: Math.min(parent.width, 520)
                from: 0
                to: 1.5
                value: settingsData.draft.system && settingsData.draft.system.audio ? settingsData.draft.system.audio.volume : 1
                onMoved: settingsData.setAudioVolume(value)
            }
            Text { text: Math.round((settingsData.draft.system && settingsData.draft.system.audio ? settingsData.draft.system.audio.volume : 1) * 100) + "%"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 11 }
            CheckBox {
                text: "Mute default output"
                checked: Boolean(settingsData.draft.system && settingsData.draft.system.audio && settingsData.draft.system.audio.muted)
                onToggled: settingsData.setAudioMuted(checked)
            }
            Text { text: settingsData.capabilities.wpctl ? "Changes use PipeWire through wpctl and are applied when you press Apply." : "wpctl is not available in this session."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
        }
    }

    Component {
        id: networkPage
        Column {
            spacing: 14
            Text { text: "Network connection"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
            ComboBox {
                width: Math.min(parent.width, 520)
                model: settingsData.draft.system && settingsData.draft.system.network ? settingsData.draft.system.network.connections.map(function(item) { return item.name }) : []
                onActivated: settingsData.setNetworkConnection(currentText)
            }
            Text { text: settingsData.capabilities.nmcli ? "Selecting a connection and pressing Apply activates it through NetworkManager." : "nmcli is not available in this session."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
        }
    }

    Component {
        id: bluetoothPage
        Column {
            spacing: 14
            Text { text: "Bluetooth device"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
            ComboBox {
                id: bluetoothDevice
                width: Math.min(parent.width, 520)
                model: settingsData.draft.system && settingsData.draft.system.bluetooth ? settingsData.draft.system.bluetooth.devices.map(function(item) { return item.name }) : []
            }
            CheckBox {
                text: "Connect selected device"
                enabled: bluetoothDevice.count > 0
                onToggled: {
                    var device = settingsData.draft.system.bluetooth.devices[bluetoothDevice.currentIndex]
                    if (device) settingsData.setBluetoothDevice(device.address, checked)
                }
            }
            Text { text: settingsData.capabilities.bluetoothctl ? "Bluetooth changes are applied through bluetoothctl." : "bluetoothctl is not available in this session."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
        }
    }

    Component {
        id: powerPage
        Column {
            spacing: 14
            Text { text: "Power profile"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
            ComboBox {
                width: Math.min(parent.width, 360)
                model: settingsData.draft.system && settingsData.draft.system.power ? settingsData.draft.system.power.profiles : []
                onActivated: settingsData.setPowerProfile(currentText)
            }
            Text { text: settingsData.capabilities.powerprofilesctl ? "The selected profile is applied through power-profiles-daemon." : "powerprofilesctl is not installed; other power controls are not yet available."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
        }
    }

    Component {
        id: diagnosticsPage
        Flickable {
            contentWidth: width
            contentHeight: diagnosticsColumn.height
            clip: true
            Column {
                id: diagnosticsColumn
                width: moduleLoader.width
                spacing: 12
                Text { text: "Orbit status"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
                Text { text: "Monitors: " + settingsData.monitors.length; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 11 }
                Repeater {
                    model: settingsData.monitors
                    delegate: Text {
                        required property var modelData
                        text: (modelData.focused ? "* " : "  ") + (modelData.name || "unknown") + "  " + (modelData.description || modelData.model || "")
                        color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; elide: Text.ElideRight; width: diagnosticsColumn.width
                    }
                }
                Text { text: "System backends"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true; topPadding: 10 }
                Repeater {
                    model: Object.keys(settingsData.capabilities)
                    delegate: Text {
                        required property string modelData
                        text: modelData + ": " + (settingsData.capabilities[modelData] ? "available" : "not found")
                        color: settingsData.capabilities[modelData] ? (themeData.colors.success || "#9ece6a") : mutedColor()
                        font.family: "JetBrains Mono"; font.pixelSize: 10
                    }
                }
            }
        }
    }

    Component {
        id: unavailablePage
        Column {
            spacing: 12
            Text { text: "Module ready for integration"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
            Text { text: "This category is registered and visible, but its backend adapter has not been connected yet."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; wrapMode: Text.WordWrap; width: parent.width }
        }
    }

    Rectangle {
        anchors.fill: parent
        z: 100
        visible: settingsData.applyConfirmationVisible
        color: Qt.alpha("#000000", 0.62)

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Rectangle {
            anchors.centerIn: parent
            width: 430
            height: 230
            radius: 12
            color: themeData.colors.window_background || "#1a1b26"
            border.color: themeData.colors.warning || themeData.colors.accent || "#7aa2f7"
            border.width: 2

            Column {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 14

                Text { text: "Confirm display changes"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 15; font.bold: true }
                Text { text: "Applying monitor settings may temporarily move, disable, or reconfigure your displays."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
                Text { text: "Confirm within " + settingsData.applyCountdown + " seconds"; color: themeData.colors.warning || "#e0af68"; font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
                Row {
                    spacing: 10
                    Button { text: "Cancel"; onClicked: settingsData.cancelApply() }
                    Button { text: "Confirm Apply"; onClicked: settingsData.confirmApply() }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        z: 110
        visible: settingsData.unsavedConfirmationVisible
        color: Qt.alpha("#000000", 0.7)
        MouseArea { anchors.fill: parent }
        Rectangle {
            anchors.centerIn: parent
            width: 430
            height: 190
            radius: 12
            color: themeData.colors.window_background || "#1a1b26"
            border.color: themeData.colors.warning || "#e0af68"
            border.width: 2
            Column {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14
                Text { text: "Unsaved changes"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 15; font.bold: true }
                Text { text: "Your changes have not been saved. Discard them?"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
                Row {
                    spacing: 10
                    Button { text: "Keep Editing"; onClicked: settingsData.cancelClose() }
                    Button { text: "Discard Changes"; onClicked: settingsData.discardAndClose() }
                }
            }
        }
    }
}
