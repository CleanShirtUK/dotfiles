# Orbit Test Suite

Run deterministic tests without mutating the live desktop:

```sh
tests/orbit/run-all
```

Run those tests plus read-only checks against the current Hyprland session:

```sh
tests/orbit/run-all --live
```

Run the safe overnight soak mode for eight hours by default:

```sh
tests/orbit/run-soak --hours 8 --interval 30
```

Use a short smoke run before relying on a new soak change:

```sh
tests/orbit/run-soak --minutes 2 --interval 5 --snapshot-every 1
```

The live mode must run as the desktop user with `XDG_RUNTIME_DIR`,
`HYPRLAND_INSTANCE_SIGNATURE`, and the user D-Bus environment intact. A root
shell should invoke the command as the desktop user rather than relying on
`sudo` to preserve those variables.

Results are written beneath `${XDG_STATE_HOME:-$HOME/.local/state}/orbit/tests`.
Each run has raw stdout/stderr, captured state, per-test results, and a
machine-readable `summary.json`. Contract failures exit 1. Missing live-session
or hardware prerequisites are reported as `SKIP` and make a live run non-zero;
they never become passes.

The suite is intentionally non-destructive. Display mutation, monitor hotplug,
VRR, application launch routing, visual placement, prompt ownership, and
cross-toolkit appearance require an attended or disposable-session test pass.

The soak runner repeatedly opens and closes the XMB and overview through their
control paths, polls Hyprland monitor/client/workspace state, reads the Orbit
settings snapshot, checks the Orbit shell service, watches its restart counter
and main-process RSS, captures recent user journal output, and checks that
generated theme artifacts remain unchanged. It records every iteration in
`events.jsonl` and periodic full state in `snapshots/`. A service restart,
malformed snapshot, failed IPC helper, generated-artifact mutation, or RSS
limit breach makes the final result fail while allowing the run to collect
more evidence.
