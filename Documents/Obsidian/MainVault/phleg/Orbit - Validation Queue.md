---
title: Orbit - Validation Queue
type: validation-queue
status: active
tags: [orbit, testing, manual-validation, handoff]
---

# Orbit Validation Queue

Workers append handoffs here. An approval session processes the first `READY`
ID in **Current Processing Order**, records the user's decision, and advances
to the next ID. Do not delete completed or superseded entries; they are the
audit trail. Only one entry per source item may be `READY`.

## Entry Template

```markdown
### VQ-YYYYMMDD-## - ITEM-ID - short title
- Status: READY
- Source issue / test / backlog: `...`
- Worker session date:
- Environment and prerequisites:
- Safe reset:
- Exact steps:
  1.
- Expected:
- Automated evidence:
- Remaining manual gate:
- Evidence to capture:
- User decision: pending
- Follow-up issue / note:
```

## Decision Vocabulary

- `PASS`: the observed behavior matches the contract.
- `PASS-WITH-NOTE`: the contract passes; an improvement is recorded separately.
- `FAIL`: the contract does not pass; retain the exact observation and create
  or update an issue.
- `BLOCKED`: the required device, fixture, permission, or safe recovery path
  is unavailable.
- `SUPERSEDED`: retained audit history replaced by a newer handoff for the same source item.

## Queue

<!-- Workers append entries below this line. -->

## Current Processing Order

Stabilization and recovery gates precede visual and feature-completion gates. Process exactly this order unless a prerequisite makes the next entry `BLOCKED`:

1. `VQ-20260817-18` - `START-004` runtime Alt+Tab binding revalidation
2. `VQ-20260817-16` - `START-006` shutdown confirmation guard
3. `VQ-20260817-06` - `START-009` persistent blank workspace
4. `VQ-20260817-12` - `SET-003` failed display apply rollback
5. `VQ-20260817-11` - `THEME-003` cross-toolkit palette runtime matrix
6. `VQ-20260817-10` - `UI-009` dock boundary magnification
7. `VQ-20260817-09` - `APP-006` Steam toast attribution
8. `VQ-20260817-02` - `UI-017` dock-to-XMB continuity
9. `VQ-20260817-03` - `APP-007` delayed launch context
10. `VQ-20260817-04` - `APP-008` desktop-entry placeholders
11. `VQ-20260817-05` - `UI-008` Settings dock icon
12. `VQ-20260817-17` - `UI-018` dock-launched XMB focus
13. `VQ-20260817-07` - `APP-009` shared launch boundary
14. `VQ-20260817-08` - `APP-010` concurrent launch correlation

### VQ-20260817-18 - START-004 - runtime Alt+Tab binding revalidation
- Status: READY
- Source issue / test / backlog: `ORB-STARTUP-BINDINGS` / `START-004` / Priority 1 State and Lifecycle
- Worker session date: 2026-08-17
- Environment and prerequisites: Current Hyprland graphical session; `orbit-shell.service` active; `HYPRLAND_INSTANCE_SIGNATURE` must match `hyprctl instances`; no unsaved work. The current direct live audit found no runtime `TAB` binding despite current service and compositor state.
- Safe reset: Do not log out, reload Hyprland, or alter configuration during the observation. If Orbit is stale, stop and record `BLOCKED` rather than mutating the session before capturing evidence.
- Exact steps:
  1. Record `date -Is`, `HYPRLAND_INSTANCE_SIGNATURE`, `hyprctl instances`, and `systemctl --user status orbit-shell.service --no-pager`.
  2. Capture the complete current `hyprctl binds -j` output and identify every binding whose key is `TAB`.
  3. Confirm whether the expected runtime Alt+Tab trigger is present exactly once and record its dispatcher and arguments.
  4. If present, perform one attended disposable Alt+Tab cycle and Alt release; if absent, do not fabricate a pass or repair it inside this validation.
  5. Capture relevant Orbit service journal lines and the final unchanged compositor signature and service state.
- Expected: The expected runtime `TAB` trigger is present exactly once in the current compositor binding table and one attended disposable cycle completes without duplicate or stuck behavior.
- Automated evidence: Earlier restart live 39/39 (`2026-08-17T17-24-13Z-655070`) and soak 11/11 (`soak-2026-08-17T17-24-16Z-654693`) are historical. The newer direct live audit found no `TAB` binding while the service was active and the compositor signature was current; therefore `START-004` is `OPEN`, not `PASS`.
- Remaining manual gate: Current binding-table observation and one attended disposable Alt+Tab/Alt-release cycle if the binding is present.
- Evidence to capture: Full binding JSON; exact matching rows; timestamps; service status and journal; compositor signature; attended cycle observation or exact absence.
- User decision: pending
- Follow-up issue / note: Keep `ORB-STARTUP-BINDINGS` and `START-004` `OPEN` until current direct evidence passes. This is the only current `READY` handoff for `START-004`.

### VQ-20260817-15 - START-006 - shutdown confirmation guard fresh worker handoff
- Status: SUPERSEDED by `VQ-20260817-16`
- Source issue / test / backlog: `ORB-SESSION-TERMINATION-GUARD` / `START-006` / Priority 1 State and Lifecycle
- Worker session date: 2026-08-17
- Environment and prerequisites: Current Hyprland graphical session 38; `HYPRLAND_INSTANCE_SIGNATURE=5c9377c15f85c50648f35ca5a213754f95b93ca0_1786975562_1510797335` matches `hyprctl instances`; `orbit-shell.service` is active; `/usr/bin/zenity` is installed; no unsaved work. The unattended worker must not choose `End session`.
- Safe reset: For the safe half, choose `Cancel`; the session remains untouched. If a surface is stale, restart `orbit-shell.service` only when necessary, then re-check the compositor signature and service state. Never terminate the graphical session during this validation and do not retry a destructive action after an ambiguous result.
- Exact steps:
  1. Record `date -Is`, `XDG_SESSION_ID`, `HYPRLAND_INSTANCE_SIGNATURE`, `hyprctl instances`, and `systemctl --user status orbit-shell.service --no-pager`.
  2. Save or close disposable work, then invoke `SUPER + M` or `.config/hypr/scripts/animate-shutdown`.
  3. Select `Cancel` in the `zenity` confirmation dialog.
  4. Confirm the dialog closes, session 38 remains active, Orbit remains healthy, and neither shutdown animation nor `loginctl terminate-session` runs.
  5. Only in a separately approved attended run, repeat with disposable state and select `End session`; after re-login, verify Orbit service health and compositor signature.
  6. Capture final service status, `hyprctl instances`, session ID, and relevant `journalctl --user -u orbit-shell.service` lines. Stop if the destructive result is ambiguous.
- Expected: Cancel is a no-op. Confirmation precedes every shutdown action; missing `zenity` fails closed. The confirm path alone starts shutdown and terminates the session.
- Automated evidence: `sh -n .config/hypr/scripts/animate-shutdown`; Python compilation; contract 35/35 (`2026-08-17T17-28-30Z-684233`); live 39/39 (`2026-08-17T17-28-30Z-684296`); one-minute soak 11/11 (`soak-2026-08-17T17-28-35Z-684232`). Existing disposable cancel and missing-`zenity` fixtures invoked no `loginctl`.
- Remaining manual gate: Attended cancel behavior and, only if explicitly approved, real confirm/logout/re-login recovery.
- Evidence to capture: Dialog screenshot or recording; timestamps; session ID before/after; `journalctl --user -u orbit-shell.service`; service status; `hyprctl instances`; proof that cancel ran no termination command; re-login health for the separately approved confirm path.
- User decision: pending
- Follow-up issue / note: Superseded by `VQ-20260817-16`; retain `VQ-20260817-01`, `VQ-20260817-13`, `VQ-20260817-14`, and this entry as audit history. Keep `ORB-SESSION-TERMINATION-GUARD` and `START-006` MANUAL. No unrelated item was changed.

### VQ-20260817-14 - START-006 - shutdown confirmation guard fresh worker handoff
- Status: SUPERSEDED by `VQ-20260817-16`
- Source issue / test / backlog: `ORB-SESSION-TERMINATION-GUARD` / `START-006` / Priority 1 State and Lifecycle
- Worker session date: 2026-08-17
- Environment and prerequisites: Current Hyprland graphical session with `HYPRLAND_INSTANCE_SIGNATURE` matching `hyprctl instances`; `hyprctl instances` currently reports the same signature; `orbit-shell.service` active; `/usr/bin/zenity` installed; `XDG_SESSION_ID=38`; no unsaved work. Do not invoke the confirm path unless the user explicitly accepts ending the graphical session.
- Safe reset: For cancel validation, select `Cancel`; the session remains untouched. If a surface is stale, restart `orbit-shell.service` only when necessary, then re-check the compositor signature and service state. Never terminate the session as part of an unattended worker run. Do not retry a destructive action after an ambiguous result.
- Exact steps:
  1. Record `date -Is`, `XDG_SESSION_ID`, `HYPRLAND_INSTANCE_SIGNATURE`, `hyprctl instances`, and `systemctl --user status orbit-shell.service --no-pager`.
  2. Save or close disposable work, then invoke `SUPER + M` or `.config/hypr/scripts/animate-shutdown`.
  3. Select `Cancel` in the `zenity` confirmation dialog.
  4. Confirm the dialog closes, the session remains active, Orbit remains healthy, and no shutdown animation or `loginctl terminate-session` action occurs.
  5. Only in a separately approved attended run, repeat with disposable session state and select `End session`; after re-login, verify Orbit service health and compositor signature.
  6. Capture final service status, `hyprctl instances`, session ID, and relevant journal lines; stop if the destructive result is ambiguous.
- Expected: Cancel is a no-op. The confirm path is the only path that starts shutdown and terminates the session; missing `zenity` fails closed.
- Automated evidence: `sh -n .config/hypr/scripts/animate-shutdown`; Python compilation passed; contract 35/35 (`2026-08-17T17-18-45Z-617766`); `START-006` passed in live 38/39 (`2026-08-17T17-18-49Z-618234`) with unrelated `START-004` failure; one-minute soak 11/11 (`soak-2026-08-17T17-18-56Z-619246`). Disposable fake-`zenity` cancel and missing-`zenity` fail-closed fixtures passed without invoking `loginctl`. No real logout was invoked.
- Remaining manual gate: Attended cancel behavior and, only if explicitly approved, real confirm/logout/re-login recovery.
- Evidence to capture: Dialog screenshot or recording; timestamps; session ID before/after; `journalctl --user -u orbit-shell.service`; service status; `hyprctl instances`; confirmation that no termination command ran on cancel; re-login health for the separately approved confirm path.
- User decision: pending
- Follow-up issue / note: Superseded by `VQ-20260817-16`; retain this entry as audit history. Keep `ORB-SESSION-TERMINATION-GUARD` and `START-006` MANUAL. The unrelated `START-004` failure is tracked by `VQ-20260817-18`.

### VQ-20260817-13 - START-006 - refreshed shutdown confirmation guard gate
- Status: SUPERSEDED by `VQ-20260817-16`
- Source issue / test / backlog: `ORB-SESSION-TERMINATION-GUARD` / `START-006` / Priority 1 State and Lifecycle
- Worker session date: 2026-08-17
- Environment and prerequisites: Current Hyprland graphical session with `HYPRLAND_INSTANCE_SIGNATURE` matching `hyprctl instances`; `orbit-shell.service` active; `/usr/bin/zenity` installed; `XDG_SESSION_ID` set; no unsaved work. Do not invoke the confirm path unless the user explicitly accepts ending the graphical session.
- Safe reset: For cancel validation, choose `Cancel` and leave the session untouched. If a surface is stale, restart `orbit-shell.service` only when necessary, then verify the compositor signature and service state. Never terminate the session as part of an unattended worker run.
- Exact steps:
  1. Record `date -Is`, `XDG_SESSION_ID`, `HYPRLAND_INSTANCE_SIGNATURE`, `hyprctl instances`, and `systemctl --user status orbit-shell.service --no-pager`.
  2. Save or close disposable work, then invoke `SUPER + M` or `.config/hypr/scripts/animate-shutdown`.
  3. Select `Cancel` in the `zenity` confirmation dialog.
  4. Confirm the dialog closes, the session remains active, Orbit remains healthy, and no shutdown animation or `loginctl terminate-session` action occurs.
  5. Only in a separately approved attended run, repeat with disposable session state and select `End session`; after re-login, verify Orbit service health and compositor signature.
  6. Capture final service status, `hyprctl instances`, session ID, and relevant journal lines; do not retry a destructive action after an ambiguous result.
- Expected: Cancel is a no-op. The confirm path is the only path that starts shutdown and terminates the session; missing `zenity` fails closed.
- Automated evidence: Syntax/Python compilation passed; contract 34/34 (`2026-08-17T16-59-05Z-480469`); `START-006` passed in live suite 37/38 (`2026-08-17T16-59-08Z-480899`) with unrelated `START-004` failure; one-minute soak 10/10 (`soak-2026-08-17T16-59-08Z-480908`). Disposable fake-`zenity`/fake-`loginctl` ordering passed. No real logout was invoked.
- Remaining manual gate: Attended cancel behavior and, only if explicitly approved, real confirm/logout/re-login recovery.
- Evidence to capture: Dialog screenshot or recording; timestamps; session ID before/after; `journalctl --user -u orbit-shell.service`; service status; `hyprctl instances`; confirmation that no termination command ran on cancel.
- User decision: pending
- Follow-up issue / note: Superseded by `VQ-20260817-16`; retain this entry and `VQ-20260817-01` as audit history. Keep `ORB-SESSION-TERMINATION-GUARD` and `START-006` MANUAL.

### VQ-20260817-12 - ORB-DISPLAY-RECOVERY - failed display apply rollback
- Status: READY
- Source issue / test / backlog: `ORB-DISPLAY-RECOVERY` / `SET-003` / Refactor Backlog Priority 4
- Worker session date: 2026-08-17
- Environment and prerequisites: Current two-monitor Hyprland session with `HYPRLAND_INSTANCE_SIGNATURE` matching `hyprctl instances`; `orbit-shell.service` active; both configured monitors connected; disposable settings values only and no unsaved work. Record current display profiles, `hyprctl monitors -j`, `hyprctl instances`, and hashes of `settings.toml` and `.config/hypr/monitors.lua` before testing. The implementation snapshots files and the observed topology, verifies requested dimensions, and restores both on a failed command/reload/verification.
- Safe reset: Do not disconnect, disable, or reconfigure a real display unless the attended test is explicitly accepted and a recovery path is visible. If a disposable apply is interrupted, run `systemctl --user restart orbit-shell.service` only if Orbit is stale, then restore the recorded settings files and run `hyprctl reload config-only`; verify both monitors and the compositor signature. Never test with unsaved work or terminate the session.
- Exact steps:
  1. Record the prerequisite outputs and hashes, then capture the current display profiles as the last-known-good baseline.
  2. In a disposable Orbit Settings display draft, change one monitor to a known-valid alternate mode/position that is supported by `hyprctl monitors -j`; do not apply yet.
  3. Trigger a controlled failure at the apply boundary using only a disposable fixture or an intentionally invalid command interception supplied by the test harness; do not make an unsupported real display mode the failure mechanism.
  4. Observe the error and confirm the previous `settings.toml`, generated `monitors.lua`, and runtime monitor topology are restored; record whether verification ran and whether rollback reported success.
  5. Repeat once with a reload/verification failure fixture if available, then close the draft without applying any real display change.
  6. Verify final monitor JSON, compositor signature, Orbit service state, settings hashes, and generated-file hashes match the baseline; perform the safe reset if anything is stale.
- Expected: A failed display apply never leaves a partial generated configuration or mixed monitor topology; the last-known-good runtime and files are restored atomically enough for the user to recover, and rollback failures are explicit.
- Automated evidence: Synthetic failure fixture passed `SET-003`; contract 34/34. Live 37/38 (`2026-08-17T16-55-27Z-455435`) with unrelated `START-004` Alt+Tab binding failure; one-minute soak 10/10 (`soak-2026-08-17T16-55-27Z-455436`). No real display mutation was performed.
- Remaining manual gate: Attended disposable two-monitor failure/recovery observation, including final topology and file-hash comparison.
- Evidence to capture: Before/after monitor JSON; settings and `monitors.lua` SHA-256 hashes; exact fixture failure; Orbit Settings error text; rollback output; `hyprctl instances`; Orbit service status; timestamps; screenshot only if safe and useful.
- User decision: pending
- Follow-up issue / note: Keep `ORB-DISPLAY-RECOVERY` and `SET-003` MANUAL until the controlled recovery result is recorded. The synthetic fixture does not prove compositor recovery on real hardware.

### VQ-20260817-11 - THEME-003 - cross-toolkit palette runtime matrix
- Status: READY
- Source issue / test / backlog: `ORB-THEME-PROPAGATION` / `THEME-003` / Refactor Backlog Priority 3 validation gap
- Worker session date: 2026-08-17
- Environment and prerequisites: Current graphical Hyprland session with `HYPRLAND_INSTANCE_SIGNATURE` matching `hyprctl instances`; `orbit-shell.service` active; current selected palette reported by `.local/bin/orbit-theme current`; disposable GTK3, GTK4, Qt/KDE, QuickShell, Kitty, and WezTerm surfaces only. The worker preserved user-dirty `.config/gtk-3.0/noctalia.css`, `.config/gtk-4.0/noctalia.css`, and `.local/share/color-schemes/noctalia.colors`; do not overwrite them without an explicit attended decision.
- Safe reset: Close only disposable applications. If a palette is intentionally applied during this approval, record the original palette and restore it with the same documented Orbit command only after capturing results; do not replace the preserved dirty adapter files or change display, audio, network, Bluetooth, or session configuration. Restart `orbit-shell.service` only if a QuickShell surface is stale.
- Exact steps:
  1. Record `orbit-theme current`, `hyprctl instances`, `systemctl --user is-active orbit-shell.service`, and SHA-256 hashes of the selected generated adapters plus the active GTK3, GTK4, and KDE files.
  2. With disposable applications open, record each surface's current palette and whether it updates live, after a toolkit reload, or only after application restart; do not use unsaved work.
  3. If safe and explicitly accepted for this attended check, apply one disposable alternate palette using `.local/bin/orbit-theme apply <palette>`, then observe Orbit/QuickShell, GTK3, GTK4, Qt/KDE, Kitty, and WezTerm in that order, recording exact reload or restart actions.
  4. Confirm the selected generated adapter content and the active adapter content correspond after the intentional apply, or record the exact mismatch and preserve it as a follow-up issue.
  5. Restore the recorded palette or perform the safe reset, close disposable windows, and verify Orbit service state and compositor signature are unchanged.
- Expected: Each toolkit's live/reload/restart requirement is explicit; supported surfaces reflect the selected palette after their documented refresh action; unsupported live updates are honestly recorded rather than inferred from generated files.
- Automated evidence: `THEME-003` disposable adapter-install contract PASS; contract 33/33 (`2026-08-17T16-49-39Z-415867`); soak 11/11 (`soak-2026-08-17T16-49-48Z-417118`); live 36/37 twice with unrelated `START-004` Alt+Tab binding failure while theme checks passed. Current selected palette is `catppuccin-mocha`; active adapter files were user-dirty and preserved.
- Remaining manual gate: Attended cross-toolkit live/reload/restart observations and safe handling of the existing dirty adapter customizations.
- Evidence to capture: palette names; before/after hashes; application names and versions; exact refresh/restart action; screenshots or color samples where useful; timestamps; Orbit service status; compositor signature; any mismatch or follow-up issue.
- User decision: pending
- Follow-up issue / note: Keep `ORB-THEME-PROPAGATION` and `THEME-003` MANUAL until the matrix is recorded. Do not claim propagation from the disposable installer fixture or generated files alone.

### VQ-20260817-10 - ORB-DOCK-MAGNIFICATION-EDGE - continuous dock boundary magnification
- Status: READY
- Source issue / test / backlog: `ORB-DOCK-MAGNIFICATION-EDGE` / `UI-009` / Refactor Backlog Priority 6
- Worker session date: 2026-08-17
- Environment and prerequisites: Current Hyprland graphical session with `HYPRLAND_INSTANCE_SIGNATURE` matching `hyprctl instances`; `orbit-shell.service` active after reload; all connected monitors with the Orbit dock visible; disposable windows only. Do not change display, audio, network, Bluetooth, or session configuration.
- Safe reset: Move the pointer away from the dock and close any disposable menu normally. If a surface is stale, run `.local/bin/orbit-xmb close`, then `systemctl --user restart orbit-shell.service`; verify the dock returns. Do not terminate the graphical session.
- Exact steps:
  1. Record `systemctl --user is-active orbit-shell.service`, `hyprctl instances`, `hyprctl monitors -j`, and the current dock layers.
  2. On each connected monitor, move the pointer slowly from the left side into the dock focus area; observe the first icon and neighboring icons through the full entry ramp.
  3. Move the pointer slowly out through the right side, then repeat from the opposite direction; repeat each direction twice.
  4. Move the pointer between dock icons and compare the scale progression with boundary entry; confirm no icon jumps directly to maximum size and no dock relocation occurs.
  5. Move focus between monitors and repeat one entry and exit on each monitor without changing monitor configuration.
  6. Record final dock layers, service state, and compositor signature; perform the safe reset if needed.
- Expected: Boundary entry and exit ramp continuously through the same magnification curve as in-dock movement; the dock remains stable, launches are unaffected, and Orbit/Hyprland remain healthy.
- Automated evidence: Contract `tests/orbit/run-all` PASS 32/32 (`2026-08-17T16-37-50Z-333107`); live PASS 36/36 after `orbit-shell.service` restart (`2026-08-17T16-39-49Z-347788`); one-minute soak PASS 11/11 (`soak-2026-08-17T16-37-56Z-334022`). Static coverage asserts the 140 ms `OutCubic` hover ramp feeds the existing `scaleAt()` calculation. Service remained active and the compositor signature matched; no Orbit QML error was logged. No attended pointer recording was performed.
- Remaining manual gate: Attended visual slow-entry/exit comparison on both sides of every connected monitor.
- Evidence to capture: monitor name; timestamps; short recording or screenshots of left/right entry and exit; dock layers before/during/after; `journalctl --user -u orbit-shell.service --since` test start; final service status and compositor signature.
- User decision: pending
- Follow-up issue / note: Keep `ORB-DOCK-MAGNIFICATION-EDGE` and `UI-009` MANUAL until the attended pointer comparison is recorded.

### VQ-20260817-09 - ORB-STEAM-TOAST - Steam toast workspace attribution
- Status: READY
- Source issue / test / backlog: `ORB-STEAM-TOAST` / `APP-006` / Refactor Backlog Priority 3
- Worker session date: 2026-08-17
- Environment and prerequisites: Current Hyprland graphical session with `HYPRLAND_INSTANCE_SIGNATURE` matching `hyprctl instances`; both configured monitors connected; Steam installed and already usable in the session; `dynamic-app-workspaces` active; only disposable Steam state and no unsaved work. Do not disconnect displays or alter audio, network, Bluetooth, or session configuration.
- Safe reset: Close the Steam toast/menu normally and leave Steam on its existing workspace. If a disposable Steam window is left behind, close it normally or use `hyprctl dispatch closewindow address:<address>` after recording its address. Do not terminate the graphical session.
- Exact steps:
  1. Record `hyprctl instances`, `hyprctl monitors -j`, `hyprctl clients -j`, and the active dynamic-workspace service/process state.
  2. Open Steam on its configured Gaming monitor and record the non-floating Steam client's address, PID, monitor, and workspace.
  3. Trigger one disposable Steam notification/toast using an already available in-app action; do not install, purchase, download, or change Steam/network settings.
  4. During the toast, record the floating Steam client's address, PID, title, monitor, workspace, and whether its PID differs from the main client.
  5. Repeat once after moving pointer focus to the other monitor, then dismiss the toast and perform the safe reset.
  6. Verify the final clients, monitor/workspace state, Orbit service state, and unchanged compositor signature.
- Expected: The floating toast remains on the same Gaming monitor and workspace as the visible non-floating Steam client, including when the toast/helper PID differs; no unrelated window moves and Orbit/Hyprland remain healthy.
- Automated evidence: `bash -n .config/hypr/scripts/dynamic-app-workspaces`; contract `tests/orbit/run-all` PASS 30/30 (`2026-08-17T15-54-08Z-17457`); live PASS 34/34 (`2026-08-17T15-54-08Z-17526`); one-minute soak PASS 11/11 (`soak-2026-08-17T15-54-13Z-17455`). Static coverage asserts title-preferred and PID-independent Steam correlation. No real Steam toast was generated in the worker session.
- Remaining manual gate: Real Steam toast/helper-window monitor and workspace placement, including differing-PID behavior and safe dismissal.
- Evidence to capture: Steam action used; timestamps; main/toast address and PID; title/class/floating state; `hyprctl monitors -j` and `hyprctl clients -j` before/during/after; dynamic-workspace logs; Orbit service status; compositor signature; screenshot or recording if safe.
- User decision: pending
- Follow-up issue / note: Keep `ORB-STEAM-TOAST` and `APP-006` MANUAL until the controlled toast result is recorded. The worker's static, contract, live, and soak evidence does not prove real Steam helper-window placement.

### VQ-20260817-01 - START-006 - shutdown confirmation guard
- Status: SUPERSEDED by `VQ-20260817-16`
- Source issue / test / backlog: `ORB-SESSION-TERMINATION-GUARD` / `START-006`
- Worker session date: 2026-08-17
- Environment and prerequisites: Current Hyprland graphical session with `HYPRLAND_INSTANCE_SIGNATURE` matching `hyprctl instances`; `orbit-shell.service` active; `zenity` installed and able to display a question; `XDG_SESSION_ID` set; current shutdown script at `.config/hypr/scripts/animate-shutdown`. Do not run this against unsaved work.
- Safe reset: For cancel validation, choose `Cancel` and leave the session untouched. Do not use the confirm path unless the user explicitly accepts ending this graphical session; after a confirmed shutdown, log back into the same user session and verify Orbit services using the startup runbook.
- Exact steps:
  1. Save or close disposable work and note the current session ID and Orbit service state.
  2. Invoke the configured `SUPER + M` shutdown shortcut, or run `.config/hypr/scripts/animate-shutdown` from the current graphical session.
  3. First choose `Cancel` in the confirmation dialog.
  4. Verify the dialog closes, the current session remains active, Orbit remains visible/healthy, and no shutdown animation or session termination occurs.
  5. If separately approving the destructive half, repeat the shortcut with a disposable session state and choose `End session`; allow the normal logout path to complete, then log in again.
  6. After re-login, run `systemctl --user is-active orbit-shell.service`, compare `HYPRLAND_INSTANCE_SIGNATURE` with `hyprctl instances`, and confirm no Orbit restart or broken Wayland connection was recorded.
- Expected: Cancel is a no-op. The confirm path is the only path that starts blanking/wallpaper shutdown and terminates the current session; it never runs before explicit confirmation. A missing `zenity` executable fails closed without session actions.
- Automated evidence: `tests/orbit/run-all` PASS 25/25 and `tests/orbit/run-all --live` PASS 29/29, run ID `2026-08-17T14-49-26Z-3685099`; one-minute soak PASS 11/11, run ID `soak-2026-08-17T14-49-35Z-3686423`; disposable fake-command cancel/confirm ordering fixture PASS; no real termination invoked.
- Remaining manual gate: Attended cancel behavior and, only if explicitly accepted, the real confirm/logout/re-login recovery path.
- Evidence to capture: Dialog screenshot or recording for cancel; timestamps; `journalctl --user -u orbit-shell.service` before/after; `systemctl --user status orbit-shell.service`; `hyprctl instances`; session ID before and after; for the confirm path, the re-login result and absence of a new Orbit crash/restart.
- User decision: pending
- Follow-up issue / note: Superseded by `VQ-20260817-16`; retain this original handoff as audit history. Keep `ORB-SESSION-TERMINATION-GUARD` open until the attended gate is recorded. Do not classify generated configuration or the disposable fixture as proof of real session recovery.
- Worker rerun evidence: `2026-08-17T16-17-04Z-191390` contract 30/30, `2026-08-17T16-17-04Z-191423` live 34/34, and `2026-08-17T16-17-05Z-191475` one-minute soak 10/10. `zenity` is installed, `orbit-shell.service` is active, and the compositor signature matched `hyprctl instances`; no real logout was invoked. This evidence is retained historically; `VQ-20260817-16` is the single current handoff.

### VQ-20260817-02 - ORB-XMB-BLANKING - dock-to-XMB handoff continuity
- Status: READY
- Source issue / test / backlog: `ORB-XMB-BLANKING` / `UI-017` / Priority 6 visual correction
- Worker session date: 2026-08-17
- Environment and prerequisites: Current Hyprland graphical session with `HYPRLAND_INSTANCE_SIGNATURE` matching `hyprctl instances`; `orbit-shell.service` active after reload; at least one connected monitor with the Orbit dock visible; disposable applications only. Do not test while unsaved work is open.
- Safe reset: Press Escape or click the XMB close button to close the launcher. If the surface is stuck, run `.local/bin/orbit-xmb close`, then `systemctl --user restart orbit-shell.service`; verify the dock is restored before continuing. Do not change display, audio, network, Bluetooth, or session state.
- Exact steps:
  1. Save or close disposable work and record `systemctl --user is-active orbit-shell.service`, `hyprctl instances`, and the current dock/XMB state.
  2. Move the pointer slowly into the Orbit dock and activate the launcher entry once.
  3. Observe the full morph from dock dimensions to the launcher surface, including the moment the launcher contents become interactive.
  4. Repeat the activation three times, including one interruption by pressing Escape during the morph; confirm the dock returns cleanly.
  5. Repeat on each connected monitor without changing monitor configuration.
  6. If any surface remains blank or stuck, run the safe reset and capture the service journal before retrying.
- Expected: The morph background and launcher remain visually continuous with no dark/transparent frame; the launcher becomes interactive only after the handoff is ready; Escape during the morph returns to one healthy dock without an orphaned surface.
- Automated evidence: Contract `tests/orbit/run-all` PASS 25/25, run ID `2026-08-17T14-53-19Z-3716300`; live `tests/orbit/run-all --live` PASS 29/29 after service restart, run ID `2026-08-17T14-53-25Z-3716878`; one-minute soak PASS 11/11, run ID `soak-2026-08-17T14-53-29Z-3717902`; current compositor signature matched `hyprctl instances`.
- Remaining manual gate: Attended visual continuity, repeated activation, interruption/recovery, and each-monitor confirmation.
- Evidence to capture: Screen recording or screenshots showing the morph at start, handoff, and settled launcher; monitor name; timestamps; `hyprctl layers -j` during/after the handoff; `journalctl --user -u orbit-shell.service --since` the test start; final dock/XMB state.
- User decision: pending
- Follow-up issue / note: Keep `ORB-XMB-BLANKING` and `UI-017` MANUAL until the attended result is recorded. Automated surface checks do not prove visual continuity or recovery.

### VQ-20260817-03 - ORB-APP-FOCUS-RACE - delayed launch context
- Status: READY
- Source issue / test / backlog: `ORB-APP-FOCUS-RACE` / `APP-007` / Refactor Backlog Priority 3
- Worker session date: 2026-08-17
- Environment and prerequisites: Current two-monitor Hyprland graphical session with `HYPRLAND_INSTANCE_SIGNATURE` matching `hyprctl instances`; `orbit-shell.service` active after reload; one disposable delayed-start application fixture whose startup class is known; no unsaved work. Do not use a real application with unsaved data.
- Safe reset: Close the disposable fixture by its normal UI action or `hyprctl dispatch closewindow address:<address>`; if Orbit surfaces are stale, run `systemctl --user restart orbit-shell.service` and confirm both docks return. Do not change display, audio, network, Bluetooth, or session state.
- Exact steps:
  1. Record `hyprctl monitors -j`, `hyprctl activeworkspace -j`, `hyprctl clients -j`, and `systemctl --user is-active orbit-shell.service`.
  2. Focus monitor A and launch the disposable delayed-start fixture from the Orbit dock or XMB.
  3. Before its window maps, move pointer focus to monitor B and leave monitor B focused until the fixture appears.
  4. Record the new client's address, class, monitor, workspace, and map timestamp with `hyprctl clients -j`.
  5. Repeat from monitor B to monitor A, then repeat once with an already-running same-class window present.
  6. Perform the safe reset and verify Orbit service health and the compositor signature.
- Expected: Each newly mapped window remains on the monitor and active workspace captured at launch, regardless of later pointer focus; existing same-class windows are not moved; Orbit remains active with no restart.
- Automated evidence: Contract `tests/orbit/run-all` PASS 25/25 (`2026-08-17T14-58-44Z-3762377`); `orbit-shell.service` restarted cleanly; live `tests/orbit/run-all --live` PASS 29/29 (`2026-08-17T15-00-42Z-3779691`); one-minute soak PASS 11/11 (`soak-2026-08-17T14-58-50Z-3763514`). The implementation captures the launch snapshot and relocates only a new matching client after map.
- Remaining manual gate: Attended delayed-start focus change and same-class safety check on both monitor directions.
- Evidence to capture: Fixture command and startup class; before/after monitor and workspace JSON; client address/PID/class; timestamps; Orbit journal; final `hyprctl clients -j`; service status and compositor signature.
- User decision: pending
- Follow-up issue / note: Keep `ORB-APP-FOCUS-RACE` and `APP-007` MANUAL until the attended fixture confirms both directions and does not move an existing same-class window.

### VQ-20260817-04 - ORB-APP-EXEC-FIELDS - desktop-entry placeholder launch
- Status: READY
- Source issue / test / backlog: `ORB-APP-EXEC-FIELDS` / `APP-008` / Priority 3 launch and routing
- Worker session date: 2026-08-17
- Environment and prerequisites: Current Hyprland graphical session with `HYPRLAND_INSTANCE_SIGNATURE` matching `hyprctl instances`; `orbit-shell.service` active; Nautilus and Zen installed; only disposable windows or no unsaved work. The worker changed `.local/bin/orbit-app-launch` to remove no-file Desktop Entry field codes before `/bin/sh -lc` execution.
- Safe reset: Close any disposable Nautilus/Zen windows normally. If a test window is left open, use `hyprctl dispatch closewindow address:<address>` after recording its address. Do not launch with real file arguments or test against unsaved work.
- Exact steps:
  1. Record `systemctl --user is-active orbit-shell.service`, `hyprctl instances`, and the current client list.
  2. From the Orbit dock, launch Nautilus once and observe whether an error popup mentions a literal `%U` path; close the disposable window.
  3. From the Orbit XMB, launch Zen once and observe whether an error popup mentions a literal `%U` path; close the disposable window.
  4. Repeat one launch from each surface if needed to distinguish a stale pre-fix process from the current launcher; record client address, PID, class, and command/error text.
  5. Confirm Orbit remains active and the compositor signature is unchanged; capture the final client list and service status.
- Expected: Nautilus and Zen launch normally without treating `%U`/`%F` as literal paths; no placeholder error popup appears; Orbit and Hyprland remain healthy.
- Automated evidence: `sh -n .local/bin/orbit-app-launch`; fake-runner field-code fixture PASS; contract `tests/orbit/run-all` PASS 26/26 (`2026-08-17T15-04-00Z-3805284`); live PASS 30/30 (`2026-08-17T15-04-03Z-3805765`); one-minute soak PASS 11/11 (`soak-2026-08-17T15-04-11Z-3806901`).
- Remaining manual gate: Attended Nautilus and Zen relaunches from both Orbit launch surfaces, including absence of the literal-placeholder error and post-launch service/session health.
- Evidence to capture: screenshots or exact popup text if any; launch surface; client address/PID/class; timestamps; before/after `hyprctl clients -j`; `systemctl --user status orbit-shell.service`; `hyprctl instances`; shell journal since test start.
- User decision: pending
- Follow-up issue / note: Keep `ORB-APP-EXEC-FIELDS` and `APP-008` MANUAL until both disposable relaunches pass. The worker fixture proves normalization at the shared boundary but does not prove each desktop entry's runtime behavior.

### VQ-20260817-06 - START-009 - persistent blank workspace on every monitor
- Status: READY
- Source issue / test / backlog: `ORB-BLANK-WORKSPACE-RESOLUTION` / `START-009` / `STATE-010`
- Worker session date: 2026-08-17
- Environment and prerequisites: Current two-monitor Hyprland session with `DP-1` and `HDMI-A-1` connected; `HYPRLAND_INSTANCE_SIGNATURE` matches `hyprctl instances`; Orbit and wallpaper services active; no unsaved work.
- Safe reset: Run `.config/hypr/scripts/blank-special-workspaces restore` if a blanking test is interrupted. If the state file is absent, return to the previously recorded workspaces manually. Do not change display, audio, network, Bluetooth, or session configuration.
- Exact steps:
  1. Record `hyprctl monitors -j`, `hyprctl activeworkspace -j`, and `hyprctl clients -j`.
  2. Run `.config/hypr/scripts/blank-special-workspaces enter`.
  3. Confirm `DP-1` is on workspace `1` and `HDMI-A-1` is on workspace `6`, or use `orbit-monitor workspace-for-monitor <monitor>` as the expected source of truth.
  4. Confirm both monitors remain on their configured blank workspaces for at least five seconds.
  5. Run `.config/hypr/scripts/blank-special-workspaces restore` and confirm the recorded workspaces return on the correct monitors.
- Expected: Every configured connected monitor enters and remains on its own reserved blank workspace; restore returns each monitor to its prior workspace.
- Automated evidence: Contract coverage asserts the blanking helper delegates to `orbit-monitor workspace-for-monitor`; run `tests/orbit/run-all` after the current worker changes settle.
- Remaining manual gate: Two-monitor enter/hold/restore behavior.
- Evidence to capture: Before/after `hyprctl monitors -j`, active workspace output, client output, timestamps, script output, and service status.
- User decision: pending
- Follow-up issue / note: Keep `ORB-BLANK-WORKSPACE-RESOLUTION` and `START-009` MANUAL until both monitors pass.

### VQ-20260817-05 - ORB-DOCK-SETTINGS-ICON - synthetic Settings dock icon
- Status: READY
- Source issue / test / backlog: `ORB-DOCK-SETTINGS-ICON` / `UI-008` / Refactor Backlog Priority 6
- Worker session date: 2026-08-17
- Environment and prerequisites: Current Hyprland graphical session with `HYPRLAND_INSTANCE_SIGNATURE` matching `hyprctl instances`; `orbit-shell.service` active after reload; Orbit dock visible; standard `settings-symbolic` icon available through the desktop icon theme. Use only the existing Orbit Settings entry and do not change display, audio, network, Bluetooth, or session state.
- Safe reset: If the dock is stale, run `systemctl --user restart orbit-shell.service` and verify both docks return. Do not remove or rewrite `dock.json`.
- Exact steps:
  1. Record `systemctl --user is-active orbit-shell.service`, `hyprctl instances`, and the current dock layers.
  2. Restart `orbit-shell.service` to load the updated `ApplicationModel.qml`.
  3. Inspect the Orbit dock on each connected monitor and locate `Orbit Settings`.
  4. Confirm the entry shows the standard settings gear icon, remains clickable, and still opens Orbit Settings without QML errors.
  5. Record the final service state, compositor signature, and dock layers.
- Expected: `Orbit Settings` displays a visible standard `settings-symbolic` icon on every dock; activation still opens Settings; Orbit and Hyprland remain healthy.
- Automated evidence: Contract `tests/orbit/run-all` PASS 26/26 (`2026-08-17T15-07-52Z-3836324`), live PASS 30/30 (`2026-08-17T15-07-54Z-3836727`), and one-minute soak PASS 11/11 (`soak-2026-08-17T15-07-57Z-3837506`); `orbit-shell.service` restarted active. The implementation returns `Quickshell.iconPath("settings-symbolic")` only for synthetic `orbit-settings` and leaves normal desktop lookup unchanged.
- Remaining manual gate: Attended visual confirmation of the icon on each connected monitor and a non-destructive Settings activation after shell reload.
- Evidence to capture: monitor names; screenshots or recording of each dock; `journalctl --user -u orbit-shell.service --since` test start; `systemctl --user status orbit-shell.service`; `hyprctl instances`; final dock layers; confirmation that Settings opened.
- User decision: pending
- Follow-up issue / note: Keep `ORB-DOCK-SETTINGS-ICON` and `UI-008` MANUAL until the attended inspection is recorded.

### VQ-20260817-17 - ORB-XMB-DOCK-FOCUS - dock-launched XMB keyboard focus
- Status: READY
- Source issue / test / backlog: `ORB-XMB-DOCK-FOCUS` / `UI-018` / Refactor Backlog Priority 2
- Worker session date: 2026-08-17
- Environment and prerequisites: Current Hyprland graphical session with `HYPRLAND_INSTANCE_SIGNATURE` matching `hyprctl instances`; `orbit-shell.service` active after reload; Orbit dock and keybind XMB available; use only disposable launcher interactions and no unsaved work.
- Safe reset: Press Escape or click the XMB close button. If the surface is stuck, run `.local/bin/orbit-xmb close`, then `systemctl --user restart orbit-shell.service`; verify the dock returns. Do not change display, audio, network, Bluetooth, or session state.
- Exact steps:
  1. Record `systemctl --user is-active orbit-shell.service`, `hyprctl instances`, and the current dock/XMB state.
  2. Move pointer focus to the intended monitor and activate the XMB from the Orbit dock once.
  3. Without clicking the XMB, type a harmless search string and use arrow/category navigation; confirm keyboard input is accepted immediately after the morph handoff.
  4. Press Escape and confirm the XMB closes and the dock returns.
  5. Repeat once with the keybind-launched XMB and confirm the two launch paths have equivalent keyboard focus and navigation behavior.
  6. Capture final service state and compositor signature; use the safe reset if any surface remains stuck.
- Expected: Dock-launched XMB claims exclusive keyboard focus after handoff, accepts search/category/navigation keys without a preliminary click, and closes cleanly with Escape. Keybind launch remains unchanged.
- Automated evidence: Contract `tests/orbit/run-all` PASS 28/28 (`2026-08-17T15-21-01Z-3954782`); live `tests/orbit/run-all --live` PASS 32/32 (`2026-08-17T15-21-01Z-3954791`); one-minute soak PASS 10/10 (`soak-2026-08-17T15-21-01Z-3954801`); `orbit-shell.service` restarted active with signature `5c9377c15f85c50648f35ca5a213754f95b93ca0_1786975562_1510797335` matching `hyprctl instances`.
- Remaining manual gate: Attended dock-open keyboard focus, search/category navigation, Escape recovery, and comparison with keybind launch.
- Evidence to capture: short recording or screenshots of dock activation and focused input; exact harmless search string; repetition count; monitor name; timestamps; before/after `hyprctl layers -j`; `journalctl --user -u orbit-shell.service --since` test start; final service status and compositor signature.
- User decision: pending
- Follow-up issue / note: Keep `ORB-XMB-DOCK-FOCUS` and `UI-018` MANUAL until the attended focus and recovery behavior is recorded. Automated state/guard checks do not prove actual compositor keyboard focus.

### VQ-20260817-07 - ORB-APP-LAUNCH-BOUNDARY - shared dock/XMB launch boundary
- Status: READY
- Source issue / test / backlog: `ORB-APP-LAUNCH-BOUNDARY` / `APP-009` / Refactor Backlog Priority 3
- Worker session date: 2026-08-17
- Environment and prerequisites: Current Hyprland graphical session with `HYPRLAND_INSTANCE_SIGNATURE` matching `hyprctl instances`; `orbit-shell.service` active; one disposable application with no unsaved data; dock and XMB available. The shared helpers `.local/bin/orbit-app-launch` and `.local/bin/orbit-app-observe` must be executable.
- Safe reset: Close only the disposable application normally. If needed, use `hyprctl dispatch closewindow address:<address>` after recording the address; restart `orbit-shell.service` only if a surface is stale. Do not test with unsaved work or change display, audio, network, Bluetooth, or session state.
- Exact steps:
  1. Record `systemctl --user is-active orbit-shell.service`, `hyprctl instances`, and `hyprctl clients -j`.
  2. Focus monitor A and launch the disposable application once from the Orbit dock; record its address, PID, class, monitor, workspace, and whether it appears in an independent user scope.
  3. Close the disposable window.
  4. Focus monitor B and launch the same disposable application from the Orbit XMB; record the same fields and confirm the launch is recorded against the desktop identity without a literal `%U`/`%F` argument.
  5. Confirm Orbit remains active, the compositor signature is unchanged, and both launch paths produced equivalent scope/routing behavior.
  6. Perform the safe reset and record the final client list and service state.
- Expected: Dock and XMB launches use the same independent `systemd-run --user --scope --collect` boundary, preserve the initiating monitor/workspace, and produce equivalent application identity observation; Orbit and Hyprland remain healthy.
- Automated evidence: Contract 29/29 (`2026-08-17T15-32-16Z-4048673`); live 33/33 (`2026-08-17T15-32-17Z-4048738`); one-minute soak 11/11 (`soak-2026-08-17T15-32-21Z-4048672`); static contract asserts both QML surfaces call both shared helpers.
- Remaining manual gate: Attended disposable launch from both surfaces with scope, monitor/workspace, identity, and post-reset equivalence checks.
- Evidence to capture: disposable command and desktop ID; monitor/workspace JSON before and after; client address/PID/class; `/proc/<pid>/cgroup` or `systemctl --user` scope; timestamps; Orbit journal; final service status and compositor signature.
- User decision: pending
- Follow-up issue / note: Keep `ORB-APP-LAUNCH-BOUNDARY` and `APP-009` MANUAL until both launch surfaces pass the attended comparison. Concurrent same-class launch correlation remains a separate backlog item.

### VQ-20260817-08 - ORB-APP-CONCURRENT-CORRELATION - same-app launch identity correlation
- Status: READY
- Source issue / test / backlog: `ORB-APP-CONCURRENT-CORRELATION` / `APP-010` / Refactor Backlog Priority 3
- Worker session date: 2026-08-17
- Environment and prerequisites: Current two-monitor Hyprland graphical session with `HYPRLAND_INSTANCE_SIGNATURE` matching `hyprctl instances`; `orbit-shell.service` active after reload; Orbit dock and XMB available; use a disposable same-desktop-entry application that opens separate windows with no unsaved data; `jq` and the shared helpers are executable.
- Safe reset: Close both disposable windows normally. If needed, record each address and use `hyprctl dispatch closewindow address:<address>`; remove only stale disposable launch records under `$XDG_RUNTIME_DIR/orbit/application-launches.jsonl`; restart `orbit-shell.service` if a surface is stale. Do not test with real unsaved work or change display, audio, network, Bluetooth, or session state.
- Exact steps:
  1. Record `systemctl --user is-active orbit-shell.service`, `hyprctl instances`, `hyprctl clients -j`, and the current `$XDG_RUNTIME_DIR/orbit/application-launches.jsonl` state.
  2. Focus monitor A and launch the same disposable application twice in rapid succession from the Orbit dock or XMB before either window is fully mapped.
  3. Record both new client addresses, PIDs, classes, titles, monitor/workspace, and map order from `hyprctl clients -j`; inspect the launch observer records and `.config/orbit/application-identities.toml`.
  4. Confirm each mapped client is associated with a distinct launch ID and that neither launch consumed the other launch's pending record.
  5. Repeat once using the other Orbit launch surface and once from monitor B; do not move existing same-class windows.
  6. Close both disposable windows, perform the safe reset if needed, and record final clients, service status, compositor signature, and remaining pending records.
- Expected: Each concurrent same-app window is correlated with its own unique launch ID and mapped address/PID/class/title; no pending record is incorrectly consumed, existing same-class windows are untouched, and Orbit/Hyprland remain healthy.
- Automated evidence: Contract `tests/orbit/run-all` PASS 30/30 (`2026-08-17T15-45-08Z-4147520`); disposable two-record correlation fixture PASS; live `tests/orbit/run-all --live` PASS 34/34 (`2026-08-17T15-45-20Z-4149043`); one-minute soak PASS 11/11 (`soak-2026-08-17T15-45-27Z-4150028`); shell restart active with matching compositor signature and no new QML errors.
- Remaining manual gate: Attended rapid same-desktop-entry launches from both surfaces and both monitor directions, including exact client-to-launch-ID evidence and safe cleanup.
- Evidence to capture: disposable command/desktop ID; launch IDs; client address/PID/class/title; before/after `hyprctl clients -j`; monitor/workspace and map timestamps; pending-record contents before/after; `application-identities.toml` diff; Orbit journal; final service state and compositor signature.
- User decision: pending
- Follow-up issue / note: Keep `ORB-APP-CONCURRENT-CORRELATION` and `APP-010` MANUAL until the attended two-window fixture confirms one-to-one correlation. This worker's fixture proves exact record selection but not compositor/window mapping under real concurrent startup.

<!-- Current worker rerun: contract 30/30 `2026-08-17T15-48-16Z-4171928`, live 34/34 `2026-08-17T15-48-17Z-4171926`, soak 11/11 `soak-2026-08-17T15-48-25Z-4173026`; launch-ID inheritance and `/proc/<pid>/environ` matching are now included. -->
### VQ-20260817-16 - START-006 - shutdown confirmation guard current worker handoff
- Status: READY
- Source issue / test / backlog: `ORB-SESSION-TERMINATION-GUARD` / `START-006` / Priority 1 State and Lifecycle
- Worker session date: 2026-08-17
- Environment and prerequisites: Current Hyprland session; `HYPRLAND_INSTANCE_SIGNATURE=5c9377c15f85c50648f35ca5a213754f95b93ca0_1786975562_1510797335` matched `hyprctl instances`; `orbit-shell.service` active; `/usr/bin/zenity` installed; `XDG_SESSION_ID=38`; no unsaved work. The unattended worker did not choose `End session`.
- Safe reset: Choose `Cancel`; the session remains untouched. Restart `orbit-shell.service` only if a surface is stale, then re-check the signature and service state. Never terminate the graphical session during unattended processing or retry after an ambiguous result.
- Exact steps:
  1. Record `date -Is`, `XDG_SESSION_ID`, `HYPRLAND_INSTANCE_SIGNATURE`, `hyprctl instances`, and `systemctl --user status orbit-shell.service --no-pager`.
  2. Save or close disposable work, then invoke `SUPER + M` or `.config/hypr/scripts/animate-shutdown`.
  3. Select `Cancel` in the `zenity` dialog.
  4. Confirm the dialog closes, session 38 remains active, Orbit remains healthy, and neither shutdown animation nor `loginctl terminate-session` runs.
  5. Only in a separately approved attended run, repeat with disposable state and select `End session`; after re-login, verify Orbit service health and compositor signature.
  6. Capture final service status, `hyprctl instances`, session ID, and relevant shell journal lines. Stop if the destructive result is ambiguous.
- Expected: Cancel is a no-op. Confirmation precedes every shutdown action; missing `zenity` fails closed. The confirm path alone starts shutdown and terminates the session.
- Automated evidence: syntax/Python compilation; contract 35/35 (`2026-08-17T17-33-32Z-719334`); live 39/39 (`2026-08-17T17-33-32Z-719339`); one-minute soak 10/10 (`soak-2026-08-17T17-33-32Z-719341`). Disposable cancel returned 0 and logged only fake `zenity`; missing-`zenity` returned 1 with the fail-closed message; fake `loginctl` was not invoked.
- Remaining manual gate: Attended cancel behavior and, only if explicitly approved, real confirm/logout/re-login recovery.
- Evidence to capture: Dialog screenshot or recording; timestamps; session ID before/after; shell journal; service status; `hyprctl instances`; proof that cancel ran no termination command; re-login health for the approved confirm path.
- User decision: pending
- Follow-up issue / note: This is the single current `START-006` handoff; earlier entries are `SUPERSEDED` audit history. Keep the issue and test MANUAL. No unrelated item was changed.
