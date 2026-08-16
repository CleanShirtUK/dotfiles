---
title: Orbit Shell Project
type: project-index
status: active
tags:
  - orbit
  - quickshell
  - hyprland
---

# Orbit Shell Project

Orbit is the QuickShell-based desktop shell replacing Noctalia in the Phleg Hyprland session.

> [!important]
> Current work must be recorded as evidence-backed status. A contract test passing does not prove visual, hardware, or causal behavior.

## Project Pages

- [[Orbit - Overview]]
- [[Orbit - Status]]
- [[Orbit - Architecture]]
- [[Orbit - Startup and Session Lifecycle]]
- [[Orbit - Testing Strategy]]
- [[Orbit - Test Matrix]]
- [[Orbit - Issues and Corrections]]
- [[Orbit - Decisions and Open Questions]]
- [[Orbit - Refactor Backlog]]
- [[Orbit - Visual Validation Log]]
- [[Orbit - Change Log]]
- [[Orbit - Prompt Repository]]
- [[Orbit - Session Scratchpad]]

## Immediate Focus

- Establish Orbit as the only Hyprland shell autostart.
- Remove the reserved-workspace fullscreen XMB prototype.
- Validate login, lock/unlock, shutdown, dock, XMB, overview, and application routing.
- Reduce duplicated state ownership and polling before adding more UI behavior.

## Repository Map

| Concern | Path |
| --- | --- |
| Orbit QuickShell root | `.config/quickshell/orbit/shell.qml` |
| Orbit helpers | `.local/bin/orbit-*` |
| Orbit settings | `.config/orbit/` |
| Hyprland configuration | `.config/hypr/` |
| User services | `.config/systemd/user/` |
| Automated tests | `tests/orbit/` |

## Historical Source

The former single-document migration notes were split into the pages above. Git history retains the original document and is the source for older implementation claims that are not yet reproduced in the current test matrix.
