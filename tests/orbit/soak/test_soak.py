#!/usr/bin/env python3
"""Safe, unattended Orbit session soak test.

This intentionally avoids launching applications, changing monitor profiles,
or changing system device state. It exercises the shell's observable control
and snapshot paths while watching for service restarts, malformed state, IPC
failures, and unbounded QuickShell memory growth.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import signal
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
HOME = Path.home()
BIN = HOME / ".local/bin"
STOP = False


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def run(command: list[str], timeout: float = 10, env: dict[str, str] | None = None) -> tuple[int, str, str]:
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=timeout, env=env)
    except (OSError, subprocess.TimeoutExpired) as error:
        return 124, "", str(error)
    return result.returncode, result.stdout.strip(), result.stderr.strip()


def json_command(command: list[str]) -> tuple[object | None, str | None]:
    code, stdout, stderr = run(command)
    if code != 0:
        return None, f"exit={code}: {stderr or stdout}"
    try:
        return json.loads(stdout), None
    except json.JSONDecodeError as error:
        return None, f"invalid JSON: {error}"


def sha256_tree(path: Path) -> str:
    digest = hashlib.sha256()
    if not path.exists():
        return "missing"
    for item in sorted(path.rglob("*")):
        if item.is_file():
            digest.update(str(item.relative_to(path)).encode())
            digest.update(item.read_bytes())
    return digest.hexdigest()


def service_state(service: str) -> dict[str, str]:
    code, stdout, stderr = run([
        "systemctl", "--user", "show", service,
        "--property=ActiveState", "--property=SubState", "--property=MainPID",
        "--property=NRestarts",
    ])
    if code != 0:
        raise RuntimeError(f"{service}: {stderr or stdout}")
    values = {}
    for line in stdout.splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            values[key] = value
    return values


def process_rss_kib(pid: str) -> int:
    if not pid.isdigit() or pid == "0":
        return 0
    code, stdout, _ = run(["ps", "-o", "rss=", "-p", pid])
    if code != 0:
        return 0
    try:
        return int(stdout.strip() or 0)
    except ValueError:
        return 0


def snapshot(log_dir: Path, iteration: int, event: dict) -> None:
    captured = {}
    commands = {
        "monitors": ["hyprctl", "monitors", "-j"],
        "clients": ["hyprctl", "clients", "-j"],
        "workspaces": ["hyprctl", "workspaces", "-j"],
        "activeworkspace": ["hyprctl", "activeworkspace", "-j"],
        "settings": [str(BIN / "orbit-settings"), "snapshot"],
    }
    for name, command in commands.items():
        value, error = json_command(command)
        if error:
            raise RuntimeError(f"{name}: {error}")
        captured[name] = value
    path = log_dir / "snapshots" / f"{iteration:06d}.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({"time": utc_now(), "event": event, "state": captured}, indent=2) + "\n")


def capture_journal(log_dir: Path, label: str, since: float) -> float:
    until = time.time()
    code, stdout, stderr = run([
        "journalctl", "--user", "-u", "orbit-shell.service",
        "--since", f"@{since:.3f}", "--until", f"@{until:.3f}",
        "--output=short-iso-precise", "--no-pager",
    ])
    if code == 0:
        journal_path = log_dir / "journal" / f"{label}.log"
        journal_path.parent.mkdir(parents=True, exist_ok=True)
        journal_path.write_text(stdout + "\n")
    elif stderr:
        with (log_dir / "journal-errors.log").open("a") as stream:
            stream.write(stderr + "\n")
    return until


def exercise_safe_state_paths() -> list[str]:
    failures = []
    commands = [
        [str(BIN / "orbit-xmb"), "open"],
        [str(BIN / "orbit-xmb"), "close"],
        [str(BIN / "orbit-overview"), "cycle"],
        [str(BIN / "orbit-overview"), "close"],
        [str(BIN / "orbit-overview"), "close-state"],
    ]
    for command in commands:
        code, stdout, stderr = run(command)
        if code != 0:
            failures.append(f"{' '.join(command)}: exit={code}: {stderr or stdout}")
    cache = Path(os.environ.get("XDG_CACHE_HOME", HOME / ".cache")) / "orbit"
    for name in ("xmb-visible", "overview-visible"):
        path = cache / name
        if path.exists() and not path.read_text().strip():
            failures.append(f"empty state file: {path}")
    if (cache / "overview-cycle").exists():
        failures.append(f"obsolete overview cycle state remains: {cache / 'overview-cycle'}")
    return failures


def signal_handler(_signum, _frame):
    global STOP
    STOP = True


def sleep_interruptibly(seconds: float) -> None:
    wake_at = time.monotonic() + seconds
    while not STOP:
        remaining = wake_at - time.monotonic()
        if remaining <= 0:
            return
        time.sleep(min(1.0, remaining))


def main() -> int:
    parser = argparse.ArgumentParser(prog="orbit-soak")
    duration_group = parser.add_mutually_exclusive_group()
    duration_group.add_argument("--hours", type=float, default=None, help="actual soak duration (default: 8)")
    duration_group.add_argument(
        "--minutes", type=float, choices=(1.0, 2.0), default=None,
        help="explicit one- or two-minute smoke run, not soak evidence",
    )
    parser.add_argument("--interval", type=float, default=30.0)
    parser.add_argument("--max-rss-mb", type=int, default=1024)
    parser.add_argument("--snapshot-every", type=int, default=10)
    args = parser.parse_args()
    mode = "smoke" if args.minutes is not None else "soak"
    duration = args.minutes * 60 if args.minutes is not None else (args.hours if args.hours is not None else 8.0) * 3600
    if duration < 0:
        parser.error("duration must not be negative")
    if mode == "soak" and duration < 3600:
        parser.error("actual soak duration must be at least one hour; use --minutes 1 or 2 for smoke")
    if args.interval <= 0 or args.snapshot_every <= 0:
        parser.error("interval and snapshot-every must be positive")

    state_root = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "orbit/tests"
    run_dir = state_root / f"soak-{datetime.now(timezone.utc).strftime('%Y-%m-%dT%H-%M-%SZ')}-{os.getpid()}"
    run_dir.mkdir(parents=True, exist_ok=True)
    events_path = run_dir / "events.jsonl"
    result_path = run_dir / "summary.json"
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    failures = []
    start = time.monotonic()
    deadline = start + duration
    baseline_service = None
    baseline_tree = sha256_tree(HOME / ".config/orbit/generated")
    if baseline_tree == "missing":
        failures.append("generated theme artifact tree is missing at start")
    maximum_rss = 0
    iteration = 0
    journal_since = time.time()

    def event(value: dict):
        value = {"time": utc_now(), **value}
        with events_path.open("a") as stream:
            stream.write(json.dumps(value) + "\n")

    baseline_environment = {
        **os.environ,
        "ORBIT_TEST_LOG_DIR": str(run_dir / "contract-baseline"),
    }
    code, stdout, stderr = run(
        [str(ROOT / "tests/orbit/run-all")], timeout=180, env=baseline_environment,
    )
    event({"kind": "contract-baseline", "exit": code, "stdout": stdout, "stderr": stderr})
    if code != 0:
        failures.append("contract baseline failed")

    try:
        baseline_service = service_state("orbit-shell.service")
        if baseline_service.get("ActiveState") != "active":
            failures.append(f"orbit-shell not active at start: {baseline_service}")
        if not baseline_service.get("MainPID", "").isdigit() or baseline_service.get("MainPID") == "0":
            failures.append(f"orbit-shell has no MainPID at start: {baseline_service}")
        event({"kind": "baseline", "service": baseline_service, "generated_sha256": baseline_tree})
    except RuntimeError as error:
        failures.append(str(error))

    while not STOP and time.monotonic() <= deadline:
        iteration += 1
        began = time.monotonic()
        current = {"kind": "iteration", "iteration": iteration}
        current_failures = exercise_safe_state_paths()
        try:
            service = service_state("orbit-shell.service")
            current["service"] = service
            if service.get("ActiveState") != "active":
                current_failures.append(f"orbit-shell state: {service}")
            if baseline_service and service.get("NRestarts") != baseline_service.get("NRestarts"):
                current_failures.append(f"orbit-shell restarted: {baseline_service.get('NRestarts')} -> {service.get('NRestarts')}")
            if baseline_service and service.get("MainPID") != baseline_service.get("MainPID"):
                current_failures.append(f"orbit-shell MainPID changed: {baseline_service.get('MainPID')} -> {service.get('MainPID')}")
            rss = process_rss_kib(service.get("MainPID", "0"))
            maximum_rss = max(maximum_rss, rss)
            current["rss_kib"] = rss
            if rss > args.max_rss_mb * 1024:
                current_failures.append(f"orbit-shell RSS exceeded limit: {rss} KiB")
            tree = sha256_tree(HOME / ".config/orbit/generated")
            current["generated_sha256"] = tree
            if tree == "missing":
                current_failures.append("generated theme artifact tree is missing")
            elif tree != baseline_tree:
                current_failures.append("generated theme artifacts changed during soak")
            if iteration % args.snapshot_every == 0 or iteration == 1:
                snapshot(run_dir, iteration, current)
                journal_since = capture_journal(run_dir, f"{iteration:06d}", journal_since)
        except Exception as error:  # noqa: BLE001 - retain the failure and continue soaking
            current_failures.append(repr(error))
        current["failures"] = current_failures
        current["elapsed_seconds"] = round(time.monotonic() - start, 3)
        current["duration_seconds"] = round(time.monotonic() - began, 3)
        event(current)
        if current_failures:
            failures.extend(f"iteration {iteration}: {failure}" for failure in current_failures)
        remaining = deadline - time.monotonic()
        if remaining > 0 and not STOP:
            sleep_interruptibly(min(args.interval, remaining))

    journal_since = capture_journal(run_dir, "final", journal_since)
    status = "INCOMPLETE" if STOP else ("PASS" if not failures else "FAIL")
    summary = {
        "run_id": run_dir.name,
        "mode": mode,
        "status": status,
        "requested_duration_seconds": duration,
        "elapsed_seconds": round(time.monotonic() - start, 3),
        "iterations": iteration,
        "maximum_orbit_shell_rss_kib": maximum_rss,
        "interrupted": STOP,
        "failures": failures,
        "log_dir": str(run_dir),
    }
    result_path.write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps(summary, indent=2))
    print(f"Logs: {run_dir}")
    if STOP:
        return 2
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
