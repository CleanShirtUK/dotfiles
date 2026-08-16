---
title: Orbit - Test Matrix
type: test-matrix
tags: [orbit, testing, tracking]
---

# Orbit Test Matrix

| ID | Requirement | Automation | State | Evidence / notes |
| --- | --- | --- | --- | --- |
| STATIC-001 | Required files and config syntax | Contract | PASS | `tests/orbit/contract/test_contract.py` |
| DOCK-001 | Dock persistence and duplicate prevention | Contract | PASS | Atomic JSON replacement |
| MON-001 | Monitor identity and Gaming fallback | Contract | PASS | Fixture contract |
| APP-001 | Application defaults, transient policy, inheritance | Contract | PASS | Policy fixtures |
| THEME-001 | Palette validation and adapters | Contract | PASS | Generated artifact contract |
| SET-001 | Policy validation and generated rules | Contract | PASS | Settings contract |
| STATE-001 | XMB and overview state transitions | Contract | PASS | State helper contract |
| START-001 | Orbit starts after environment import | Live / attended | MANUAL | Fresh login and reused user manager |
| START-002 | Noctalia is absent from session autostart | Live | MANUAL | Inspect target and process graph |
| START-003 | No prototype XMB clients or service remain | Live | MANUAL | Inspect clients and units |
| LIVE-001 | Hyprland and Orbit snapshots | Live | SKIP if no session | Read-only |
| LIVE-002 | Home/Gaming roles resolve | Live | SKIP if no session | Read-only |
| LIVE-003 | Orbit services active | Live | SKIP if unavailable | Orbit shell and input helper |
| UI-001 | Dock appears independently per monitor | Attended | MANUAL | Two-monitor inspection |
| UI-002 | XMB is focused-monitor-only and workspace-free | Attended | MANUAL | Both monitors |
| UI-003 | XMB/dock interaction and animations | Attended | MANUAL | Rapid navigation, menus, launch feedback |
| UI-006 | Alt release and MRU behavior | Attended | MANUAL | Normal and rapid release |
| APP-002 | Steam routes to Gaming | Attended | MANUAL | Controlled launch |
| APP-006 | Steam toast monitor correctness | Attended | FAIL | Known defect, see Issues |
| SET-003 | Failed display apply recovery | Disposable | BLOCKED | Recovery implementation incomplete |
| THEME-003 | Cross-toolkit palette propagation | Attended | MANUAL | Runtime matrix |
| MON-003 | Monitor disconnect/reconnect fallback | Hardware | MANUAL | Requires attended hardware test |

Add new IDs before implementing a behavior that needs repeatable validation.
