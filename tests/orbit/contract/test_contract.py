#!/usr/bin/env python3
"""Deterministic Orbit contract tests; never mutate the live configuration."""

from __future__ import annotations

import importlib.machinery
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HOME = ROOT
BIN = HOME / ".local/bin"
RESULTS = []

REQUIRED_EXECUTABLES = (
    BIN / "phleg-quickshell",
    BIN / "orbit-app-launch",
    BIN / "orbit-app-observe",
    BIN / "orbit-app-policy",
    BIN / "orbit-appmenu",
    BIN / "orbit-appmenu-atspi",
    BIN / "orbit-dock",
    BIN / "orbit-edit-desktop",
    BIN / "orbit-input-state",
    BIN / "orbit-monitor",
    BIN / "orbit-overview",
    BIN / "orbit-settings",
    BIN / "orbit-shell",
    BIN / "orbit-shell-ui",
    BIN / "orbit-theme",
    BIN / "orbit-xmb",
)
REQUIRED_LIBRARIES = (
    HOME / ".local/lib/orbit-state",
    HOME / ".local/lib/orbit_settings_actions.py",
    HOME / ".local/lib/orbit_settings_artifacts.py",
    HOME / ".local/lib/orbit_settings_persistence.py",
    HOME / ".local/lib/orbit_settings_runtime.py",
    HOME / ".local/lib/orbit_settings_validation.py",
)
REQUIRED_SERVICES = (
    HOME / ".config/systemd/user/orbit-input-state.service",
    HOME / ".config/systemd/user/orbit-shell.service",
)
REQUIRED_FILES = (
    HOME / "orbit/project-manifest.json",
    HOME / "tests/orbit/validate-project.py",
    HOME / ".config/orbit/app-policies.toml",
    HOME / ".config/orbit/application-identities.toml",
    HOME / ".config/orbit/dock.json",
    HOME / ".config/orbit/hypridle-defaults.toml",
    HOME / ".config/orbit/input-devices.toml",
    HOME / ".config/orbit/settings-menu.toml",
    HOME / ".config/orbit/settings.toml",
    HOME / ".config/orbit/xmb.json",
    HOME / ".config/quickshell/orbit/shell.qml",
)


def load(name: str, path: Path):
    loader = importlib.machinery.SourceFileLoader(name, str(path))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def check(name: str, function):
    try:
        function()
    except Exception as error:  # noqa: BLE001 - the result must identify the failing check
        RESULTS.append({"id": name, "status": "FAIL", "error": repr(error)})
    else:
        RESULTS.append({"id": name, "status": "PASS"})


def test_files_and_syntax():
    required = REQUIRED_EXECUTABLES + REQUIRED_LIBRARIES + REQUIRED_SERVICES + REQUIRED_FILES
    missing = [str(path.relative_to(HOME)) for path in required if not path.is_file()]
    assert not missing, f"missing required Orbit files: {missing}"
    not_executable = [str(path.relative_to(HOME)) for path in REQUIRED_EXECUTABLES if not os.access(path, os.X_OK)]
    assert not not_executable, f"Orbit helpers are not executable: {not_executable}"

    for path in REQUIRED_EXECUTABLES:
        source = path.read_text()
        if source.startswith("#!/usr/bin/env python3"):
            compile(source, str(path), "exec")
        elif source.startswith("#!/bin/sh"):
            subprocess.run(["sh", "-n", str(path)], check=True, capture_output=True, text=True)
    for path in REQUIRED_LIBRARIES:
        source = path.read_text()
        if path.suffix == ".py":
            compile(source, str(path), "exec")
        else:
            subprocess.run(["sh", "-n", str(path)], check=True, capture_output=True, text=True)
    for path in (HOME / ".config/orbit").rglob("*.toml"):
        tomllib.loads(path.read_text())
    for path in (HOME / ".config/orbit").rglob("*.json"):
        json.loads(path.read_text())

    settings = tomllib.loads((HOME / ".config/orbit/settings.toml").read_text())
    generated_appearance = json.loads(
        (HOME / ".config/orbit/generated/appearance.json").read_text()
    )
    assert generated_appearance == settings["appearance"], (
        "generated appearance does not match canonical settings.toml"
    )

    policies = tomllib.loads((HOME / ".config/orbit/app-policies.toml").read_text())
    artifacts = load(
        "orbit_settings_artifacts_static", BIN.parent / "lib/orbit_settings_artifacts.py"
    )
    with tempfile.TemporaryDirectory() as temporary:
        expected_rules = Path(temporary) / "orbit-window-rules.lua"
        artifacts.write_window_rules(policies.get("rule", []), expected_rules)
        assert expected_rules.read_text() == (
            HOME / ".config/hypr/orbit-window-rules.lua"
        ).read_text(), "generated window rules do not match app-policies.toml"


def test_delayed_launch_context_contract():
    launcher = (BIN / "orbit-app-launch").read_text()
    application = (HOME / ".config/quickshell/orbit/ApplicationModel.qml").read_text()
    xmb = (HOME / ".config/quickshell/orbit/XmbModel.qml").read_text()
    assert "--monitor" in launcher and "--workspace" in launcher
    assert "movetoworkspacesilent" in launcher
    assert "--class" in launcher and "before=$(hyprctl clients -j" in launcher
    assert 'monitorModel.focusedName' in application
    assert 'monitorModel.focusedName' in xmb


def test_dock_and_xmb_share_launch_observation_boundary():
    launcher = BIN / "orbit-app-launch"
    observer = BIN / "orbit-app-observe"
    application = (HOME / ".config/quickshell/orbit/ApplicationModel.qml").read_text()
    xmb = (HOME / ".config/quickshell/orbit/XmbModel.qml").read_text()
    assert launcher.exists() and observer.exists()
    assert "orbit-app-launch" in application
    assert "orbit-app-observe" in application
    assert "orbit-app-launch" in xmb
    assert "orbit-app-observe" in xmb
    assert "systemd-run --user --scope --collect --quiet" in launcher.read_text()
    assert "record_launch" in observer.read_text()


def test_concurrent_launch_correlation_contract():
    launcher = (BIN / "orbit-app-launch").read_text()
    observer = (BIN / "orbit-app-observe").read_text()
    application = (HOME / ".config/quickshell/orbit/ApplicationModel.qml").read_text()
    xmb = (HOME / ".config/quickshell/orbit/XmbModel.qml").read_text()
    assert "--launch-id" in launcher and "--launch-id" in observer
    assert 'record.get("id")' in observer and '== launch_id' in observer
    assert "--address" in observer and "--pid" in observer
    assert "ORBIT_LAUNCH_ID" in launcher and "/proc/$candidate_pid/environ" in launcher
    assert 'var launchId = "orbit-"' in application
    assert 'var launchId = "orbit-"' in xmb
    assert '"--launch-id", launchId' in application
    assert '"--launch-id", launchId' in xmb


def test_dock_xmb_handoff_releases_keyboard_focus_guard():
    shell = (HOME / ".config/quickshell/orbit/shell.qml").read_text()
    assert "WlrLayershell.keyboardFocus: root.xmbVisible && !root.dockMorphing" in shell
    assert "root.dockHandoff = true" in shell
    handoff = shell.index("root.dockHandoff = true")
    assert shell.index("root.dockMorphing = false", handoff) > handoff


def test_dock_boundary_magnification_uses_animated_hover_ramp():
    shell = (HOME / ".config/quickshell/orbit/shell.qml").read_text()
    assert "property real hoverAmount: 0" in shell
    assert "Behavior on hoverAmount" in shell
    assert "NumberAnimation { duration: 140" in shell
    assert "scaleAt(itemCenter)" in shell


def test_shared_hyprland_snapshot_contract():
    snapshot = (HOME / ".config/quickshell/orbit/HyprlandModel.qml").read_text()
    monitor = (HOME / ".config/quickshell/orbit/MonitorModel.qml").read_text()
    window = (HOME / ".config/quickshell/orbit/WindowModel.qml").read_text()
    overview = (HOME / ".config/quickshell/orbit/OverviewModel.qml").read_text()
    shell = (HOME / ".config/quickshell/orbit/shell.qml").read_text()
    assert all(command in snapshot for command in (
        '"hyprctl", "monitors", "-j"',
        '"hyprctl", "clients", "-j"',
        '"hyprctl", "workspaces", "-j"',
        '"hyprctl", "activeworkspace", "-j"',
    ))
    assert 'command: ["hyprctl"' not in monitor
    assert 'command: ["hyprctl"' not in window
    assert 'command: ["hyprctl"' not in overview
    assert "HyprlandModel { id: hyprlandModel }" in shell
    assert "snapshot: hyprlandModel" in shell


def test_settings_uses_shared_hyprland_clients_contract():
    settings = (HOME / ".config/quickshell/orbit/SettingsModel.qml").read_text()
    matching = (HOME / ".config/quickshell/orbit/SettingsApplicationMatching.qml").read_text()
    shell = (HOME / ".config/quickshell/orbit/shell.qml").read_text()
    assert "required property var snapshot" in settings
    assert "SettingsApplicationMatching {" in settings
    assert "target: root.snapshot" in matching
    assert "function onClientsChanged() { root.updateClientsFromSnapshot() }" in matching
    assert 'command: ["hyprctl", "clients", "-j"]' not in settings
    assert "SettingsModel { id: settingsModel; snapshot: hyprlandModel }" in shell


def test_settings_system_actions_have_a_narrow_owner():
    settings = (HOME / ".config/quickshell/orbit/SettingsModel.qml").read_text()
    actions = (HOME / ".config/quickshell/orbit/SettingsSystemActions.qml").read_text()
    assert "SettingsSystemActions {" in settings
    assert "refreshCallback: root.refresh" in settings
    assert "systemActions.execute(action, payload)" in settings
    assert 'actionProcess.command = [helper, "action", action' in actions
    assert "refreshCallback()" in actions
    assert "systemActionProcess" not in settings


def test_settings_draft_lifecycle_has_a_narrow_owner():
    settings = (HOME / ".config/quickshell/orbit/SettingsModel.qml").read_text()
    lifecycle = (HOME / ".config/quickshell/orbit/SettingsDraftLifecycle.qml").read_text()
    assert "SettingsDraftLifecycle {" in settings
    assert "property alias draft: draftLifecycle.draft" in settings
    assert "property alias activeSettings: draftLifecycle.activeSettings" in settings
    assert "draftLifecycle.requestApply()" in settings
    assert "draftLifecycle.confirmApply()" in settings
    assert "function loadSnapshot(value)" in lifecycle
    assert "function cancel()" in lifecycle
    assert 'command = [helper, "apply", JSON.stringify({ settings: draft, baseline: activeSettings })]' in lifecycle
    assert "applyConfirmationTimer" in lifecycle


def test_settings_runtime_observation_has_a_narrow_owner():
    settings = (BIN / "orbit-settings").read_text()
    runtime = (HOME / ".local/lib/orbit_settings_runtime.py").read_text()
    assert "import orbit_settings_runtime" in settings
    assert "orbit_settings_runtime.system_snapshot(HYPRIDLE, HYPRIDLE_DEFAULTS)" in settings
    for function in (
        "parse_audio_status",
        "parse_nmcli_connections",
        "parse_nmcli_devices",
        "parse_nmcli_wifi",
        "parse_bluetooth",
        "tuned_settings",
    ):
        assert f"def {function}" in runtime


def test_settings_application_matching_has_a_narrow_owner():
    settings = (HOME / ".config/quickshell/orbit/SettingsModel.qml").read_text()
    matching = (HOME / ".config/quickshell/orbit/SettingsApplicationMatching.qml").read_text()
    assert "SettingsApplicationMatching {" in settings
    assert "id: applicationMatching" in settings
    assert "property alias clients: applicationMatching.clients" in settings
    assert "function beginApplicationMatch" in matching
    assert "function updateClientsFromSnapshot" in matching
    assert "applicationMatchProcess" not in settings


def test_startup_contract():
    hyprland = (HOME / ".config/hypr/hyprland.lua").read_text()
    transition = (HOME / ".config/hypr/scripts/wallpaper-session-effects").read_text()
    animation = (HOME / ".config/hypr/scripts/wallpaper-animation").read_text()
    assert 'orbit-xmb toggle' in hyprland
    assert 'reserved-workspace-anchors' not in hyprland
    assert 'noctalia.service' not in hyprland
    assert "hyprctl reload config-only; systemctl --user restart orbit-shell.service" in hyprland
    assert 'noctalia msg' not in transition
    assert 'noctalia msg' not in animation
    assert not (HOME / ".config/systemd/user/noctalia.service").exists()
    assert not (HOME / ".config/systemd/user/reserved-workspace-anchors.service").exists()
    assert not (HOME / ".config/hypr/scripts/reserved-workspace-xmb.qml").exists()


def test_shell_duplicate_and_startup_readiness_contract():
    shell = (BIN / "orbit-shell").read_text()
    assert 'for _ in $(seq 1 60); do' in shell
    assert 'WAYLAND_DISPLAY' in shell
    assert 'HYPRLAND_INSTANCE_SIGNATURE' in shell
    assert 'command -v hyprctl' in shell
    assert 'Orbit overview bindings were not installed; refusing to start the shell.' in shell
    assert 'exec "$HOME/.local/bin/phleg-quickshell" --no-duplicate' in shell
    assert shell.index('for _ in $(seq 1 30); do') < shell.index('exec "$HOME/.local/bin/phleg-quickshell"')
    assert 'Orbit requires a Hyprland Wayland session environment.' in shell


def test_input_focus_contract():
    settings = tomllib.loads((HOME / ".config/orbit/settings.toml").read_text())
    hyprland = (HOME / ".config/hypr/hyprland.lua").read_text()
    assert settings["input"]["follow_mouse"] == 2
    assert "function orbit_follow_mouse()" in hyprland
    assert 'settings.toml", "r"' in hyprland
    assert 'line:match("^%s*follow_mouse%s*=%s*(%d+)")' in hyprland
    assert "follow_mouse = orbitFollowMouse" in hyprland


def test_session_shutdown_confirmation_contract():
    shutdown = (HOME / ".config/hypr/scripts/animate-shutdown").read_text()
    assert "command -v zenity" in shutdown
    assert "zenity --question" in shutdown
    assert "--ok-label='End session'" in shutdown
    assert "--cancel-label='Cancel'" in shutdown
    assert shutdown.index("zenity --question") < shutdown.index("blank-special-workspaces")
    assert 'loginctl terminate-session "${XDG_SESSION_ID:?}"' in shutdown


def test_application_scope_contract():
    launcher = (BIN / "orbit-app-launch").read_text()
    application = (HOME / ".config/quickshell/orbit/ApplicationModel.qml").read_text()
    xmb = (HOME / ".config/quickshell/orbit/XmbModel.qml").read_text()
    assert "systemd-run --user --scope --collect --quiet" in launcher
    assert '/bin/sh -lc "$command"' in launcher
    assert "orbit-app-launch" in application
    assert "orbit-app-launch" in xmb
    assert "desktop.execute()" not in application
    assert "app.execute()" not in xmb


def test_desktop_exec_field_codes_are_not_passed_as_paths():
    launcher = BIN / "orbit-app-launch"
    with tempfile.TemporaryDirectory() as directory:
        fake_bin = Path(directory) / "bin"
        fake_bin.mkdir()
        fake_runner = fake_bin / "systemd-run"
        fake_runner.write_text("#!/bin/sh\nprintf '%s\\n' \"$@\"\n")
        fake_runner.chmod(0o755)
        result = subprocess.run(
            [str(launcher), "nautilus --new-window %U"],
            env={**os.environ, "PATH": f"{fake_bin}:{os.environ['PATH']}"},
            text=True,
            capture_output=True,
            check=True,
        )
        assert "%U" not in result.stdout
        assert "nautilus --new-window  " in result.stdout


def test_input_helper_permission_contract():
    service = (HOME / ".config/systemd/user/orbit-input-state.service").read_text()
    helper = (BIN / "orbit-input-state").read_text()
    devices = (HOME / ".config/orbit/input-devices.toml").read_text()
    assert "ExecStart=/usr/bin/sg input -c %h/.local/bin/orbit-input-state" in service
    assert "pyudev" in helper
    assert "ID_INPUT_KEYBOARD" in helper
    assert "ID_SERIAL" in helper
    assert "glob.glob(\"/dev/input/event*\")" not in helper
    assert '"DZTECH_DZ65RGBV3"' in devices
    assert '"Logitech_USB_Receiver"' in devices


def test_overview_binding_contract():
    shell = (BIN / "orbit-shell").read_text()
    assert 'hl.bind(\\"ALT + TAB\\", hl.dsp.exec_cmd(\\"$overview cycle\\"), { repeating = false })' in shell
    assert "for _ in $(seq 1 30)" in shell
    assert "bindings_ready()" in shell
    assert "grep -q '^[[:space:]]*key: TAB$'" in shell
    assert 'hl.bind(\\"Alt_L\\"' not in shell
    assert 'hl.bind(\\"Alt_R\\"' not in shell


def test_overview_open_ownership_contract():
    model = (HOME / ".config/quickshell/orbit/OverviewModel.qml").read_text()
    assert model.count("Qt.callLater(root.focusSelectedWorkspace)") == 1
    assert 'property int cycleCounter: -1' in model
    assert "overview-cycle" not in model
    assert 'Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-overview", "open"])' in model
    assert 'Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/orbit-overview", "cycle"])' in model
    assert "altObservedHeld" in model
    assert "altReleaseGuard" not in model
    assert "altReleaseArmed" not in model
    assert "signal refocusOverlayRequested()" in model
    assert "refocusOverlayRequested()" in model

    overview = (HOME / ".config/quickshell/orbit/Overview.qml").read_text()
    assert "onRefocusOverlayRequested" in overview
    assert "property bool focusPulse: false" in overview
    assert "visible && !focusPulse ? WlrKeyboardFocus.Exclusive" in overview
    assert "interval: 75" in overview
    assert "Keys.onReleased" not in overview


def test_dock_xmb_transition_contract():
    shell = (HOME / ".config/quickshell/orbit/shell.qml").read_text()
    application = (HOME / ".config/quickshell/orbit/ApplicationModel.qml").read_text()
    assert "signal launcherActivated()" in application
    assert "root.launcherActivated()" in application
    assert 'orbit-xmb", "open"' in shell
    assert "property bool dockMorphing: false" in shell
    assert "property bool dockHandoff: false" in shell
    assert "function startDockMorph()" in shell
    assert "function startDockMorphAnimation()" in shell
    assert "function finishDockMorph()" in shell
    assert "duration: 360" in shell
    assert "id: dockMorphSurface" in shell
    assert "visible: root.dockMorphing" in shell
    assert "opacity: Math.max(0, 1 - morphSurface.morphProgress / 0.82)" in shell
    assert "id: xmbLauncherSurface" in shell
    assert "visible: !root.dockMorphing || root.dockHandoff" in shell
    assert "root.startDockMorphAnimation()" in shell
    assert "targetWidth: xmbModel.fullscreen ? parent.width" in shell
    assert "exclusiveZone: 58" in shell


def test_surface_transparency_contract():
    settings = tomllib.loads((HOME / ".config/orbit/settings.toml").read_text())
    theme = (HOME / ".config/quickshell/orbit/Theme.qml").read_text()
    shell = (HOME / ".config/quickshell/orbit/shell.qml").read_text()
    assert settings["appearance"]["transparency"]["shell_opacity"] == 0.30
    assert "property real shellOpacity: 0.30" in theme
    assert "appearance\\.transparency" in theme
    assert "shellOpacity = opacityMatch" in theme
    assert shell.count("theme.shellOpacity") >= 3
    assert 'surfaceFormat.opaque: false' not in shell


def test_dock_icon_startup_contract():
    model = (HOME / ".config/quickshell/orbit/ApplicationModel.qml").read_text()
    assert "property int iconRevision: 0" in model
    assert "id: iconReadinessTimer" in model
    assert "interval: 250" in model
    assert "function reconcileIcons()" in model
    assert "iconReadinessTimer.stop()" in model
    assert 'item.desktop === "orbit-xmb" || item.desktop === "orbit-settings"' in model
    assert 'item.desktop === "orbit-settings"' in model
    assert 'Quickshell.iconPath("settings-symbolic")' in model


def test_top_panel_contract():
    panel = (HOME / ".config/quickshell/orbit/TopPanel.qml").read_text()
    shell = (HOME / ".config/quickshell/orbit/shell.qml").read_text()
    assert 'import Quickshell.Services.SystemTray' in panel
    assert 'SystemClock {' in panel
    assert 'precision: SystemClock.Minutes' in panel
    assert 'text: Qt.formatDateTime(clock.date, "HH:mm")' in panel
    assert 'model: SystemTray.items' in panel
    assert 'modelData.activate()' in panel
    assert 'modelData.display(root, mouse.x, mouse.y)' in panel
    assert 'surfaceFormat.opaque: false' in panel
    assert 'exclusiveZone: 42' in panel
    assert 'WlrLayershell.layer: WlrLayer.Overlay' in panel
    assert 'TopPanel {' in shell
    assert 'onLauncherRequested: Quickshell.execDetached' in shell


def test_application_menu_contract():
    model = (HOME / ".config/quickshell/orbit/ApplicationMenuModel.qml").read_text()
    panel = (HOME / ".config/quickshell/orbit/TopPanel.qml").read_text()
    shell = (HOME / ".config/quickshell/orbit/shell.qml").read_text()
    assert "property var lastFocused" in model
    assert "function workspaceKey(client)" in model
    assert "DesktopEntries.heuristicLookup(identity)" in model
    assert "function classSuffix(value)" in model
    assert "function monitorFor(monitorName)" in model
    assert "Number(client.monitor) === Number(monitor.id)" in model
    assert "function titleFor(monitorName)" in model
    assert "function availableFor(monitorName)" in model
    assert "candidate.menu || dbusMenuFor(monitorName)" in model
    assert "function hasCandidateFor(monitorName)" in model
    assert "function menuFor(monitorName)" in model
    assert "function openFor(menuAnchor, monitorName)" in model
    assert "menuAnchor.menu = candidate.menu" in model
    assert "menuAnchor.open()" in model
    assert "function closeFor(monitorName)" in model
    assert "function forceQuitFor(monitorName)" in model
    assert '"hyprctl dispatch \'" + focus + "\' && hyprctl dispatch \'hl.dsp.window.close()\'"' in model
    assert '["kill", "-KILL", String(candidate.pid)]' in model
    assert 'typeof left.focusHistoryID === "number"' in model
    assert "client.address === remembered.address" in model
    assert "Boolean(candidate && (candidate.menu || dbusMenuFor(monitorName)))" in model
    assert "property var applicationMenuData" in panel
    assert "required property string monitorName" in panel
    assert "applicationMenuData.titleFor(monitorName)" in panel
    assert "applicationMenuData.openFor(applicationMenuAnchor, monitorName)" in panel
    assert "id: applicationActions" in panel
    assert "PopupWindow {" in panel
    assert "grabFocus: true" in panel
    assert "property bool applicationActionsVisible: false" in panel
    assert "id: applicationMenuAnchor" in panel
    assert "anchor.item: appMenuButton" in panel
    assert "anchor.gravity: Edges.Bottom | Edges.Left" in panel
    assert "anchor.adjustment: PopupAdjustment.All" in panel
    assert "id: trayMouse" in panel
    assert "trayMouse.containsMouse" in panel
    assert "applicationMenuData.hasCandidateFor(monitorName)" in panel
    assert "monitorName: modelData.name" in shell


def test_application_menu_registrar_bridge_contract():
    helper = (HOME / ".local/bin/orbit-appmenu").read_text()
    model = (HOME / ".config/quickshell/orbit/ApplicationMenuModel.qml").read_text()
    panel = (HOME / ".config/quickshell/orbit/TopPanel.qml").read_text()
    shell = (HOME / ".config/quickshell/orbit/shell.qml").read_text()
    assert "com.canonical.AppMenu.Registrar" in helper
    assert "GetMenuForWindow" in helper
    assert "com.canonical.dbusmenu" in helper
    assert '"snapshot"' in helper
    assert '"activate"' in helper
    assert "property var dbusMenus" in model
    assert "property var atspiMenus" in model
    assert "orbit-appmenu-atspi" in model
    assert "function dbusMenuFor(monitorName)" in model
    assert "function dbusRowsFor(monitorName)" in model
    assert "function fallbackRowsFor(monitorName)" in model
    assert "function activateFallback(monitorName, action)" in model
    assert "Open new window" in model
    assert "function activateDbus(monitorName, item)" in model
    assert "dbusApplicationMenuVisible" in panel
    assert "applicationMenuData.dbusRowsFor(monitorName)" in panel
    assert "applicationMenuData.activateDbus(monitorName, modelData)" in panel
    assert "ApplicationMenuModel" in shell


def test_unsupported_application_menu_fallback_contract():
    model = (HOME / ".config/quickshell/orbit/ApplicationMenuModel.qml").read_text()
    panel = (HOME / ".config/quickshell/orbit/TopPanel.qml").read_text()
    assert "function fallbackRowsFor(monitorName)" in model
    assert "Open new window" in model
    assert "Close window" in model
    assert "Force quit application" in model
    assert "applicationMenuData.fallbackRowsFor(monitorName)" in panel


def test_application_close_dispatch_contract():
    model = (HOME / ".config/quickshell/orbit/ApplicationMenuModel.qml").read_text()
    application = (HOME / ".config/quickshell/orbit/ApplicationModel.qml").read_text()
    assert "hl.dsp.window.close()" in model
    assert "hl.dsp.window.close()" in application
    assert "function closeFor(monitorName)" in model
    assert "function close(item)" in application


def test_native_wayland_atspi_contract():
    helper = (HOME / ".local/bin/orbit-appmenu-atspi").read_text()
    model = (HOME / ".config/quickshell/orbit/ApplicationMenuModel.qml").read_text()
    assert "org.a11y.atspi.Registry" in helper
    assert "org.a11y.atspi.Accessible" in helper
    assert "org.a11y.atspi.Action" in helper
    assert "IsEnabled" in helper
    assert '"source": "atspi"' in helper
    assert "def resolve_menu_for_client" in helper
    assert 'entry.source === "atspi"' in model
    assert "orbit-appmenu-atspi" in model


def test_dock_persistence():
    module = load("orbit_dock", BIN / "orbit-dock")
    with tempfile.TemporaryDirectory() as directory:
        module.DOCK = Path(directory) / "dock.json"
        module.update("pin", "example.desktop", "Example", "Example")
        stored = json.loads(module.DOCK.read_text())
        assert stored["pinned"] == [{"label": "Example", "desktop": "example.desktop", "class": "Example"}]
        module.update("pin", "example.desktop", "Example", "Example")
        assert len(json.loads(module.DOCK.read_text())["pinned"]) == 1
        module.update("unpin", "example.desktop")
        assert json.loads(module.DOCK.read_text())["pinned"] == []


def test_monitor_contract():
    module = load("orbit_monitor", BIN / "orbit-monitor")
    dynamic = (HOME / ".config/hypr/scripts/dynamic-app-workspaces").read_text()
    blank_special = (HOME / ".config/hypr/scripts/blank-special-workspaces").read_text()
    assert 'workspace-for-monitor "$1"' in dynamic
    assert "DP-1)" not in dynamic and "HDMI-A-1)" not in dynamic
    assert 'select(.class == "steam" and (.floating | not) and .title == "Steam")' in dynamic
    assert 'select(.class == "steam" and (.floating | not))' in dynamic
    assert 'different PID' in dynamic
    assert 'orbit-monitor workspace-for-monitor "$1"' in blank_special
    assert "DP-1)" not in blank_special and "HDMI-A-1)" not in blank_special
    with tempfile.TemporaryDirectory() as directory:
        module.SETTINGS = Path(directory) / "settings.toml"
        module.SETTINGS.write_text(
            '[monitors.home]\nserial = "HOME-SERIAL"\nworkspace = 1\n'
            '[monitors.gaming]\nserial = "MISSING"\nworkspace = 6\n'
        )
        available = [
            {"name": "HDMI-A-1", "serial": "GAME-SERIAL", "focused": False},
            {"name": "DP-1", "serial": "HOME-SERIAL", "focused": True},
        ]
        assert module.select_monitor("home", available, True)[0]["name"] == "DP-1"
        assert module.select_monitor("gaming", available, False)[0]["name"] == "DP-1"
        assert module.workspace_for_monitor("DP-1", available) == "1"
        try:
            module.select_monitor("gaming", available, True)
        except SystemExit:
            pass
        else:
            raise AssertionError("strict unavailable role did not fail")


def test_monitor_workspace_source_contract():
    settings = tomllib.loads((HOME / ".config/orbit/settings.toml").read_text())
    monitor = (BIN / "orbit-monitor").read_text()
    dynamic = (HOME / ".config/hypr/scripts/dynamic-app-workspaces").read_text()
    blank = (HOME / ".config/hypr/scripts/blank-special-workspaces").read_text()
    assert all("workspace" in settings["monitors"][role] for role in ("home", "gaming"))
    assert "workspace-for-monitor" in monitor
    assert "workspace-for-monitor" in dynamic
    assert "workspace-for-monitor" in blank


def test_policy_contract():
    module = load("orbit_policy", BIN / "orbit-app-policy")
    with tempfile.TemporaryDirectory() as directory:
        module.POLICIES = Path(directory) / "policies.toml"
        module.IDENTITIES = Path(directory) / "identities.toml"
        module.POLICIES.write_text(
            '[defaults]\nmonitor_role = "focused"\nworkspace_policy = "dedicated"\n'
            'children = "inherit"\n\n'
            '[[policy]]\nname = "transient"\nclass_pattern = "^dialog$"\n'
            'workspace_policy = "transient"\n\n'
            '[[policy]]\nname = "game"\nclass_pattern = "^steam_app_.*$"\n'
            'monitor_role = "gaming"\ninherit_exclude = "^steam$"\n'
        )
        assert module.resolve("dialog", "Prompt")["workspace_policy"] == "transient"
        game = module.resolve("steam_app_123", "Game")
        assert game["monitor_role"] == "gaming"
        assert game["inherit_exclude"] == "^steam$"
        assert module.resolve("org.example", "App")["workspace_policy"] == "dedicated"
        module.POLICIES.write_text(
            '[defaults]\nworkspace_policy = "dedicated"\n\n'
            '[[rule]]\nmatch_type = "title"\nmatch_value = "Prompt"\n'
            'match_pattern = "Prompt"\nworkspace_policy = "transient"\npriority = 1\n'
        )
        assert module.resolve("org.example", "Prompt")["workspace_policy"] == "transient"
        module.POLICIES.write_text(
            '[defaults]\nworkspace_policy = "dedicated"\n\n'
            '[[policy]]\nclass_pattern = "^org\\\\.example$"\n'
            'title_pattern = "Prompt"\nworkspace_policy = "transient"\n'
        )
        assert module.resolve("org.example", "Prompt")["workspace_policy"] == "transient"


def test_theme_contract():
    module = load("orbit_theme", BIN / "orbit-theme")
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        module.HOME = root
        module.ORBIT = root
        module.SETTINGS = root / "settings.toml"
        module.PALETTES = root / "palettes"
        module.GENERATED = root / "generated"
        source = HOME / ".config/orbit/palettes/tokyo-night.toml"
        module.PALETTES.mkdir()
        (module.PALETTES / "tokyo-night.toml").write_text(source.read_text())
        output = module.generate("tokyo-night")
        expected = {"semantic.json", "quickshell.json", "gtk-3.0.css", "gtk-4.0.css", "hyprland.lua", "kitty.conf", "wezterm.toml", "ferrosonic.toml"}
        assert {path.name for path in output.iterdir()} == expected
        semantic = json.loads((output / "semantic.json").read_text())
        assert semantic["semantic"]["accent"].startswith("#")
        assert "hl.config" in (output / "hyprland.lua").read_text()


def test_theme_active_adapter_contract():
    module = load("orbit_theme_active", BIN / "orbit-theme")
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        module.ORBIT = root / "orbit"
        module.SETTINGS = module.ORBIT / "settings.toml"
        module.PALETTES = module.ORBIT / "palettes"
        module.GENERATED = module.ORBIT / "generated"
        module.GTK3_ACTIVE = root / "gtk-3.0/noctalia.css"
        module.GTK4_ACTIVE = root / "gtk-4.0/noctalia.css"
        module.KDE_SCHEME_ACTIVE = root / "color-schemes/noctalia.colors"
        module.PALETTES.mkdir(parents=True)
        source = HOME / ".config/orbit/palettes/tokyo-night.toml"
        (module.PALETTES / "tokyo-night.toml").write_text(source.read_text())
        output = module.generate("tokyo-night")
        module.install_active_adapters("tokyo-night")
        assert module.GTK3_ACTIVE.read_text() == (output / "gtk-3.0.css").read_text()
        assert module.GTK4_ACTIVE.read_text() == (output / "gtk-4.0.css").read_text()
        kde = module.KDE_SCHEME_ACTIVE.read_text()
        assert "Name=noctalia" in kde
        assert "activeBackground=" in kde


def test_settings_contract():
    module = load("orbit_settings", BIN / "orbit-settings")
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        module.HOME = root
        module.ORBIT = root
        module.SETTINGS = root / "settings.toml"
        module.APP_POLICIES = root / "app-policies.toml"
        module.APPLICATION_IDENTITIES = root / "application-identities.toml"
        (root / ".config/hypr").mkdir(parents=True)
        module.SETTINGS.write_text("[theme]\npalette = \"tokyo-night\"\n")
        try:
            module.update_application_policies({"defaults": {"monitor_role": "invalid"}, "rules": []})
        except ValueError:
            pass
        else:
            raise AssertionError("invalid policy was accepted")
        module.write_window_rules([{
            "id": "test", "name": "Test", "kind": "simple", "match_type": "class",
            "match_value": "^test$", "priority": 1, "no_shadow": True, "center": False,
        }])
        generated = (root / ".config/hypr/orbit-window-rules.lua")
        assert "no_shadow = true" in generated.read_text()


def test_settings_artifact_boundary_contract():
    module = load("orbit_settings_artifacts", HOME / ".local/lib/orbit_settings_artifacts.py")
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        module.write_window_rules([{
            "id": "test", "name": "Test", "kind": "simple", "match_type": "class",
            "match_value": "^test$", "priority": 1, "no_shadow": True,
        }], root / "window-rules.lua")
        module.write_monitors_lua([{
            "connector": "DP-1", "width": 1920, "height": 1080,
            "refresh_rate": 60, "x": 0, "y": 0,
        }], root / "monitors.lua")
        values = {
            "style": {"button_shape": "rounded", "corner_radius": 10},
            "transparency": {"active_opacity": 1.0, "inactive_opacity": 0.9, "shell_opacity": 0.3},
            "effects": {
                "hyprglass_enabled": True, "hyprglass_blur_type": "glass",
                "hyprwindowshade_enabled": True, "animations_enabled": True,
                "animations": {"global": {"enabled": True, "speed": 1.0, "type": "default"}},
            },
        }
        module.write_appearance_artifacts(values, root / "generated")
        assert "no_shadow = true" in (root / "window-rules.lua").read_text()
        assert 'output = "DP-1"' in (root / "monitors.lua").read_text()
        assert 'shell_opacity = 0.3' in (root / "generated/appearance.lua").read_text()


def test_settings_persistence_boundary_contract():
    source = (BIN / "orbit-settings").read_text()
    assert "from orbit_settings_persistence import" in source
    module = load("orbit_settings_persistence", HOME / ".local/lib/orbit_settings_persistence.py")
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        toml_path = root / "nested/settings.toml"
        json_path = root / "nested/state.json"
        module.atomic_write(toml_path, '[theme]\npalette = "tokyo-night"\n')
        module.atomic_write(json_path, '{"visible": true}\n')
        assert module.read_toml(toml_path)["theme"]["palette"] == "tokyo-night"
        assert module.read_json(json_path, {}) == {"visible": True}
        assert module.read_json(root / "missing.json", {"fallback": True}) == {"fallback": True}
        assert module.toml_value(["a", "b"]) == '["a", "b"]'


def test_settings_validation_boundary_contract():
    source = (BIN / "orbit-settings").read_text()
    assert "from orbit_settings_validation import" in source
    module = load("orbit_settings_validation", HOME / ".local/lib/orbit_settings_validation.py")
    module.validate_application_policies({
        "defaults": {"monitor_role": "focused", "workspace_policy": "inherit", "children": "inherit"},
        "rules": [{"name": "Test", "application": "test", "match_type": "class", "match_value": "^test$"}],
    })
    module.validate_appearance({"style": {"corner_radius": 10}, "transparency": {"shell_opacity": 0.3}})
    module.validate_display_profiles([{"connector": "DP-1", "width": 1920, "height": 1080, "refresh_rate": 60}])
    for validator, value in (
        (module.validate_application_policies, {"defaults": {"monitor_role": "invalid"}, "rules": []}),
        (module.validate_appearance, {"style": {"corner_radius": 99}}),
        (module.validate_display_profiles, [{"connector": "DP-1", "width": 0, "height": 1080, "refresh_rate": 60}]),
    ):
        try:
            validator(value)
        except (TypeError, ValueError):
            pass
        else:
            raise AssertionError("invalid settings were accepted")


def test_settings_mutating_actions_have_a_narrow_owner():
    source = (BIN / "orbit-settings").read_text()
    assert "import orbit_settings_actions" in source
    assert "return orbit_settings_actions.run_system_action(" in source
    module = load("orbit_settings_actions", HOME / ".local/lib/orbit_settings_actions.py")
    calls = []

    class Completed:
        returncode = 0
        stderr = ""
        stdout = ""

    def runner(command, **kwargs):
        calls.append(command)
        return Completed()

    assert module.run_system_action("audio-volume", {"id": 42, "volume": 0.5}, runner=runner)["ok"]
    assert calls == [["wpctl", "set-volume", "42", "0.5"]]
    with tempfile.TemporaryDirectory() as directory:
        module.write_hypridle({"enabled": False, "lock_timeout": 60, "suspend_timeout": 120}, Path(directory) / "hypridle.conf", runner=runner)
        assert "timeout = 60" in (Path(directory) / "hypridle.conf").read_text()


def test_display_apply_rolls_back_files_and_runtime_on_failure():
    module = load("orbit_settings_display_recovery", BIN / "orbit-settings")
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        module.HOME = root
        module.ORBIT = root / ".config/orbit"
        module.SETTINGS = module.ORBIT / "settings.toml"
        monitor_file = root / ".config/hypr/monitors.lua"
        module.ORBIT.mkdir(parents=True)
        monitor_file.parent.mkdir(parents=True)
        original_settings = '[displays.home]\nconnector = "DP-1"\nmode = "1920x1080@60.00"\n'
        original_monitors = '-- last-known-good\n'
        module.SETTINGS.write_text(original_settings)
        monitor_file.write_text(original_monitors)
        snapshot = [{"name": "DP-1", "width": 1920, "height": 1080, "refreshRate": 60.0, "x": 0, "y": 0, "scale": 1.0}]
        calls = []

        class Result:
            returncode = 1
            stderr = "synthetic apply failure"
            stdout = ""

        def fake_run(command, **_kwargs):
            calls.append(command)
            result = Result()
            if command[-1].startswith("DP-1,1920x1080") or command[-1] == "config-only":
                result.returncode = 0
            return result

        module.monitors = lambda: snapshot
        original_run = module.subprocess.run
        module.subprocess.run = fake_run
        try:
            try:
                module.apply_display_profile_changes([{
                    "connector": "DP-1", "width": 1280, "height": 720,
                    "refresh_rate": 60, "x": 0, "y": 0,
                }], {"home": {"connector": "DP-1"}})
            except ValueError as error:
                assert "rollback restored the prior topology" in str(error)
            else:
                raise AssertionError("failed display apply was accepted")
        finally:
            module.subprocess.run = original_run
        assert module.SETTINGS.read_text() == original_settings
        assert monitor_file.read_text() == original_monitors
        assert any(command[-1].startswith("DP-1,1920x1080") for command in calls)


def test_appearance_contract():
    module = load("orbit_settings_appearance", BIN / "orbit-settings")
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        module.HOME = root
        module.ORBIT = root / ".config/orbit"
        module.SETTINGS = module.ORBIT / "settings.toml"
        module.SETTINGS.parent.mkdir(parents=True)
        module.SETTINGS.write_text("[theme]\npalette = \"tokyo-night\"\n")
        values = module.appearance_settings()
        assert values["style"]["corner_radius"] == 10
        values["effects"]["animations"]["workspaces"]["speed"] = 2.5
        module.update_appearance(values)
        module.write_appearance_artifacts(values)
        stored = tomllib.loads(module.SETTINGS.read_text())
        assert stored["appearance"]["effects"]["animations"]["workspaces"]["speed"] == 2.5
        assert 'hyprglass_blur_type = "glass"' in (module.ORBIT / "generated/appearance.lua").read_text()
        try:
            module.update_appearance({"style": {"corner_radius": 99}})
        except ValueError:
            pass
        else:
            raise AssertionError("invalid appearance radius was accepted")

        palette_root = module.ORBIT / "palettes"
        palette_root.mkdir()
        (palette_root / "tokyo-night.toml").write_text(
            '[palette]\nname = "Tokyo Night"\nappearance = "dark"\n\n'
            '[colors]\nbackground = "#111111"\nsurface = "#222222"\naccent = "#333333"\ntext = "#eeeeee"\n'
        )
        module.update_palette("orbit-custom", {"base": "tokyo-night", "label": "Orbit Custom", "colors": {"accent": "#abcdef"}})
        custom = tomllib.loads((palette_root / "orbit-custom.toml").read_text())
        assert custom["palette"]["name"] == "Orbit Custom"
        assert custom["colors"]["accent"] == "#abcdef"


def test_system_adapter_contract():
    module = load("orbit_settings_system", BIN / "orbit-settings")
    outputs = {
        ("wpctl", "status"): (
            "Audio\n"
            " \u2514\u2500 Sinks:\n"
            "       * 42. Test Output [vol: 0.75]\n"
            " \u2514\u2500 Sources:\n"
            "       * 43. Test Input\n"
            " \u2514\u2500 Streams:\n"
            "       44. Example App\n"
            "          45. output_FL\n"
            "Video\n"
            " \u2514\u2500 Sources:\n"
            "       * 99. Webcam\n"
        ),
        ("wpctl", "get-volume"): "Volume: 0.75\n",
        ("nmcli", "-t"): "Wi-Fi:802-11-wireless:wlp4s0:activated:yes\n",
        ("nmcli", "-g"): "Home Wi-Fi\n802-11-wireless\nyes\nwlp4s0\nHome Wi-Fi\ninfrastructure\nwpa-psk\nauto\n\n\nauto\n\n\n\nnone\n",
        ("nmcli", "wifi"): "*:Home Wi-Fi:Infra:6:54 Mbit/s:80:****:WPA2:wlp4s0\n:Guest Wi-Fi:Infra:11:54 Mbit/s:40:***:WPA2:wlp4s0\n",
        ("bluetoothctl", "show"): "Powered: yes\nDiscovering: no\nPairable: yes\n",
        ("bluetoothctl", "devices"): "Device AA:BB:CC:DD:EE:FF Headphones\n",
        ("bluetoothctl", "info"): "Name: Headphones\nConnected: yes\nPaired: yes\nTrusted: yes\nBlocked: no\nRSSI: -42\nIcon: audio-card\n",
        ("tuned-adm", "list"): "Available profiles:\n- balanced - General\n- balanced-battery - Battery\n",
        ("tuned-adm", "active"): "Current active profile: balanced\n",
        ("powerprofilesctl", "list"): "",
    }

    original_output = module.command_output

    def fake_output(command):
        if command[:1] == ["nmcli"] and "-g" in command:
            return outputs[("nmcli", "-g")]
        if command[-2:] == ["wifi", "list"]:
            return outputs[("nmcli", "wifi")]
        if command[:2] == ["tuned-adm", "list"]:
            return outputs[("tuned-adm", "list")]
        if command[:2] == ["tuned-adm", "active"]:
            return outputs[("tuned-adm", "active")]
        prefix = tuple(command[:2])
        if prefix in outputs:
            return outputs[prefix]
        if command[:1] == ["wpctl"] and command[1:2] == ["get-volume"]:
            return outputs[("wpctl", "get-volume")]
        return ""

    module.command_output = fake_output
    snapshot = module.system_snapshot()
    module.command_output = original_output

    assert snapshot["audio"]["default_sink"] == 42
    assert snapshot["audio"]["default_source"] == 43
    assert [item["name"] for item in snapshot["audio"]["streams"]] == ["Example App"]
    assert len(snapshot["audio"]["sources"]) == 1
    assert snapshot["network"]["connections"][0]["active"] is True
    assert snapshot["bluetooth"]["devices"][0]["connected"] is True
    assert snapshot["bluetooth"]["devices"][0]["rssi"] == -42
    assert snapshot["bluetooth"]["devices"][0]["icon"] == "audio-card"
    assert snapshot["network"]["connections"][0]["details"]["ssid"] == "Home Wi-Fi"
    assert len(snapshot["network"]["wifi_networks"]) == 2
    assert snapshot["power"]["profile"] == "balanced"
    assert "balanced-battery" in snapshot["power"]["profiles"]

    calls = []

    class Completed:
        returncode = 0
        stderr = ""
        stdout = ""

    original_run = module.subprocess.run
    module.subprocess.run = lambda command, **kwargs: (calls.append(command) or Completed())
    module.run_system_action("audio-volume", {"id": 42, "volume": 0.5})
    module.run_system_action("network-profile-save", {"name": "Home Wi-Fi", "values": {"ssid": "Home Wi-Fi", "autoconnect": True}})
    module.run_system_action("network-wifi-connect", {"ssid": "Guest Wi-Fi", "password": "secret", "device": "wlp4s0"})
    module.run_system_action("bluetooth-pair", {"address": "AA:BB:CC:DD:EE:FF"})
    module.run_system_action("tuned-profile", {"profile": "balanced"})
    module.subprocess.run = original_run
    assert calls == [
        ["wpctl", "set-volume", "42", "0.5"],
        ["nmcli", "connection", "modify", "Home Wi-Fi", "connection.autoconnect", "yes", "802-11-wireless.ssid", "Home Wi-Fi"],
        ["nmcli", "device", "wifi", "connect", "Guest Wi-Fi", "password", "secret", "ifname", "wlp4s0"],
        ["bluetoothctl", "pair", "AA:BB:CC:DD:EE:FF"],
        ["tuned-adm", "profile", "balanced"],
    ]

    with tempfile.TemporaryDirectory() as directory:
        module.HYPRIDLE = Path(directory) / "hypridle.conf"
        module.subprocess.run = lambda command, **kwargs: Completed()
        module.write_hypridle({"enabled": True, "lock_timeout": 120, "suspend_timeout": 240})
        hypridle = module.HYPRIDLE.read_text()
        assert "timeout = 120" in hypridle
        assert "timeout = 240" in hypridle
        assert "loginctl lock-session" in hypridle
    module.subprocess.run = original_run


def test_state_contract():
    with tempfile.TemporaryDirectory() as directory:
        runtime = Path(directory) / "runtime"
        (runtime / "orbit").mkdir(parents=True)
        (runtime / "orbit/alt-held").write_text("1\n")
        environment = {**os.environ, "XDG_CACHE_HOME": directory, "XDG_RUNTIME_DIR": str(runtime), "HOME": str(HOME)}
        xmb = BIN / "orbit-xmb"
        subprocess.run([str(xmb), "open"], env=environment, check=True)
        assert (Path(directory) / "orbit/xmb-visible").read_text().strip() == "1"
        subprocess.run([str(xmb), "toggle"], env=environment, check=True)
        assert (Path(directory) / "orbit/xmb-visible").read_text().strip() == "0"
        overview = BIN / "orbit-overview"
        subprocess.run([str(overview), "close-state"], env=environment, check=True)
        subprocess.run([str(overview), "cycle"], env=environment, check=True)
        assert len((Path(directory) / "orbit/overview-visible").read_text().split()) == 3
        subprocess.run([str(overview), "close-state"], env=environment, check=True)
        (runtime / "orbit/alt-held").write_text("0\n")
        subprocess.run([str(overview), "cycle"], env=environment, check=True)
        assert len((Path(directory) / "orbit/overview-visible").read_text().split()) == 3


def test_overview_state_machine_contract():
    helper = (BIN / "orbit-overview").read_text()
    model = (HOME / ".config/quickshell/orbit/OverviewModel.qml").read_text()
    assert 'state="closed 0 0"' in helper
    assert "state_cycles" in helper
    assert 'orbit_state_write "$state_file" "$1 $2 $3"' in helper
    assert "obsolete_cycle_file" in helper
    assert "overview-cycle" not in model
    assert "cycleCounter" in model
    assert "pendingCycles" in model
    assert "revision <= stateRevision" in model
    assert "if (!wasVisible) {\n                selectFocused()" in model


def test_equal_overview_revisions_are_ignored():
    model = (HOME / ".config/quickshell/orbit/OverviewModel.qml").read_text()
    boundary = model.index("revision <= stateRevision")
    assert "return" in model[boundary:boundary + 100]


def test_overview_refocuses_after_workspace_dispatch():
    model = (HOME / ".config/quickshell/orbit/OverviewModel.qml").read_text()
    overview = (HOME / ".config/quickshell/orbit/Overview.qml").read_text()
    assert "refocusOverlayRequested()" in model
    assert "onRefocusOverlayRequested" in overview
    assert "focusScope.forceActiveFocus()" in overview


def test_shared_state_writer_contract():
    helper = (HOME / ".local/lib/orbit-state").read_text()
    assert "mktemp \"${orbit_state_file}.tmp.XXXXXX\"" in helper
    assert 'flock -x 9' in helper
    assert 'mv -f "$orbit_state_temporary" "$orbit_state_file"' in helper
    for name in ("orbit-shell-ui", "orbit-xmb", "orbit-overview"):
        script = (BIN / name).read_text()
        assert '. "$HOME/.local/lib/orbit-state"' in script


def test_power_contract():
    module = load("orbit_settings_power", BIN / "orbit-settings")
    module.command_output = lambda command: {
        ("tuned-adm", "list"): "Available profiles:\n- balanced - General\n- powersave - Low power\n",
        ("tuned-adm", "active"): "Current active profile: powersave\n",
    }.get(tuple(command[:2]), "")
    power = module.tuned_settings()
    assert power["backend"] == "tuned"
    assert power["profile"] == "powersave"
    assert power["profiles"] == ["balanced", "powersave"]


TESTS = (
    ("STATIC-001", test_files_and_syntax),
    ("APP-007", test_delayed_launch_context_contract),
    ("APP-009", test_dock_and_xmb_share_launch_observation_boundary),
    ("APP-010", test_concurrent_launch_correlation_contract),
    ("UI-018", test_dock_xmb_handoff_releases_keyboard_focus_guard),
    ("UI-009", test_dock_boundary_magnification_uses_animated_hover_ramp),
    ("STATE-008", test_shared_hyprland_snapshot_contract),
    ("STATE-009", test_settings_uses_shared_hyprland_clients_contract),
    ("STATE-011", test_settings_system_actions_have_a_narrow_owner),
    ("STATE-013", test_settings_draft_lifecycle_has_a_narrow_owner),
    ("SET-009", test_settings_runtime_observation_has_a_narrow_owner),
    ("STATE-012", test_settings_application_matching_has_a_narrow_owner),
    ("START-002", test_startup_contract),
    ("START-008", test_shell_duplicate_and_startup_readiness_contract),
    ("INPUT-001", test_input_focus_contract),
    ("START-006", test_session_shutdown_confirmation_contract),
    ("START-007", test_application_scope_contract),
    ("APP-008", test_desktop_exec_field_codes_are_not_passed_as_paths),
    ("SEC-001", test_input_helper_permission_contract),
    ("UI-006", test_overview_binding_contract),
    ("STATE-002", test_overview_open_ownership_contract),
    ("UI-007", test_dock_xmb_transition_contract),
    ("THEME-004", test_surface_transparency_contract),
    ("START-005", test_dock_icon_startup_contract),
    ("UI-010", test_top_panel_contract),
    ("UI-011", test_application_menu_contract),
    ("UI-012", test_application_menu_registrar_bridge_contract),
    ("UI-016", test_unsupported_application_menu_fallback_contract),
    ("UI-019", test_application_close_dispatch_contract),
    ("UI-013", test_native_wayland_atspi_contract),
    ("DOCK-001", test_dock_persistence),
    ("MON-001", test_monitor_contract),
    ("STATE-010", test_monitor_workspace_source_contract),
    ("APP-001", test_policy_contract),
    ("THEME-001", test_theme_contract),
    ("THEME-003", test_theme_active_adapter_contract),
    ("SET-001", test_settings_contract),
    ("SET-006", test_settings_artifact_boundary_contract),
    ("SET-007", test_settings_persistence_boundary_contract),
    ("SET-008", test_settings_validation_boundary_contract),
    ("SET-010", test_settings_mutating_actions_have_a_narrow_owner),
    ("SET-003", test_display_apply_rolls_back_files_and_runtime_on_failure),
    ("APPEARANCE-001", test_appearance_contract),
    ("SYSTEM-001", test_system_adapter_contract),
    ("STATE-001", test_state_contract),
    ("STATE-004", test_overview_state_machine_contract),
    ("STATE-006", test_equal_overview_revisions_are_ignored),
    ("STATE-007", test_overview_refocuses_after_workspace_dispatch),
    ("STATE-003", test_shared_state_writer_contract),
    ("POWER-001", test_power_contract),
)


def validate_registry() -> None:
    defined = {
        name for name, value in globals().items()
        if name.startswith("test_") and callable(value)
    }
    registered = [function.__name__ for _test_id, function in TESTS]
    test_ids = [test_id for test_id, _function in TESTS]
    assert len(test_ids) == len(set(test_ids)), "duplicate Test Matrix IDs in contract registry"
    assert len(registered) == len(set(registered)), "contract function registered more than once"
    missing = sorted(defined - set(registered))
    unknown = sorted(set(registered) - defined)
    assert not missing and not unknown, f"contract registry mismatch: unregistered={missing}, unknown={unknown}"


def main() -> int:
    result_path = Path(os.environ.get("ORBIT_TEST_LOG_DIR", ".")) / "contract.results.json"
    result_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        validate_registry()
    except AssertionError as error:
        result_path.write_text(json.dumps({"tests": [], "registry_error": str(error)}, indent=2) + "\n")
        print(f"contract registry invalid: {error}", file=sys.stderr)
        return 1

    for test_id, function in TESTS:
        check(test_id, function)
    result_path.write_text(json.dumps({"tests": RESULTS}, indent=2) + "\n")
    print(json.dumps({"tests": RESULTS}, indent=2))
    return 1 if any(item["status"] == "FAIL" for item in RESULTS) else 0


if __name__ == "__main__":
    raise SystemExit(main())
