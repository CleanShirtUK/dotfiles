import Quickshell
import QtQuick
import QtQuick.Window
import QtQuick.Controls as Controls
import "components" as Orbit

Window {
    id: root

    required property var settingsData
    required property var themeData
    required property var monitorData

    title: "Orbit Settings"
    width: 1120
    height: 720
    visible: settingsData.settingsVisible
    property string selectedPalette: settingsData.draft.theme ? settingsData.draft.theme.palette : "tokyo-night"
    property var previewColors: settingsData.palettePreviews[selectedPalette] || themeData.colors
    property var previewAppearance: settingsData.draft.appearance || ({})
    property var previewStyle: previewAppearance.style || ({ corner_radius: 10 })
    property var previewTransparency: previewAppearance.transparency || ({ shell_opacity: 1.0 })
    color: previewColor("window_background", "#1a1b26")
    flags: Qt.Window

    onVisibleChanged: if (visible) Qt.callLater(function() {
        requestActivate()
        settingsFocus.forceActiveFocus()
    })

    onClosing: function(event) {
        event.accepted = false
        settingsData.requestClose()
    }

    function previewColor(key, fallback) { return previewColors[key] || themeData.colors[key] || fallback }
    function textColor() { return previewColor("text", "#c0caf5") }
    function mutedColor() { return previewColor("text_muted", "#9aa5ce") }
    function surfaceColor() { return previewColor("surface", "#24283b") }
    function selectedColor() { return previewColor("surface_selected", "#333954") }
    function accentColor() { return previewColor("accent", "#7aa2f7") }
    function pageDescription(id) {
        var descriptions = {
            appearance: "Choose how Orbit and connected applications look.",
            shell: "Configure launcher and shell behavior.",
            wallpaper: "Manage the wallpaper source and appearance integration.",
            displays: "Arrange monitors and assign Home and Gaming roles.",
            audio: "Choose devices and adjust output and input levels.",
            network: "Manage NetworkManager connections and Wi-Fi profiles.",
            bluetooth: "Pair, connect, and manage Bluetooth devices.",
            applications: "Control window placement, workspaces, and application rules.",
            power: "Configure performance profiles and idle behavior.",
            diagnostics: "Inspect Orbit capabilities and recover the shell."
        }
        return descriptions[id] || "Configure Orbit and the desktop session."
    }

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
            color: Qt.alpha(previewColor("window_background", "#1a1b26"), Number(previewTransparency.shell_opacity))
            border.color: previewColor("border", "#3d4355")
            border.width: 1
            radius: Number(root.previewStyle.corner_radius) + 4

            Row {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 18

                Rectangle {
                    width: 252
                    height: parent.height
                    color: Qt.alpha(surfaceColor(), 0.54)
                    radius: 14

                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Text {
                            text: "Settings"
                            color: accentColor()
                            font.family: themeData.uiFont
                            font.pixelSize: 20
                            font.bold: true
                        }

                        Text {
                            text: "Shell and system control"
                            color: mutedColor()
                            font.family: themeData.uiFont
                            font.pixelSize: 11
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
                                property bool showGroup: Boolean(modelData.group) && (index === 0 || menuList.model[index - 1].group !== modelData.group)
                                width: menuList.width
                                height: 42 + (showGroup ? 27 : 0)
                                color: "transparent"

                                Text {
                                    visible: showGroup
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.top: parent.top
                                    height: 25
                                    text: modelData.group
                                    color: mutedColor()
                                    font.family: themeData.uiFont
                                    font.pixelSize: 10
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Rectangle {
                                    y: showGroup ? 27 : 0
                                    width: parent.width
                                    height: 42
                                    radius: 10
                                    color: index === menuList.currentIndex ? Qt.alpha(accentColor(), 0.18) : "transparent"

                                    OrbitIcon {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 20
                                        height: 20
                                        iconName: modelData.icon || ""
                                        iconSize: 32
                                        opacity: index === menuList.currentIndex ? 1 : 0.72
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 42
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label || modelData.id
                                        color: index === menuList.currentIndex ? textColor() : mutedColor()
                                        font.family: themeData.uiFont
                                        font.pixelSize: 12
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
                }

                Column {
                    width: parent.width - 256
                    height: parent.height
                    spacing: 12

                    Row {
                        width: parent.width
                        height: 54
                        spacing: 12

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text {
                                text: settingsData.menu.length > menuList.currentIndex ? (settingsData.menu[menuList.currentIndex].label || "Settings") : "Settings"
                                color: textColor()
                                font.family: themeData.uiFont
                                font.pixelSize: 20
                                font.bold: true
                            }
                            Text {
                                text: settingsData.menu.length > menuList.currentIndex ? root.pageDescription(settingsData.menu[menuList.currentIndex].id) : "Configure Orbit and the desktop session."
                                color: mutedColor()
                                font.family: themeData.uiFont
                                font.pixelSize: 11
                            }
                        }

                        Item { width: parent.width - 170; height: 1 }

                        Orbit.OrbitIconButton {
                            themeData: root.themeData
                            iconSource: Quickshell.iconPath("window-close-symbolic")
                            accessibleLabel: "Close settings"
                            onClicked: settingsData.requestClose()
                        }
                    }

                    Loader {
                        id: moduleLoader
                        width: parent.width
                         height: parent.height - 116
                        sourceComponent: {
                            if (!settingsData.menu.length)
                                return diagnosticsPage
                            var id = settingsData.menu[menuList.currentIndex].id
                            if (id === "appearance") return appearancePage
                            if (id === "shell") return shellPage
                            if (id === "wallpaper") return wallpaperPage
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

                        Orbit.OrbitButton {
                            themeData: root.themeData
                            text: "Cancel"
                            subtle: true
                            enabled: settingsData.dirty
                            onClicked: settingsData.cancel()
                        }
                        Orbit.OrbitButton {
                            themeData: root.themeData
                            text: "Apply"
                            highlighted: true
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
        Item {
            id: appearanceRoot
            property string section: "colours"
            property var appearance: settingsData.draft.appearance || ({})
            property var style: appearance.style || ({ button_shape: "rounded", corner_radius: 10 })
            property var transparency: appearance.transparency || ({ active_opacity: 1.0, inactive_opacity: 0.9, shell_opacity: 1.0 })
            property var effects: appearance.effects || ({})
            property var animations: effects.animations || ({})
            property bool customPaletteVisible: false

            Row {
                anchors.fill: parent
                spacing: 14

                Column {
                    width: 150
                    spacing: 5
                    Repeater {
                        model: [
                            ["colours", "Colours"],
                            ["styles", "Styles"],
                            ["transparency", "Transparency"],
                            ["effects", "Effects"]
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: 150
                            height: 34
                            radius: 7
                            color: appearanceRoot.section === modelData[0] ? selectedColor() : "transparent"
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData[1]
                                color: appearanceRoot.section === modelData[0] ? textColor() : mutedColor()
                                font.family: "JetBrains Mono"
                                font.pixelSize: 10
                            }
                            MouseArea { anchors.fill: parent; onClicked: appearanceRoot.section = modelData[0] }
                        }
                    }
                }

                Loader {
                    width: parent.width - 164
                    height: parent.height
                    sourceComponent: appearanceRoot.section === "colours" ? coloursSection
                        : appearanceRoot.section === "styles" ? stylesSection
                        : appearanceRoot.section === "transparency" ? transparencySection
                        : effectsSection
                }
            }
        }
    }

    Component {
        id: coloursSection
        Flickable {
            id: coloursSectionRoot
            contentWidth: width
            contentHeight: coloursColumn.height
            clip: true
            property bool customPaletteVisible: false
            Column {
                id: coloursColumn
                width: parent.width
                spacing: 12
                Text { text: "Colours"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
                Text { text: "Select a shared palette for Orbit, Hyprland, and connected toolkits."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
                Flow {
                    width: parent.width
                    spacing: 10
                    add: Transition { NumberAnimation { properties: "x,y"; duration: 140; easing.type: Easing.OutCubic } }
                    Repeater {
                        model: settingsData.palettes
                        delegate: Rectangle {
                            required property string modelData
                            width: Math.min(184, (coloursSectionRoot.width - 10) / 2)
                            height: 92
                            radius: 12
                            color: modelData === root.selectedPalette ? Qt.alpha(accentColor(), 0.16) : Qt.alpha(surfaceColor(), 0.58)
                            border.width: modelData === root.selectedPalette ? 2 : 1
                            border.color: modelData === root.selectedPalette ? accentColor() : (themeData.colors.border || "#3d4355")
                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8
                                Row {
                                    width: parent.width
                                    Text { width: parent.width - 24; text: modelData; color: textColor(); font.family: themeData.uiFont; font.pixelSize: 12; font.bold: modelData === root.selectedPalette; elide: Text.ElideRight }
                                    Text { text: modelData === root.selectedPalette ? "✓" : ""; color: accentColor(); font.family: themeData.uiFont; font.pixelSize: 14; font.bold: true }
                                }
                                Row {
                                    width: parent.width
                                    spacing: 2
                                    Repeater {
                                        model: ["background", "surface", "accent", "text"]
                                        delegate: Rectangle {
                                            required property string modelData
                                            width: (parent.parent.width - 6) / 4
                                            height: 34
                                            radius: 6
                                            color: (settingsData.palettePreviews[parent.parent.parent.modelData] || {})[modelData] || "#24283b"
                                            border.color: Qt.alpha(textColor(), 0.2)
                                            border.width: 1
                                        }
                                    }
                                }
                            }
                            MouseArea { anchors.fill: parent; onClicked: settingsData.setThemePalette(modelData) }
                        }
                    }
                }
                Rectangle { width: parent.width; height: 1; color: themeData.colors.border || "#3d4355" }
                Text { text: "Wallpaper-derived palette"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                Button {
                    text: settingsData.wallpaper.mode === "shader" ? "Unavailable while shader wallpaper is active" : "Derive palette from wallpaper"
                    enabled: settingsData.wallpaper.mode !== "shader"
                }
                Text { text: settingsData.wallpaper.mode === "shader" ? "The current PS3 shader has no source image to sample." : "The wallpaper backend can provide a source for palette derivation."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
                Text { text: "Custom palette"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                Button { text: coloursSectionRoot.customPaletteVisible ? "Hide custom palette editor" : "Create custom palette"; onClicked: coloursSectionRoot.customPaletteVisible = !coloursSectionRoot.customPaletteVisible }
                Column {
                    visible: coloursSectionRoot.customPaletteVisible
                    spacing: 8
                    property string customName: "orbit-custom"
                    property string customLabel: "Orbit Custom"
                    property string background: themeData.colors.window_background || "#1a1b26"
                    property string surface: themeData.colors.surface || "#24283b"
                    property string accent: themeData.colors.accent || "#7aa2f7"
                    property string textValue: themeData.colors.text || "#c0caf5"
                    TextField { width: 300; placeholderText: "Palette id (lowercase-dashes)"; text: parent.customName; onTextChanged: parent.customName = text }
                    TextField { width: 300; placeholderText: "Palette display name"; text: parent.customLabel; onTextChanged: parent.customLabel = text }
                    Row {
                        spacing: 8
                        Text { text: "Background"; color: mutedColor(); width: 80; anchors.verticalCenter: parent.verticalCenter }
                        TextField { width: 180; text: parent.parent.background; onTextChanged: parent.parent.background = text }
                    }
                    Row {
                        spacing: 8
                        Text { text: "Surface"; color: mutedColor(); width: 80; anchors.verticalCenter: parent.verticalCenter }
                        TextField { width: 180; text: parent.parent.surface; onTextChanged: parent.parent.surface = text }
                    }
                    Row {
                        spacing: 8
                        Text { text: "Accent"; color: mutedColor(); width: 80; anchors.verticalCenter: parent.verticalCenter }
                        TextField { width: 180; text: parent.parent.accent; onTextChanged: parent.parent.accent = text }
                    }
                    Row {
                        spacing: 8
                        Text { text: "Text"; color: mutedColor(); width: 80; anchors.verticalCenter: parent.verticalCenter }
                        TextField { width: 180; text: parent.parent.textValue; onTextChanged: parent.parent.textValue = text }
                    }
                    Button { text: "Stage custom palette"; onClicked: settingsData.setCustomPalette(parent.customName, parent.customLabel, { background: parent.background, surface: parent.surface, accent: parent.accent, text: parent.textValue }) }
                }
                Text { text: "Custom palettes use the same validated TOML schema as the built-in palettes."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
            }
        }
    }

    Component {
        id: stylesSection
        Flickable {
            id: stylesSectionRoot
            contentWidth: width
            contentHeight: stylesColumn.height
            clip: true
            property var style: (settingsData.draft.appearance && settingsData.draft.appearance.style) || ({ button_shape: "rounded", corner_radius: 10 })
            Column {
                id: stylesColumn
                width: parent.width
                spacing: 14
                Text { text: "Styles"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
                Text { text: "These values are shared where GTK, Qt, QuickShell, and Hyprland expose equivalent controls."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
                Row {
                    spacing: 12
                    Text { text: "Button shape"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; width: 130; anchors.verticalCenter: parent.verticalCenter }
                    ComboBox { model: ["rounded", "square", "pill"]; currentIndex: model.indexOf(stylesSectionRoot.style.button_shape); onActivated: settingsData.setAppearanceValue("style", "button_shape", currentText) }
                }
                Row {
                    spacing: 12
                    Text { text: "Corner roundness"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; width: 130; anchors.verticalCenter: parent.verticalCenter }
                    Slider { from: 0; to: 32; stepSize: 1; value: stylesSectionRoot.style.corner_radius; onMoved: settingsData.setAppearanceValue("style", "corner_radius", Math.round(value)) }
                    Text { text: Math.round(stylesSectionRoot.style.corner_radius) + " px"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }

    Component {
        id: transparencySection
        Flickable {
            id: transparencySectionRoot
            contentWidth: width
            contentHeight: transparencyColumn.height
            clip: true
            property var transparency: (settingsData.draft.appearance && settingsData.draft.appearance.transparency) || ({ active_opacity: 1.0, inactive_opacity: 0.9, shell_opacity: 1.0 })
            Column {
                id: transparencyColumn
                width: parent.width
                spacing: 14
                Text { text: "Transparency"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
                Text { text: "Standard Hyprland opacity is separate from Hyprglass. Lower values reveal the wallpaper without enabling a blur effect."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
                Repeater {
                    model: [["Active window", "active_opacity"], ["Inactive window", "inactive_opacity"], ["Orbit shell", "shell_opacity"]]
                    delegate: Row {
                        required property var modelData
                        width: transparencyColumn.width
                        spacing: 12
                        Text { text: modelData[0]; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; width: 130; anchors.verticalCenter: parent.verticalCenter }
                        Slider { from: 0; to: 1; stepSize: 0.05; value: transparencySectionRoot.transparency[modelData[1]]; onMoved: settingsData.setAppearanceValue("transparency", modelData[1], Math.round(value * 100) / 100) }
                        Text { text: Math.round(transparencySectionRoot.transparency[modelData[1]] * 100) + "%"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }
    }

    Component {
        id: effectsSection
        Flickable {
            id: effectsSectionRoot
            contentWidth: width
            contentHeight: effectsColumn.height
            clip: true
            property var effects: (settingsData.draft.appearance && settingsData.draft.appearance.effects) || ({})
            property var animations: effects.animations || ({})
            property var animationTypeLabels: ["Default", "Fade", "Slide", "Pop-in", "Slide + fade", "Vertical slide + fade"]
            property var animationTypeValues: ["default", "fade", "slide", "popin", "slidefade", "slidefadevert"]
            Column {
                id: effectsColumn
                width: parent.width
                spacing: 12
                Text { text: "Effects"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
                CheckBox { text: "Enable Hyprglass"; checked: effectsSectionRoot.effects.hyprglass_enabled !== false; onToggled: settingsData.setAppearanceValue("effects", "hyprglass_enabled", checked) }
                Row {
                    spacing: 12
                    Text { text: "Blur type"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; width: 130; anchors.verticalCenter: parent.verticalCenter }
                    ComboBox { model: ["glass", "soft", "clear"]; currentIndex: model.indexOf(effectsSectionRoot.effects.hyprglass_blur_type || "glass"); onActivated: settingsData.setAppearanceValue("effects", "hyprglass_blur_type", currentText) }
                }
                CheckBox { text: "Enable HyprWindowShade shader"; checked: effectsSectionRoot.effects.hyprwindowshade_enabled !== false; onToggled: settingsData.setAppearanceValue("effects", "hyprwindowshade_enabled", checked) }
                Rectangle { width: parent.width; height: 1; color: themeData.colors.border || "#3d4355" }
                CheckBox { text: "Enable animations"; checked: effectsSectionRoot.effects.animations_enabled !== false; onToggled: settingsData.setAppearanceValue("effects", "animations_enabled", checked) }
                Text { text: "Animation groups"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                Text { text: "Speed controls how quickly the animation completes. Higher values are faster."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
                Repeater {
                    model: [["global", "Global and borders"], ["windows", "Windows"], ["fades", "Window fades"], ["layers", "Layers"], ["workspaces", "Workspaces"], ["movement", "Movement and zoom"]]
                    delegate: Row {
                        required property var modelData
                        width: effectsColumn.width
                        spacing: 8
                        CheckBox { checked: effectsSectionRoot.animations[modelData[0]] ? effectsSectionRoot.animations[modelData[0]].enabled !== false : true; onToggled: settingsData.setAnimationValue(modelData[0], "enabled", checked) }
                        Text { text: modelData[1]; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; width: 130; anchors.verticalCenter: parent.verticalCenter }
                        ComboBox {
                            width: 128
                            model: effectsSectionRoot.animationTypeLabels
                            currentIndex: Math.max(0, effectsSectionRoot.animationTypeValues.indexOf(effectsSectionRoot.animations[modelData[0]] ? effectsSectionRoot.animations[modelData[0]].type : "default"))
                            onActivated: settingsData.setAnimationValue(modelData[0], "type", effectsSectionRoot.animationTypeValues[index])
                        }
                        Slider { width: 150; from: 0.5; to: 12; stepSize: 0.1; value: effectsSectionRoot.animations[modelData[0]] ? effectsSectionRoot.animations[modelData[0]].speed : 1; onMoved: settingsData.setAnimationValue(modelData[0], "speed", Math.round(value * 100) / 100) }
                        Text { text: "Speed " + (effectsSectionRoot.animations[modelData[0]] ? Number(effectsSectionRoot.animations[modelData[0]].speed).toFixed(2) : "1.00"); color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
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
        id: wallpaperPage
        Flickable {
            contentWidth: width
            contentHeight: wallpaperColumn.height
            clip: true

            Column {
                id: wallpaperColumn
                width: parent.width
                spacing: 14

                Text { text: "Wallpaper"; color: textColor(); font.family: themeData.uiFont; font.pixelSize: 14; font.bold: true }
                Text {
                    text: "Orbit reads the active wallpaper mode so appearance features can integrate safely with it."
                    color: mutedColor()
                    font.family: themeData.uiFont
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Rectangle {
                    width: parent.width
                    height: wallpaperStatus.height + 28
                    color: Qt.alpha(surfaceColor(), 0.62)
                    radius: 12
                    border.color: themeData.colors.border || "#3d4355"
                    border.width: 1
                    Column {
                        id: wallpaperStatus
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 6
                        Text { text: "Current wallpaper source"; color: accentColor(); font.family: themeData.uiFont; font.pixelSize: 12; font.bold: true }
                        Text { text: settingsData.wallpaper.mode === "shader" ? "PS3 wave shader" : String(settingsData.wallpaper.mode || "Unknown"); color: textColor(); font.family: themeData.uiFont; font.pixelSize: 13 }
                        Text { text: settingsData.wallpaper.mode === "shader" ? "Shader wallpaper does not expose a source image for palette sampling." : "The wallpaper backend can provide a source image for palette integration."; color: mutedColor(); font.family: themeData.uiFont; font.pixelSize: 11; wrapMode: Text.WordWrap; width: parent.width }
                        Row {
                            spacing: 10
                            Text { text: "Service: " + settingsData.wallpaperServiceStatus; color: settingsData.wallpaperServiceStatus === "active" ? (themeData.colors.success || "#9ece6a") : (themeData.colors.warning || "#e0af68"); font.family: themeData.uiFont; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                            Orbit.OrbitButton {
                                themeData: root.themeData
                                compact: true
                                text: settingsData.wallpaperServiceStatus === "active" ? "Restart service" : "Start service"
                                highlighted: settingsData.wallpaperServiceStatus !== "active"
                                onClicked: settingsData.restartWallpaperService()
                            }
                        }
                    }
                }

                Text { text: "Wallpaper controls are not connected yet."; color: mutedColor(); font.family: themeData.uiFont; font.pixelSize: 11 }
            }
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
        Flickable {
            contentWidth: width
            contentHeight: audioColumn.height
            clip: true
            Column {
                id: audioColumn
                width: parent.width
                spacing: 16
                property var audio: settingsData.draft.system && settingsData.draft.system.audio ? settingsData.draft.system.audio : ({})
                Text { text: "Choose where sound plays and which microphone applications use. Changes apply immediately."; color: mutedColor(); font.family: themeData.uiFont; font.pixelSize: 11; wrapMode: Text.WordWrap; width: parent.width }
                Text { visible: settingsData.systemActionStatus !== ""; text: settingsData.systemActionStatus; color: themeData.colors.warning || "#e0af68"; font.family: themeData.uiFont; font.pixelSize: 11 }

                Text { text: "Output"; color: textColor(); font.family: themeData.uiFont; font.pixelSize: 13; font.bold: true }
                Repeater {
                    model: audioColumn.audio.sinks || []
                    delegate: Rectangle {
                        required property var modelData
                        width: audioColumn.width
                        height: outputCardColumn.height + 24
                        color: modelData.default ? Qt.alpha(accentColor(), 0.12) : Qt.alpha(surfaceColor(), 0.55)
                        radius: 12
                        border.width: modelData.default ? 2 : 1
                        border.color: modelData.default ? accentColor() : (themeData.colors.border || "#3d4355")
                        Column {
                            id: outputCardColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 10
                            Row {
                                width: parent.width
                                spacing: 10
                                Image { width: 24; height: 24; source: Quickshell.iconPath("audio-speakers-symbolic"); sourceSize: Qt.size(24, 24); anchors.verticalCenter: parent.verticalCenter }
                                Column {
                                    width: parent.width - 136
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { text: modelData.name; color: textColor(); font.family: themeData.uiFont; font.pixelSize: 12; elide: Text.ElideRight; width: parent.width }
                                }
                                CheckBox {
                                    width: 100
                                    text: "Default"
                                    checked: modelData.default
                                    themeData: root.themeData
                                    onClicked: if (!modelData.default) settingsData.setDefaultAudioSink(modelData.id)
                                }
                            }
                            Row {
                                width: parent.width
                                spacing: 10
                                Text { text: "Volume"; width: 50; color: mutedColor(); font.family: themeData.uiFont; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                Slider { width: parent.width - 180; from: 0; to: 1.5; stepSize: 0.01; value: modelData.volume || 0; onMoved: settingsData.setAudioDeviceVolume(modelData.id, value, false) }
                                Text { text: Math.round((modelData.volume || 0) * 100) + "%"; width: 42; color: textColor(); font.family: themeData.uiFont; font.pixelSize: 11; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter }
                                Orbit.OrbitButton { width: 58; compact: true; themeData: root.themeData; text: modelData.muted ? "Unmute" : "Mute"; subtle: !modelData.muted; onClicked: settingsData.setAudioDeviceMuted(modelData.id, !modelData.muted, false) }
                            }
                        }
                    }
                }
                Text { visible: !(audioColumn.audio.sinks || []).length; text: "No output devices reported by PipeWire."; color: mutedColor(); font.family: themeData.uiFont; font.pixelSize: 11 }

                Text { text: "Input"; color: textColor(); font.family: themeData.uiFont; font.pixelSize: 13; font.bold: true }
                Repeater {
                    model: audioColumn.audio.sources || []
                    delegate: Rectangle {
                        required property var modelData
                        width: audioColumn.width
                        height: inputCardColumn.height + 24
                        color: modelData.default ? Qt.alpha(accentColor(), 0.12) : Qt.alpha(surfaceColor(), 0.55)
                        radius: 12
                        border.width: modelData.default ? 2 : 1
                        border.color: modelData.default ? accentColor() : (themeData.colors.border || "#3d4355")
                        Column {
                            id: inputCardColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 10
                            Row {
                                width: parent.width
                                spacing: 10
                                Image { width: 24; height: 24; source: Quickshell.iconPath("audio-input-microphone-symbolic"); sourceSize: Qt.size(24, 24); anchors.verticalCenter: parent.verticalCenter }
                                Column {
                                    width: parent.width - 136
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { text: modelData.name; color: textColor(); font.family: themeData.uiFont; font.pixelSize: 12; elide: Text.ElideRight; width: parent.width }
                                }
                                CheckBox {
                                    width: 100
                                    text: "Default"
                                    checked: modelData.default
                                    themeData: root.themeData
                                    onClicked: if (!modelData.default) settingsData.setDefaultAudioSource(modelData.id)
                                }
                            }
                            Row {
                                width: parent.width
                                spacing: 10
                                Text { text: "Volume"; width: 50; color: mutedColor(); font.family: themeData.uiFont; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                Slider { width: parent.width - 180; from: 0; to: 1.5; stepSize: 0.01; value: modelData.volume || 0; onMoved: settingsData.setAudioDeviceVolume(modelData.id, value, true) }
                                Text { text: Math.round((modelData.volume || 0) * 100) + "%"; width: 42; color: textColor(); font.family: themeData.uiFont; font.pixelSize: 11; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter }
                                Orbit.OrbitButton { width: 58; compact: true; themeData: root.themeData; text: modelData.muted ? "Unmute" : "Mute"; subtle: !modelData.muted; onClicked: settingsData.setAudioDeviceMuted(modelData.id, !modelData.muted, true) }
                            }
                        }
                    }
                }
                Text { visible: !(audioColumn.audio.sources || []).length; text: "No input devices reported by PipeWire."; color: mutedColor(); font.family: themeData.uiFont; font.pixelSize: 11 }

                Rectangle {
                    width: parent.width
                    height: streamsColumn.height + 24
                    color: Qt.alpha(surfaceColor(), 0.42)
                    radius: 12
                    border.color: themeData.colors.border || "#3d4355"
                    border.width: 1
                    Column {
                        id: streamsColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 8
                        Text { text: "Active streams"; color: textColor(); font.family: themeData.uiFont; font.pixelSize: 13; font.bold: true }
                        Text { text: "Applications currently sending or receiving audio."; color: mutedColor(); font.family: themeData.uiFont; font.pixelSize: 11 }
                        Repeater {
                            model: audioColumn.audio.streams || []
                            delegate: Row {
                                required property var modelData
                                width: streamsColumn.width
                                spacing: 8
                                Image { width: 18; height: 18; source: Quickshell.iconPath("multimedia-player-symbolic"); sourceSize: Qt.size(18, 18); anchors.verticalCenter: parent.verticalCenter }
                                Text { text: modelData.name; color: textColor(); font.family: themeData.uiFont; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width - 26; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                        Text { visible: !(audioColumn.audio.streams || []).length; text: "No active audio streams."; color: mutedColor(); font.family: themeData.uiFont; font.pixelSize: 11 }
                    }
                }
                Text { visible: !settingsData.capabilities.wpctl; text: "wpctl is not available in this session."; color: themeData.colors.warning || "#e0af68"; font.family: themeData.uiFont; font.pixelSize: 11 }
            }
        }
    }

    Component {
        id: networkPage
        Item {
            id: networkEditor
            property var network: settingsData.draft.system && settingsData.draft.system.network ? settingsData.draft.system.network : ({})
            property string selectedName: ""
            property string selectedTab: "general"
            property bool newDialogVisible: false
            property string newName: ""
            property string newSsid: ""
            property string newType: "wifi"
            property string wifiSearch: ""
            property string wifiPassword: ""
            property bool wifiBrowserVisible: false

            onNetworkChanged: selectFirst()

            property string interfaceValue: ""
            property string ssidValue: ""
            property string wifiModeValue: "infrastructure"
            property string securityValue: ""
            property string passwordValue: ""
            property string ipv4MethodValue: "auto"
            property string ipv4AddressesValue: ""
            property string ipv4GatewayValue: ""
            property string ipv4DnsValue: ""
            property string ipv6MethodValue: "auto"
            property string ipv6AddressesValue: ""
            property string ipv6GatewayValue: ""
            property string ipv6DnsValue: ""
            property string proxyMethodValue: "none"
            property bool autoconnectValue: true

            function profiles() {
                return (network.connections || []).filter(function(item) {
                    return ["bridge", "loopback", "tun"].indexOf(item.type) < 0
                })
            }
            function isWifi() {
                var profile = selectedProfile()
                return profile && profile.type === "802-11-wireless"
            }
            function tabs() {
                var values = [["general", "General"]]
                if (isWifi()) values.push(["wifi", "Wi-Fi"])
                values.push(["ipv4", "IPv4"], ["ipv6", "IPv6"], ["proxy", "Proxy"])
                return values
            }
            function wifiNetworks() {
                var query = wifiSearch.toLowerCase()
                return (network.wifi_networks || []).filter(function(item) {
                    return !query || item.ssid.toLowerCase().indexOf(query) >= 0
                })
            }
            function selectedProfile() {
                var values = profiles()
                for (var index = 0; index < values.length; index++)
                    if (values[index].name === selectedName) return values[index]
                return values.length ? values[0] : null
            }
            function loadProfile(profile) {
                if (!profile) return
                selectedName = profile.name
                selectedTab = "general"
                wifiPassword = ""
                var details = profile.details || ({})
                interfaceValue = details.interface || ""
                ssidValue = details.ssid || ""
                wifiModeValue = details.wifi_mode || "infrastructure"
                securityValue = details.security || ""
                passwordValue = ""
                ipv4MethodValue = details.ipv4_method || "auto"
                ipv4AddressesValue = details.ipv4_addresses || ""
                ipv4GatewayValue = details.ipv4_gateway || ""
                ipv4DnsValue = details.ipv4_dns || ""
                ipv6MethodValue = details.ipv6_method || "auto"
                ipv6AddressesValue = details.ipv6_addresses || ""
                ipv6GatewayValue = details.ipv6_gateway || ""
                ipv6DnsValue = details.ipv6_dns || ""
                proxyMethodValue = details.proxy_method || "none"
                autoconnectValue = details.autoconnect !== false
            }
            function saveProfile() {
                var values = {
                    interface: interfaceValue, ssid: ssidValue, wifi_mode: wifiModeValue,
                    security: securityValue, ipv4_method: ipv4MethodValue,
                    ipv4_addresses: ipv4AddressesValue, ipv4_gateway: ipv4GatewayValue,
                    ipv4_dns: ipv4DnsValue, ipv6_method: ipv6MethodValue,
                    ipv6_addresses: ipv6AddressesValue, ipv6_gateway: ipv6GatewayValue,
                    ipv6_dns: ipv6DnsValue, proxy_method: proxyMethodValue,
                    autoconnect: autoconnectValue
                }
                if (passwordValue !== "") values.password = passwordValue
                settingsData.networkProfileSave(selectedName, values)
            }
            function selectFirst() { if (!selectedName && profiles().length) loadProfile(profiles()[0]) }

            Component.onCompleted: selectFirst()

            Row {
                anchors.fill: parent
                spacing: 12

                Rectangle {
                    width: 290
                    height: parent.height
                    color: Qt.alpha(surfaceColor(), 0.72)
                    radius: 10
                    border.color: themeData.colors.border || "#3d4355"
                    border.width: 1
                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10
                        Text { text: "Network connections"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 12; font.bold: true }
                        Text { text: "Saved profiles"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }
                        ListView {
                            id: connectionList
                            width: parent.width
                            height: parent.height - 122
                            clip: true
                            spacing: 4
                            model: networkEditor.profiles()
                            delegate: Rectangle {
                                required property var modelData
                                width: connectionList.width
                                height: 48
                                radius: 7
                                color: modelData.name === networkEditor.selectedName ? selectedColor() : "transparent"
                                Column {
                                    anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 18
                                    Text { text: modelData.name; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
                                    Text { text: (modelData.type || "connection") + (modelData.active ? "  ACTIVE" : ""); color: modelData.active ? (themeData.colors.success || "#9ece6a") : mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 9 }
                                }
                                MouseArea { anchors.fill: parent; onClicked: networkEditor.loadProfile(modelData) }
                            }
                        }
                        Row {
                            spacing: 6
                            Button { text: "New"; onClicked: { networkEditor.newName = ""; networkEditor.newSsid = ""; networkEditor.newDialogVisible = true } }
                            Button { text: "Delete"; enabled: networkEditor.selectedName !== ""; onClicked: settingsData.networkProfileDelete(networkEditor.selectedName) }
                        }
                    }
                }

                Column {
                    width: parent.width - 302
                    height: parent.height
                    spacing: 10
                    Text { text: "Network"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
                    Text { text: "Edit NetworkManager connection profiles."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }
                    Text { visible: settingsData.systemActionStatus !== ""; text: settingsData.systemActionStatus; color: themeData.colors.warning || "#e0af68"; font.family: "JetBrains Mono"; font.pixelSize: 10 }

                    Row {
                        spacing: 8
                        Text { text: "Available Wi-Fi"; color: accentColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                        TextField { width: 180; placeholderText: "Search SSIDs"; text: networkEditor.wifiSearch; onTextChanged: networkEditor.wifiSearch = text }
                        TextField { width: 150; echoMode: TextInput.Password; placeholderText: "Password if needed"; onTextChanged: networkEditor.wifiPassword = text }
                        Button { text: networkEditor.wifiBrowserVisible ? "Refresh" : "Scan"; onClicked: { networkEditor.wifiBrowserVisible = true; settingsData.scanWifi() } }
                    }
                    ListView {
                        visible: networkEditor.wifiBrowserVisible
                        width: parent.width
                        height: Math.min(112, Math.max(34, networkEditor.wifiNetworks().length * 34))
                        clip: true
                        model: networkEditor.wifiNetworks()
                        delegate: Row {
                            required property var modelData
                            width: parent.width
                            height: 32
                            spacing: 10
                            Text { width: 210; text: modelData.ssid; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
                            Text { width: 100; text: (modelData.signal || "") + "%  " + (modelData.security || "open"); color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
                            Button { text: "Connect"; onClicked: settingsData.connectWifi(modelData.ssid, networkEditor.wifiPassword, modelData.device) }
                        }
                    }

                    Row {
                        spacing: 6
                        Repeater {
                            model: networkEditor.tabs()
                            delegate: Button { required property var modelData; text: modelData[1]; highlighted: networkEditor.selectedTab === modelData[0]; onClicked: networkEditor.selectedTab = modelData[0] }
                        }
                        Item { width: 1; height: 1 }
                        Button { text: "Connect"; enabled: networkEditor.selectedName !== ""; onClicked: settingsData.activateNetwork(networkEditor.selectedName) }
                    }

                    Rectangle {
                        width: parent.width
                        height: parent.height - 142
                        color: Qt.alpha(surfaceColor(), 0.48)
                        radius: 10
                        border.color: themeData.colors.border || "#3d4355"
                        border.width: 1
                        Flickable {
                            anchors.fill: parent; anchors.margins: 16; contentWidth: width; contentHeight: editorColumn.height; clip: true
                            Column {
                                id: editorColumn
                                width: parent.width
                                spacing: 11
                                visible: networkEditor.selectedName !== ""
                                Text { text: networkEditor.selectedName || "No connection selected"; color: accentColor(); font.family: "JetBrains Mono"; font.pixelSize: 12; font.bold: true }
                                Text { visible: networkEditor.selectedTab === "general"; text: "Connection settings"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                                Row {
                                    visible: networkEditor.selectedTab === "general"; spacing: 10
                                    Text { text: "Interface"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                    TextField { width: 300; text: networkEditor.interfaceValue; placeholderText: "Any interface"; onEditingFinished: networkEditor.interfaceValue = text }
                                }
                                CheckBox { visible: networkEditor.selectedTab === "general"; text: "Automatically connect"; checked: networkEditor.autoconnectValue; onToggled: networkEditor.autoconnectValue = checked }
                                Text { visible: networkEditor.selectedTab === "wifi"; text: "Wi-Fi settings"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                                Row {
                                    visible: networkEditor.selectedTab === "wifi"; spacing: 10
                                    Text { text: "SSID"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                    TextField { width: 300; text: networkEditor.ssidValue; onEditingFinished: networkEditor.ssidValue = text }
                                }
                                Row {
                                    visible: networkEditor.selectedTab === "wifi"; spacing: 10
                                    Text { text: "Mode"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                    ComboBox { width: 220; model: ["infrastructure", "adhoc", "ap", "mesh"]; currentIndex: Math.max(0, model.indexOf(networkEditor.wifiModeValue)); onActivated: networkEditor.wifiModeValue = currentText }
                                }
                                Row {
                                    visible: networkEditor.selectedTab === "wifi"; spacing: 10
                                    Text { text: "Security"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                    ComboBox { width: 220; model: ["", "wpa-psk", "sae", "wpa-eap", "owe"]; currentIndex: Math.max(0, model.indexOf(networkEditor.securityValue)); onActivated: networkEditor.securityValue = currentText }
                                }
                                Row {
                                    visible: networkEditor.selectedTab === "wifi"; spacing: 10
                                    Text { text: "Password"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                    TextField { width: 300; echoMode: TextInput.Password; placeholderText: "Leave blank to keep current password"; onEditingFinished: networkEditor.passwordValue = text }
                                }
                                Text { visible: networkEditor.selectedTab === "ipv4"; text: "IPv4 settings"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                                Row {
                                    visible: networkEditor.selectedTab === "ipv4"; spacing: 10
                                    Text { text: "Method"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                    ComboBox { width: 220; model: ["auto", "manual", "disabled", "link-local", "shared"]; currentIndex: Math.max(0, model.indexOf(networkEditor.ipv4MethodValue)); onActivated: networkEditor.ipv4MethodValue = currentText }
                                }
                                Row {
                                    visible: networkEditor.selectedTab === "ipv4"; spacing: 10
                                    Text { text: "Addresses"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                    TextField { width: 300; text: networkEditor.ipv4AddressesValue; placeholderText: "192.168.1.20/24"; onEditingFinished: networkEditor.ipv4AddressesValue = text }
                                }
                                Row {
                                    visible: networkEditor.selectedTab === "ipv4"; spacing: 10
                                    Text { text: "Gateway"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                    TextField { width: 300; text: networkEditor.ipv4GatewayValue; onEditingFinished: networkEditor.ipv4GatewayValue = text }
                                }
                                Row {
                                    visible: networkEditor.selectedTab === "ipv4"; spacing: 10
                                    Text { text: "DNS"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                    TextField { width: 300; text: networkEditor.ipv4DnsValue; placeholderText: "1.1.1.1,8.8.8.8"; onEditingFinished: networkEditor.ipv4DnsValue = text }
                                }
                                Text { visible: networkEditor.selectedTab === "ipv6"; text: "IPv6 settings"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                                Row {
                                    visible: networkEditor.selectedTab === "ipv6"; spacing: 10
                                    Text { text: "Method"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                    ComboBox { width: 220; model: ["auto", "manual", "disabled", "link-local", "ignore"]; currentIndex: Math.max(0, model.indexOf(networkEditor.ipv6MethodValue)); onActivated: networkEditor.ipv6MethodValue = currentText }
                                }
                                Row {
                                    visible: networkEditor.selectedTab === "ipv6"; spacing: 10
                                    Text { text: "Addresses"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                    TextField { width: 300; text: networkEditor.ipv6AddressesValue; onEditingFinished: networkEditor.ipv6AddressesValue = text }
                                }
                                Row {
                                    visible: networkEditor.selectedTab === "ipv6"; spacing: 10
                                    Text { text: "Gateway"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                    TextField { width: 300; text: networkEditor.ipv6GatewayValue; onEditingFinished: networkEditor.ipv6GatewayValue = text }
                                }
                                Row {
                                    visible: networkEditor.selectedTab === "ipv6"; spacing: 10
                                    Text { text: "DNS"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                    TextField { width: 300; text: networkEditor.ipv6DnsValue; onEditingFinished: networkEditor.ipv6DnsValue = text }
                                }
                                Text { visible: networkEditor.selectedTab === "proxy"; text: "Proxy settings"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                                Row {
                                    visible: networkEditor.selectedTab === "proxy"; spacing: 10
                                    Text { text: "Method"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                    ComboBox { width: 220; model: ["none", "auto", "manual"]; currentIndex: Math.max(0, model.indexOf(networkEditor.proxyMethodValue)); onActivated: networkEditor.proxyMethodValue = currentText }
                                }
                                Text { visible: networkEditor.selectedName === ""; text: "Create or select a saved connection to edit its settings."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }
                            }
                        }
                    }
                    Row {
                        spacing: 8
                        Button { text: "Save"; enabled: networkEditor.selectedName !== ""; onClicked: networkEditor.saveProfile() }
                        Button { text: "Disconnect"; enabled: networkEditor.selectedName !== ""; onClicked: settingsData.deactivateNetwork(networkEditor.selectedName) }
                    }
                }
            }

            Rectangle {
                visible: networkEditor.newDialogVisible
                anchors.fill: parent
                z: 20
                color: Qt.alpha("#000000", 0.68)
                MouseArea { anchors.fill: parent }
                Rectangle {
                    anchors.centerIn: parent
                    width: 460; height: 270; radius: 12
                    color: surfaceColor(); border.color: accentColor(); border.width: 1
                    Column {
                        anchors.fill: parent; anchors.margins: 20; spacing: 12
                        Text { text: "New connection"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 14; font.bold: true }
                        ComboBox { width: 220; model: ["wifi", "ethernet"]; currentIndex: 0; onActivated: networkEditor.newType = currentText }
                        TextField { width: parent.width; placeholderText: "Connection name"; onTextChanged: networkEditor.newName = text }
                        TextField { visible: networkEditor.newType === "wifi"; width: parent.width; placeholderText: "Wi-Fi SSID"; onTextChanged: networkEditor.newSsid = text }
                        Row {
                            spacing: 10
                            Button { text: "Cancel"; onClicked: networkEditor.newDialogVisible = false }
                            Button { text: "Create"; enabled: networkEditor.newName !== "" && (networkEditor.newType !== "wifi" || networkEditor.newSsid !== ""); onClicked: { settingsData.networkProfileAdd(networkEditor.newName, networkEditor.newType, networkEditor.newSsid); networkEditor.newDialogVisible = false } }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: bluetoothPage
        Item {
            id: bluetoothEditor
            property var bluetooth: settingsData.draft.system && settingsData.draft.system.bluetooth ? settingsData.draft.system.bluetooth : ({ adapter: {}, devices: [] })
            property string selectedAddress: ""
            property string search: ""

            function devices() {
                var query = search.toLowerCase()
                return (bluetooth.devices || []).filter(function(item) {
                    var label = (item.alias || item.name || item.address).toLowerCase()
                    return !query || label.indexOf(query) >= 0 || item.address.toLowerCase().indexOf(query) >= 0
                })
            }
            function selectedDevice() {
                var values = bluetooth.devices || []
                for (var index = 0; index < values.length; index++)
                    if (values[index].address === selectedAddress) return values[index]
                return values.length ? values[0] : null
            }
            function selectFirst() {
                var device = selectedDevice()
                if (device && !selectedAddress) selectedAddress = device.address
            }
            onBluetoothChanged: selectFirst()
            Component.onCompleted: selectFirst()

            Column {
                anchors.fill: parent
                spacing: 10
                Text { text: "Bluetooth"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
                Text { text: "Manage adapters, paired devices, and nearby Bluetooth hardware."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }
                Text { visible: settingsData.systemActionStatus !== ""; text: settingsData.systemActionStatus; color: themeData.colors.warning || "#e0af68"; font.family: "JetBrains Mono"; font.pixelSize: 10 }

                Rectangle {
                    width: parent.width
                    height: 58
                    color: Qt.alpha(surfaceColor(), 0.72)
                    radius: 9
                    Row {
                        anchors.fill: parent; anchors.margins: 10; spacing: 12
                        CheckBox { text: "Enabled"; checked: bluetoothEditor.bluetooth.adapter && bluetoothEditor.bluetooth.adapter.powered === true; onToggled: settingsData.setBluetoothPower(checked) }
                        CheckBox { text: "Discovering"; enabled: bluetoothEditor.bluetooth.adapter && bluetoothEditor.bluetooth.adapter.powered === true; checked: bluetoothEditor.bluetooth.adapter && bluetoothEditor.bluetooth.adapter.discovering === true; onToggled: settingsData.setBluetoothScanning(checked) }
                        CheckBox { text: "Pairable"; enabled: bluetoothEditor.bluetooth.adapter && bluetoothEditor.bluetooth.adapter.powered === true; checked: bluetoothEditor.bluetooth.adapter && bluetoothEditor.bluetooth.adapter.pairable === true; onToggled: settingsData.setBluetoothPairable(checked) }
                        CheckBox { text: "Discoverable"; enabled: bluetoothEditor.bluetooth.adapter && bluetoothEditor.bluetooth.adapter.powered === true; checked: bluetoothEditor.bluetooth.adapter && bluetoothEditor.bluetooth.adapter.discoverable === true; onToggled: settingsData.setBluetoothDiscoverable(checked) }
                    }
                }

                Row {
                    width: parent.width
                    height: parent.height - 150
                    spacing: 12
                    Rectangle {
                        width: 300; height: parent.height
                        color: Qt.alpha(surfaceColor(), 0.72); radius: 10
                        border.color: themeData.colors.border || "#3d4355"; border.width: 1
                        Column {
                            anchors.fill: parent; anchors.margins: 12; spacing: 10
                            Text { text: "Devices"; color: accentColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                            TextField { width: parent.width; placeholderText: "Search devices"; text: bluetoothEditor.search; onTextChanged: bluetoothEditor.search = text }
                            ListView {
                                id: bluetoothList
                                width: parent.width; height: parent.height - 70; clip: true; spacing: 4
                                model: bluetoothEditor.devices()
                                delegate: Rectangle {
                                    required property var modelData
                                    width: bluetoothList.width; height: 52; radius: 7
                                    color: modelData.address === bluetoothEditor.selectedAddress ? selectedColor() : "transparent"
                                    Column {
                                        anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 18
                                        Text { text: modelData.alias || modelData.name || modelData.address; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
                                        Text { text: (modelData.connected ? "CONNECTED" : (modelData.paired ? "PAIRED" : "AVAILABLE")) + (modelData.rssi !== undefined ? "  " + modelData.rssi + " dBm" : ""); color: modelData.connected ? (themeData.colors.success || "#9ece6a") : mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 9 }
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: bluetoothEditor.selectedAddress = modelData.address }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width - 312; height: parent.height
                        color: Qt.alpha(surfaceColor(), 0.48); radius: 10
                        border.color: themeData.colors.border || "#3d4355"; border.width: 1
                        Flickable {
                            anchors.fill: parent; anchors.margins: 16; contentWidth: width; contentHeight: bluetoothDetails.height; clip: true
                            Column {
                                id: bluetoothDetails
                                width: parent.width; spacing: 12
                                property var device: bluetoothEditor.selectedDevice() || ({})
                                Text { text: bluetoothDetails.device.alias || bluetoothDetails.device.name || "No device selected"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 14; font.bold: true }
                                Text { text: bluetoothDetails.device.address || "Scan for nearby devices to begin."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }
                                Text { visible: bluetoothDetails.device.icon !== undefined; text: "Type: " + (bluetoothDetails.device.icon || "unknown"); color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }
                                Text { visible: bluetoothDetails.device.battery !== undefined; text: "Battery: " + bluetoothDetails.device.battery + "%"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }
                                Text { visible: bluetoothDetails.device.rssi !== undefined; text: "Signal: " + bluetoothDetails.device.rssi + " dBm"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10 }
                                Row {
                                    spacing: 8
                                    Button { text: bluetoothDetails.device.connected ? "Disconnect" : "Connect"; enabled: bluetoothDetails.device.address !== undefined; onClicked: bluetoothDetails.device.connected ? settingsData.disconnectBluetooth(bluetoothDetails.device.address) : settingsData.connectBluetooth(bluetoothDetails.device.address) }
                                    Button { text: bluetoothDetails.device.paired ? "Paired" : "Pair"; enabled: !bluetoothDetails.device.paired && bluetoothDetails.device.address !== undefined; onClicked: settingsData.pairBluetooth(bluetoothDetails.device.address) }
                                }
                                Row {
                                    spacing: 8
                                    CheckBox { text: "Trusted"; enabled: bluetoothDetails.device.paired === true; checked: bluetoothDetails.device.trusted === true; onToggled: settingsData.trustBluetooth(bluetoothDetails.device.address, checked) }
                                    CheckBox { text: "Blocked"; enabled: bluetoothDetails.device.address !== undefined; checked: bluetoothDetails.device.blocked === true; onToggled: settingsData.blockBluetooth(bluetoothDetails.device.address, checked) }
                                }
                                Row {
                                    spacing: 8
                                    Button { text: "Remove device"; enabled: bluetoothDetails.device.paired === true || bluetoothDetails.device.blocked === true; onClicked: settingsData.removeBluetooth(bluetoothDetails.device.address) }
                                }
                                Text { visible: !settingsData.capabilities.bluetoothctl; text: "bluetoothctl is not available in this session."; color: themeData.colors.warning || "#e0af68"; font.family: "JetBrains Mono"; font.pixelSize: 10 }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: powerPage
        Flickable {
            contentWidth: width
            contentHeight: powerColumn.height
            clip: true
            Item {
                id: powerEditor
                width: parent.width
                height: powerColumn.height
                property var power: settingsData.draft.system && settingsData.draft.system.power ? settingsData.draft.system.power : ({})
                property var idle: power.hypridle || ({ enabled: true, lock_timeout: 180, suspend_timeout: 300 })
                property bool idleEnabled: true
                property int lockTimeout: 180
                property int suspendTimeout: 300
                property string lockAction: "loginctl lock-session"
                property string suspendAction: "systemctl suspend"

                function syncIdle() {
                    idleEnabled = idle.enabled !== false
                    lockTimeout = Number(idle.lock_timeout || 0)
                    suspendTimeout = Number(idle.suspend_timeout || 0)
                    lockAction = idle.lock_action || "loginctl lock-session"
                    suspendAction = idle.suspend_action || "systemctl suspend"
                }
                onPowerChanged: syncIdle()
                Component.onCompleted: syncIdle()

                Column {
                    id: powerColumn
                    width: parent.width
                    spacing: 14
                    Text { text: "Power"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
                    Text { text: "TuneD performance profiles and Hypridle session behavior."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
                    Text { visible: settingsData.systemActionStatus !== ""; text: settingsData.systemActionStatus; color: themeData.colors.warning || "#e0af68"; font.family: "JetBrains Mono"; font.pixelSize: 10 }

                    Rectangle {
                        width: parent.width
                        height: tunedColumn.height + 24
                        color: Qt.alpha(surfaceColor(), 0.72)
                        radius: 10
                        border.color: themeData.colors.border || "#3d4355"
                        border.width: 1
                        Column {
                            id: tunedColumn
                            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12
                            spacing: 10
                            Text { text: "System performance profile"; color: accentColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                            Row {
                                spacing: 10
                                Text { text: powerEditor.power.backend === "tuned" ? "TuneD profile" : "Power profile"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                ComboBox {
                                    width: 300
                                    model: powerEditor.power.profiles || []
                                    currentIndex: Math.max(0, model.indexOf(powerEditor.power.profile || ""))
                                    enabled: powerEditor.power.backend === "tuned" && settingsData.capabilities["tuned-adm"]
                                    onActivated: settingsData.setTunedProfile(currentText)
                                }
                            }
                            Text { text: powerEditor.power.backend === "tuned" ? "TuneD is managing the active system profile." : "TuneD is unavailable; install a compatible power profile backend."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: idleColumn.height + 24
                        color: Qt.alpha(surfaceColor(), 0.72)
                        radius: 10
                        border.color: themeData.colors.border || "#3d4355"
                        border.width: 1
                        Column {
                            id: idleColumn
                            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12
                            spacing: 10
                            Text { text: "Lock and idle"; color: accentColor(); font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                            CheckBox { text: "Enable Hypridle"; checked: powerEditor.idleEnabled; onToggled: powerEditor.idleEnabled = checked }
                            Row {
                                spacing: 10
                                Text { text: "Lock after"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                SpinBox { from: 0; to: 7200; stepSize: 30; value: powerEditor.lockTimeout; enabled: powerEditor.idleEnabled; onValueModified: powerEditor.lockTimeout = value }
                                Text { text: powerEditor.lockTimeout === 0 ? "disabled" : powerEditor.lockTimeout + " seconds"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                            }
                            Row {
                                spacing: 10
                                Text { text: "Suspend after"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                SpinBox { from: 0; to: 14400; stepSize: 30; value: powerEditor.suspendTimeout; enabled: powerEditor.idleEnabled; onValueModified: powerEditor.suspendTimeout = value }
                                Text { text: powerEditor.suspendTimeout === 0 ? "disabled" : powerEditor.suspendTimeout + " seconds"; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                            }
                            Row {
                                spacing: 10
                                Text { text: "Lock command"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                TextField { width: 360; text: powerEditor.lockAction; onEditingFinished: powerEditor.lockAction = text }
                            }
                            Row {
                                spacing: 10
                                Text { text: "Suspend command"; color: mutedColor(); width: 120; font.family: "JetBrains Mono"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                TextField { width: 360; text: powerEditor.suspendAction; onEditingFinished: powerEditor.suspendAction = text }
                            }
                            Button { text: "Stage Hypridle settings"; onClicked: settingsData.saveHypridle({ enabled: powerEditor.idleEnabled, lock_timeout: powerEditor.lockTimeout, suspend_timeout: powerEditor.suspendTimeout, lock_action: powerEditor.lockAction, suspend_action: powerEditor.suspendAction }) }
                            Text { text: "Changes remain staged until the global Apply button is pressed."; color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
                            Text { text: settingsData.capabilities.hypridle ? "Changes restart the user Hypridle service." : "hypridle is not available in this session."; color: settingsData.capabilities.hypridle ? mutedColor() : (themeData.colors.warning || "#e0af68"); font.family: "JetBrains Mono"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
                        }
                    }
                }
            }
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
                Row {
                    spacing: 10
                    Orbit.OrbitButton {
                        themeData: root.themeData
                        text: "Reload Orbit"
                        highlighted: true
                        onClicked: settingsData.reloadOrbit()
                    }
                    Text {
                        text: "Restarts the Orbit shell without changing system settings."
                        color: mutedColor()
                        font.family: themeData.uiFont
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                Text { text: "Monitors: " + settingsData.monitors.length; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 11 }
                Repeater {
                    model: settingsData.monitors
                    delegate: Text {
                        required property var modelData
                        text: (modelData.focused ? "* " : "  ") + (modelData.name || "unknown") + "  " + (modelData.description || modelData.model || "")
                        color: mutedColor(); font.family: "JetBrains Mono"; font.pixelSize: 10; elide: Text.ElideRight; width: diagnosticsColumn.width
                    }
                }
                Text { text: "System backends"; color: textColor(); font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
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
