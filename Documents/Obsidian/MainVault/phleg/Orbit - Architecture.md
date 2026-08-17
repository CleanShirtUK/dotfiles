---
title: Orbit - Architecture
type: technical-reference
tags: [orbit, architecture]
---

# Orbit Architecture

The planned repository split is documented in [[Orbit - Repository Boundaries]]. The current worktree is still a transitional combined dotfiles repository.

## Ownership

| Responsibility | Owner |
| --- | --- |
| Session startup and environment import | Hyprland startup hook + user systemd |
| Shell surfaces | QuickShell `.config/quickshell/orbit/` |
| Top panel | QuickShell `TopPanel.qml`; native system tray service and shared theme |
| Global application menu | Orbit top panels + desktop-entry/window-class identity tracking + application menu protocol |
| Shell visibility transition | `.local/bin/orbit-shell-ui` + Orbit state file |
| Monitor identity | `.local/bin/orbit-monitor` |
| Reserved workspace identity | `.config/orbit/settings.toml` `[monitors.<role].workspace`, resolved by `.local/bin/orbit-monitor` |
| Workspace/application routing | `dynamic-app-workspaces` + `orbit-app-policy` |
| Core Hyprland runtime snapshot | QuickShell `HyprlandModel.qml` |
| Application launch identity correlation | `.local/bin/orbit-app-observe` launch IDs plus `.local/bin/orbit-app-launch` process-environment/client matching |
| Persistent dock pins | `.local/bin/orbit-dock` |
| Palette generation | `.local/bin/orbit-theme` |
| System settings actions | `.local/bin/orbit-settings` |
| Orbit settings persistence primitives | `.local/lib/orbit_settings_persistence.py` |
| Orbit settings validation | `.local/lib/orbit_settings_validation.py` |
| Orbit settings runtime observation | `.local/lib/orbit_settings_runtime.py` |
| Orbit settings mutating runtime actions | `.local/lib/orbit_settings_actions.py` |
| Settings system-action process boundary | QuickShell `SettingsSystemActions.qml` |
| Settings application matching and client observation | QuickShell `SettingsApplicationMatching.qml` |
| Settings draft lifecycle and apply transaction | QuickShell `SettingsDraftLifecycle.qml` |
| Wallpaper rendering | `ps3-wave-wallpaper.service` |

## Surface Rules

- The dock is global and may appear on every connected monitor.
- XMB is a layer-shell overlay on the focused monitor only.
- XMB never owns a workspace and never launches a fullscreen managed client.
- Overview is a shell surface; it does not create a workspace.
- Normal applications launch on the focused monitor unless policy routes them elsewhere.

## State Principles

- One authoritative writer per state machine.
- State files must be atomic and revision-aware.
- Runtime snapshots should be shared rather than independently polling Hyprland.
- `HyprlandModel.qml` owns the core monitor, client, workspace, and active-workspace snapshot; feature-specific helpers may retain narrower external polling boundaries.
- A generated artifact is evidence of generation, not proof of runtime behavior.

## Configuration Sources

- `.config/orbit/settings.toml`: monitor roles, appearance, wallpaper, display profiles.
- `.config/orbit/settings.toml` `[input]`: Hyprland pointer-focus policy, including `follow_mouse`.
- `.config/orbit/app-policies.toml`: application routing policy.
- `.config/orbit/xmb.json`: launcher categories and classification.
- `.config/orbit/generated/`: generated runtime artifacts.

## Existing Tooling And Dependency Policy

- Search existing repository, distribution, desktop, QuickShell, Hyprland, and protocol tooling before implementing a new capability.
- Prefer a maintained or purpose-built existing tool integrated at a narrow ownership boundary over a new Orbit replacement.
- Every adopted tool must have a documented source, exact version or commit, runtime and build dependencies, installation/enablement method, lifecycle owner, and fallback behavior.
- Keep build-only dependencies separate from runtime dependencies, and do not silently enable global environment changes when a per-application or per-service configuration is sufficient.
- Validate the tool independently before wiring it into Orbit; a working protocol fixture or service is evidence of the dependency, not proof that Orbit integration is complete.
- If no suitable tool exists, record the search and the reason a new implementation is necessary before adding one.

## Input State Helper Boundary

- `.local/bin/orbit-input-state` uses `pyudev` 0.24.4 to enumerate input event nodes and reads only keyboard devices whose `ID_SERIAL` is explicitly listed in `.config/orbit/input-devices.toml`.
- The user service retains its existing `/usr/bin/sg input` compatibility path because the current user manager cannot add the `input` supplementary group after it was changed during the session; the group is granted only to this service, not Orbit shell processes.
- Missing `pyudev`, missing configuration, malformed configuration, or an empty allowlist fails closed. Hardware changes require an explicit allowlist update and fresh-login validation.

## Alt-Release Ownership

- `orbit-input-state` is the authoritative source for physical Alt release; `OverviewModel.qml` closes the overview only after observing the helper's `1 → 0` transition.
- Hyprland owns the `Alt+Tab` trigger only. It must not independently close the overview through `bindr Alt_L` or `bindr Alt_R` actions.
