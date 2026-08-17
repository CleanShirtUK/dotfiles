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
| SEC-001 | Input helper uses only session-authorized keyboard devices | Contract / Live / Attended | FAIL | ACL-only mitigation made keyboard devices inaccessible after logout/login and was reverted; see `ORB-INPUT-PERMISSIONS` |
| START-004 | Runtime Alt+Tab bindings survive compositor transition | Live / Attended | PASS | 2026-08-17 fresh login: all three bindings present without manual restoration; `tests/orbit/run-all --live` passed. See `ORB-STARTUP-BINDINGS` |
| UI-001 | Dock appears independently per monitor | Attended | MANUAL | Two-monitor inspection |
| UI-002 | XMB is focused-monitor-only and workspace-free | Attended | MANUAL | Both monitors |
| UI-003 | XMB/dock interaction and animations | Attended | MANUAL | Rapid navigation, menus, launch feedback |
| UI-007 | Dock launcher presents a cohesive transition into ready-to-use XMB | Attended | MANUAL | Not yet run; activate dock launcher and assess handoff, readiness, interruption, and user approval; see `ORB-XMB-TRANSITION` |
| UI-006 | Alt release, MRU, and rapid cycle behavior | Attended | PASS | 2026-08-17: after shell reload, repeated rapid Alt-down/Tab press-release/Alt-up cycles produced exactly one workspace switch per invocation; slower behavior remained intact. See `ORB-ALT-RAPID-CYCLE` |
| APP-002 | Steam routes to Gaming | Attended | MANUAL | Controlled launch |
| APP-006 | Steam toast monitor correctness | Attended | FAIL | Known defect, see Issues |
| SET-003 | Failed display apply recovery | Disposable | BLOCKED | Recovery implementation incomplete |
| THEME-003 | Cross-toolkit palette propagation | Attended | MANUAL | Runtime matrix |
| MON-003 | Monitor disconnect/reconnect fallback | Hardware | MANUAL | Requires attended hardware test |

Add new IDs before implementing a behavior that needs repeatable validation.
