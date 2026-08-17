---
title: Orbit - Refactor Backlog
type: engineering-backlog
tags: [orbit, refactor]
---

# Refactor Backlog

## Priority 1: State And Lifecycle

- [x] Replace broad input handling with an allowlisted keyboard-only helper and Alt-release regression coverage; the service-scoped `input` compatibility path remains documented for future ACL replacement. Source: `ORB-INPUT-PERMISSIONS`.
- [x] Make runtime Alt+Tab binding ownership durable across compositor transitions: validate the exact trigger, supervise it for the QuickShell lifetime, reinstall it after loss, and fail closed if bounded recovery fails. The disposable transition fixture passes; current live and attended revalidation remain `VQ-20260817-18`. Source: `ORB-STARTUP-BINDINGS`.
- [x] Centralize atomic state-file writes and advisory locking for shell visibility, XMB, and overview runtime state files; persistent configuration writers remain separately owned.
- [x] Make overview visibility, revision, and cycle requests one state machine in the authoritative `overview-visible` state file; remove the separate cycle request file.
- [x] Select the allowlisted `orbit-input-state` helper as the authoritative Alt-release source; remove duplicate Hyprland `bindr` release actions.
- [x] Serialize or coalesce asynchronous workspace-focus requests during rapid overview cycling; the authoritative overview state file now counts cycle requests under the shared lock, and QML consumes each revision once. Contract/live checks and attended rapid-cycle validation pass. Source: `ORB-ALT-RAPID-CYCLE`.
- [x] Add duplicate-process and startup readiness tests; `START-008` covers the
  QuickShell `--no-duplicate` guard and bounded Wayland/Hyprland readiness wait.
- [x] Add dock icon startup readiness and reconciliation coverage; attended `START-005` validation passed. Source: `ORB-DOCK-ICON-STARTUP`.

## Priority 2: Runtime Snapshots

- [x] Correct dock and top-panel application close actions for Hyprland 0.56.1's Lua dispatcher syntax; disposable close fixture passed. Source: `ORB-APP-CLOSE-DISPATCH` / `UI-019`.

- [x] Consolidate the core monitor, client, workspace, and active-workspace `hyprctl` polling behind shared `HyprlandModel.qml`; settings matching and external menu bridges retain their narrower polling boundaries.
- [x] Remove the independent SettingsModel `hyprctl clients -j` poll; application matching now consumes `HyprlandModel.qml` client updates. Source: `ORB-RUNTIME-INDEPENDENT-POLLING` / `STATE-009`.
- [x] Make monitor role and reserved workspace resolution use one source; `[monitors.<role].workspace` and `orbit-monitor workspace-for-monitor` now drive the dynamic workspace daemon and persistent blank-workspace helper. Source: `ORB-MONITOR-WORKSPACE-SOURCE` / `STATE-010` / `ORB-BLANK-WORKSPACE-RESOLUTION`.
- [x] Release the dock-to-XMB morph state at handoff so dock-launched XMB can claim keyboard focus; attended validation remains. Source: `ORB-XMB-DOCK-FOCUS` / `UI-018`.

## Priority 3: Launch And Routing

- [x] Unify dock and XMB launch execution and observation through the shared
  `orbit-app-launch` scope/routing boundary and `orbit-app-observe` identity
  recorder; attended cross-surface launch validation remains queued. Source:
  `ORB-APP-LAUNCH-BOUNDARY` / `APP-009`.
- [x] Add launch IDs and PID/address correlation for concurrent same-app launches; attended fixture validation remains queued. Source: `ORB-APP-CONCURRENT-CORRELATION` / `APP-010`.
- [x] Normalize legacy `[[policy]]` and modern `[[rule]]` formats; the resolver
  now converts both schemas to one matching representation while preserving
  modern priority precedence. Source: `APP-001`.
- [x] Resolve Steam toast monitor attribution by correlating floating Steam surfaces with the visible non-floating Steam client without PID equality; attended toast validation remains queued. Source: `ORB-STEAM-TOAST` / `APP-006`.
- [x] Preserve launch monitor/workspace context across delayed window creation; attended fixture remains. Source: `ORB-APP-FOCUS-RACE` / `APP-007`.
- [x] Normalize Desktop Entry field codes at the shared launch boundary so no-file `%U`/`%F` values are not passed as literal paths; attended relaunch remains. Source: `ORB-APP-EXEC-FIELDS` / `APP-008`.
- [ ] Complete the cross-toolkit palette runtime matrix; deterministic adapter-install coverage now exists, while attended live/reload/restart evidence remains queued. Source: `ORB-THEME-PROPAGATION` / `THEME-003` / `VQ-20260817-11`.

## Priority 4: Settings

- [x] Split `SettingsModel.qml` by draft lifecycle, application matching, and system actions; each boundary now has a dedicated QML owner with compatibility wrappers in the parent.
- [x] Extract system-action process execution into `SettingsSystemActions.qml` while preserving the `SettingsModel.qml` compatibility API. Source: `ORB-SETTINGS-MODEL-BOUNDARIES`.
- [x] Split `orbit-settings` persistence, validation, artifact generation, and runtime adapters. Persistence, validation, artifact generation, read-only observation, and mutating runtime actions are isolated in dedicated `.local/lib/orbit_settings_*.py` modules; CLI compatibility wrappers preserve the public surface. Source: `ORB-SETTINGS-ACTIONS-BOUNDARY` / `SET-010`.
- [x] Extract the read-only Settings runtime snapshot adapters into `.local/lib/orbit_settings_runtime.py` while retaining the CLI compatibility wrapper; mutating actions were subsequently isolated in `.local/lib/orbit_settings_actions.py`. Source: `SET-009` / `SET-010`.
- [x] Extract `orbit-settings` artifact generation into `.local/lib/orbit_settings_artifacts.py`; compatibility wrappers preserve the CLI boundary. Source: `ORB-SETTINGS-PYTHON-BOUNDARIES` / `SET-006`.
- [x] Implement prepare/apply/verify/rollback for display changes; deterministic failure recovery passes, while disposable hardware/live recovery remains queued. Source: `ORB-DISPLAY-RECOVERY` / `SET-003`.
- [ ] Define and implement editable keybinds in Orbit Settings. Source: `DES-20260816-04` (original scratchpad label `DES-20260816-03`).
- [ ] Define and implement dock size, magnification, opacity, and padding controls in Orbit Settings. Source: `DES-20260817-01`.

## Priority 6: Visual Polish And Feature Work

- [ ] Validate and, if needed, correct the cohesive dock-to-XMB transition when the dock launcher is activated; the recorded smoke check did not establish attended continuity. Source: `ORB-XMB-TRANSITION`.
- [ ] Validate and, if needed, correct dock-to-XMB handoff blanking without expanding feature scope. The implementation keeps the morph surface painted through handoff; only attended continuity/recovery evidence remains. Source: `ORB-XMB-BLANKING`.
- [ ] Validate the implemented 30% shell opacity and unchanged transparent top panel under Hyprglass on both monitors; the contract is implemented and only the attended visual gate remains. Source: `ORB-SURFACE-TRANSPARENCY` / `THEME-004`.
- [x] Add a standard icon fallback for the synthetic Orbit Settings dock entry; attended inspection remains. Source: `ORB-DOCK-SETTINGS-ICON` / `UI-008`.
- [x] Correct dock boundary entry magnification so it follows continuous in-dock interpolation; `hoverAmount` now ramps into the existing `scaleAt()` function. Attended two-monitor validation remains queued. Source: `ORB-DOCK-MAGNIFICATION-EDGE` / `UI-009`.
- [ ] Define and persist user-overridable top-panel nerd-font tray aliases. Source: `DES-20260817-02` / `UI-010`.
- [x] Implement global application menus on both Orbit panels with per-monitor application selection, desktop-name fallback, XWayland DBusMenu, native-Wayland AT-SPI, and honest fallback actions. Source: `DES-20260817-04` / `UI-011` / `UI-012` / `UI-013` / `UI-016`.
- [ ] Complete two-monitor interaction, destructive fallback-action, GTK4 coverage, and Electron coverage validation without claiming unsupported menu extraction. Source: `UI-011` / `UI-014` / `UI-015`.

## Rules

- Refactor one ownership boundary at a time.
- Add or update a contract before changing state semantics.
- Do not combine visual redesign with lifecycle refactors.
- Preserve unrelated dirty-worktree changes.
- Resolve stabilization and revalidation items before feature work.
- Treat `orbit/project-manifest.json` as canonical and validate this Markdown view against it.
