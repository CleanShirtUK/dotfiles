"""Read-only runtime adapters used by the Orbit Settings snapshot.

This module deliberately owns observation only.  Mutating device actions remain
behind the CLI action boundary until each action has its own safety contract.
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
from pathlib import Path


def command_output(command: list[str]) -> str:
    try:
        return subprocess.run(command, check=True, capture_output=True, text=True).stdout.strip()
    except (FileNotFoundError, subprocess.SubprocessError):
        return ""


def parse_volume(node_id: int | str) -> dict:
    fields = command_output(["wpctl", "get-volume", str(node_id)]).split()
    result = {"volume": 1.0, "muted": False}
    if fields:
        try:
            result["volume"] = float(fields[0])
        except ValueError:
            pass
        result["muted"] = "MUTED" in fields
    return result


def parse_audio_status() -> dict:
    sections = {"sinks": [], "sources": [], "streams": []}
    section = ""
    video_seen = False
    for raw_line in command_output(["wpctl", "status"]).splitlines():
        line = re.sub(r"^[│├└─ ]+", "", raw_line.strip())
        if line == "Sinks:":
            section = "sinks"
        elif line == "Sources:":
            section = "video-sources" if video_seen else "sources"
        elif line == "Streams:":
            section = "streams"
        elif line == "Video":
            video_seen, section = True, "video"
        elif line in {"Filters:", "Settings"}:
            section = ""
        match = re.match(r"([* ]?)\s*(\d+)\.\s+(.+?)(?:\s+\[vol: ([0-9.]+)\])?$", line)
        if not match or section not in sections:
            continue
        default, node_id, name, volume = match.groups()
        item = {"id": int(node_id), "name": name.strip(), "default": default == "*"}
        if section in {"sinks", "sources"}:
            item.update(parse_volume(node_id))
            if volume is not None:
                item["volume"] = float(volume)
        elif name.startswith(("input_", "output_", "monitor_")) or "<" in name:
            continue
        sections[section].append(item)
    return {
        **sections,
        "default_sink": next((x["id"] for x in sections["sinks"] if x["default"]), None),
        "default_source": next((x["id"] for x in sections["sources"] if x["default"]), None),
    }


def parse_nmcli_connections() -> list[dict]:
    result = []
    output = command_output(["nmcli", "-t", "--escape", "no", "-f", "NAME,TYPE,DEVICE,STATE,ACTIVE", "connection", "show"])
    for line in output.splitlines():
        fields = line.split(":", 4) + [""] * 5
        if fields[0]:
            result.append({"name": fields[0], "type": fields[1], "device": fields[2], "state": fields[3], "active": fields[4].lower() == "yes", "details": connection_details(fields[0])})
    return result


def connection_details(name: str) -> dict:
    fields = ["connection.id", "connection.type", "connection.autoconnect", "connection.interface-name", "802-11-wireless.ssid", "802-11-wireless.mode", "802-11-wireless-security.key-mgmt", "ipv4.method", "ipv4.addresses", "ipv4.gateway", "ipv4.dns", "ipv6.method", "ipv6.addresses", "ipv6.gateway", "ipv6.dns", "proxy.method"]
    values = command_output(["nmcli", "-t", "--escape", "no", "-g", ",".join(fields), "connection", "show", name]).splitlines()
    values += [""] * (len(fields) - len(values))
    return {"id": values[0], "type": values[1], "autoconnect": values[2].lower() in {"yes", "true"}, "interface": values[3], "ssid": values[4], "wifi_mode": values[5], "security": values[6], "ipv4_method": values[7], "ipv4_addresses": values[8], "ipv4_gateway": values[9], "ipv4_dns": values[10], "ipv6_method": values[11], "ipv6_addresses": values[12], "ipv6_gateway": values[13], "ipv6_dns": values[14], "proxy_method": values[15]}


def parse_nmcli_devices() -> list[dict]:
    result = []
    output = command_output(["nmcli", "-t", "--escape", "no", "-f", "DEVICE,TYPE,STATE,CONNECTION,CON-UUID", "device"])
    for line in output.splitlines():
        fields = line.split(":", 4) + [""] * 5
        if fields[0]:
            result.append({"device": fields[0], "type": fields[1], "state": fields[2], "connection": fields[3], "uuid": fields[4]})
    return result


def parse_nmcli_wifi() -> list[dict]:
    result = []
    output = command_output(["nmcli", "-t", "--escape", "no", "-f", "IN-USE,SSID,MODE,CHAN,RATE,SIGNAL,BARS,SECURITY,DEVICE", "device", "wifi", "list"])
    for line in output.splitlines():
        fields = line.split(":", 8) + [""] * 9
        if fields[1]:
            result.append({"active": fields[0] == "*", "ssid": fields[1], "mode": fields[2], "channel": fields[3], "rate": fields[4], "signal": fields[5], "bars": fields[6], "security": fields[7], "device": fields[8]})
    return result


def parse_bluetooth() -> dict:
    adapter = {"powered": False, "discoverable": False, "pairable": False, "discovering": False}
    for line in command_output(["bluetoothctl", "show"]).splitlines():
        key, separator, value = line.strip().partition(":")
        if separator and key in adapter:
            adapter[key.lower()] = value.strip().lower() == "yes"
    devices = []
    for line in command_output(["bluetoothctl", "devices"]).splitlines():
        fields = line.split(" ", 2)
        if len(fields) == 3 and fields[0] == "Device":
            device = parse_bluetooth_info(fields[1])
            device.setdefault("name", fields[2])
            devices.append(device)
    connected = next((x for x in devices if x.get("connected")), None)
    return {"adapter": adapter, "devices": devices, "address": connected["address"] if connected else "", "connected": bool(connected)}


def parse_bluetooth_info(address: str) -> dict:
    info = {"address": address, "connected": False, "paired": False, "trusted": False, "blocked": False}
    for line in command_output(["bluetoothctl", "info", address]).splitlines():
        key, separator, value = line.strip().partition(":")
        if not separator:
            continue
        value = value.strip()
        if key in {"Connected", "Paired", "Trusted", "Blocked"}:
            info[key.lower()] = value.lower() == "yes"
        elif key == "Name":
            info["name"] = value
        elif key == "Alias":
            info["alias"] = value
        elif key == "Icon":
            info["icon"] = value
        elif key == "RSSI":
            match = re.search(r"-?\d+", value)
            if match:
                info["rssi"] = int(match.group(0))
    return info


def tuned_settings() -> dict:
    if not shutil.which("tuned-adm"):
        return {"backend": "powerprofilesctl", "profile": "", "profiles": []}
    profiles = [m.group(1) for m in (re.match(r"\s*-\s+(.+?)\s+-\s+", line) for line in command_output(["tuned-adm", "list"]).splitlines()) if m]
    active = re.search(r"Current active profile:\s*(\S+)", command_output(["tuned-adm", "active"]))
    return {"backend": "tuned", "profile": active.group(1) if active else "", "profiles": profiles}


def system_snapshot(hypridle_path: Path, defaults_path: Path) -> dict:
    audio = parse_audio_status()
    sink = next((x for x in audio["sinks"] if x["default"]), {"volume": 1.0, "muted": False})
    source = next((x for x in audio["sources"] if x["default"]), {"volume": 1.0, "muted": False})
    connections = parse_nmcli_connections()
    power = tuned_settings()
    for line in command_output(["powerprofilesctl", "list"]).splitlines():
        value = line.strip().lstrip("*").strip()
        if value and value not in power["profiles"]:
            power["profiles"].append(value)
        if value and line.strip().startswith("*") and power["backend"] != "tuned":
            power["profile"] = value
    return {"audio": {**audio, "volume": sink.get("volume", 1.0), "muted": sink.get("muted", False), "input_volume": source.get("volume", 1.0), "input_muted": source.get("muted", False)}, "network": {"devices": parse_nmcli_devices(), "connections": connections, "connection": next((x["name"] for x in connections if x["active"]), ""), "wifi_networks": parse_nmcli_wifi()}, "bluetooth": parse_bluetooth(), "power": power}
