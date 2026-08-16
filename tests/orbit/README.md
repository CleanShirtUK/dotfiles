# Orbit Test Suite

Run deterministic tests without mutating the live desktop:

```sh
tests/orbit/run-all
```

Run those tests plus read-only checks against the current Hyprland session:

```sh
tests/orbit/run-all --live
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
