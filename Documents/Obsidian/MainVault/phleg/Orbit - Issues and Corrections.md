---
title: Orbit - Issues and Corrections
type: issue-tracker
tags: [orbit, issues]
---

# Issues And Corrections

Use one entry per issue. Do not bury unresolved defects in status prose.

## Template

```markdown
### ORB-YYYYMMDD-01 Short title
- Status: Open
- Severity: High / Medium / Low
- Area: startup / shell / routing / settings / appearance / hardware
- Reproduction:
  1.
- Expected:
- Actual:
- Evidence:
- Suspected cause:
- Fix:
- Validation:
```

## Active Issues

### ORB-XMB-TRANSITION Dock-to-XMB transition is not defined or validated
- Status: Open
- Severity: Low
- Area: shell
- Classification: Feature / behavior clarification
- Reproduction:
  1. Open the Orbit dock on a monitor.
  2. Activate the launcher entry.
  3. Observe the transition into the XMB and whether the dock visually becomes or hands off to it.
- Expected: The dock-to-XMB transition makes the launcher feel like one cohesive surface, with the XMB ready for immediate use.
- Actual: The desired transition is recorded, but its animation, handoff behavior, and user-approved acceptance have not been defined or validated.
- Evidence: `Orbit - Session Scratchpad`, `DES-YYYYMMDD-## Create a transtion from the dock to XMB to enable them to appear as one cohesive unit`.
- Suspected cause: Not established; this is a feature request rather than a confirmed implementation defect.
- Fix: Define the smallest transition contract, implement it at the dock/XMB ownership boundary, and validate it with an attended interaction pass.
- Validation: Add and run `UI-007` after implementation; record visual evidence and user approval.

### ORB-STEAM-TOAST Steam toast monitor mismatch
- Status: Open
- Severity: Medium
- Area: routing
- Expected: Steam toast remains with Steam's monitor and workspace.
- Actual: Toast can appear on the wrong monitor while focus moves to Steam's workspace.
- Evidence: Existing `APP-006` history.
- Next action: Capture client identity, parent process, monitor, workspace, and timing during a controlled launch.

### ORB-DISPLAY-RECOVERY Display apply has no proven rollback
- Status: Blocked
- Severity: High
- Area: settings / hardware
- Expected: Failed display apply restores the last-known-good topology.
- Actual: Apply is sequential and rollback is not yet safety-proven.
- Evidence: `SET-003`.

### ORB-THEME-PROPAGATION Palette propagation is not uniformly live
- Status: Open
- Severity: Medium
- Area: appearance
- Expected: Each toolkit's live/reload/restart behavior is known.
- Actual: Running surfaces can retain old colors.
- Next action: Complete the palette runtime matrix.

### ORB-INPUT-PERMISSIONS Input helper is broader than necessary
- Status: Open; attempted mitigation reverted after behavior regression
- Severity: Medium
- Area: security
- Expected: Input state helper reads only the intended keyboard device.
- Actual: The service uses `/usr/bin/sg input`, granting the helper access to every input-group device. Removing that elevation left the actual keyboard devices inaccessible after logout/login and made Alt+Tab unresponsive.
- Fix: Reverted the unproven ACL-only change. Keep the existing access path until a device-specific ACL or privileged helper design is implemented and validated.
- Validation: Regression reproduced after logout/login; direct Orbit binding commands restored Alt+Tab in the current session. Fresh-login ACL behavior and attended Alt-release tests remain open.

### ORB-STARTUP-BINDINGS Runtime Alt+Tab bindings can be lost during compositor transition
- Status: Closed
- Severity: Medium
- Area: startup / shell
- Reproduction:
  1. Log out and log back into Hyprland.
  2. Inspect `hyprctl binds` for the Orbit `ALT + TAB` and Alt-release bindings.
  3. Try Alt+Tab if the bindings are absent.
- Expected: Orbit installs its runtime bindings after the new Hyprland control socket is ready.
- Actual: After the fresh login on 2026-08-16, the shell and input services were active but `hyprctl binds` contained no Orbit `TAB`, `Alt_L`, or `Alt_R` bindings. Direct eval commands returned `ok` and restored them.
- Evidence: Fresh-login command output; shell journal showed `Configuration Loaded` but no binding evidence. `tests/orbit/run-all --live` initially passed because it did not inspect bindings. Manual binding restoration made `START-004` pass in the current session.
- Suspected cause: The final Hyprland `reload config-only` in the startup hook can erase bindings installed by the earlier Orbit service start.
- Fix: Restart `orbit-shell.service` immediately after the final config reload, retain verification-aware binding retry, and assert binding presence in `START-004`.
- Validation: Fresh-login verification on 2026-08-17 found all three bindings present without manual restoration; `tests/orbit/run-all` PASS (14 checks), `tests/orbit/run-all --live` PASS (18 checks), and repeated attended Alt+Tab testing passed after shell reload.

### ORB-ALT-RAPID-CYCLE Rapid Alt+Tab can issue duplicate workspace cycles
- Status: Closed
- Severity: Medium
- Area: shell
- Reproduction:
  1. Hold `Alt` and use a rapid `Tab` press or rapid Tab sequence.
  2. Observe the active workspace while the overview is open.
- Expected: Each physical Tab press that began while Alt was held advances the overview exactly once, even if Alt is released before Tab; releasing Alt closes the overview without cancelling or duplicating that committed cycle.
- Actual: User reproduced the double workspace switch again after a fresh login. It remains intermittent and only occurs with very rapid Alt+Tab; slower chords do not reproduce it.
- Evidence: Prior timing capture in `/tmp/orbit-keys-full.log` and `/tmp/orbit-hypr-events-precise.log`; new attended reproduction after lifecycle validation.
- Suspected cause: Both the trigger path and the file-state open transition could focus the selected workspace, allowing asynchronous MRU changes to issue a second focus request.
- Fix: `OverviewModel.qml` now gives `openFromTrigger()` sole ownership of the initial workspace focus; the state transition only updates visibility. Added `STATE-002` contract coverage.
- Validation: `sh -n .local/bin/orbit-overview .local/bin/orbit-shell`; `tests/orbit/run-all` PASS (14 checks); `tests/orbit/run-all --live` PASS (18 checks). On 2026-08-17, after reloading `orbit-shell.service`, attended rapid Alt-down/Tab press-release/Alt-up testing was rock solid across repeated cycles with exactly one workspace switch per invocation. Evidence: current-session verification and shell reload journal.
