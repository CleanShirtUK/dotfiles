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
        HOME / ".config/quickshell/orbit/shell.qml",
    ]
    assert all(path.is_file() for path in required)
    assert all(os.access(path, os.X_OK) for path in required[:6])
    for path in (HOME / ".config/orbit").rglob("*.toml"):
        tomllib.loads(path.read_text())
    for path in (HOME / ".config/orbit").rglob("*.json"):
        json.loads(path.read_text())


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


def test_state_contract():
    with tempfile.TemporaryDirectory() as directory:
        environment = {**os.environ, "XDG_CACHE_HOME": directory, "HOME": str(HOME)}
        xmb = BIN / "orbit-xmb"
        subprocess.run([str(xmb), "open"], env=environment, check=True)
        assert (Path(directory) / "orbit/xmb-visible").read_text().strip() == "1"
        subprocess.run([str(xmb), "toggle"], env=environment, check=True)
        assert (Path(directory) / "orbit/xmb-visible").read_text().strip() == "0"
        overview = BIN / "orbit-overview"
        subprocess.run([str(overview), "close-state"], env=environment, check=True)
        subprocess.run([str(overview), "cycle"], env=environment, check=True)
        assert (Path(directory) / "orbit/overview-visible").read_text().startswith("open ")


def main() -> int:
    check("STATIC-001", test_files_and_syntax)
    check("MON-001", test_monitor_contract)
    check("APP-001", test_policy_contract)
    check("THEME-001", test_theme_contract)
    check("SET-001", test_settings_contract)
    check("STATE-001", test_state_contract)
    result_path = Path(os.environ.get("ORBIT_TEST_LOG_DIR", ".")) / "contract.results.json"
    result_path.parent.mkdir(parents=True, exist_ok=True)
    result_path.write_text(json.dumps({"tests": RESULTS}, indent=2) + "\n")
    print(json.dumps({"tests": RESULTS}, indent=2))
    return 1 if any(item["status"] == "FAIL" for item in RESULTS) else 0


if __name__ == "__main__":
    raise SystemExit(main())
