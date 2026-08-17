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
| Shell visibility transition | `.local/bin/orbit-shell-ui` + Orbit state file |
| Monitor identity | `.local/bin/orbit-monitor` |
| Workspace/application routing | `dynamic-app-workspaces` + `orbit-app-policy` |
| Persistent dock pins | `.local/bin/orbit-dock` |
| Palette generation | `.local/bin/orbit-theme` |
| System settings actions | `.local/bin/orbit-settings` |
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
- A generated artifact is evidence of generation, not proof of runtime behavior.

## Configuration Sources

- `.config/orbit/settings.toml`: monitor roles, appearance, wallpaper, display profiles.
- `.config/orbit/app-policies.toml`: application routing policy.
- `.config/orbit/xmb.json`: launcher categories and classification.
- `.config/orbit/generated/`: generated runtime artifacts.
