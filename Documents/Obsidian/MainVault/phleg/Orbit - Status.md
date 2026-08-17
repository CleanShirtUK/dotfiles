---
title: Orbit - Status
type: project-status
updated: 2026-08-16
tags: [orbit, status]
---

# Orbit Status

## Phase Summary

| Deliverable | State | Evidence / next gate |
| --- | --- | --- |
| Monitor role resolver | PASS | `.local/bin/orbit-monitor`, `MON-001` |
| Application policy resolver | PASS | `.local/bin/orbit-app-policy`, `APP-001` |
| Dynamic workspace routing | MANUAL | Live child-window and Steam validation |
| Orbit shell and dock | IMPLEMENTED | Live two-monitor interaction pass |
| Focused-monitor XMB | IMPLEMENTED | Rapid navigation and monitor-focus pass |
| Overview / Alt+Tab | IMPLEMENTED | Initial-open focus ownership deduplicated; rapid attended retest passed |
| Dock-to-XMB transition | NOT STARTED | Low-priority feature; define and run `UI-007` |
| Settings | FIRST PASS | Transactional display recovery and page split remain |
| Theme generator | IMPLEMENTED | Cross-toolkit propagation matrix remains |
| Noctalia autostart removal | IMPLEMENTED | Fresh login and transition validation |
| Reserved XMB prototype removal | IMPLEMENTED | Confirm no prototype surfaces or service |
| Input helper permissions | OPEN | ACL-only mitigation regressed Alt+Tab after logout/login; existing `input` group path restored |
| Runtime Alt+Tab binding startup | IMPLEMENTED | Restart-after-config-reload and binding-table verification passed fresh-login validation |
| Refactor pass | NOT STARTED | See [[Orbit - Refactor Backlog]] |

## Definition Of Done

An item is complete only when its contract tests pass and all applicable live, attended, hardware, or recovery gates are recorded in [[Orbit - Test Matrix]].

## Next Session Checklist

- [ ] Log out and log in with the user manager reused.
- [ ] Confirm `orbit-shell.service` is active and Noctalia is inactive/not installed in the session graph.
- [ ] Confirm no `phleg-xmb-*` clients exist.
- [ ] Test startup and unlock wallpaper transitions.
- [ ] Test XMB focus ownership on both monitors.
- [x] Test overview release and rapid release.
- [ ] Capture failures in [[Orbit - Issues and Corrections]].

## Latest Automated Evidence

- `tests/orbit/run-all`: PASS, 14 contract checks.
- `tests/orbit/run-all --live`: PASS, 18 checks with the current Hyprland instance environment, including `START-004` binding presence and `STATE-002` open ownership.
- Input helper permissions: OPEN; ACL-only mitigation regressed after logout/login and was reverted.
- Runtime Alt+Tab binding startup: fresh-login validation passed with bindings present without manual restoration.
- Rapid Alt+Tab: duplicate-focus fix passed repeated attended rapid-cycle testing after shell reload.
- Two-minute soak: PASS, 19 iterations, no failures.
- Soak maximum recorded Orbit RSS: approximately 481 MiB; investigate during the runtime snapshot/polling refactor.
