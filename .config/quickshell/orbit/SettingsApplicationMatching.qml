import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    required property var settingsModel
    required property var snapshot
    property var clients: []
    property bool matchDialogVisible: false
    property string matchApplication: ""
    property int matchRuleIndex: -1
    property string matchError: ""
    property var matchCandidates: []
    property real matchSecondsRemaining: 0
    property var matchBaseline: ({})
    property var matchLaunchDesktop: null

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

    function updateClientsFromSnapshot() {
        clients = (snapshot.clients || []).filter(function(client) {
            return client.mapped && !client.hidden && client.class !== "org.quickshell"
        }).map(function(client) {
            return { address: client.address, class: client.class, title: client.title,
                pid: client.pid, workspace: client.workspace ? client.workspace.name : "",
                floating: client.floating, xwayland: client.xwayland }
        })
        if (matchDialogVisible && !matchCandidates.length) {
            var candidates = clients.filter(function(client) { return !matchBaseline[client.address] })
            if (candidates.length) {
                matchCandidates = candidates
                matchTimer.stop()
            }
        }
    }

    function knownClasses(application) {
        var identities = settingsModel.draft.application_identities || settingsModel.applicationIdentities || {}
        var identity = identities[application]
        return identity && identity.classes ? identity.classes : []
    }

    function identityConfidence(application) {
        var identities = settingsModel.draft.application_identities || settingsModel.applicationIdentities || {}
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
        matchSecondsRemaining = Math.max(0, matchSecondsRemaining - 0.4)
        if (matchSecondsRemaining <= 0) {
            matchTimer.stop()
            matchError = "Unable to match application. Manually find the class using hyprctl or create a custom rule."
        }
    }

    function selectApplicationMatch(candidate) {
        if (!candidate) return
        matchLaunchTimer.stop()
        matchLaunchDesktop = null
        settingsModel.addApplicationClass(matchApplication, candidate.class, "confirmed")
        if (matchRuleIndex >= 0)
            settingsModel.setApplicationRule(matchRuleIndex, "match_value", classPattern(candidate.class))
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

    Component.onCompleted: updateClientsFromSnapshot()

    Connections {
        target: root.snapshot
        function onClientsChanged() { root.updateClientsFromSnapshot() }
    }
}
