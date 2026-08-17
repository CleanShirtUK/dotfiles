import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    readonly property var defaultCategories: [
        "All", "System", "Utilities", "Graphics", "Games", "Media", "Web",
        "Social", "Development", "Office", "Education", "Science"
    ]
    property var categories: defaultCategories
    property var categoryMap: ({})
    property var overrides: ({})
    property bool fullscreen: false
    required property var monitorModel
    property string query: ""
    property string category: "All"
    property int launchRevision: 0
    readonly property var applications: DesktopEntries.applications.values

    FileView {
        id: configFile
        path: Quickshell.env("HOME") + "/.config/orbit/xmb.json"
        blockLoading: true
        watchChanges: true
        onLoaded: root.reload()
        onFileChanged: reload()
    }

    function reload() {
        try {
            var config = JSON.parse(configFile.text())
            categories = config.categories || defaultCategories
            categoryMap = config.category_map || {}
            overrides = config.overrides || {}
            fullscreen = config.fullscreen === true
        } catch (error) {
            categories = defaultCategories
            categoryMap = {}
            overrides = {}
            fullscreen = false
        }
    }

    function normalized(value) {
        return String(value || "").toLowerCase()
    }

    function categoryFor(app) {
        if (overrides[app.id])
            return overrides[app.id]

        var appCategories = app.categories || []
        for (var index = 0; index < appCategories.length; index++) {
            var standard = appCategories[index]
            if (categoryMap[standard])
                return categoryMap[standard]
        }
        return "Utilities"
    }

    function categoryIcon(category) {
        var icons = {
            "All": "applications-all-symbolic",
            "System": "preferences-system-symbolic",
            "Utilities": "applications-utilities-symbolic",
            "Graphics": "applications-graphics-symbolic",
            "Games": "applications-games-symbolic",
            "Media": "applications-multimedia-symbolic",
            "Web": "applications-internet-symbolic",
            "Social": "user-available-symbolic",
            "Development": "applications-development-symbolic",
            "Office": "x-office-document-symbolic",
            "Education": "accessories-dictionary-symbolic",
            "Science": "accessories-calculator-symbolic"
        }
        return icons[category] || "folder-symbolic"
    }

    function matches(app) {
        var search = normalized(query).trim()
        if (!search)
            return true

        var haystack = [app.name, app.genericName, app.id].concat(app.keywords || []).join(" ")
        return normalized(haystack).indexOf(search) >= 0
    }

    function filteredApps() {
        var result = []
        for (var index = 0; index < applications.length; index++) {
            var app = applications[index]
            if (app.noDisplay || !matches(app))
                continue
            if (category !== "All" && categoryFor(app) !== category)
                continue
            result.push(app)
        }
        result.sort(function(left, right) {
            return String(left.name).localeCompare(String(right.name))
        })
        return result
    }

    function launch(app) {
        if (app) {
            var monitor = monitorModel.focusedName
            var workspace = ""
            for (var index = 0; index < monitorModel.monitors.length; index++) {
                var candidate = monitorModel.monitors[index]
                if (candidate.name === monitor && candidate.activeWorkspace)
                    workspace = String(candidate.activeWorkspace.name || candidate.activeWorkspace.id)
            }
            var expectedClass = app.startupWMClass || app.id
            var launchId = "orbit-" + Date.now() + "-" + (++launchRevision)
            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-app-observe", "launch", "--desktop", app.id, "--command", app.execString || "", "--launch-id", launchId])
            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-app-launch", "--monitor", monitor, "--workspace", workspace, "--class", expectedClass, "--launch-id", launchId, app.execString || ""])
        }
    }

    Component.onCompleted: reload()
}
