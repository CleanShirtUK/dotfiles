import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    required property string helper
    required property var refreshCallback
    property var activeSettings: ({})
    property var draft: ({})
    property bool dirty: false
    property bool applyConfirmationVisible: false
    property bool unsavedConfirmationVisible: false
    property int applyCountdown: 0
    property string status: ""

    Timer {
        id: applyConfirmationTimer
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.applyCountdown <= 1)
                root.cancelApply()
            else
                root.applyCountdown -= 1
        }
    }

    Process {
        id: applyProcess
        running: false
        stdout: StdioCollector { onStreamFinished: root.finishApply(text) }
    }

    function clone(value) { return JSON.parse(JSON.stringify(value || {})) }

    function loadSnapshot(value) {
        activeSettings = value.settings || {}
        activeSettings.system = value.system || {}
        activeSettings.display_profiles = value.display_profiles || []
        activeSettings.application_policies = value.application_policies || { defaults: {}, rules: [] }
        draft = clone(activeSettings)
        dirty = false
        status = ""
    }

    function update(path, value) {
        var next = clone(draft)
        var target = next
        for (var index = 0; index < path.length - 1; index++) {
            if (!target[path[index]] || typeof target[path[index]] !== "object")
                target[path[index]] = {}
            target = target[path[index]]
        }
        target[path[path.length - 1]] = value
        draft = next
        dirty = true
    }

    function setThemePalette(value) { update(["theme", "palette"], value) }
    function setCustomPalette(name, label, colors) {
        var next = clone(draft)
        if (!next.theme) next.theme = {}
        next.theme.palette = name
        next.theme.custom = { base: activeSettings.theme ? activeSettings.theme.palette : "tokyo-night", label: label, colors: colors }
        draft = next
        dirty = true
    }
    function setAppearanceValue(section, key, value) { update(["appearance", section, key], value) }
    function setAnimationValue(group, key, value) { update(["appearance", "effects", "animations", group, key], value) }
    function setXmbFullscreen(value) { update(["shell", "xmb_fullscreen"], value) }
    function setAudioVolume(value) { update(["system", "audio", "volume"], value) }
    function setAudioMuted(value) { update(["system", "audio", "muted"], value) }
    function setNetworkConnection(value) { update(["system", "network", "connection"], value) }
    function setBluetoothDevice(address, connected) { update(["system", "bluetooth"], { address: address, connected: connected }) }
    function setPowerProfile(value) { update(["system", "power"], { profile: value }) }
    function setTunedProfile(value) { update(["system", "power", "profile"], value) }
    function setHypridleValue(key, value) { update(["system", "power", "hypridle", key], value) }
    function saveHypridle(values) { update(["system", "power", "hypridle"], values) }

    function setDisplayRole(role, monitor) {
        update(["displays", role], {
            connector: monitor.name || "", serial: monitor.serial || "", make: monitor.make || "",
            model: monitor.model || "", description: monitor.description || "",
            mode: monitor.width + "x" + monitor.height + "@" + Number(monitor.refreshRate).toFixed(2),
            position: (monitor.x || 0) + "x" + (monitor.y || 0), scale: monitor.scale || 1.0
        })
    }
    function setDisplayField(role, field, value) { update(["displays", role, field], value) }
    function setProfileField(index, field, value) {
        var next = clone(draft)
        if (!next.display_profiles) next.display_profiles = []
        if (!next.display_profiles[index]) return
        next.display_profiles[index][field] = value
        draft = next
        dirty = true
    }
    function setProfileRole(role, profile, enabled) {
        var next = clone(draft)
        if (!next.displays) next.displays = {}
        if (enabled) {
            var existing = next.displays[role] || {}
            existing.connector = profile.connector || ""; existing.serial = profile.serial || ""
            existing.make = profile.make || ""; existing.model = profile.model || ""
            existing.description = profile.description || ""
            existing.mode = (profile.width || 0) + "x" + (profile.height || 0) + "@" + Number(profile.refresh_rate || 0).toFixed(2)
            existing.position = (profile.x || 0) + "x" + (profile.y || 0)
            existing.active = profile.active !== false; existing.adaptive_sync = profile.adaptive_sync === true
            next.displays[role] = existing
        } else if (next.displays[role] && next.displays[role].connector === profile.connector) {
            delete next.displays[role]
        }
        draft = next; dirty = true
    }
    function setApplicationDefaults(field, value) { update(["application_policies", "defaults", field], value) }
    function setApplicationRule(index, field, value) {
        var next = clone(draft)
        if (!next.application_policies || !next.application_policies.rules[index]) return
        next.application_policies.rules[index][field] = value; draft = next; dirty = true
    }
    function addApplicationRule(rule) {
        var next = clone(draft)
        if (!next.application_policies) next.application_policies = { defaults: {}, rules: [] }
        if (!next.application_policies.rules) next.application_policies.rules = []
        next.application_policies.rules.push(rule); draft = next; dirty = true
    }
    function removeApplicationRule(index) {
        var next = clone(draft)
        if (!next.application_policies || !next.application_policies.rules) return
        next.application_policies.rules.splice(index, 1); draft = next; dirty = true
    }
    function setApplicationIdentity(application, field, value) {
        var next = clone(draft)
        if (!next.application_identities) next.application_identities = {}
        if (!next.application_identities[application]) next.application_identities[application] = { classes: [], titles: [], confidence: "observed" }
        next.application_identities[application][field] = value; draft = next; dirty = true
    }
    function cancel() { draft = clone(activeSettings); dirty = false; status = "" }
    function requestApply() {
        if (!dirty) return
        applyCountdown = 10; applyConfirmationVisible = true; applyConfirmationTimer.start()
    }
    function cancelApply() { applyConfirmationTimer.stop(); applyConfirmationVisible = false; applyCountdown = 0 }
    function confirmApply() {
        if (!dirty) { cancelApply(); return }
        cancelApply(); status = "Applying changes..."
        applyProcess.command = [helper, "apply", JSON.stringify({ settings: draft, baseline: activeSettings })]
        applyProcess.running = true
    }
    function finishApply(raw) {
        try {
            var result = JSON.parse(raw)
            if (!result.ok) throw new Error(result.error || "Apply failed")
            activeSettings = clone(draft); dirty = false
            status = "Applied. QuickShell will reload the updated settings."
            refreshCallback()
        } catch (error) { status = "Apply failed: " + error.message }
    }
}
