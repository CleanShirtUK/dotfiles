---
title: Orbit - Repository Boundaries
type: architecture-decision
tags: [orbit, architecture, repositories]
---

# Orbit Repository Boundaries

## Target End State

The project will be managed as three repositories once the boundaries are stable:

| Repository | Owns | Must not own |
| --- | --- | --- |
| Standard dotfiles | A reproducible desktop setup, unrelated application configuration, dependency installation, and integration wiring | Orbit implementation internals or wallpaper implementation internals |
| Orbit | QuickShell surfaces, Orbit scripts, Orbit services, Orbit-only configuration, tests, and Orbit documentation | Unrelated desktop dotfiles or wallpaper implementation |
| Wallpaper | A standalone PS3 wave wallpaper project, its renderer, service, and user-facing configuration | A dependency on Orbit |

## Dependency Direction

- Standard dotfiles may depend on Orbit and Wallpaper to reproduce the complete desktop setup.
- Orbit may depend on Wallpaper's documented configuration and service interfaces.
- Wallpaper must remain fully usable without Orbit.
- Orbit settings will eventually write or adapt Wallpaper configuration files rather than embedding wallpaper implementation details.
- Orbit and Wallpaper must not require unrelated standard dotfiles to function.

## Migration Rule

This is a target boundary, not a request to split the current worktree immediately. The current repository is a transitional combined dotfiles repository. Split files only after each project's installation, configuration, dependency, and test contracts are explicit and independently reproducible.

## Required Future Contracts

- Standard dotfiles documents how to install and enable Orbit and Wallpaper as optional or complete-setup dependencies.
- Orbit documents its minimum Hyprland, QuickShell, runtime, and Wallpaper interface dependencies.
- Wallpaper documents standalone installation, configuration, service lifecycle, and operation without Orbit.
- Orbit settings integration writes only the documented Wallpaper configuration surface.

See [[Orbit - Architecture]] and [[Orbit - Status]] for current ownership and migration status.
