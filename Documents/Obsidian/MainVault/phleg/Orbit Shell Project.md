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
- [[Orbit - Agent Workflows]]
- [[Orbit - Validation Queue]]
- [[Orbit - Repository Boundaries]]

## Canonical Project Data

- `orbit/project-manifest.json`: canonical project scope, completion definition, work-item state, evidence, and processing policy.
- Orbit Markdown pages: human-readable views validated against the manifests. Until both manifests exist, the evidence-backed Markdown remains the tracking source.

## Immediate Focus

- Revalidate startup invariants, beginning with the missing runtime `Alt+Tab` binding, and close applicable attended stabilization gates.
- Validate `orbit/project-manifest.json` and keep the Markdown projections synchronized with it.
- Complete remaining full-scratchpad Orbit 1.0 behavior only after stabilization.
- Complete the independently reproducible Standard dotfiles, Orbit, and Wallpaper repository split required for Orbit 1.0.

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
