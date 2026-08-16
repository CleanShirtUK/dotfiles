import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    required property var windowModel
    property var fallbackPinned: [
        { label: "Terminal", desktop: "org.wezfurlong.wezterm", class: "org.wezfurlong.wezterm" },
        { label: "Files", desktop: "org.gnome.Nautilus", class: "org.gnome.Nautilus", command: "nautilus --new-window" },
        { label: "Browser", desktop: "zen-browser", class: "zen" },
        { label: "Steam", desktop: "steam", class: "steam" },
        { label: "ProtonUp-Qt", desktop: "net.davidotek.pupgui2", class: "net.davidotek.pupgui2" },
        { label: "Music", desktop: "org.jeffvli.feishin", class: "feishin" }
    ]
    property var pinned: fallbackPinned

    FileView {
        id: dockFile
        path: Quickshell.env("HOME") + "/.config/orbit/dock.json"
        blockLoading: true
        watchChanges: true
        onLoaded: root.reload()
        onFileChanged: reload()
    }

    function reload() {
        try {
            pinned = JSON.parse(dockFile.text()).pinned || fallbackPinned
        } catch (error) {
            pinned = fallbackPinned
        }
    }

    function pinnedClass(entry) {
        return entry.class || entry.desktop
    }

    function desktopFor(id) {
        return DesktopEntries.byId(id) || DesktopEntries.heuristicLookup(id)
    }

    function iconPath(item) {
        var desktop = desktopFor(item.desktop)
        return desktop ? Quickshell.iconPath(desktop.icon) : ""
    }

    function items() {
        var allClients = windowModel.clients
        var usedAddresses = []
        var usedClasses = []
        var result = []

        for (var pinIndex = 0; pinIndex < pinned.length; pinIndex++) {
            var pin = pinned[pinIndex]
            var matches = allClients.filter(function(client) {
                return client.class === root.pinnedClass(pin)
            })
            matches.sort(function(left, right) {
                return (left.focusHistoryID || 999999) - (right.focusHistoryID || 999999)
            })
            var match = matches.length > 0 ? matches[0] : null
            if (match)
                usedAddresses.push(match.address)
            usedClasses.push(root.pinnedClass(pin))
            result.push({
                label: match ? (match.title || pin.label) : pin.label,
                desktop: pin.desktop,
                class: pin.class,
                command: pin.command || "",
                address: match ? match.address : "",
                running: Boolean(match)
            })
        }

        for (var clientIndex = 0; clientIndex < allClients.length; clientIndex++) {
            var client = allClients[clientIndex]
            if (usedAddresses.indexOf(client.address) >= 0 || usedClasses.indexOf(client.class) >= 0)
                continue

            usedClasses.push(client.class)
            result.push({
                label: client.title || client.class,
                desktop: client.class,
                class: client.class,
                address: client.address,
                running: true
            })
        }
        return result
    }

    function launch(item) {
        var desktop = desktopFor(item.desktop)
        if (desktop) {
            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-app-observe", "launch", "--desktop", desktop.id || item.desktop, "--command", desktop.execString || ""])
            desktop.execute()
        } else if (item.command)
            Quickshell.execDetached(["sh", "-lc", item.command])
    }

    function focusClient(address) {
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ window = \"address:" + address + "\" })"])
    }

    function activate(item) {
        if (item.desktop === "orbit-settings") {
            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-settings", "open"])
            return
        }
        if (item.desktop === "orbit-xmb") {
            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-xmb", "toggle"])
            return
        }
        if (item.address)
            focusClient(item.address)
        else
            launch(item)
    }

    Component.onCompleted: reload()
}
