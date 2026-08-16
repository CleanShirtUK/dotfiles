import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property var clients: []

    Process {
        id: process
        command: ["hyprctl", "clients", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.reload(text)
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    function refresh() {
        if (!process.running)
            process.running = true
    }

    function reload(raw) {
        try {
            clients = JSON.parse(raw).filter(function(client) {
                return client.mapped && !client.hidden && client.class !== "org.quickshell"
            })
        } catch (error) {
            clients = []
        }
    }

    Component.onCompleted: refresh()
}
