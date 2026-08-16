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
    property string query: ""
    property string category: "All"
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
            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-app-observe", "launch", "--desktop", app.id, "--command", app.execString || ""])
            app.execute()
        }
    }

    Component.onCompleted: reload()
}
