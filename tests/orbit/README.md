# Orbit Test Suite

Run deterministic tests without mutating the live desktop:

```sh
tests/orbit/run-all
```

Every `test_*` contract function is registered against one unique stable Test
Matrix ID. The runner performs a registry self-check before executing tests, so
an unregistered future function, duplicate ID, or duplicate registration fails
the run. If `tests/orbit/validate-project.py` exists, `run-all` invokes it first;
its absence is reported as `SKIP` and is not an error.

Run those tests plus read-only checks against the current Hyprland session:

```sh
tests/orbit/run-all --live
```

Run the safe overnight soak mode for eight hours by default:

```sh
tests/orbit/run-soak --hours 8 --interval 30
```

Use an explicitly short smoke run before relying on a new soak change:

```sh
tests/orbit/run-soak --minutes 2 --interval 5 --snapshot-every 1
```

`--minutes` accepts only one or two minutes and records `mode: smoke`; it is not
soak evidence. An actual soak uses `--hours` (or the eight-hour default) and
records `mode: soak`.

The live mode must run as the desktop user with `XDG_RUNTIME_DIR`,
`HYPRLAND_INSTANCE_SIGNATURE`, and the user D-Bus environment intact. A root
shell should invoke the command as the desktop user rather than relying on
`sudo` to preserve those variables.

Results are written beneath `${XDG_STATE_HOME:-$HOME/.local/state}/orbit/tests`.
Each run has raw stdout/stderr, captured state, per-test results, and a
machine-readable `summary.json`. Contract failures exit 1. Missing live-session
or hardware prerequisites are reported as `SKIP` and make a live run non-zero;
they never become passes.

`environment.txt` is deliberately allowlisted. It records Git HEAD/tree and
hashed dirty-state evidence, tool versions, and only presence/absence for safe
session prerequisites. It never dumps the process environment or variable
values that may contain credentials.

The suite is intentionally non-destructive. Display mutation, monitor hotplug,
VRR, application launch routing, visual placement, prompt ownership, and
cross-toolkit appearance require an attended or disposable-session test pass.
Use `tests/orbit/run-manual` in an interactive terminal for those gates. Commands
that can launch applications, restart services, alter hardware state, or end a
session remain operator-attended; the runner does not silently approve them.

The soak runner repeatedly opens and closes the XMB and overview through their
control paths, polls Hyprland monitor/client/workspace state, reads the Orbit
settings snapshot, checks the Orbit shell service, watches its restart counter
and `MainPID`, watches main-process RSS, captures user journal output bounded to
the run window, and checks that generated theme artifacts exist and remain
unchanged. It records every iteration in `events.jsonl` and periodic full state
in `snapshots/`. A service restart or PID replacement, malformed snapshot,
failed IPC helper, missing or changed generated tree, or RSS limit breach makes
the final result fail while allowing the run to collect more evidence. SIGINT
or SIGTERM produces `INCOMPLETE` and exits 2, even when no check had failed.
