import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects

FloatingWindow {
    id: root

    visible: true
    implicitWidth: 1720
    implicitHeight: 900
    color: "transparent"
    title: Quickshell.env("PHLEG_XMB_TITLE") || "phleg-xmb"

    property var fallbackConfig: ({
        categories: ["System", "Utilities", "Graphics", "Games", "Media", "Web", "Social"],
        exclude: [],
        entries: []
    })
    property var config: fallbackConfig
    property int categoryIndex: 0
    property int entryIndex: 0
    property string status: "Ready"
    property string monitorName: Quickshell.env("PHLEG_XMB_MONITOR") || "reserved"

    FileView {
        id: configFile
        path: root.homeConfigPath
        blockLoading: true
        watchChanges: true
        onLoaded: root.reloadConfig()
        onFileChanged: reload()
    }

    readonly property string homeConfigPath: Quickshell.env("HOME") + "/.config/phleg/xmb.json"
    readonly property var categories: config.categories || fallbackConfig.categories

    function reloadConfig() {
        try {
            var loaded = JSON.parse(configFile.text())
            config = loaded
            categoryIndex = Math.min(categoryIndex, categories.length - 1)
            entryIndex = Math.min(entryIndex, entriesForCurrentCategory().length - 1)
        } catch (error) {
            status = "Menu config error"
        }
    }

    function entriesFor(category) {
        var excluded = config.exclude || []
        return (config.entries || []).filter(function(entry) {
            return entry.category === category && excluded.indexOf(entry.id) < 0 && entry.enabled !== false
        })
    }

    function displayEntriesFor(category) {
        var entries = entriesFor(category)
        return entries.length > 0 ? entries : [{
            id: "empty-" + category,
            label: "No items",
            icon: "folder-open-symbolic",
            placeholder: true
        }]
    }

    function entriesForCurrentCategory() {
        return entriesFor(categories[categoryIndex] || "System")
    }

    function categoryIcon(category) {
        var icons = {
            "System": "preferences-system-symbolic",
            "Utilities": "applications-utilities-symbolic",
            "Graphics": "applications-graphics-symbolic",
            "Games": "applications-games-symbolic",
            "Media": "applications-multimedia-symbolic",
            "Web": "applications-internet-symbolic",
            "Social": "user-available-symbolic"
        }
        return icons[category] || "folder"
    }

    function categoryOpacity(index) {
        var distance = Math.abs(index - categoryIndex)
        if (distance === 0)
            return 1.0
        if (distance === 1)
            return 0.6
        if (distance === 2)
            return 0.3
        if (distance === 3)
            return 0.15
        if (distance === 4)
            return 0.08
        return 0.0
    }

    function entryOpacity(index) {
        var distance = Math.abs(index - entryIndex)
        if (distance === 0)
            return 1.0
        if (distance === 1)
            return 0.6
        if (distance === 2)
            return 0.3
        if (distance === 3)
            return 0.15
        if (distance === 4)
            return 0.08
        return 0.0
    }

    function entryIcon(entry) {
        if (entry.icon)
            return Quickshell.iconPath(entry.icon)

        var desktop = entry.desktop ? (DesktopEntries.byId(entry.desktop) || DesktopEntries.heuristicLookup(entry.desktop)) : null
        if (desktop && desktop.icon)
            return Quickshell.iconPath(desktop.icon)

        var icons = {
            "btop": "utilities-system-monitor",
            "steam": "steam",
            "counter-strike-2": "steam",
            "rocket-league": "steam",
            "dead-by-daylight": "steam"
        }
        return Quickshell.iconPath(icons[entry.id] || "application-x-executable")
    }

    function selectCategory(index) {
        categoryIndex = (index + categories.length) % categories.length
        entryIndex = 0
    }

    function selectEntry(index) {
        var count = entriesForCurrentCategory().length
        if (count > 0)
            entryIndex = (index + count) % count
    }

    function launchEntry(entry) {
        var desktop = entry.desktop ? DesktopEntries.byId(entry.desktop) : null
        if (!desktop && entry.desktop)
            desktop = DesktopEntries.heuristicLookup(entry.desktop)
        if (desktop) {
            desktop.execute()
            status = "Launching " + entry.label
        } else if (entry.command) {
            Quickshell.execDetached(["sh", "-lc", entry.command])
            status = "Launching " + entry.label
        } else {
            status = "No launcher configured for " + entry.label
        }
    }

        FocusScope {
        id: content
        anchors.fill: parent
        focus: true

        Component.onCompleted: forceActiveFocus()

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Left) {
                root.selectCategory(root.categoryIndex - 1)
            } else if (event.key === Qt.Key_Right) {
                root.selectCategory(root.categoryIndex + 1)
            } else if (event.key === Qt.Key_Up) {
                root.selectEntry(root.entryIndex - 1)
            } else if (event.key === Qt.Key_Down) {
                root.selectEntry(root.entryIndex + 1)
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                var entries = root.entriesForCurrentCategory()
                if (entries.length > 0)
                    root.launchEntry(entries[root.entryIndex])
            } else {
                return
            }
            event.accepted = true
        }

        Item {
            anchors.fill: parent

            Item {
                anchors.fill: parent

                Item {
                    id: categoryColumns
                    width: parent.width
                    y: parent.height * 0.33 - 184
                    height: parent.height - y
                    property real categorySpacing: 10
                    clip: true

                    Repeater {
                        model: root.categories
                        delegate: Item {
                            id: categoryColumn
                            required property string modelData
                            required property int index
                            property int categoryColumnIndex: index
                            property var categoryEntries: root.entriesFor(modelData)
                            width: (categoryColumns.width - (root.categories.length - 1) * categoryColumns.categorySpacing) / root.categories.length
                            height: categoryColumns.height
                            x: categoryColumns.width * 0.33 - width / 2 + (categoryColumnIndex - root.categoryIndex) * (width + categoryColumns.categorySpacing)

                            Behavior on x {
                                NumberAnimation {
                                    duration: 220
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Column {
                                anchors.fill: parent
                                spacing: 12

                                Item {
                                    width: parent.width
                                    height: 126
                                    property bool fitsViewport: categoryColumn.x >= 0 && categoryColumn.x + categoryColumn.width <= categoryColumns.width
                                    opacity: fitsViewport ? root.categoryOpacity(categoryColumn.categoryColumnIndex) : 0
                                    layer.enabled: fitsViewport && root.categoryOpacity(categoryColumn.categoryColumnIndex) > 0
                                    layer.effect: MultiEffect {
                                        shadowEnabled: categoryColumn.categoryColumnIndex === root.categoryIndex
                                        shadowColor: "#000000"
                                        shadowOpacity: 0.7
                                        shadowBlur: 0.65
                                        shadowVerticalOffset: 3
                                        blurEnabled: true
                                        blur: (1 - root.categoryOpacity(categoryColumn.categoryColumnIndex)) * 0.7
                                    }

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 220
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Column {
                                        anchors.fill: parent
                                        spacing: 8
                                        Image {
                                            width: 64
                                            height: 64
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            source: Quickshell.iconPath(root.categoryIcon(modelData))
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                        }
                                        Text {
                                            width: parent.width
                                            text: modelData
                                            color: "#bdefff"
                                            font.pixelSize: 24
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideRight
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: parent.opacity > 0
                                        onClicked: root.selectCategory(index)
                                    }
                                }

                                Item {
                                    id: entryTrack
                                    width: categoryColumns.width
                                    x: -(categoryColumns.width - parent.width) / 2
                                    height: parent.height - 138
                                    clip: true

                                    Repeater {
                                        model: categoryColumn.categoryColumnIndex === root.categoryIndex ? root.displayEntriesFor(modelData) : []
                                        delegate: Item {
                                            required property var modelData
                                            required property int index
                                            property bool placeholder: modelData.placeholder === true
                                            property real rowSpacing: 16
                                            property bool contentFitsViewport: {
                                                var left = categoryColumn.x + entryTrack.x + (root.categoryIndex === categoryColumn.categoryColumnIndex && root.entryIndex === index ? applicationLabel.x : applicationIcon.x)
                                                var right = categoryColumn.x + entryTrack.x + (root.categoryIndex === categoryColumn.categoryColumnIndex && root.entryIndex === index ? applicationLabel.x + applicationLabel.implicitWidth : applicationIcon.x + applicationIcon.width)
                                                return left >= 0 && right <= categoryColumns.width
                                            }
                                            width: entryTrack.width
                                            height: 92
                                            opacity: contentFitsViewport ? root.entryOpacity(index) : 0
                                            layer.enabled: contentFitsViewport && root.entryOpacity(index) > 0
                                            layer.effect: MultiEffect {
                                                shadowEnabled: root.categoryIndex === categoryColumn.categoryColumnIndex && root.entryIndex === index
                                                shadowColor: "#000000"
                                                shadowOpacity: 0.75
                                                shadowBlur: 0.65
                                                shadowVerticalOffset: 3
                                                blurEnabled: true
                                                blur: (1 - root.entryOpacity(index)) * 0.7
                                            }
                                            y: (index - root.entryIndex) * (height + rowSpacing)

                                            Behavior on y {
                                                NumberAnimation {
                                                    duration: 220
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: 220
                                                    easing.type: Easing.OutCubic
                                                }
                                            }

                                            Image {
                                                id: applicationIcon
                                                width: 64
                                                height: 64
                                                x: (categoryColumn.width - width) / 2 - entryTrack.x
                                                anchors.verticalCenter: parent.verticalCenter
                                                source: placeholder ? Quickshell.iconPath(modelData.icon) : root.entryIcon(modelData)
                                                fillMode: Image.PreserveAspectFit
                                                smooth: true
                                            }
                                            Text {
                                                id: applicationLabel
                                                visible: placeholder || (root.categoryIndex === categoryColumn.categoryColumnIndex && root.entryIndex === index)
                                                x: applicationIcon.x + applicationIcon.width + 10
                                                width: implicitWidth
                                                text: modelData.label
                                                color: "#e1f7ff"
                                                font.pixelSize: 22
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: !placeholder && parent.opacity > 0
                                                onClicked: {
                                                    root.selectCategory(categoryColumn.categoryColumnIndex)
                                                    root.selectEntry(index)
                                                }
                                                onDoubleClicked: root.launchEntry(modelData)
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
    }
}
