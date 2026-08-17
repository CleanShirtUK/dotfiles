import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    signal launcherActivated()

    required property var windowModel
    required property var monitorModel
    property var fallbackPinned: [
        { label: "Terminal", desktop: "org.wezfurlong.wezterm", class: "org.wezfurlong.wezterm" },
        { label: "Files", desktop: "org.gnome.Nautilus", class: "org.gnome.Nautilus", command: "nautilus --new-window" },
        { label: "Browser", desktop: "zen-browser", class: "zen" },
        { label: "Steam", desktop: "steam", class: "steam" },
        { label: "ProtonUp-Qt", desktop: "net.davidotek.pupgui2", class: "net.davidotek.pupgui2" },
        { label: "Music", desktop: "org.jeffvli.feishin", class: "feishin" }
    ]
    property var pinned: fallbackPinned
    property var pendingLaunches: ({})
    property int launchRevision: 0
    property int iconRevision: 0
    property int iconReconciliationAttempts: 0

    FileView {
        id: dockFile
        path: Quickshell.env("HOME") + "/.config/orbit/dock.json"
        blockLoading: true
        watchChanges: true
        onLoaded: root.reload()
        onFileChanged: reload()
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: root.reconcileLaunches()
    }

    Timer {
        id: iconReadinessTimer
        interval: 250
        running: true
        repeat: true
        onTriggered: root.reconcileIcons()
    }

    Connections {
        target: root.windowModel
        function onClientsChanged() { root.reconcileLaunches() }
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
        iconRevision
        if (item.desktop === "orbit-settings")
            return Quickshell.iconPath("settings-symbolic")
        var desktop = desktopFor(item.desktop)
        return desktop ? Quickshell.iconPath(desktop.icon) : ""
    }

    function reconcileIcons() {
        iconRevision++
        iconReconciliationAttempts++

        var unresolved = items().some(function(item) {
            if (item.desktop === "orbit-xmb" || item.desktop === "orbit-settings")
                return false
            return !root.iconPath(item)
        })
        if (!unresolved || iconReconciliationAttempts >= 40)
            iconReadinessTimer.stop()
    }

    function appClass(item) {
        return item.class || item.desktop
    }

    function isLaunching(item) {
        launchRevision
        return Boolean(pendingLaunches[item.desktop])
    }

    function beginLaunch(item) {
        var next = {}
        for (var key in pendingLaunches)
            next[key] = pendingLaunches[key]
        next[item.desktop] = Date.now()
        pendingLaunches = next
        launchRevision++
    }

    function reconcileLaunches() {
        var now = Date.now()
        var next = {}
        var changed = false
        for (var desktop in pendingLaunches) {
            var item = { desktop: desktop }
            var desktopEntry = desktopFor(desktop)
            var expectedClass = desktopEntry && desktopEntry.startupWMClass ? desktopEntry.startupWMClass : desktop
            var found = windowModel.clients.some(function(client) {
                return client.class === expectedClass || client.class === desktop
            })
            if (!found && now - pendingLaunches[desktop] < 10000)
                next[desktop] = pendingLaunches[desktop]
            else
                changed = true
        }
        if (changed) {
            pendingLaunches = next
            launchRevision++
        }
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
                dockIndex: result.length,
                label: match ? (match.title || pin.label) : pin.label,
                desktop: pin.desktop,
                class: pin.class,
                command: pin.command || "",
                address: match ? match.address : "",
                running: Boolean(match),
                pinned: true
            })
        }

        for (var clientIndex = 0; clientIndex < allClients.length; clientIndex++) {
            var client = allClients[clientIndex]
            if (usedAddresses.indexOf(client.address) >= 0 || usedClasses.indexOf(client.class) >= 0)
                continue

            usedClasses.push(client.class)
            result.push({
                dockIndex: result.length,
                label: client.title || client.class,
                desktop: client.class,
                class: client.class,
                address: client.address,
                running: true,
                pinned: false
            })
        }
        return result
    }

    function launch(item) {
        var desktop = desktopFor(item.desktop)
        var monitor = monitorModel.focusedName
        var workspace = ""
        for (var index = 0; index < monitorModel.monitors.length; index++) {
            var candidate = monitorModel.monitors[index]
            if (candidate.name === monitor && candidate.activeWorkspace)
                workspace = String(candidate.activeWorkspace.name || candidate.activeWorkspace.id)
        }
        var expectedClass = desktop && desktop.startupWMClass ? desktop.startupWMClass : appClass(item)
        var context = ["--monitor", monitor, "--workspace", workspace, "--class", expectedClass]
        var launchId = "orbit-" + Date.now() + "-" + (++launchRevision)
        if (desktop) {
            beginLaunch(item)
            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-app-observe", "launch", "--desktop", desktop.id || item.desktop, "--command", desktop.execString || "", "--launch-id", launchId])
            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-app-launch"].concat(context).concat(["--launch-id", launchId, desktop.execString || ""]))
        } else if (item.command) {
            beginLaunch(item)
            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-app-launch"].concat(context).concat([item.command]))
        }
    }

    function launchNewWindow(item) {
        var desktop = desktopFor(item.desktop)
        if (desktop)
            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-app-launch", desktop.execString || ""])
        else if (item.command)
            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-app-launch", item.command])
    }

    function close(item) {
        var expectedClass = appClass(item)
        windowModel.clients.forEach(function(client) {
            if (client.class === expectedClass) {
                var focus = "hl.dsp.focus({ window = \"address:" + client.address + "\" })"
                Quickshell.execDetached(["sh", "-lc", "hyprctl dispatch '" + focus + "' && hyprctl dispatch 'hl.dsp.window.close()'"])
            }
        })
    }

    function setPinned(item, value) {
        var action = value ? "pin" : "unpin"
        var command = [Quickshell.env("HOME") + "/.local/bin/orbit-dock", action, "--desktop", item.desktop]
        if (value)
            command = command.concat(["--class", appClass(item), "--label", item.label])
        Quickshell.execDetached(command)
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
            root.launcherActivated()
            return
        }
        if (item.address)
            focusClient(item.address)
        else
            launch(item)
    }

    Component.onCompleted: reload()
}
