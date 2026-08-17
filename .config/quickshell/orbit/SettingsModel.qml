import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    required property var snapshot
    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/orbit-settings"
    property bool settingsVisible: false
    property bool loaded: false
    property alias dirty: draftLifecycle.dirty
    property alias applyConfirmationVisible: draftLifecycle.applyConfirmationVisible
    property alias unsavedConfirmationVisible: draftLifecycle.unsavedConfirmationVisible
    property alias applyCountdown: draftLifecycle.applyCountdown
    property alias status: draftLifecycle.status
    property alias systemActionStatus: systemActions.status
    property alias activeSettings: draftLifecycle.activeSettings
    property alias draft: draftLifecycle.draft
    property var menu: []
    property var palettes: []
    property var palettePreviews: ({})
    property var wallpaper: ({ mode: "shader" })
    property var monitors: []
    property var displayProfiles: []
    property var applicationPolicies: ({})
    property var applicationIdentities: ({})
    readonly property var applications: DesktopEntries.applications.values
    property alias clients: applicationMatching.clients
    property alias matchDialogVisible: applicationMatching.matchDialogVisible
    property alias matchApplication: applicationMatching.matchApplication
    property alias matchRuleIndex: applicationMatching.matchRuleIndex
    property alias matchError: applicationMatching.matchError
    property alias matchCandidates: applicationMatching.matchCandidates
    property alias matchSecondsRemaining: applicationMatching.matchSecondsRemaining
    property alias matchBaseline: applicationMatching.matchBaseline
    property alias matchLaunchDesktop: applicationMatching.matchLaunchDesktop
    property int selectedMonitorIndex: 0
    property var capabilities: ({})
    property string wallpaperServiceStatus: "unknown"

    SettingsSystemActions {
        id: systemActions
        helper: root.helper
        refreshCallback: root.refresh
    }

    SettingsApplicationMatching {
        id: applicationMatching
        settingsModel: root
        snapshot: root.snapshot
    }

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

    SettingsDraftLifecycle {
        id: draftLifecycle
        helper: root.helper
        refreshCallback: root.refresh
    }

    Process {
        id: wallpaperStatusProcess
        command: ["systemctl", "--user", "is-active", "ps3-wave-wallpaper.service"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.wallpaperServiceStatus = text.trim() || "unknown"
        }
    }

    Process {
        id: wallpaperRestartProcess
        command: ["systemctl", "--user", "restart", "ps3-wave-wallpaper.service"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper-animation", "intro"])
                root.refreshWallpaperService()
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.refreshWallpaperService()
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

    function refreshWallpaperService() {
        if (!wallpaperStatusProcess.running)
            wallpaperStatusProcess.running = true
    }

    function restartWallpaperService() {
        if (wallpaperRestartProcess.running)
            return
        wallpaperServiceStatus = "restarting"
        wallpaperRestartProcess.running = true
    }

    function close() {
        Quickshell.execDetached([helper, "close"])
    }

    function reloadOrbit() {
        Quickshell.execDetached(["systemctl", "--user", "restart", "orbit-shell.service"])
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
            draftLifecycle.loadSnapshot(value)
            menu = value.menu || []
            palettes = value.palettes || []
            palettePreviews = value.palette_previews || {}
            wallpaper = value.wallpaper || { mode: "shader" }
            monitors = value.monitors || []
            displayProfiles = value.display_profiles || []
            applicationPolicies = value.application_policies || { defaults: {}, rules: [] }
            applicationIdentities = value.application_identities || {}
            selectedMonitorIndex = Math.max(0, Math.min(selectedMonitorIndex, displayProfiles.length - 1))
            capabilities = value.capabilities || {}
            loaded = true
        } catch (error) {
            status = "Could not load Orbit settings"
        }
    }

    function setThemePalette(value) {
        draftLifecycle.setThemePalette(value)
    }

    function setCustomPalette(name, label, colors) {
        draftLifecycle.setCustomPalette(name, label, colors)
    }

    function setAppearanceValue(section, key, value) {
        draftLifecycle.setAppearanceValue(section, key, value)
    }

    function setAnimationValue(group, key, value) {
        draftLifecycle.setAnimationValue(group, key, value)
    }

    function setXmbFullscreen(value) {
        draftLifecycle.setXmbFullscreen(value)
    }

    function setAudioVolume(value) {
        draftLifecycle.setAudioVolume(value)
    }

    function setAudioMuted(value) {
        draftLifecycle.setAudioMuted(value)
    }

    function setNetworkConnection(value) {
        draftLifecycle.setNetworkConnection(value)
    }

    function setBluetoothDevice(address, connected) {
        draftLifecycle.setBluetoothDevice(address, connected)
    }

    function setPowerProfile(value) {
        draftLifecycle.setPowerProfile(value)
    }

    function setTunedProfile(value) {
        draftLifecycle.setTunedProfile(value)
    }

    function setHypridleValue(key, value) {
        draftLifecycle.setHypridleValue(key, value)
    }

    function saveHypridle(values) {
        draftLifecycle.saveHypridle(values)
    }

    function systemAction(action, payload) {
        systemActions.execute(action, payload)
    }

    function setDefaultAudioSink(id) { systemAction("audio-default", { id: id }) }
    function setDefaultAudioSource(id) { systemAction("audio-default", { id: id }) }
    function setAudioDeviceVolume(id, value, input) { systemAction(input ? "audio-input-volume" : "audio-volume", { id: id, volume: value }) }
    function setAudioDeviceMuted(id, value, input) { systemAction(input ? "audio-input-mute" : "audio-mute", { id: id, muted: value }) }
    function activateNetwork(name) { systemAction("network-up", { name: name }) }
    function deactivateNetwork(name) { systemAction("network-down", { name: name }) }
    function networkProfileSave(name, values) { systemAction("network-profile-save", { name: name, values: values }) }
    function networkProfileAdd(name, type, ssid) { systemAction("network-profile-add", { name: name, type: type, ssid: ssid }) }
    function networkProfileDelete(name) { systemAction("network-profile-delete", { name: name }) }
    function scanWifi() { systemAction("network-wifi-scan", {}) }
    function connectWifi(ssid, password, device) { systemAction("network-wifi-connect", { ssid: ssid, password: password, device: device }) }
    function connectBluetooth(address) { systemAction("bluetooth-connect", { address: address }) }
    function disconnectBluetooth(address) { systemAction("bluetooth-disconnect", { address: address }) }
    function setBluetoothPower(value) { systemAction("bluetooth-power", { powered: value }) }
    function setBluetoothScanning(value) { systemAction("bluetooth-scan", { discovering: value }) }
    function pairBluetooth(address) { systemAction("bluetooth-pair", { address: address }) }
    function trustBluetooth(address, value) { systemAction(value ? "bluetooth-trust" : "bluetooth-untrust", { address: address }) }
    function blockBluetooth(address, value) { systemAction(value ? "bluetooth-block" : "bluetooth-unblock", { address: address }) }
    function setBluetoothPairable(value) { systemAction("bluetooth-pairable", { enabled: value }) }
    function setBluetoothDiscoverable(value) { systemAction("bluetooth-discoverable", { enabled: value }) }
    function removeBluetooth(address) { systemAction("bluetooth-remove", { address: address }) }

    function setDisplayRole(role, monitor) {
        draftLifecycle.setDisplayRole(role, monitor)
    }

    function setDisplayField(role, field, value) {
        draftLifecycle.setDisplayField(role, field, value)
    }

    function selectMonitor(index) {
        if (index >= 0 && index < displayProfiles.length)
            selectedMonitorIndex = index
    }

    function selectedProfile() {
        return (draft.display_profiles && draft.display_profiles[selectedMonitorIndex]) || displayProfiles[selectedMonitorIndex] || {}
    }

    function setProfileField(field, value) {
        draftLifecycle.setProfileField(selectedMonitorIndex, field, value)
    }

    function setProfileRole(role, enabled) {
        draftLifecycle.setProfileRole(role, selectedProfile(), enabled)
    }

    function setApplicationDefaults(field, value) {
        draftLifecycle.setApplicationDefaults(field, value)
    }

    function setApplicationRule(index, field, value) {
        draftLifecycle.setApplicationRule(index, field, value)
    }

    function addApplicationRule() {
        addApplicationRuleFor("", "simple")
    }

    function addApplicationRuleFor(application, kind) {
        var classes = applicationMatching.knownClasses(application)
        draftLifecycle.addApplicationRule({
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
    }

    function setApplicationIdentity(application, field, value) {
        draftLifecycle.setApplicationIdentity(application, field, value)
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

    // Compatibility wrappers keep the settings surface API stable while the
    // application-matching state owns its timers and client snapshot.
    function knownClasses(application) { return applicationMatching.knownClasses(application) }
    function identityConfidence(application) { return applicationMatching.identityConfidence(application) }
    function matchingClients(application) { return applicationMatching.matchingClients(application) }
    function classPattern(value) { return applicationMatching.classPattern(value) }
    function beginApplicationMatch(application, ruleIndex) { applicationMatching.beginApplicationMatch(application, ruleIndex) }
    function pollMatch() { applicationMatching.pollMatch() }
    function selectApplicationMatch(candidate) { applicationMatching.selectApplicationMatch(candidate) }
    function cancelApplicationMatch() { applicationMatching.cancelApplicationMatch() }

    function removeApplicationRule(index) {
        draftLifecycle.removeApplicationRule(index)
    }

    function cancel() {
        draftLifecycle.cancel()
    }

    function requestApply() {
        draftLifecycle.requestApply()
    }

    function cancelApply() {
        draftLifecycle.cancelApply()
    }

    function confirmApply() {
        draftLifecycle.confirmApply()
    }

    function finishApply(raw) {
        draftLifecycle.finishApply(raw)
    }

    Component.onCompleted: {
        reloadVisibility()
        refresh()
        refreshWallpaperService()
    }

}
