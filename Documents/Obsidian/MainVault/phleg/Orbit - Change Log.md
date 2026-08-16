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
