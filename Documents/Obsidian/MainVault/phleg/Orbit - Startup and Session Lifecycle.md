---
title: Orbit - Startup and Session Lifecycle
type: runbook
tags: [orbit, startup, hyprland]
---

# Startup And Session Lifecycle

## Login

1. Hyprland starts and imports the current Wayland/session environment into the user manager.
2. `hyprland-session.target` is started.
3. `orbit-shell.service` starts with restart-on-failure protection.
4. `orbit-shell` waits for the Wayland and Hyprland environment before launching QuickShell.
5. The wallpaper service starts and `wallpaper-session-effects` hides/reveals Orbit through `orbit-shell-ui`.

## Lock / Unlock

- Lock enters the configured blank special workspaces and sends the wallpaper exit transition.
- Unlock starts the wallpaper intro, reveals Orbit, waits for shell readiness, and restores workspaces.
- Noctalia IPC is not part of this lifecycle.

## Shutdown

- Orbit is hidden.
- Special workspaces are blanked.
- The wallpaper exit transition and logout sound run.
- The session terminates.

## Recovery Checks

```sh
systemctl --user status orbit-shell.service
systemctl --user status wallpaper-session-effects.service
systemctl --user is-enabled noctalia.service
hyprctl clients -j | jq '[.[] | select(.title | startswith("phleg-xmb-"))]'
```

Expected results: Orbit active, wallpaper transition service active or completed as designed, Noctalia absent/disabled, and no prototype clients.
