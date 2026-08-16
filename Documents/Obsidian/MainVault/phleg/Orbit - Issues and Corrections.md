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
- Status: Open
- Severity: Medium
- Area: security
- Expected: Input state helper reads only the intended keyboard device.
- Actual: It currently uses the `input` group.
- Next action: Narrow permissions and repeat Alt-release tests.
