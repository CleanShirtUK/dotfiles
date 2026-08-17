import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    required property var windowModel
    required property var monitorModel
    property bool overviewVisible: false
    property int selectedWorkspaceIndex: 0
    property string originalAddress: ""
    property var workspaces: []
    property var workspaceMru: ({})
    property string activeWorkspaceName: ""
    property string activeWorkspaceMonitor: ""
    property int stateRevision: -1
    property bool altHeld: false
    property bool altObservedHeld: false
    property bool altReleaseArmed: false

    readonly property string statePath: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/orbit/overview-visible"
    readonly property string cyclePath: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/orbit/overview-cycle"
    readonly property string altStatePath: (Quickshell.env("XDG_RUNTIME_DIR") || ("/run/user/" + Quickshell.env("UID"))) + "/orbit/alt-held"
    property string lastCycleRequest: ""

    FileView {
        id: stateFile
        path: root.statePath
        blockLoading: true
        watchChanges: true
        onLoaded: root.reloadState()
        onFileChanged: reload()
    }

    Process {
        id: stateProcess
        command: ["cat", root.statePath]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.setState(text)
        }
    }

    Process {
        id: cycleProcess
        command: ["cat", root.cyclePath]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.handleCycleRequest(text)
        }
    }

    Process {
        id: activeWorkspaceProcess
        command: ["hyprctl", "activeworkspace", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.recordActiveWorkspace(text)
        }
    }

    Process {
        id: altStateProcess
        command: ["cat", root.altStatePath]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.handleAltState(text)
        }
    }

    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: {
            if (!stateProcess.running)
                stateProcess.running = true
            if (!cycleProcess.running)
                cycleProcess.running = true
            if (!activeWorkspaceProcess.running)
                activeWorkspaceProcess.running = true
            if (!altStateProcess.running)
                altStateProcess.running = true
        }
    }

    Timer {
        id: altReleaseGuard
        interval: 100
        repeat: false
        onTriggered: {
            if (!root.altHeld && root.overviewVisible)
                root.closeFromInput()
        }
    }

    Process {
        id: workspaceProcess
        command: ["hyprctl", "workspaces", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.reloadWorkspaces(text)
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    function refresh() {
        if (!workspaceProcess.running)
            workspaceProcess.running = true
    }

    function reloadState() {
        setState(stateFile.text())
    }

    function setState(raw) {
        var fields = raw.trim().split(/\s+/)
        var status = fields[0]
        var revision = fields.length > 1 ? parseInt(fields[1]) : 0
        if (status === "1")
            status = "open"
        if (status === "0")
            status = "closed"
        if (isNaN(revision) || revision < stateRevision)
            return
        stateRevision = revision
        var nextVisible = status === "open"
        if (nextVisible === overviewVisible)
            return
        overviewVisible = nextVisible
        if (nextVisible) {
            lastCycleRequest = ""
            selectFocused()
        } else {
            lastCycleRequest = ""
        }
    }

    function openFromTrigger() {
        if (overviewVisible)
            return
        lastCycleRequest = ""
        // Require a real helper press edge; a stale pre-trigger 0 must not
        // close the newly opened overlay.
        altObservedHeld = false
        altReleaseArmed = false
        altReleaseGuard.restart()
        selectFocused()
        overviewVisible = true
        Qt.callLater(root.focusSelectedWorkspace)
    }

    function cycleFromTrigger() {
        if (!overviewVisible) {
            openFromTrigger()
            return
        }
        cycle(1)
    }

    function closeFromTrigger() {
        altReleaseGuard.stop()
        altReleaseArmed = false
        overviewVisible = false
    }

    function closeFromInput() {
        altReleaseGuard.stop()
        altReleaseArmed = false
        overviewVisible = false
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-overview", "close-state"])
    }

    function handleAltState(raw) {
        var state = raw.trim()
        if (state !== "0" && state !== "1")
            return
        altHeld = state === "1"
        if (state === "1") {
            altObservedHeld = true
        } else if (state === "0" && overviewVisible && altObservedHeld) {
            closeFromInput()
        }
    }

    function handleCycleRequest(raw) {
        var request = raw.trim()
        if (!request || request === "0" || request === lastCycleRequest)
            return
        lastCycleRequest = request
        if (overviewVisible)
            cycle(1)
    }

    function reloadWorkspaces(raw) {
        try {
            workspaces = JSON.parse(raw).filter(function(workspace) {
                return !String(workspace.name || "").startsWith("special:")
            }).sort(function(left, right) {
                return left.id - right.id
            })
        } catch (error) {
            workspaces = []
        }
    }

    function recordActiveWorkspace(raw) {
        try {
            var active = JSON.parse(raw)
            var monitor = String(active.monitor || "")
            var name = String(active.name || "")
            if (!monitor || !name)
                return

            activeWorkspaceMonitor = monitor
            activeWorkspaceName = name

            var history = (workspaceMru[monitor] || []).slice()
            var existing = history.indexOf(name)
            if (existing >= 0)
                history.splice(existing, 1)
            history.unshift(name)

            var nextMru = {}
            for (var key in workspaceMru)
                nextMru[key] = workspaceMru[key]
            nextMru[monitor] = history
            workspaceMru = nextMru
        } catch (error) {
            return
        }
    }

    function items() {
        var monitor = monitorModel.focusedId
        return windowModel.clients.filter(function(client) {
            return client.monitor === monitor && client.workspace && client.workspace.id >= 0
        }).sort(function(left, right) {
            return (left.focusHistoryID === undefined ? 999999 : left.focusHistoryID)
                - (right.focusHistoryID === undefined ? 999999 : right.focusHistoryID)
        })
    }

    function workspaceItems() {
        var result = []
        var monitor = monitorModel.focusedName
        var monitorId = monitorModel.focusedId
        for (var index = 0; index < workspaces.length; index++) {
            var workspace = workspaces[index]
            if (workspace.monitor !== monitor)
                continue
            result.push({
                id: workspace.id,
                name: workspace.name,
                windows: windowModel.clients.filter(function(client) {
                    return client.monitor === monitorId && client.workspace && client.workspace.id === workspace.id
                })
            })
        }
        return result
    }

    function selectFocused() {
        var all = workspaceItems()
        originalAddress = ""

        var history = workspaceMru[activeWorkspaceMonitor] || []
        for (var historyIndex = 0; historyIndex < history.length; historyIndex++) {
            if (history[historyIndex] !== activeWorkspaceName) {
                for (var historyWorkspace = 0; historyWorkspace < all.length; historyWorkspace++) {
                    if (all[historyWorkspace].name === history[historyIndex]) {
                        selectedWorkspaceIndex = historyWorkspace
                        traceSelection(history)
                        return
                    }
                }
            }
        }

        for (var index = 0; index < all.length; index++) {
            if (all[index].name === activeWorkspaceName) {
                selectedWorkspaceIndex = index
                traceSelection(history)
                return
            }
        }
        selectedWorkspaceIndex = all.length > 0 ? 0 : -1
        traceSelection(history)
    }

    function traceSelection(history) {
        Quickshell.execDetached(["logger", "-t", "orbit-mru", "monitor=" + activeWorkspaceMonitor,
            "current=" + activeWorkspaceName, "history=" + history.join(","),
            "selected=" + selectedWorkspaceIndex])
    }

    function cycle(delta) {
        var all = workspaceItems()
        if (all.length === 0) {
            selectedWorkspaceIndex = -1
            return
        }
        if (selectedWorkspaceIndex < 0)
            selectedWorkspaceIndex = 0
        selectedWorkspaceIndex = (selectedWorkspaceIndex + delta + all.length) % all.length
        focusWorkspace(all[selectedWorkspaceIndex])
    }

    function focusWorkspace(workspace) {
        if (!workspace || !workspace.name)
            return
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-overview", "workspace", workspace.name])
    }

    function focusSelectedWorkspace() {
        var all = workspaceItems()
        if (selectedWorkspaceIndex >= 0 && selectedWorkspaceIndex < all.length)
            focusWorkspace(all[selectedWorkspaceIndex])
    }

    function activateSelected() {
        var all = workspaceItems()
        if (selectedWorkspaceIndex >= 0 && selectedWorkspaceIndex < all.length)
            focusWorkspace(all[selectedWorkspaceIndex])
        else
            close()
    }

    function selectWorkspace(index) {
        var all = workspaceItems()
        if (index < 0 || index >= all.length)
            return
        selectedWorkspaceIndex = index
        focusWorkspace(all[index])
    }

    function close() {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-overview", "close"])
    }

    Component.onCompleted: refresh()
}
