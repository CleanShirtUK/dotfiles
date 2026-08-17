---
title: Orbit - Overview
type: project-overview
tags: [orbit, project]
---

# Orbit Overview

## Goal

Replace Noctalia with a maintainable QuickShell desktop shell for Hyprland while preserving the Phleg session's monitor roles, dynamic workspaces, theme system, wallpaper transitions, and application routing.

## Orbit 1.0 Completion

Orbit 1.0 is complete when the full accepted product vision in [[Orbit - Session Scratchpad]] is implemented and independently validated, all required stabilization gates are closed, and the three-repository split in [[Orbit - Repository Boundaries]] is complete and independently reproducible. Stabilization precedes feature completion work.

## Product Surfaces

- Global dock on every connected monitor.
- Focused-monitor, workspace-free XMB launcher.
- Alt+Tab/overview workspace switcher.
- Unified Settings window.
- Orbit theme and palette adapters.
- Global application menus on Orbit panels.
- Orbit-aware application and workspace routing.

## Non-Goals

- Recreating every Noctalia implementation detail.
- Treating generated configuration as proof of runtime behavior.
- Changing monitors, audio, network, or Bluetooth state in unattended tests.

## Current Boundary

Orbit owns the shell, dock, XMB, overview, settings, and shell visibility transitions. The PS3 wallpaper remains a separate service. Noctalia is no longer a session autostart dependency; remaining historical filenames such as `noctalia.css` are theme-adapter compatibility names and should be renamed in a separate controlled change.

The required Orbit 1.0 three-repository boundary is documented in [[Orbit - Repository Boundaries]]. The current repository remains the transitional complete desktop setup until that split is complete.

The machine-readable `orbit/project-manifest.json` is canonical for project metadata and work-item state; these Markdown pages are the human-readable view and must be validated against it.

See [[Orbit - Status]] for deliverables and [[Orbit - Issues and Corrections]] for known defects.
