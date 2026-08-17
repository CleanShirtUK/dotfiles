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
COMMAND_TIMEOUT = 10


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
    return subprocess.run(
        args, check=True, capture_output=True, text=True, timeout=COMMAND_TIMEOUT,
    ).stdout.strip()


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
        result = subprocess.run(
            ["systemctl", "--user", "is-active", service],
            capture_output=True,
            text=True,
            timeout=COMMAND_TIMEOUT,
        )
        if result.returncode != 0:
            raise AssertionError(f"{service}: {result.stdout.strip() or result.stderr.strip()}")


def check_overview_bindings():
    require_session()
    bindings = json.loads(command("hyprctl", "binds", "-j"))
    tab = [binding for binding in bindings if str(binding.get("key", "")).upper() == "TAB"]
    assert len(tab) == 1, f"expected exactly one TAB binding, found {len(tab)}"
    binding = tab[0]
    assert int(binding.get("modmask", 0)) & 8, "TAB binding does not require Alt"
    assert binding.get("dispatcher") == "__lua", "Alt+Tab does not use the expected Lua action"
    assert not binding.get("repeat") and not binding.get("release"), "Alt+Tab action must be press-only and non-repeating"

    shell = (Path.home() / ".local/bin/orbit-shell").read_text()
    expected = 'hl.bind(\\"ALT + TAB\\", hl.dsp.exec_cmd(\\"$overview cycle\\"), { repeating = false })'
    assert expected in shell, "runtime Alt+Tab owner does not install the Orbit overview cycle command"


def main() -> int:
    for directory in (LOG_DIR, LOG_DIR / "before", LOG_DIR / "after", LOG_DIR / "artifacts"):
        directory.mkdir(parents=True, exist_ok=True)
    check("LIVE-001", capture_state)
    check("LIVE-002", check_roles)
    check("LIVE-003", check_services)
    check("START-004", check_overview_bindings)
    result_path = LOG_DIR / "live.results.json"
    result_path.write_text(json.dumps({"tests": RESULTS}, indent=2) + "\n")
    print(json.dumps({"tests": RESULTS}, indent=2))
    # A live run with unavailable prerequisites is not a successful validation.
    return 1 if any(item["status"] in {"FAIL", "SKIP"} for item in RESULTS) else 0


if __name__ == "__main__":
    raise SystemExit(main())
