---
title: Orbit - Refactor Backlog
type: engineering-backlog
tags: [orbit, refactor]
---

# Refactor Backlog

## Priority 1: State And Lifecycle

- [ ] Centralize atomic state-file writes and advisory locking.
- [ ] Make overview state, revision, and cycle requests one state machine.
- [ ] Select one authoritative Alt-release event source.
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

## Rules

- Refactor one ownership boundary at a time.
- Add or update a contract before changing state semantics.
- Do not combine visual redesign with lifecycle refactors.
- Preserve unrelated dirty-worktree changes.
