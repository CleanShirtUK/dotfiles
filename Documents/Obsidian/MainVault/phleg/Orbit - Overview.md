---
title: Orbit - Overview
type: project-overview
tags: [orbit, project]
---

# Orbit Overview

## Goal

Replace Noctalia with a maintainable QuickShell desktop shell for Hyprland while preserving the Phleg session's monitor roles, dynamic workspaces, theme system, wallpaper transitions, and application routing.

## Product Surfaces

- Global dock on every connected monitor.
- Focused-monitor, workspace-free XMB launcher.
- Alt+Tab/overview workspace switcher.
- Unified Settings window.
- Orbit theme and palette adapters.
- Orbit-aware application and workspace routing.

## Non-Goals

- Recreating every Noctalia implementation detail.
- Treating generated configuration as proof of runtime behavior.
- Changing monitors, audio, network, or Bluetooth state in unattended tests.

## Current Boundary

Orbit owns the shell, dock, XMB, overview, settings, and shell visibility transitions. The PS3 wallpaper remains a separate service. Noctalia is no longer a session autostart dependency; remaining historical filenames such as `noctalia.css` are theme-adapter compatibility names and should be renamed in a separate controlled change.

See [[Orbit - Status]] for deliverables and [[Orbit - Issues and Corrections]] for known defects.
