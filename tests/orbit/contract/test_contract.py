#!/usr/bin/env python3
"""Deterministic Orbit contract tests; never mutate the live configuration."""

from __future__ import annotations

import importlib.machinery
import importlib.util
import json
import os
import subprocess
import tempfile
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HOME = ROOT
BIN = HOME / ".local/bin"
RESULTS = []


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
    required = [
        BIN / "orbit-monitor", BIN / "orbit-app-policy", BIN / "orbit-theme",
        BIN / "orbit-settings", BIN / "orbit-overview", BIN / "orbit-xmb",
        BIN / "orbit-dock", BIN / "orbit-shell-ui",
        HOME / ".config/quickshell/orbit/shell.qml",
        HOME / ".config/systemd/user/orbit-shell.service",
    ]
    assert all(path.is_file() for path in required)
    assert all(os.access(path, os.X_OK) for path in required[:8])
    for path in (HOME / ".config/orbit").rglob("*.toml"):
        tomllib.loads(path.read_text())
    for path in (HOME / ".config/orbit").rglob("*.json"):
        json.loads(path.read_text())


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


def test_input_helper_permission_contract():
    service = (HOME / ".config/systemd/user/orbit-input-state.service").read_text()
    assert "ExecStart=/usr/bin/sg input -c %h/.local/bin/orbit-input-state" in service


def test_overview_binding_contract():
    shell = (BIN / "orbit-shell").read_text()
    assert 'hl.bind(\\"ALT + TAB\\", hl.dsp.exec_cmd(\\"$overview cycle\\"), { repeating = false })' in shell
    assert "for _ in $(seq 1 30)" in shell
    assert "bindings_ready()" in shell
    assert "grep -q '^[[:space:]]*key: TAB$'" in shell
    assert "grep -q '^[[:space:]]*key: Alt_L$'" in shell
    assert "grep -q '^[[:space:]]*key: Alt_R$'" in shell


def test_overview_open_ownership_contract():
    model = (HOME / ".config/quickshell/orbit/OverviewModel.qml").read_text()
    assert model.count("Qt.callLater(root.focusSelectedWorkspace)") == 1


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
    with tempfile.TemporaryDirectory() as directory:
        module.SETTINGS = Path(directory) / "settings.toml"
        module.SETTINGS.write_text(
            '[monitors.home]\nserial = "HOME-SERIAL"\n'
            '[monitors.gaming]\nserial = "MISSING"\n'
        )
        available = [
            {"name": "HDMI-A-1", "serial": "GAME-SERIAL", "focused": False},
            {"name": "DP-1", "serial": "HOME-SERIAL", "focused": True},
        ]
        assert module.select_monitor("home", available, True)[0]["name"] == "DP-1"
        assert module.select_monitor("gaming", available, False)[0]["name"] == "DP-1"
        try:
            module.select_monitor("gaming", available, True)
        except SystemExit:
            pass
        else:
            raise AssertionError("strict unavailable role did not fail")


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
        assert (Path(directory) / "orbit/overview-visible").read_text().startswith("open ")
        subprocess.run([str(overview), "close-state"], env=environment, check=True)
        (runtime / "orbit/alt-held").write_text("0\n")
        subprocess.run([str(overview), "cycle"], env=environment, check=True)
        assert (Path(directory) / "orbit/overview-visible").read_text().startswith("open ")


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


def main() -> int:
    check("STATIC-001", test_files_and_syntax)
    check("START-001", test_startup_contract)
    check("SEC-001", test_input_helper_permission_contract)
    check("UI-006", test_overview_binding_contract)
    check("STATE-002", test_overview_open_ownership_contract)
    check("DOCK-001", test_dock_persistence)
    check("MON-001", test_monitor_contract)
    check("APP-001", test_policy_contract)
    check("THEME-001", test_theme_contract)
    check("SET-001", test_settings_contract)
    check("APPEARANCE-001", test_appearance_contract)
    check("SYSTEM-001", test_system_adapter_contract)
    check("POWER-001", test_power_contract)
    check("STATE-001", test_state_contract)
    result_path = Path(os.environ.get("ORBIT_TEST_LOG_DIR", ".")) / "contract.results.json"
    result_path.parent.mkdir(parents=True, exist_ok=True)
    result_path.write_text(json.dumps({"tests": RESULTS}, indent=2) + "\n")
    print(json.dumps({"tests": RESULTS}, indent=2))
    return 1 if any(item["status"] == "FAIL" for item in RESULTS) else 0


if __name__ == "__main__":
    raise SystemExit(main())
