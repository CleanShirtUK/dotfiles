import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    required property var windowModel
    required property var monitorModel
    property var lastFocused: ({})
    property var selectedByMonitor: ({})
    property var dbusMenus: []
    property var atspiMenus: []
    property var current: null
    property string title: "No application menu"
    property bool available: false

    Connections {
        target: windowModel
        function onClientsChanged() { root.refresh() }
    }

    Connections {
        target: monitorModel
        function onMonitorsChanged() { root.refresh() }
    }

    Process {
        id: dbusMenuProcess
        command: [Quickshell.env("HOME") + "/.local/bin/orbit-appmenu", "snapshot"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.dbusMenus = JSON.parse(text)
                } catch (error) {
                    root.dbusMenus = []
                }
            }
        }
    }

    Process {
        id: atspiMenuProcess
        command: [Quickshell.env("HOME") + "/.local/bin/orbit-appmenu-atspi", "snapshot"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.atspiMenus = JSON.parse(text)
                } catch (error) {
                    root.atspiMenus = []
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!dbusMenuProcess.running)
                dbusMenuProcess.running = true
            if (!atspiMenuProcess.running)
                atspiMenuProcess.running = true
        }
    }

    function workspaceKey(client) {
        return client.monitor + ":" + (client.workspace ? client.workspace.id : -1)
    }

    function classSuffix(value) {
        var parts = (value || "").split(".")
        return parts[parts.length - 1] || "Unknown application"
    }

    function desktopFor(client) {
        var identity = client.initialClass || client.class || ""
        return DesktopEntries.heuristicLookup(identity) || DesktopEntries.byId(identity)
    }

    function prettyName(client) {
        var desktop = desktopFor(client)
        return desktop && desktop.name ? desktop.name : classSuffix(client.class || client.initialClass)
    }

    function monitorFor(monitorName) {
        return monitorModel.monitors.filter(function(item) { return item.name === monitorName })[0]
    }

    function candidateFor(monitorName) {
        var focused = monitorModel.focusedName === monitorName
        var monitor = monitorFor(monitorName)
        var candidates = windowModel.clients.filter(function(client) {
            return monitor && Number(client.monitor) === Number(monitor.id) && client.workspace && client.workspace.id === currentWorkspace(monitorName)
        })
        candidates.sort(function(left, right) {
            var leftHistory = typeof left.focusHistoryID === "number" ? left.focusHistoryID : 999999
            var rightHistory = typeof right.focusHistoryID === "number" ? right.focusHistoryID : 999999
            return leftHistory - rightHistory
        })
        if (focused && candidates.length > 0)
            return candidates[0]
        var remembered = lastFocused[monitorName + ":" + currentWorkspace(monitorName)]
        if (remembered) {
            var current = candidates.filter(function(client) {
                return remembered.address && client.address === remembered.address
            })
            if (current.length > 0)
                return current[0]
        }
        return candidates.length > 0 ? candidates[0] : null
    }

    function titleFor(monitorName) {
        var candidate = candidateFor(monitorName)
        return candidate ? prettyName(candidate) : "No application menu"
    }

    function availableFor(monitorName) {
        var candidate = candidateFor(monitorName)
        return Boolean(candidate && (candidate.menu || dbusMenuFor(monitorName)))
    }

    function menuFor(monitorName) {
        var candidate = candidateFor(monitorName)
        return candidate && candidate.menu ? candidate.menu : null
    }

    function dbusMenuFor(monitorName) {
        var candidate = candidateFor(monitorName)
        if (!candidate)
            return null
        var atspi = atspiMenus.filter(function(item) {
            return Number(item.pid) === Number(candidate.pid)
                && item.title === candidate.title
                && item.monitor === monitorName
        })
        if (atspi.length > 0)
            return atspi[0]
        if (!candidate.xwayland)
            return null
        var exact = dbusMenus.filter(function(item) {
            return Number(item.pid) === Number(candidate.pid) && item.title === candidate.title
        })
        if (exact.length > 0)
            return exact[0]
        var matching = dbusMenus.filter(function(item) {
            return Number(item.pid) === Number(candidate.pid)
                && (item.wmClass === candidate.class || item.wmClass === candidate.initialClass)
        })
        return matching.length > 0 ? matching[0] : null
    }

    function dbusRowsFor(monitorName) {
        var entry = dbusMenuFor(monitorName)
        if (!entry || !entry.layout || !entry.layout.root)
            return []
        var rows = []
        function append(node, depth) {
            var properties = node.properties || ({})
            var label = properties.label !== undefined ? properties.label : node.label
            var visible = properties.visible !== undefined ? properties.visible : node.visible
            var enabled = properties.enabled !== undefined ? properties.enabled : node.enabled
            var hasChildren = node.children && node.children.length > 0
            var separator = (properties.type || node.type) === "separator"
            if (node.id !== 0 && visible !== false && (label || !hasChildren)) {
                rows.push({
                    id: node.id,
                    depth: depth,
                    label: separator ? "────────" : String(label || "").replace(/_/g, ""),
                    enabled: enabled !== false,
                    hasChildren: hasChildren,
                    service: node.service || "",
                    path: node.path || "",
                })
            }
            var nextDepth = node.id === 0 || !label ? depth : depth + 1
            ;(node.children || []).forEach(function(child) { append(child, nextDepth) })
        }
        append(entry.layout.root, 0)
        return rows
    }

    function fallbackRowsFor(monitorName) {
        var candidate = candidateFor(monitorName)
        if (!candidate)
            return []
        var rows = []
        var desktop = desktopFor(candidate)
        if (desktop && desktop.execString) {
            rows.push({
                id: "open-new-window",
                label: "Open new window",
                enabled: true,
                action: "launch"
            })
        }
        rows.push({ id: "close", label: "Close window", enabled: true, action: "close" })
        rows.push({ id: "force-quit", label: "Force quit application", enabled: true, action: "force-quit" })
        return rows
    }

    function activateFallback(monitorName, action) {
        var candidate = candidateFor(monitorName)
        if (!candidate)
            return
        if (action === "close") {
            closeFor(monitorName)
            return
        }
        if (action === "force-quit") {
            forceQuitFor(monitorName)
            return
        }
        if (action === "launch") {
            var desktop = desktopFor(candidate)
            if (desktop && desktop.execString)
                Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-app-launch", desktop.execString])
        }
    }

    function activateDbus(monitorName, item) {
        var entry = dbusMenuFor(monitorName)
        if (!entry)
            return
        if (entry.source === "atspi") {
            if (item.service && item.path)
                Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-appmenu-atspi", "activate", item.service, item.path])
        } else {
            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-appmenu", "activate", String(entry.windowId), String(item.id)])
        }
    }

    function hasCandidateFor(monitorName) {
        return Boolean(candidateFor(monitorName))
    }

    function currentWorkspace(monitorName) {
        var monitor = monitorFor(monitorName)
        return monitor ? monitor.activeWorkspace.id : -1
    }

    function refresh() {
        var next = {}
        windowModel.clients.forEach(function(client) {
            if (client.focusHistoryID === 0 || client.focused)
                next[workspaceKey(client)] = client
        })
        for (var key in next)
            lastFocused[key] = next[key]

        var selected = candidateFor(monitorModel.focusedName)
        current = selected
        available = Boolean(selected && selected.menu)
        title = selected ? prettyName(selected) : "No application menu"
    }

    function openFor(menuAnchor, monitorName) {
        var candidate = candidateFor(monitorName)
        if (candidate && candidate.menu)
            menuAnchor.menu = candidate.menu
            menuAnchor.open()
    }

    function closeFor(monitorName) {
        var candidate = candidateFor(monitorName)
        if (candidate && candidate.address) {
            var focus = "hl.dsp.focus({ window = \"address:" + candidate.address + "\" })"
            Quickshell.execDetached(["sh", "-lc", "hyprctl dispatch '" + focus + "' && hyprctl dispatch 'hl.dsp.window.close()'"])
        }
    }

    function forceQuitFor(monitorName) {
        var candidate = candidateFor(monitorName)
        if (candidate && candidate.pid)
            Quickshell.execDetached(["kill", "-KILL", String(candidate.pid)])
    }

    Component.onCompleted: refresh()
}
