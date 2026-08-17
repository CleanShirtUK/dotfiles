import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    required property string helper
    required property var refreshCallback
    property string status: ""

    Process {
        id: actionProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.finish(text)
        }
    }

    function execute(action, payload) {
        if (actionProcess.running)
            return
        status = "Applying " + action + "..."
        actionProcess.command = [helper, "action", action, JSON.stringify(payload || {})]
        actionProcess.running = true
    }

    function finish(raw) {
        try {
            var result = JSON.parse(raw)
            if (!result.ok)
                throw new Error(result.error || "Action failed")
            status = ""
            refreshCallback()
        } catch (error) {
            status = "Action failed: " + error.message
            refreshCallback()
        }
    }
}
