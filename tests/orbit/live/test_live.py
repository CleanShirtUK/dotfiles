#!/usr/bin/env python3
"""Read-only checks against the current user Hyprland session."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path

RESULTS = []
LOG_DIR = Path(os.environ.get("ORBIT_TEST_LOG_DIR", "."))


def check(name, function):
    try:
        function()
    except SkipTest as error:
        RESULTS.append({"id": name, "status": "SKIP", "reason": str(error)})
    except Exception as error:  # noqa: BLE001
        RESULTS.append({"id": name, "status": "FAIL", "error": repr(error)})
    else:
        RESULTS.append({"id": name, "status": "PASS"})


class SkipTest(Exception):
    pass


def command(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout.strip()


def require_session():
    if os.geteuid() == 0:
        raise SkipTest("run as the desktop user, not root")
    if not os.environ.get("XDG_RUNTIME_DIR") or not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        raise SkipTest("Hyprland user-session environment is unavailable")
    if not shutil.which("hyprctl"):
        raise SkipTest("hyprctl is unavailable")


def capture_state():
    require_session()
    for name, args in {
        "monitors": ("hyprctl", "monitors", "-j"),
        "clients": ("hyprctl", "clients", "-j"),
        "workspaces": ("hyprctl", "workspaces", "-j"),
        "activeworkspace": ("hyprctl", "activeworkspace", "-j"),
        "orbit-settings": (str(Path.home() / ".local/bin/orbit-settings"), "snapshot"),
    }.items():
        value = command(*args)
        json.loads(value)
        (LOG_DIR / "before" / f"{name}.json").write_text(value + "\n")


def check_roles():
    require_session()
    monitor = Path.home() / ".local/bin/orbit-monitor"
    command(str(monitor), "list")
    home = command(str(monitor), "resolve", "home")
    gaming = command(str(monitor), "resolve", "gaming")
    if not home or not gaming:
        raise AssertionError(f"empty monitor role result: home={home!r}, gaming={gaming!r}")


def check_services():
    require_session()
    for service in ("orbit-shell.service", "orbit-input-state.service"):
        result = subprocess.run(["systemctl", "--user", "is-active", service], capture_output=True, text=True)
        if result.returncode != 0:
            raise AssertionError(f"{service}: {result.stdout.strip() or result.stderr.strip()}")


def main() -> int:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    check("LIVE-001", capture_state)
    check("LIVE-002", check_roles)
    check("LIVE-003", check_services)
    result_path = LOG_DIR / "live.results.json"
    result_path.write_text(json.dumps({"tests": RESULTS}, indent=2) + "\n")
    print(json.dumps({"tests": RESULTS}, indent=2))
    # A live run with unavailable prerequisites is not a successful validation.
    return 1 if any(item["status"] in {"FAIL", "SKIP"} for item in RESULTS) else 0


if __name__ == "__main__":
    raise SystemExit(main())
