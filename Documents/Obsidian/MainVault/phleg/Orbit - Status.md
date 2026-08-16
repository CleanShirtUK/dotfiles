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
| Overview / Alt+Tab | IMPLEMENTED | Release, rapid-release, and MRU pass |
| Settings | FIRST PASS | Transactional display recovery and page split remain |
| Theme generator | IMPLEMENTED | Cross-toolkit propagation matrix remains |
| Noctalia autostart removal | IMPLEMENTED | Fresh login and transition validation |
| Reserved XMB prototype removal | IMPLEMENTED | Confirm no prototype surfaces or service |
| Refactor pass | NOT STARTED | See [[Orbit - Refactor Backlog]] |

## Definition Of Done

An item is complete only when its contract tests pass and all applicable live, attended, hardware, or recovery gates are recorded in [[Orbit - Test Matrix]].

## Next Session Checklist

- [ ] Log out and log in with the user manager reused.
- [ ] Confirm `orbit-shell.service` is active and Noctalia is inactive/not installed in the session graph.
- [ ] Confirm no `phleg-xmb-*` clients exist.
- [ ] Test startup and unlock wallpaper transitions.
- [ ] Test XMB focus ownership on both monitors.
- [ ] Test overview release and rapid release.
- [ ] Capture failures in [[Orbit - Issues and Corrections]].

## Latest Automated Evidence

- `tests/orbit/run-all`: PASS, 11 contract checks.
- `tests/orbit/run-all --live`: PASS, 14 checks with the current Hyprland instance environment.
- Two-minute soak: PASS, 19 iterations, no failures.
- Soak maximum recorded Orbit RSS: approximately 481 MiB; investigate during the runtime snapshot/polling refactor.
