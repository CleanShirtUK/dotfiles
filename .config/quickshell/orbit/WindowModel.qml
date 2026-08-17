import Quickshell
import QtQuick

Item {
    id: root

    required property var snapshot
    readonly property var clients: snapshot.clients
}
