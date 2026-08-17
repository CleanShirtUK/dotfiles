import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property var monitors: []
    property var clients: []
    property var workspaces: []
    property var activeWorkspace: ({})

    Process { id: monitorProcess; command: ["hyprctl", "monitors", "-j"]; stdout: StdioCollector { onStreamFinished: root.updateList("monitors", text) } }
    Process { id: clientProcess; command: ["hyprctl", "clients", "-j"]; stdout: StdioCollector { onStreamFinished: root.updateClients(text) } }
    Process { id: workspaceProcess; command: ["hyprctl", "workspaces", "-j"]; stdout: StdioCollector { onStreamFinished: root.updateWorkspaces(text) } }
    Process { id: activeProcess; command: ["hyprctl", "activeworkspace", "-j"]; stdout: StdioCollector { onStreamFinished: root.updateActive(text) } }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    function refresh() {
        if (!monitorProcess.running) monitorProcess.running = true
        if (!clientProcess.running) clientProcess.running = true
        if (!workspaceProcess.running) workspaceProcess.running = true
        if (!activeProcess.running) activeProcess.running = true
    }

    function parseList(raw) {
        var parsed = JSON.parse(raw)
        return Array.isArray(parsed) ? parsed : []
    }

    function updateList(name, raw) {
        try { root[name] = parseList(raw) } catch (error) { root[name] = [] }
    }

    function updateClients(raw) {
        try {
            clients = parseList(raw).filter(function(client) {
                return client.mapped && !client.hidden && client.class !== "org.quickshell"
            })
        } catch (error) { clients = [] }
    }

    function updateWorkspaces(raw) {
        try {
            workspaces = parseList(raw).filter(function(workspace) {
                return !String(workspace.name || "").startsWith("special:")
            }).sort(function(left, right) { return left.id - right.id })
        } catch (error) { workspaces = [] }
    }

    function updateActive(raw) {
        try { activeWorkspace = JSON.parse(raw) } catch (error) { activeWorkspace = ({}) }
    }

    Component.onCompleted: refresh()
}
