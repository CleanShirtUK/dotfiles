import Quickshell
import QtQuick

Item {
    id: root

    required property var snapshot
    readonly property var monitors: snapshot.monitors
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

}
