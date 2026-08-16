import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property var monitors: []
    readonly property string focusedName: {
        for (var index = 0; index < monitors.length; index++) {
            if (monitors[index].focused)
                return monitors[index].name
        }
        return ""
    }
    readonly property int focusedId: {
        for (var index = 0; index < monitors.length; index++) {
            if (monitors[index].focused)
                return monitors[index].id
        }
        return -1
    }

    Process {
        id: process
        command: ["hyprctl", "monitors", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.reload(text)
        }
    }

    Timer {
        interval: 1000
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
            monitors = JSON.parse(raw)
        } catch (error) {
            monitors = []
        }
    }

    Component.onCompleted: refresh()
}
