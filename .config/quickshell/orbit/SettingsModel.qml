import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/orbit-settings"
    property bool settingsVisible: false
    property bool loaded: false
    property bool dirty: false
    property bool applyConfirmationVisible: false
    property bool unsavedConfirmationVisible: false
    property int applyCountdown: 0
    property string status: ""
    property var activeSettings: ({})
    property var draft: ({})
    property var menu: []
    property var palettes: []
    property var monitors: []
    property var displayProfiles: []
    property var applicationPolicies: ({})
    property var applicationIdentities: ({})
    readonly property var applications: DesktopEntries.applications.values
    property var clients: []
    property bool matchDialogVisible: false
    property string matchApplication: ""
    property int matchRuleIndex: -1
    property string matchError: ""
    property var matchCandidates: []
    property real matchSecondsRemaining: 0
    property var matchBaseline: ({})
    property var matchLaunchDesktop: null
    property int selectedMonitorIndex: 0
    property var capabilities: ({})

    FileView {
        id: stateFile
        path: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/orbit/settings-visible"
        watchChanges: true
        onLoaded: root.reloadVisibility()
        onFileChanged: reload()
    }

    Process {
        id: snapshotProcess
        command: [root.helper, "snapshot"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.loadSnapshot(text)
        }
    }

    Process {
        id: clientProcess
        command: ["hyprctl", "clients", "-j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.finishClientPoll(text)
        }
    }

    Timer {
        id: matchTimer
        interval: 400
        repeat: true
        onTriggered: root.pollMatch()
    }

    Timer {
        id: matchLaunchTimer
        interval: 150
        repeat: false
        onTriggered: if (root.matchLaunchDesktop) {
            root.matchLaunchDesktop.execute()
            root.matchLaunchDesktop = null
        }
    }

    Timer {
        id: applyConfirmationTimer
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.applyCountdown <= 1) {
                root.cancelApply()
            } else {
                root.applyCountdown -= 1
            }
        }
    }

    Process {
        id: applyProcess
        command: [root.helper, "apply", "{}"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.finishApply(text)
        }
    }

    function clone(value) {
        return JSON.parse(JSON.stringify(value || {}))
    }

    function reloadVisibility() {
        settingsVisible = stateFile.text().trim() === "1"
    }

    function open() {
        Quickshell.execDetached([helper, "open"])
    }

    function close() {
        Quickshell.execDetached([helper, "close"])
    }

    function requestClose() {
        if (dirty) {
            unsavedConfirmationVisible = true
            return
        }
        close()
    }

    function cancelClose() {
        unsavedConfirmationVisible = false
    }

    function discardAndClose() {
        unsavedConfirmationVisible = false
        cancel()
        close()
    }

    function refresh() {
        if (!snapshotProcess.running)
            snapshotProcess.running = true
    }

    function loadSnapshot(raw) {
        try {
            var value = JSON.parse(raw)
            activeSettings = value.settings || {}
            activeSettings.system = value.system || {}
            activeSettings.display_profiles = value.display_profiles || []
            activeSettings.application_policies = value.application_policies || { defaults: {}, rules: [] }
            draft = clone(activeSettings)
            menu = value.menu || []
            palettes = value.palettes || []
            monitors = value.monitors || []
            displayProfiles = value.display_profiles || []
            applicationPolicies = value.application_policies || { defaults: {}, rules: [] }
            applicationIdentities = value.application_identities || {}
            clients = value.clients || []
            selectedMonitorIndex = Math.max(0, Math.min(selectedMonitorIndex, displayProfiles.length - 1))
            capabilities = value.capabilities || {}
            dirty = false
            loaded = true
            status = ""
        } catch (error) {
            status = "Could not load Orbit settings"
        }
    }

    function setThemePalette(value) {
        var next = clone(draft)
        if (!next.theme)
            next.theme = {}
        next.theme.palette = value
        draft = next
        dirty = true
    }

    function setXmbFullscreen(value) {
        var next = clone(draft)
        if (!next.shell)
            next.shell = {}
        next.shell.xmb_fullscreen = value
        draft = next
        dirty = true
    }

    function setAudioVolume(value) {
        var next = clone(draft)
        if (!next.system) next.system = {}
        if (!next.system.audio) next.system.audio = {}
        next.system.audio.volume = value
        draft = next
        dirty = true
    }

    function setAudioMuted(value) {
        var next = clone(draft)
        if (!next.system) next.system = {}
        if (!next.system.audio) next.system.audio = {}
        next.system.audio.muted = value
        draft = next
        dirty = true
    }

    function setNetworkConnection(value) {
        var next = clone(draft)
        if (!next.system) next.system = {}
        if (!next.system.network) next.system.network = {}
        next.system.network.connection = value
        draft = next
        dirty = true
    }

    function setBluetoothDevice(address, connected) {
        var next = clone(draft)
        if (!next.system) next.system = {}
        next.system.bluetooth = { address: address, connected: connected }
        draft = next
        dirty = true
    }

    function setPowerProfile(value) {
        var next = clone(draft)
        if (!next.system) next.system = {}
        next.system.power = { profile: value }
        draft = next
        dirty = true
    }

    function setDisplayRole(role, monitor) {
        var next = clone(draft)
        if (!next.displays) next.displays = {}
        next.displays[role] = {
            connector: monitor.name || "",
            serial: monitor.serial || "",
            make: monitor.make || "",
            model: monitor.model || "",
            description: monitor.description || "",
            mode: monitor.width + "x" + monitor.height + "@" + Number(monitor.refreshRate).toFixed(2),
            position: (monitor.x || 0) + "x" + (monitor.y || 0),
            scale: monitor.scale || 1.0
        }
        draft = next
        dirty = true
    }

    function setDisplayField(role, field, value) {
        var next = clone(draft)
        if (!next.displays) next.displays = {}
        if (!next.displays[role]) next.displays[role] = {}
        next.displays[role][field] = value
        draft = next
        dirty = true
    }

    function selectMonitor(index) {
        if (index >= 0 && index < displayProfiles.length)
            selectedMonitorIndex = index
    }

    function selectedProfile() {
        return (draft.display_profiles && draft.display_profiles[selectedMonitorIndex]) || displayProfiles[selectedMonitorIndex] || {}
    }

    function setProfileField(field, value) {
        var next = clone(draft)
        if (!next.display_profiles) next.display_profiles = clone(displayProfiles)
        if (!next.display_profiles[selectedMonitorIndex]) return
        next.display_profiles[selectedMonitorIndex][field] = value
        draft = next
        dirty = true
    }

    function setProfileRole(role, enabled) {
        var profile = selectedProfile()
        var next = clone(draft)
        if (!next.displays) next.displays = {}
        if (enabled) {
            var existing = next.displays[role] || {}
            existing.connector = profile.connector || ""
            existing.serial = profile.serial || ""
            existing.make = profile.make || ""
            existing.model = profile.model || ""
            existing.description = profile.description || ""
            existing.mode = (profile.width || 0) + "x" + (profile.height || 0) + "@" + Number(profile.refresh_rate || 0).toFixed(2)
            existing.position = (profile.x || 0) + "x" + (profile.y || 0)
            existing.active = profile.active !== false
            existing.adaptive_sync = profile.adaptive_sync === true
            next.displays[role] = existing
        } else if (next.displays[role] && next.displays[role].connector === profile.connector) {
            delete next.displays[role]
        }
        draft = next
        dirty = true
    }

    function setApplicationDefaults(field, value) {
        var next = clone(draft)
        if (!next.application_policies) next.application_policies = { defaults: {}, rules: [] }
        if (!next.application_policies.defaults) next.application_policies.defaults = {}
        next.application_policies.defaults[field] = value
        draft = next
        dirty = true
    }

    function setApplicationRule(index, field, value) {
        var next = clone(draft)
        if (!next.application_policies || !next.application_policies.rules[index]) return
        next.application_policies.rules[index][field] = value
        draft = next
        dirty = true
    }

    function addApplicationRule() {
        addApplicationRuleFor("", "simple")
    }

    function addApplicationRuleFor(application, kind) {
        var next = clone(draft)
        if (!next.application_policies) next.application_policies = { defaults: {}, rules: [] }
        if (!next.application_policies.rules) next.application_policies.rules = []
        var classes = knownClasses(application)
        next.application_policies.rules.push({
            id: "rule-" + Date.now(),
            application: application || "",
            name: kind === "custom" ? "New custom rule" : "New window rule",
            kind: kind || "simple",
            match_type: "class",
            match_mode: "regex",
            match_value: kind === "simple" && classes.length ? classPattern(classes[0]) : "",
            match_pattern: "",
            priority: 100,
            monitor_role: "",
            workspace_policy: "",
            children: "",
            inherit_exclude: "",
            custom_source: kind === "custom" ? "hl.window_rule({})" : ""
        })
        draft = next
        dirty = true
    }

    function setApplicationIdentity(application, field, value) {
        var next = clone(draft)
        if (!next.application_identities) next.application_identities = {}
        if (!next.application_identities[application]) next.application_identities[application] = { classes: [], titles: [], confidence: "observed" }
        next.application_identities[application][field] = value
        draft = next
        dirty = true
    }

    function addApplicationClass(application, className, confidence) {
        className = String(className || "").trim()
        if (!className) return
        var identity = clone((draft.application_identities || {})[application] || { classes: [], titles: [], confidence: "observed" })
        if (!identity.classes) identity.classes = []
        if (identity.classes.indexOf(className) < 0) identity.classes.push(className)
        identity.confidence = confidence || identity.confidence || "observed"
        setApplicationIdentity(application, "classes", identity.classes)
        setApplicationIdentity(application, "confidence", identity.confidence)
    }

    function knownClasses(application) {
        var identities = draft.application_identities || applicationIdentities || {}
        var identity = identities[application]
        return identity && identity.classes ? identity.classes : []
    }

    function identityConfidence(application) {
        var identities = draft.application_identities || applicationIdentities || {}
        var identity = identities[application]
        return identity ? String(identity.confidence || "observed") : ""
    }

    function matchingClients(application) {
        var classes = knownClasses(application)
        return clients.filter(function(client) { return classes.indexOf(client.class) >= 0 })
    }

    function classPattern(value) {
        return "^" + String(value || "").replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "$"
    }

    function beginApplicationMatch(application, ruleIndex) {
        var applicationId = String(application || "")
        if (!applicationId) {
            matchError = "Unable to match application. Select an installed application first."
            matchDialogVisible = true
            return
        }
        matchApplication = applicationId
        matchRuleIndex = ruleIndex === undefined ? -1 : ruleIndex
        matchError = ""
        matchCandidates = matchingClients(applicationId)
        if (matchCandidates.length) {
            matchDialogVisible = true
            return
        }
        matchBaseline = {}
        for (var index = 0; index < clients.length; index++) matchBaseline[clients[index].address] = true
        matchCandidates = []
        matchSecondsRemaining = 15
        matchDialogVisible = true
        matchTimer.start()
        var desktop = DesktopEntries.byId(applicationId) || DesktopEntries.heuristicLookup(applicationId)
        if (!desktop) {
            matchError = "Unable to launch application. Manually find the class using hyprctl or create a custom rule."
            matchTimer.stop()
            return
        }
        matchLaunchDesktop = desktop
        Quickshell.execDetached(["hyprctl", "dispatch", "workspace", "emptynm"])
        matchLaunchTimer.start()
        pollMatch()
    }

    function pollMatch() {
        if (!matchDialogVisible || matchCandidates.length) return
        if (!clientProcess.running) clientProcess.running = true
        matchSecondsRemaining = Math.max(0, matchSecondsRemaining - 0.4)
        if (matchSecondsRemaining <= 0) {
            matchTimer.stop()
            matchError = "Unable to match application. Manually find the class using hyprctl or create a custom rule."
        }
    }

    function finishClientPoll(raw) {
        try {
            var observed = JSON.parse(raw)
            clients = observed.filter(function(client) { return client.mapped && !client.hidden && client.class !== "org.quickshell" }).map(function(client) {
                return { address: client.address, class: client.class, title: client.title, pid: client.pid, workspace: client.workspace ? client.workspace.name : "", floating: client.floating, xwayland: client.xwayland }
            })
            if (!matchDialogVisible || matchCandidates.length) return
            var candidates = clients.filter(function(client) { return !matchBaseline[client.address] })
            if (candidates.length) {
                matchCandidates = candidates
                matchTimer.stop()
            }
        } catch (error) {
            if (matchDialogVisible) matchError = "Unable to watch windows. Manually find the class using hyprctl or create a custom rule."
        }
    }

    function selectApplicationMatch(candidate) {
        if (!candidate) return
        matchLaunchTimer.stop()
        matchLaunchDesktop = null
        addApplicationClass(matchApplication, candidate.class, "confirmed")
        if (matchRuleIndex >= 0)
            setApplicationRule(matchRuleIndex, "match_value", classPattern(candidate.class))
        matchDialogVisible = false
        matchError = ""
        matchCandidates = []
        matchRuleIndex = -1
    }

    function cancelApplicationMatch() {
        matchTimer.stop()
        matchLaunchTimer.stop()
        matchLaunchDesktop = null
        matchDialogVisible = false
        matchCandidates = []
        matchError = ""
        matchRuleIndex = -1
    }

    function removeApplicationRule(index) {
        var next = clone(draft)
        if (!next.application_policies || !next.application_policies.rules) return
        next.application_policies.rules.splice(index, 1)
        draft = next
        dirty = true
    }

    function cancel() {
        draft = clone(activeSettings)
        dirty = false
        status = ""
    }

    function requestApply() {
        if (!dirty)
            return
        applyCountdown = 10
        applyConfirmationVisible = true
        applyConfirmationTimer.start()
    }

    function cancelApply() {
        applyConfirmationTimer.stop()
        applyConfirmationVisible = false
        applyCountdown = 0
    }

    function confirmApply() {
        if (!dirty) {
            cancelApply()
            return
        }
        cancelApply()
        status = "Applying changes..."
        applyProcess.command = [helper, "apply", JSON.stringify({ settings: draft, baseline: activeSettings })]
        applyProcess.running = true
    }

    function finishApply(raw) {
        try {
            var result = JSON.parse(raw)
            if (!result.ok)
                throw new Error(result.error || "Apply failed")
            activeSettings = clone(draft)
            dirty = false
            status = "Applied. QuickShell will reload the updated settings."
            refresh()
        } catch (error) {
            status = "Apply failed: " + error.message
        }
    }

    Component.onCompleted: {
        reloadVisibility()
        refresh()
    }
}
