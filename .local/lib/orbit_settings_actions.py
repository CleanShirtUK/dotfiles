"""Transient Orbit Settings runtime actions.

This module owns commands that change external desktop state.  It deliberately
accepts plain payloads and validates them before invoking the existing desktop
tools; persistence and snapshot observation remain separate boundaries.
"""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path
from typing import Callable

from orbit_settings_persistence import atomic_write


Runner = Callable[..., object]


def _run(command: list[str], runner: Runner | None = None):
    runner = runner or subprocess.run
    result = runner(command, check=False, capture_output=True, text=True)
    if result.returncode != 0:
        raise ValueError(result.stderr.strip() or result.stdout.strip() or "System action failed")
    return result


def write_hypridle(values: dict, path: Path, current: dict | None = None,
                   runner: Runner | None = None) -> None:
    """Persist hypridle settings and apply only the user service change."""
    values = values if isinstance(values, dict) else {}
    current = current if isinstance(current, dict) else {}
    enabled = bool(values.get("enabled", True))
    lock_timeout = int(values.get("lock_timeout", 180))
    suspend_timeout = int(values.get("suspend_timeout", 300))
    lock_action = str(values.get("lock_action", current.get("lock_action", "loginctl lock-session"))).strip()
    suspend_action = str(values.get("suspend_action", current.get("suspend_action", "systemctl suspend"))).strip()
    if lock_timeout < 0 or suspend_timeout < 0 or not lock_action or not suspend_action:
        raise ValueError("Hypridle timeouts cannot be negative")
    lines = [
        "general {",
        "    lock_cmd = ~/.config/hypr/scripts/start-hyprlock",
        "    after_sleep_cmd = ~/.config/hypr/scripts/restore-dpms",
        "}", "",
    ]
    if lock_timeout:
        lines += ["listener {", f"    timeout = {lock_timeout}", f"    on-timeout = {lock_action}", "}", ""]
    if suspend_timeout:
        lines += ["listener {", f"    timeout = {suspend_timeout}", f"    on-timeout = {suspend_action}", "}", ""]
    atomic_write(path, "\n".join(lines))
    service_action = "start" if enabled else "stop"
    _run(["systemctl", "--user", service_action, "hypridle.service"], runner)
    if enabled:
        _run(["systemctl", "--user", "restart", "hypridle.service"], runner)


def run_system_action(action: str, payload: dict, *, hypridle_path: Path | None = None,
                      hypridle_current: dict | None = None,
                      runner: Runner | None = None) -> dict:
    """Apply a transient device/system action without changing Orbit settings."""
    payload = payload if isinstance(payload, dict) else {}
    if action == "tuned-profile":
        profile = str(payload.get("profile", "")).strip()
        if not profile or not shutil.which("tuned-adm"):
            raise ValueError("A valid Tuned profile is required")
        _run(["tuned-adm", "profile", profile], runner)
    elif action == "hypridle-save":
        if hypridle_path is None:
            raise ValueError("Hypridle path is required")
        write_hypridle(payload, hypridle_path, hypridle_current, runner)
    elif action == "network-profile-save":
        name, values = str(payload.get("name", "")).strip(), payload.get("values", {})
        if not name or not isinstance(values, dict):
            raise ValueError("A connection name and profile values are required")
        allowed = {"autoconnect": "connection.autoconnect", "interface": "connection.interface-name", "ssid": "802-11-wireless.ssid", "wifi_mode": "802-11-wireless.mode", "security": "802-11-wireless-security.key-mgmt", "password": "802-11-wireless-security.psk", "ipv4_method": "ipv4.method", "ipv4_addresses": "ipv4.addresses", "ipv4_gateway": "ipv4.gateway", "ipv4_dns": "ipv4.dns", "ipv6_method": "ipv6.method", "ipv6_addresses": "ipv6.addresses", "ipv6_gateway": "ipv6.gateway", "ipv6_dns": "ipv6.dns", "proxy_method": "proxy.method"}
        command = ["nmcli", "connection", "modify", name]
        for key, nm_key in allowed.items():
            if key in values:
                value = "yes" if key == "autoconnect" and values[key] else "no" if key == "autoconnect" else values[key]
                command += [nm_key, str(value)]
        if len(command) == 4:
            raise ValueError("No editable profile values were supplied")
        _run(command, runner)
    elif action == "network-profile-add":
        name, kind = str(payload.get("name", "")).strip(), str(payload.get("type", "wifi"))
        if not name or kind not in {"wifi", "ethernet"}:
            raise ValueError("A valid profile name and type are required")
        if kind == "wifi":
            ssid = str(payload.get("ssid", "")).strip()
            if not ssid:
                raise ValueError("A Wi-Fi profile needs an SSID")
            command = ["nmcli", "connection", "add", "type", "wifi", "ifname", "*", "con-name", name, "ssid", ssid]
        else:
            command = ["nmcli", "connection", "add", "type", "ethernet", "ifname", "*", "con-name", name]
        _run(command, runner)
    elif action == "network-profile-delete":
        name = str(payload.get("name", "")).strip()
        if not name:
            raise ValueError("A connection name is required")
        _run(["nmcli", "connection", "delete", "id", name], runner)
    elif action == "network-wifi-scan":
        _run(["nmcli", "device", "wifi", "rescan"], runner)
    elif action == "network-wifi-connect":
        ssid, password, device = str(payload.get("ssid", "")).strip(), str(payload.get("password", "")), str(payload.get("device", "")).strip()
        if not ssid:
            raise ValueError("A Wi-Fi SSID is required")
        command = ["nmcli", "device", "wifi", "connect", ssid]
        if password: command += ["password", password]
        if device: command += ["ifname", device]
        _run(command, runner)
    elif action.startswith("bluetooth-"):
        names = {"bluetooth-pair": "pair", "bluetooth-trust": "trust", "bluetooth-untrust": "untrust", "bluetooth-block": "block", "bluetooth-unblock": "unblock", "bluetooth-remove": "remove", "bluetooth-connect": "connect", "bluetooth-disconnect": "disconnect"}
        if action in names:
            address = str(payload.get("address", "")).strip()
            if not address: raise ValueError("A Bluetooth device address is required")
            _run(["bluetoothctl", names[action], address], runner)
        elif action in {"bluetooth-pairable", "bluetooth-discoverable"}:
            _run(["bluetoothctl", "pairable" if action.endswith("pairable") else "discoverable", "yes" if payload.get("enabled") else "no"], runner)
        elif action in {"bluetooth-power", "bluetooth-scan"}:
            _run(["bluetoothctl", "power" if action.endswith("power") else "scan", "on" if payload.get("powered", payload.get("discovering")) else "off"], runner)
        else: raise ValueError(f"Invalid system action: {action}")
    else:
        commands = {
            "audio-volume": ["wpctl", "set-volume", str(payload.get("id", "@DEFAULT_AUDIO_SINK@")), str(float(payload.get("volume", 1.0)))],
            "audio-mute": ["wpctl", "set-mute", str(payload.get("id", "@DEFAULT_AUDIO_SINK@")), "1" if payload.get("muted") else "0"],
            "audio-default": ["wpctl", "set-default", str(payload.get("id", ""))],
            "network-up": ["nmcli", "connection", "up", "id", str(payload.get("name", ""))],
            "network-down": ["nmcli", "connection", "down", "id", str(payload.get("name", ""))],
            "audio-input-volume": ["wpctl", "set-volume", str(payload.get("id", "@DEFAULT_AUDIO_SOURCE@")), str(float(payload.get("volume", 1.0)))],
            "audio-input-mute": ["wpctl", "set-mute", str(payload.get("id", "@DEFAULT_AUDIO_SOURCE@")), "1" if payload.get("muted") else "0"],
        }
        command = commands.get(action)
        if not command or any(not value for value in command[1:]): raise ValueError(f"Invalid system action: {action}")
        _run(command, runner)
    return {"ok": True, "action": action}
