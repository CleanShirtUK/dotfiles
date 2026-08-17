---
title: Orbit - Change Log
type: project-changelog
tags: [orbit, history]
---

# Orbit Change Log

## 2026-08-16

- Orbit became the intended Hyprland shell autostart.
- Noctalia session autostart and the reserved-workspace anchor service were removed from tracked configuration.
- The legacy fullscreen reserved-workspace XMB implementations were removed.
- Wallpaper transition scripts now control Orbit shell visibility instead of calling Noctalia IPC.
- Documentation was split into linked project, testing, issue, decision, refactor, and validation pages.
- Contract, live, and two-minute soak validation passed after the migration. The live run required the current `HYPRLAND_INSTANCE_SIGNATURE` because the terminal had inherited a stale compositor signature after the session transition.
- Added a context-clean prompt repository and freeform session scratchpad for repeatable OpenCode workflows.

Older implementation history remains available in Git history and should be summarized here only after current evidence is reproduced.

## 2026-08-17

- `ORB-DISPLAY-RECOVERY`: display role/profile applies now use a transactional file/runtime snapshot, post-apply dimension verification, and explicit rollback on command, reload, or verification failure. Added the deterministic `SET-003` failure fixture; disposable hardware recovery remains `VQ-20260817-12`.
- Confirmed rapid Alt+Tab workspace switching and startup binding lifecycle after fresh-login and attended validation.
- Initially adopted immediate commit/push for confirmed fixes; the normalized policy now requires independent per-item verification first, followed by one item-scoped direct-to-`main` commit and push.
- Documented the target split into Standard dotfiles, Orbit, and standalone Wallpaper repositories; the current combined repository remains transitional.
- Updated Prompt 2 so selecting one-feature work first presents the current open feature/correction choices from repository evidence.
- Added the existing-tooling/dependency policy: search and validate available tools first, document exact provenance and dependencies, and keep build-only/runtime requirements separate.
- Researched native-Wayland menu options: Heaven is an early protocol/library candidate with no Hyprland or application integrations, while `yolo-labz/noctalia-appmenu` is an active AT-SPI bridge with real Qt6/GTK4/Electron coverage but niri-only focus tracking.
- Centralized atomic replacement and advisory locking for shell visibility, XMB, overview, and cycle-request runtime state in `.local/lib/orbit-state`; `STATE-003` passed in the 24-check contract run.
- Added a first-pass udev-identity allowlist for `orbit-input-state`; at that point current-service and contract validation passed while fresh-login and attended Alt-release gates remained open.
- Consolidated overview visibility, revision, and cycle requests into the authoritative `overview-visible` state file and removed the separate `overview-cycle` path; the 25-check contract, live, and one-minute soak validation passed.
- Selected `orbit-input-state` as the sole Alt-release authority and removed duplicate Hyprland Alt-release actions; the 25-check contract and 29-check live suites passed after shell restart.
- Corrected repeated overview refocus by ignoring equal state revisions; contract and live suites passed after QuickShell restart. Manual retest is tracked as `ORB-OVERVIEW-STATE-REFRESH`.
- Added delayed overview `FocusScope` refocus after workspace dispatch to preserve Tab cycling when a floating client receives focus; manual floating-window validation is tracked as `ORB-OVERVIEW-FLOATING-CYCLE`.
- Closed `ORB-OVERVIEW-STATE-REFRESH` and `ORB-OVERVIEW-FLOATING-CYCLE` after attended standard-speed cycling passed with and without floating windows.
- Added a per-item fresh-session worker workflow, append-only validation queue, and sequential approval protocol so autonomous implementation is not blocked by attended validation.
- Documented the `systemd-inhibit --what=idle:sleep` wrapper for running the autonomous worker loop without Hypridle idle lock or suspend interruptions.
- Corrected persistent blank-workspace entry to use the shared monitor/workspace resolver instead of connector-specific selection; two-monitor attended validation remains pending.
- Corrected the dock-to-XMB handoff boundary by retaining the morph background during launcher-surface realization; contract/live/one-minute soak checks pass, with attended visual validation queued.
- Corrected delayed application launch routing by capturing initiating monitor/workspace context and relocating the newly mapped matching client; contract/live/one-minute soak checks pass, with the attended focus-change fixture queued.
- Completed the Settings ownership split by extracting draft/apply/cancel lifecycle into `SettingsDraftLifecycle.qml`; contract 30/30, live 34/34, and one-minute soak 10/10 passed, and the restarted shell loaded without new Orbit QML errors.
- Corrected dock-launched XMB keyboard focus by releasing the completed morph state at launcher handoff; contract/live/one-minute soak checks pass, with attended keyboard and Escape recovery queued.
- Removed the SettingsModel duplicate Hyprland client poll by consuming the shared `HyprlandModel` snapshot; contract/live/one-minute soak checks pass and the service restart/signature check passed.
- Consolidated monitor-role and reserved-workspace resolution: role workspace numbers now live in Orbit monitor settings and `dynamic-app-workspaces` delegates output resolution to `orbit-monitor`; contract/live/one-minute soak checks pass.
- Corrected Steam transient workspace correlation so floating menus/toasts do not require the main Steam client's PID; contract/live/one-minute soak checks pass, with attended toast validation queued.
- Normalized legacy `[[policy]]` and modern `[[rule]]` application-policy schemas through one resolver matcher; contract/live/one-minute soak checks pass.
- Extracted Settings system-action process execution into `SettingsSystemActions.qml` while retaining the `SettingsModel.qml` public API; contract 30/30, live 34/34, and one-minute soak 11/11 passed (`2026-08-17T16-02-54Z-77266`, `2026-08-17T16-02-57Z-77660`, `soak-2026-08-17T16-02-57Z-77661`). Draft lifecycle and application matching remain intentionally in the parent model.
- Extracted Settings application matching and shared-client observation into `SettingsApplicationMatching.qml` while retaining compatibility aliases/wrappers; contract 30/30, live 34/34, and one-minute soak 10/10 passed (`2026-08-17T16-07-40Z-117230`, `2026-08-17T16-07-42Z-117595`, `soak-2026-08-17T16-07-46Z-118244`). Draft lifecycle remains parent-owned for a later bounded refactor.
- Extracted Orbit settings artifact generation into `.local/lib/orbit_settings_artifacts.py` while retaining CLI compatibility wrappers; contract 31/31 (`2026-08-17T16-24-50Z-244811`), live 35/35 (`2026-08-17T16-24-53Z-245194`), and one-minute soak 11/11 (`soak-2026-08-17T16-25-01Z-246161`) passed. Persistence, validation, and runtime-adapter boundaries remain separate work.
- Extracted Orbit settings persistence primitives into `.local/lib/orbit_settings_persistence.py`; the CLI retains its public command and file-format boundaries. `SET-007` contract 31/31 (`2026-08-17T16-28-50Z-272290`), live 35/35 (`2026-08-17T16-28-54Z-272765`), and one-minute soak 10/10 (`soak-2026-08-17T16-28-54Z-272766`) passed. Validation and runtime-adapter boundaries remain separate work.
- Extracted Orbit settings validation into `.local/lib/orbit_settings_validation.py`; the CLI retains its public command and rejection semantics. `SET-008` contract 32/32 (`2026-08-17T16-33-23Z-302845`), live 36/36 (`2026-08-17T16-33-28Z-303410`), and one-minute soak 10/10 (`soak-2026-08-17T16-33-28Z-303422`) passed. Runtime-adapter extraction remains separate work.
- Corrected dock boundary magnification by animating `dockContent.hoverAmount` over 140 ms while retaining the shared `scaleAt()` pointer-distance curve. Contract 32/32 (`2026-08-17T16-37-50Z-333107`), live 36/36 after shell restart (`2026-08-17T16-39-49Z-347788`), and one-minute soak 11/11 (`soak-2026-08-17T16-37-56Z-334022`) passed. Attended two-monitor pointer validation is queued as `VQ-20260817-10`.
- Extracted mutating Orbit Settings runtime actions into `.local/lib/orbit_settings_actions.py` with deterministic runner injection and CLI compatibility wrappers. `SET-010` contract passed 35/35 (`2026-08-17T17-06-34Z-532628`), live passed 38/39 with unrelated `START-004` binding failure, and one-minute soak passed 10/10. No real device or network mutation was performed.
- Corrected dock and top-panel application close actions for Hyprland 0.56.1 by focusing the selected client with `hl.dsp.focus` and then invoking `hl.dsp.window.close`; disposable WezTerm validation passed and `UI-019` was recorded as PASS.
- Refreshed the `START-006` shutdown-guard worker evidence: contract 35/35, item-specific live PASS within 38/39 (unrelated `START-004` failure), one-minute soak 11/11, and safe cancel/missing-`zenity` fixtures passed without session termination; attended cancel and explicitly approved recovery remain queued as `VQ-20260817-14`.
- Hardened `ORB-STARTUP-BINDINGS`: Orbit now waits up to 60 bounded attempts for its runtime Alt+Tab binding and fails closed before QuickShell startup if the binding is unavailable. After restart, contract 35/35, live 39/39, and one-minute soak 11/11 passed (`2026-08-17T17-24-08Z-654311`, `2026-08-17T17-24-13Z-655070`, `soak-2026-08-17T17-24-16Z-654693`).
- Closed the input authorization gate after the udev-identity allowlist, fresh-login service restart, fail-closed filtering, and attended Alt+Tab/Alt-release checks passed; this superseded the reverted ACL-only attempt.
- A later direct live audit found no runtime `TAB` binding while `orbit-shell.service` was active and the compositor signature was current. This supersedes the prior current `START-004` PASS classification; the earlier successful runs above remain historical evidence and `START-004` now requires revalidation.
- Normalized Orbit tracking around the full-scratchpad and three-repository Orbit 1.0 definition, stabilization-first ordering, `orbit/project-manifest.json` authority, and independent per-item direct-to-`main` integration.
- Added the canonical 171-record Orbit project manifest and structural validator, including audit-discovered Settings, monitor, launch-correlation, and overview contract gaps. The validator now reports zero errors and zero migration warnings.
- Repaired contract discovery so every `test_*` function is registered and every PASS requirement with contract automation has an exact emitted ID; the current deterministic suite passes 50/50.
- Hardened evidence handling by replacing full-environment capture with an allowlist, separating smoke from soak evidence, making interrupted soak runs incomplete, strengthening live Alt+Tab validation, and normalizing the manual runner and queue IDs.
- Reworked autonomous execution into canonical-manifest selection, bounded Luna execution, deterministic independent verification, direct-to-`main` supervisor publication, manual Sol handling for high-risk items, and Sol audits at project phase boundaries rather than every routine item.
- Expanded the repository allowlist to include all required Orbit helpers, libraries, services, configuration, palettes, generated artifacts, agent definitions, and manifest files; canonical appearance and window-rule artifacts were reconciled with their source settings.
- Cleanup verification passed 50/50 deterministic contracts and an 11-iteration one-minute smoke. Current live validation passed 53/54; only `START-004` failed because the active compositor contained no runtime `TAB` binding, so that issue remains open rather than being hidden by aggregate counts.
