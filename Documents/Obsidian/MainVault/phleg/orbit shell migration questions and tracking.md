# Orbit Shell Migration

## Status

Orbit is a QuickShell-based replacement for Noctalia in a Hyprland session.
Orbit currently runs alongside Noctalia. Removal of Noctalia is a later,
attended migration step.

| Area | Status | Evidence |
| --- | --- | --- |
| Monitor role resolver | Implemented; contract-tested | `.local/bin/orbit-monitor`, `MON-001` |
| Application policy resolver | Implemented; contract-tested | `.local/bin/orbit-app-policy`, `APP-001` |
| Dynamic workspace routing | Implemented; live validation incomplete | `.config/hypr/scripts/dynamic-app-workspaces` |
| QuickShell shell, dock, XMB, overview | Implemented; live/UI validation incomplete | `.config/quickshell/orbit/` |
| Settings panel | First usable pass; display recovery incomplete | `.config/quickshell/orbit/Settings.qml` |
| Theme generator | Implemented; adapters need attended visual validation | `.local/bin/orbit-theme`, `THEME-001` |
| Noctalia removal | Not started | Phase 11 |

Do not mark an area complete based only on configuration or policy resolution
when the intended behavior depends on a real window, monitor, prompt, device,
or visual result.

## Scope And Architecture

- Project names are `Orbit`, `orbit-shell`, and `orbit-wallpaper`.
- Home and Gaming are logical monitor roles. Stable serial/model identity is
  preferred; connector names are hardware fallback data only.
- The dock is a compact global application surface on every connected monitor.
- The XMB is a focused-monitor layer-shell overlay and must not own a workspace.
- Normal applications launch on the focused monitor.
- Steam and configured games target Gaming, with Gaming falling back to Home.
- The default workspace model is one application or process tree per workspace.
- Child processes inherit their parent workspace unless policy excludes them.
- The empty Home workspace remains visible in the overview.
- Palette selection is centralized; Tokyo Night is the current reference.

## Implementation Map

| Concern | Path |
| --- | --- |
| Monitor settings | `.config/orbit/settings.toml` |
| Monitor resolver | `.local/bin/orbit-monitor` |
| Application policies | `.config/orbit/app-policies.toml` |
| Policy resolver | `.local/bin/orbit-app-policy` |
| Workspace routing | `.config/hypr/scripts/dynamic-app-workspaces` |
| Theme source/generator | `.config/orbit/palettes/`, `.local/bin/orbit-theme` |
| Generated theme artifacts | `.config/orbit/generated/` |
| Settings backend | `.local/bin/orbit-settings` |
| Settings menu | `.config/orbit/settings-menu.toml` |
| Settings QML | `.config/quickshell/orbit/Settings*.qml` |
| QuickShell root | `.config/quickshell/orbit/shell.qml` |
| Generated monitor config | `.config/hypr/monitors.lua` |
| Automated tests | `tests/orbit/` |

## Validation Policy

Every requirement has one of these states:

- `PASS`: the defined contract and its observable result passed.
- `FAIL`: a reproducible assertion failed; investigate the recorded run.
- `BLOCKED`: required application, device, fixture, or recovery path does not exist.
- `MANUAL`: visual, causal, or hardware behavior requires an attended session.
- `SKIP`: an optional live prerequisite was unavailable during a test run.

The automated suite is intentionally non-destructive. It does not disable
monitors, change audio/network/Bluetooth state, launch games, or remove
Noctalia. Live tests are read-only smoke checks.

Run deterministic tests:

```sh
tests/orbit/run-all
```

Run deterministic tests plus read-only session checks:

```sh
tests/orbit/run-all --live
```

Run as the desktop user with `HOME`, `XDG_RUNTIME_DIR`,
`HYPRLAND_INSTANCE_SIGNATURE`, and user D-Bus variables intact. A separate
root terminal should invoke the command as that user rather than assuming
`sudo` preserves the graphical session environment.

Logs are stored under:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/orbit/tests/<run-id>/
```

Each run contains `summary.json`, environment data, raw stdout/stderr,
captured state, and per-test result files. Exit status `0` means all applicable
tests passed; `1` means a failure; `2` means test setup failure.

## Automated Test Matrix

| ID | Requirement | Automation | State |
| --- | --- | --- | --- |
| STATIC-001 | Required files, executability, TOML and JSON syntax | Contract suite | PASS |
| MON-001 | Identity resolution, strict failure, Gaming fallback | Contract suite with fixtures | PASS |
| APP-001 | Defaults, transient policy, game routing, inheritance exclusion | Contract suite | PASS |
| THEME-001 | Palette validation and generated adapter set | Contract suite | PASS |
| SET-001 | Invalid policy rejection and generated rule attributes | Contract suite | PASS |
| STATE-001 | XMB and overview state transitions | Contract suite | PASS |
| LIVE-001 | Hyprland and Orbit settings snapshots | Read-only live suite | SKIP when no session |
| LIVE-002 | Home/Gaming roles resolve in the active session | Read-only live suite | SKIP when no session |
| LIVE-003 | Orbit user services are active | Read-only live suite | SKIP when service unavailable |
| MON-002 | Reordered connector role resolution | Fixture contract plus attended hardware test | MANUAL hardware portion |
| MON-003 | Disconnect/reconnect role fallback | Disposable or attended session | MANUAL |
| MON-004 | Wallpaper survives reconnect on every enabled monitor | Wallpaper observation | MANUAL |
| MON-005 | Disable/re-enable active monitor recovery | Disposable or attended session | MANUAL |
| MON-006 | Adaptive Sync persistence and runtime behavior | Compatible hardware | MANUAL |
| APP-002 | Steam receives Gaming monitor and dedicated workspace | Controlled live launch | MANUAL/ATTENDED |
| APP-003 | Game child windows remain with the game | Controlled game fixture | MANUAL/ATTENDED |
| APP-004 | Launcher/emulator dedicated child workspace | Installed application fixture | MANUAL/ATTENDED |
| APP-005 | Keyring prompt remains with initiating application | Reproducible locked-keyring fixture | BLOCKED |
| APP-006 | Steam toasts remain with Steam workspace and monitor | Live observation | FAIL: known bug |
| UI-001 | Dock appears independently on every monitor | Live shell inspection | MANUAL |
| UI-002 | XMB is focused-monitor-only and workspace-free | Live shell inspection | MANUAL |
| UI-003 | XMB/dock animations remain usable with two monitors | Attended interaction | MANUAL |
| UI-004 | Empty Home workspace appears in overview | Live shell inspection | MANUAL |
| UI-005 | No orphaned surfaces remain after monitor changes | Hotplug observation | MANUAL |
| UI-006 | Alt+Tab release, rapid release, and MRU behavior | Input/session observation | MANUAL |
| SET-002 | Staged draft, Cancel, Apply, and timeout cancellation | Attended UI test | MANUAL |
| SET-003 | Display failed-apply recovery and last-known-good restore | Disposable session | BLOCKED until recovery exists |
| SET-004 | Settings while Noctalia remains active | Live coexistence test | MANUAL |
| THEME-002 | Live reload versus restart behavior per application | Runtime matrix | MANUAL |
| THEME-003 | GTK, Qt, terminal, Zed, Zen, Obsidian, QuickShell, Hyprland | Visual/runtime matrix | MANUAL |
| THEME-004 | Flatpak toolkit styling | Flatpak runtime matrix | MANUAL |
| SEC-001 | Input helper device permissions | Security review and device test | MANUAL |

## Migration Phases

1. Establish logical monitor roles and resolver.
2. Integrate replay and monitor selection.
3. Implement policy-driven application and workspace routing.
4. Establish Tokyo Night palette and generated adapters.
5. Run the Orbit QuickShell foundation and global dock alongside Noctalia.
6. Replace the prototype launcher with focused-monitor XMB behavior.
7. Replace Hyprshell Alt+Tab and overview behavior with QuickShell.
8. Build and validate the unified Settings panel.
9. Replace the top bar and move control-center behavior into Settings.
10. Add notifications and standard event sounds.
11. Finish styling, including dock, launcher, Settings, and overview.
12. Remove Noctalia for an attended observation period.
13. Clean up, refactor, review the ecosystem, and push the dotfiles.
14. Prepare and publish the showcase build.

Phase completion requires the relevant automated tests plus the attended or
hardware-gated tests in the matrix. A policy resolver passing is not runtime
validation.

## Settings Panel Contract

The panel is a regular managed Qt window, floated and centered by its
`Orbit Settings` Hyprland rule. It has configurable menu ordering through
`.config/orbit/settings-menu.toml`, staged drafts, Cancel, Apply, and a
ten-second confirmation dialog.

Implemented first-pass modules include Appearance, Shell, Displays, Windows
and Applications, Audio, Network, Bluetooth, Power, and Diagnostics. Lock and
Idle, Wallpaper, richer system adapters, schema migration, backups, complete
transaction reporting, and robust rollback remain unfinished.

Display changes must not be considered safe until reconnect, missing-role,
disabled-monitor, failed-apply, persistence, and last-known-good recovery
paths have been exercised in a disposable or attended session.

## Workspace And Application Decisions

- Steam and configured game launchers target Gaming.
- `steam_app_*` children inherit a game workspace and exclude the Steam launcher.
- Transient authentication and desktop dialogs follow the initiating application.
- Floating utilities remain on their launch workspace while floating.
- A floating utility moved to tiled mode receives a dedicated workspace.
- Pinned and running applications share one dock item model without duplicates.
- Title-only rules are allowed but must display a persistent reliability warning.
- Application identity aliases must survive Orbit and Hyprland restarts.
- Conflicting `StartupWMClass` values need an explicit resolution policy.

## Themes And Palette Work

The current canonical palette is Tokyo Night. Planned palettes are Catppuccin,
Gruvbox, Nord, Dracula, Solarized, One Dark, Everforest, Rose Pine, Ayu, and
Monokai. Future theme work includes icon themes, Hyprland window styling,
hyprwindowshade/hyprglass values, wallpaper-derived palettes, and reliable
Flatpak styling.

For every application, record whether a change is live, reload-only, or
restart-required. Do not mark visual parity based solely on generated files.

## Known Defects And Blockers

- Steam toasts have been observed focusing Steam's workspace while appearing on
  the wrong monitor.
- Keyring prompt validation is blocked because the default keyring is already
  unlocked and desktop locking does not reproduce a prompt.
- Physical hotplug and failed display recovery are not yet safety-proven.
- VRR behavior is unvalidated on compatible hardware.
- The input helper can read event devices through the `input` group; narrowing
  permissions to the main keyboard is a security follow-up.
- ProtonUp-Qt requires its KDE Flatpak runtime/theme setup and a restart after
  changes.

## Open Design Questions

- How should launcher left/right category navigation work?
- Which application classifications should be exposed in the editor?
- Which standard window attributes should be configurable without Lua?
- How should side-by-side applications differ from dedicated applications?
- How should conflicting desktop-entry and observed classes be presented?
- Should wallpaper support PS3 waves, recoloring, shaders, and derived palettes?
- Should SDDM replace the current session manager?
- Should dock launch animations stop on window load or after ten seconds?

## Security Follow-Up

- Review the input helper's device permissions.
- Restrict access to the intended keyboard device where practical.
- Re-run the Alt+Tab release and rapid-release tests after permission changes.
- Do not treat `sg input` access as the final security design.

## Historical Validation Notes

Previously observed behavior includes successful monitor listing and fallback,
replay capture using Gaming or Home fallback, Steam routing, transient Steam
window retention, policy-driven routing without move loops, child-process
inheritance, floating utility transitions, dock deduplication, Settings display
rendering, confirmed monitor profile reload, and generated Tokyo Night adapters.

These observations remain useful history but must be reproduced through the
test matrix before being used as current phase-completion evidence.
