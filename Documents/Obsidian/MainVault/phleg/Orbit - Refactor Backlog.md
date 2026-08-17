---
title: Orbit - Refactor Backlog
type: engineering-backlog
tags: [orbit, refactor]
---

# Refactor Backlog

## Priority 1: State And Lifecycle

- [ ] Replace broad `input`-group elevation with a device-specific keyboard ACL or privileged helper, with Alt-release regression coverage. Source: `ORB-INPUT-PERMISSIONS`.
- [x] Make runtime Alt+Tab binding installation retry-aware across compositor startup transitions; fresh-login validation remains. Source: `ORB-STARTUP-BINDINGS`.
- [ ] Centralize atomic state-file writes and advisory locking.
- [ ] Make overview state, revision, and cycle requests one state machine.
- [ ] Select one authoritative Alt-release event source.
- [ ] Serialize or coalesce asynchronous workspace-focus requests during rapid overview cycling. Source: `ORB-ALT-RAPID-CYCLE`.
- [ ] Add duplicate-process and startup readiness tests.

## Priority 2: Runtime Snapshots

- [ ] Consolidate repeated `hyprctl` polling behind shared Orbit models.
- [ ] Remove independent QML polling where event-driven updates are available.
- [ ] Make monitor role and reserved workspace resolution use one source.

## Priority 3: Launch And Routing

- [ ] Unify dock and XMB launch execution and observation.
- [ ] Add launch IDs or PID/address correlation for concurrent same-app launches.
- [ ] Normalize legacy `[[policy]]` and modern `[[rule]]` formats.
- [ ] Resolve Steam toast monitor attribution.

## Priority 4: Settings

- [ ] Split `SettingsModel.qml` by draft lifecycle, application matching, and system actions.
- [ ] Split `orbit-settings` persistence, validation, artifact generation, and runtime adapters.
- [ ] Implement prepare/apply/verify/rollback for display changes.

## Priority 6: Visual Polish And Feature Work

- [ ] Define and implement a cohesive dock-to-XMB transition when the dock launcher is activated; validate with `UI-007` and user approval. Source: `ORB-XMB-TRANSITION`.

## Rules

- Refactor one ownership boundary at a time.
- Add or update a contract before changing state semantics.
- Do not combine visual redesign with lifecycle refactors.
- Preserve unrelated dirty-worktree changes.
