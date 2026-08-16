# Orbit Shell Migration

## Status

Orbit is a QuickShell-based replacement for Noctalia in a Hyprland session.
Orbit currently runs alongside Noctalia. Removal of Noctalia is a later,
attended migration step.

| Area                                  | Status                                                                                              | Evidence                                           |
| ------------------------------------- | --------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| Monitor role resolver                 | Implemented; contract-tested                                                                        | `.local/bin/orbit-monitor`, `MON-001`              |
| Application policy resolver           | Implemented; contract-tested                                                                        | `.local/bin/orbit-app-policy`, `APP-001`           |
| Dynamic workspace routing             | Implemented; live validation incomplete                                                             | `.config/hypr/scripts/dynamic-app-workspaces`      |
| QuickShell shell, dock, XMB, overview | Implemented; dock interaction first pass complete; live/UI validation incomplete                 | `.config/quickshell/orbit/`, `DOCK-001`, `UI-003` |
| Settings panel                        | Structured first pass; display recovery, palette propagation, and full visual validation incomplete | `.config/quickshell/orbit/Settings.qml`            |
| Theme generator                       | Implemented; active adapters installed but cross-toolkit propagation remains unproven               | `.local/bin/orbit-theme`, `THEME-001`, `THEME-003` |
| Noctalia removal                      | Not started                                                                                         | Phase 12                                           |

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
- Palette selection is centralized; Tokyo Night remains the reference palette and
  `gruvbox-dark` is the current active test palette.

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
| Hypridle defaults | `.config/orbit/hypridle-defaults.toml` |
| QuickShell root | `.config/quickshell/orbit/shell.qml` |
| Dock persistence helper | `.local/bin/orbit-dock` |
| Shared scalable icon component | `.config/quickshell/orbit/OrbitIcon.qml` |
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

### Overnight Soak

The smoke suite is intentionally quick. For unattended stability testing, use
the non-destructive soak runner:

```sh
tests/orbit/run-soak --hours 8 --interval 30
```

Before relying on a new test change, validate the runner with:

```sh
tests/orbit/run-soak --minutes 2 --interval 5 --snapshot-every 1
```

The soak runner does not launch applications, change monitors, or mutate
audio/network/Bluetooth state. It repeatedly exercises XMB/overview open and
close control paths, validates Hyprland JSON snapshots and settings snapshots,
checks Orbit service health, restart counts, QuickShell RSS, recent user
journal output, and generated-theme integrity. It writes `events.jsonl`,
periodic `snapshots/`, journal captures, and a final `summary.json` beneath the
run directory. Any observed failure remains recorded while the soak continues
to gather evidence.

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
| DOCK-001 | Dock pin and unpin persistence, duplicate prevention, atomic JSON replacement | Contract suite | PASS |
| MON-001 | Identity resolution, strict failure, Gaming fallback | Contract suite with fixtures | PASS |
| APP-001 | Defaults, transient policy, game routing, inheritance exclusion | Contract suite | PASS |
| THEME-001 | Palette validation and generated adapter set | Contract suite | PASS |
| SET-001 | Invalid policy rejection and generated rule attributes | Contract suite | PASS |
| SYSTEM-001 | Audio, Network, and Bluetooth snapshot parsing and action contract | Contract suite | PASS |
| POWER-001 | TuneD profile and Hypridle configuration contract | Contract suite | PASS |
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
| UI-003 | XMB/dock animations, expanded pointer surface, menus, and launch feedback remain usable with two monitors | Attended interaction | MANUAL |
| UI-004 | Empty Home workspace appears in overview | Live shell inspection | MANUAL |
| UI-005 | No orphaned surfaces remain after monitor changes | Hotplug observation | MANUAL |
| UI-006 | Alt+Tab release, rapid release, and MRU behavior | Input/session observation | MANUAL |
| SET-002 | Staged draft, Cancel, Apply, and timeout cancellation | Attended UI test | MANUAL |
| SET-003 | Display failed-apply recovery and last-known-good restore | Disposable session | BLOCKED until recovery exists |
| SET-004 | Settings while Noctalia remains active | Live coexistence test | MANUAL |
| APPEARANCE-001 | Appearance schema, generated runtime artifacts, and validation | Contract suite | PASS |
| APPEARANCE-002 | Palette preview and staged appearance controls | Attended UI test | MANUAL |
| APPEARANCE-003 | Hyprland style, opacity, Hyprglass, and animation reload behavior | Attended session | MANUAL |
| APPEARANCE-004 | Wallpaper-derived palette disabled for shader wallpaper | Attended UI test | MANUAL |
| THEME-002 | Live reload versus restart behavior per application | Runtime matrix | MANUAL |
| THEME-003 | GTK, Qt, terminal, Zed, Zen, Obsidian, QuickShell, Hyprland | Visual/runtime matrix | MANUAL |
| THEME-004 | Flatpak toolkit styling | Flatpak runtime matrix | MANUAL |
| SEC-001 | Input helper device permissions | Security review and device test | MANUAL |
| SYSTEM-002 | Audio output/input selection, volume, mute, and stream behavior | Attended session with PipeWire devices | MANUAL |
| SYSTEM-003 | Network device/profile state, connect/disconnect, and coexistence | Attended NetworkManager session | MANUAL |
| SYSTEM-004 | Bluetooth adapter, scan, connect/disconnect, and removal behavior | Attended Bluetooth hardware test | MANUAL/BLOCKED without device |
| POWER-002 | TuneD profile switching and staged Apply behavior | Attended session | MANUAL |
| POWER-003 | Hypridle command, timeout, staged Apply, and service restart behavior | Attended session | MANUAL |

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
and Applications, Audio, Network, Bluetooth, Power, and Diagnostics. Audio,
Network, and Bluetooth now expose structured live device state and immediate
runtime actions. Network now includes a two-pane NetworkManager profile editor
covering general, Wi-Fi, IPv4, IPv6, and proxy settings, with hidden virtual
connection types and available-SSID search/connect controls. Bluetooth includes
adapter controls, device search, pairing, trust/block, connect, and removal
actions. Power uses TuneD when available and exposes staged Hypridle
enablement, lock, and suspend settings. Wallpaper now reports the shader
service state and provides a restart/reveal recovery action. Schema migration,
backups, complete transaction reporting, and robust rollback remain
unfinished.

Display changes must not be considered safe until reconnect, missing-role,
disabled-monitor, failed-apply, persistence, and last-known-good recovery
paths have been exercised in a disposable or attended session.

### System Settings First Pass

Audio exposes PipeWire output/input devices, defaults, volume, mute, and active
streams. Network exposes a two-pane NetworkManager profile editor with General,
Wi-Fi, IPv4, IPv6, and Proxy sections, saved-profile actions, hidden virtual
connection types, and available-SSID search/connect controls. Bluetooth follows
a Blueman-style layout with adapter controls, searchable devices, pairing,
trust/block, connect, and removal actions; hardware validation is deferred
because no Bluetooth devices are currently visible in the session.

Power uses TuneD when available instead of requiring `powerprofilesctl`. The
Power page exposes TuneD profiles and staged Hypridle enablement, lock and
suspend timeouts, and editable lock/suspend commands. Defaults are stored in
`.config/orbit/hypridle-defaults.toml`; changes remain staged until the global
Apply action writes `hypridle.conf` and restarts the user Hypridle service.

The deterministic suite covers system adapter parsing and TuneD/Hypridle
contracts. Network profile editing, audio device changes, Bluetooth hardware,
TuneD switching, and Hypridle behavior remain attended validation items.

### Appearance First Pass

The Appearance page now has four compact submenus: Colours, Styles,
Transparency, and Effects. Colours presents each palette as a name with four
swatches for background, surface, accent, and text. It also includes custom
palette creation and a wallpaper-derived palette action that is disabled while
the current shader wallpaper is active. Styles currently exposes shared button
shape and corner roundness. Transparency exposes active, inactive, and Orbit
shell opacity. Effects exposes Hyprglass enablement and blur type,
HyprWindowShade enablement, and grouped animation enablement, type, and speed.

Appearance edits are staged. Palette, radius, and shell transparency changes
preview inside the Settings window immediately, while Hyprland, toolkit
artifacts, and other shell surfaces remain unchanged until Apply. Apply writes
the appearance schema, generated `appearance.lua`/`appearance.json` artifacts,
and active GTK/KDE adapter files, then reloads the relevant Hyprland
configuration. Cross-toolkit palette propagation remains unproven and must not
be treated as complete. The current
animation groups are global and borders, windows, fades, layers, workspaces,
and movement/zoom. Animation types include default, fade, slide, pop-in,
slide/fade, and vertical slide/fade.

### Appearance Validation

Run `tests/orbit/run-all` for schema validation, generated artifact checks,
custom palette validation, and state regression coverage. In an attended
session, verify palette swatches and local-only previews, Cancel/Apply behavior,
custom palette creation, opacity and corner-radius previews, and the disabled
shader-wallpaper derivation action. Then verify Hyprland reload behavior for
Hyprglass, HyprWindowShade, opacity, animation type, animation speed, and each
animation group. Finally run the toolkit/runtime matrix for GTK, Qt,
QuickShell, terminals, Zed, Zen, Obsidian, Hyprland, and Flatpak applications;
record whether each change is live, reload-only, or restart-required.

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

Tokyo Night remains the canonical reference palette. The current active test
palette is `gruvbox-dark`; Catppuccin Mocha and Nord are also available as
schema-valid test palettes. Planned palettes are Dracula, Solarized, One Dark,
Everforest, Rose Pine, Ayu, and Monokai. Future theme work includes icon themes,
Hyprland window styling, hyprwindowshade/hyprglass values, wallpaper-derived
palettes, and reliable Flatpak styling.

For every application, record whether a change is live, reload-only, or
restart-required. Do not mark visual parity based solely on generated files.

### Palette Propagation Follow-Up

Palette installation now updates the active GTK3/GTK4 CSS imports and the KDE
color scheme, and Orbit follows the selected generated QuickShell palette.
However, palette changes are not yet considered reliable across all running
applications or all Orbit surfaces. The next testing pass must switch between
Tokyo Night, Gruvbox Dark, Catppuccin Mocha, and Nord; inspect Orbit controls,
GTK3, GTK4/libadwaita, Breeze Qt, Flatpak Qt, terminals, and editor surfaces;
and record whether each application updates live, needs a reload, or needs a
restart. Any stale surface or old color is a `FAIL` until its propagation path
is understood.

## Known Defects And Blockers

- Steam toasts have been observed focusing Steam's workspace while appearing on
  the wrong monitor.
- Keyring prompt validation is blocked because the default keyring is already
  unlocked and desktop locking does not reproduce a prompt.
- Physical hotplug and failed display recovery are not yet safety-proven. The
  monitor disable flow also needs review because the current panel does not yet
  expose a safe re-enable/recovery path.
- VRR behavior is unvalidated on compatible hardware.
- Palette changes can leave stale colors in running GTK, Qt, Flatpak, or Orbit
  surfaces; propagation and restart requirements remain under investigation.
- Manual PS3 wallpaper service restarts previously left the renderer hidden;
  Orbit now sends the reveal request after restart, but startup and reconnect
  behavior still require attended validation.
- The input helper can read event devices through the `input` group; narrowing
  permissions to the main keyboard is a security follow-up.
- ProtonUp-Qt requires its KDE Flatpak runtime/theme setup and a restart after
  changes.

## Dock Interaction Pass

Orbit now provides a global dock interaction model with continuous pointer
tracking over an expanded layer-shell surface, hover magnification, cumulative
neighboring-icon response, launch feedback, and a ten-second launch timeout.
Pointer tracking is owned by one passive `HoverHandler`; icon hit areas are
reserved for clicks and context menus, avoiding icon-to-icon hover deadzones.
The visible dock remains a compact capsule while its layer-shell exclusive zone
stays fixed at the normal dock footprint.

Launch feedback clears when any matching-class Hyprland window appears. The dock
context menu supports pinning, unpinning, opening a new window through the
desktop entry, and closing every window belonging to the application. Close is
hidden for applications that are not running. Menu space is overlay space and
does not expand the Hyprland reserved workspace area. Dock pin changes are
persisted atomically in `.config/orbit/dock.json`.

Orbit shell surfaces now share an SVG-capable icon component with size-aware
loading for Kora's scalable icon assets. Visual validation of the hover, launch,
menu, launch timeout, and multi-monitor behavior remains attended work. Dock
styling is intentionally deferred until this interaction pass is accepted.

## XMB Launcher Rail Pass

The focused-monitor XMB launcher now uses two explicit rails rather than a
standard scrolling list:

- The category rail uses repeated category sequences and a fixed focused
  position. Cyclic navigation moves one normal slot in either direction instead
  of flying across the viewport at the wrap boundary.
- The application rail positions entries relative to the selected entry. The
  selected application remains at the top of the result viewport, while dense
  neighboring entries move through the same slot distance.
- Up and down selection uses directional entrance motion. Moving up brings the
  new entry down from above; moving down brings it up from below. Cyclic app
  wrapping follows the same relative movement as ordinary navigation.
- The selected category icon is the master horizontal axis. The search icon
  and every application icon share its centerline, and result text begins at a
  fixed distance from each icon.
- Category icons are large and category labels use one shared compact font size
  constrained to the icon width. Selected and neighboring entries use
  progressive opacity and blur.
- The launcher has a fixed non-fullscreen size with an internal bottom safe
  zone. It does not resize based on category or result count.
- Search uses the same icon/text treatment as the selected application entry.
- A right-click application menu provides `Pin to Dock` and `Edit Desktop File`.
  Pinning reuses the atomic dock persistence path. Desktop files are resolved by
  `.local/bin/orbit-edit-desktop` and opened through the system default editor
  association.
- The Settings control uses the shared symbolic icon/color treatment, including
  the System category icon.

The selected application entrance now uses an alpha mask at the top of the
result viewport rather than a colored overlay, preventing a visible gradient
artifact while the entry moves into place.

Current evidence:

- `tests/orbit/run-all`: PASS.
- `tests/orbit/run-all --live`: PASS.
- `git diff --check`: PASS.
- Active QuickShell reloads: PASS.
- Visual captures include `/tmp/opencode/orbit-xmb-circular-soft-edge.png` and
  `/tmp/opencode/orbit-xmb-selected-entrance.png`.

The following remain attended validation items rather than completion claims:

- Rapid left/right category movement, category wrap, rapid up/down movement, and
  application wrap should be observed in the live session.
- Right-click pinning and desktop-file editing should be tested with an actual
  application; the editor path should resolve to Zen through the session default.
- Two-monitor focus ownership, animation usability, and final visual balance
  remain part of `UI-002` and `UI-003` manual validation.

## Open Design Questions

- Which application classifications should be exposed in the editor?
- Which standard window attributes should be configurable without Lua?
- How should side-by-side applications differ from dedicated applications?
- How should conflicting desktop-entry and observed classes be presented?
- Should wallpaper support PS3 waves, recoloring, shaders, and derived palettes?
- Should SDDM replace the current session manager?

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
rendering, confirmed monitor profile reload, generated palette adapters, and
 the PS3 wallpaper reveal/restart path.

These observations remain useful history but must be reproduced through the
test matrix before being used as current phase-completion evidence.

## GNOME-Inspired UI Overhaul

The first UI overhaul pass is implemented without changing the palette source,
settings schema, backend actions, workspace routing, or shell IPC contracts.

### Implemented Foundation

- `Theme.qml` now owns shared UI typography and geometry tokens. JetBrains Mono
  remains the current interface font, while `uiFont` and `technicalFont` are
  separate update points for the planned system-wide font split.
- Orbit-owned QuickShell controls now cover buttons, icon buttons, text fields,
  text areas, checkboxes, combo boxes, sliders, and spin boxes.
- `orbit-shell` explicitly sets `QT_QUICK_CONTROLS_STYLE=Basic` as the
  deterministic fallback for controls not yet replaced by an Orbit component.
  `QT_STYLE_OVERRIDE=Breeze` remains the Qt Widgets setting and does not style
  Qt Quick Controls.
- Settings navigation now renders configured menu icons, uses a quieter
  GNOME-style selection treatment, and uses Orbit controls for its action and
  form surfaces.
- Diagnostics now provides a `Reload Orbit` action that restarts only the
  `orbit-shell.service` user service.
- Dock, XMB, and overview surfaces use the shared spacing, radius, focus,
  selection, and typography direction. Existing monitor ownership, keyboard
  handling, launch behavior, MRU behavior, and application deduplication are
  unchanged.

### Evidence

- `tests/orbit/run-all`: PASS, 9 contract tests.
- `tests/orbit/run-all --live`: PASS, including live Hyprland, Orbit settings,
  and service checks.
- `git diff --check`: PASS.
- Active QuickShell reload after the component migration: PASS.
- Attended screenshots captured for Settings and XMB at:
  `/tmp/opencode/orbit-settings.png` and `/tmp/opencode/orbit-xmb.png`.

## Icon Theme Alignment

GTK3 and GTK4 already select the scalable Kora theme from
`~/.local/share/icons/kora`. Qt had been split from GTK by explicitly selecting
`breeze-dark` in `hyprqt6engine.conf`, while `kdeglobals` still referenced the
stale `YAMIS` theme. Qt6ct, hyprqt6engine, KDE configuration, and the
ProtonUp-Qt Flatpak helper now all select Kora. Orbit symbolic controls use the
Qt icon resolver rather than shipping a separate icon asset.

Existing Qt applications need to be restarted after this configuration change;
the session platform environment is established when the application starts.

### Remaining UI Work

- Split the 1,900-line Settings implementation into page components while
  preserving the current dirty-worktree changes.
- Replace remaining literal text controls and technical labels with symbolic
  icons and accessible labels where appropriate.
- Validate every Settings page, modal, and system action in an attended pass.
- Run the full GTK4, Breeze Qt, Flatpak, terminal, editor, and QuickShell
  visual/runtime matrix.
- Run the overnight soak after the page split and record its result here.

## Settings Page Review And Flow

The enabled Settings pages were reviewed against the current implementation and
reorganized without removing any exposed setting:

| Group | Pages | Review result |
| --- | --- | --- |
| Personalization | Appearance, Shell, Wallpaper | Appearance retains its Colours, Styles, Transparency, and Effects sections. Shell retains XMB behavior. Wallpaper now reports the active shader/source mode instead of falling through to an unavailable-module message. |
| Hardware | Displays, Audio, Network, Bluetooth | Displays retains topology editing, monitor roles, mode, refresh, VRR, and staged changes. Audio retains devices, defaults, volume, mute, and streams. Network retains profile editing, Wi-Fi scan/connect, IPv4, IPv6, proxy, and immediate actions. Bluetooth retains adapter, discovery, pairing, trust, block, connect, and removal controls. |
| System | Windows and Applications, Power, Diagnostics | Applications retains rule creation, matching, editing, aliases, and delete confirmation. Power retains TuneD and staged Hypridle controls. Diagnostics retains capability status and Reload Orbit. |

Navigation now uses the groups `Personalization`, `Hardware`, and `System`,
with a consistent page description in the header. Nested flows remain explicit:
Appearance uses section navigation, Network uses profile and protocol
navigation, and Applications uses rule selection plus an editor. No backend
binding or settings action was removed.

Validation after the flow redesign:

- `tests/orbit/run-all`: PASS.
- `tests/orbit/run-all --live`: PASS.
- Active QuickShell reload: PASS.
- Grouped Settings screenshot: `/tmp/opencode/orbit-settings-grouped.png`.

The Appearance > Colours palette selector is now a compact responsive card grid
with four swatches, a selected outline, and a selected check indicator rather
than a full-width row. Catppuccin Mocha, Nord, and Gruvbox Dark were added as
schema-valid test palettes alongside Tokyo Night. The palette generator lists
and validates all four palettes; `gruvbox-dark` remains the active generated
runtime palette. Cross-toolkit propagation is still a follow-up test item.

## Audio Page Review

Audio was reworked into a device-oriented control panel. Output and Input are
separate sections with one compact card per PipeWire device. Each card presents
the device name, a checked `Default` checkbox, volume slider, percentage, and
mute/unmute action. Redundant availability/default metadata and the repeated
Audio page heading were removed. The checkbox remains an immediate PipeWire
default-device action, not a staged setting.

Active streams now occupy a separate status card with application names and a
clear empty state. The existing immediate `wpctl` actions and snapshot schema
are unchanged. The current session was used as a layout fixture: five output
devices, two input devices, and three active streams.

The shared checkbox primitive was also corrected to reserve explicit indicator
space before its label, preventing checkbox text overlap across all Settings
pages.

## Theme Runtime And Wallpaper Recovery

Orbit theme loading now follows `[theme].palette` in `settings.toml` instead of
being fixed to the Tokyo Night QuickShell artifact. Shared Orbit controls also
load the selected generated palette when a page does not explicitly pass a
theme object, preventing blue Tokyo Night controls from appearing inside a
Gruvbox surface.

`orbit-theme apply <palette>` now installs the generated GTK3/GTK4 adapter CSS
into the active `noctalia.css` imports and regenerates the shared KDE color
scheme used by Qt. Appearance Apply uses this adapter-installing path rather
than only generating inactive artifacts. Existing GTK and Qt applications may
still require restart or toolkit reload to pick up the new values.

The Wallpaper page now polls `ps3-wave-wallpaper.service`, displays its state,
and provides a Start/Restart service button. The action only restarts the PS3
wallpaper user service.

Validation:

- Active palette: `gruvbox-dark`.
- GTK and KDE adapters regenerated and installed.
- `tests/orbit/run-all`: PASS.
- `tests/orbit/run-all --live`: PASS.
- PS3 wallpaper service: `active`.

## PS3 Wallpaper Investigation

The wallpaper service was running and its `ps3-wave-wallpaper` background layer
was present on the active HDMI monitor. The incorrect black/hidden state was
caused by the service intentionally starting with `PS3_WAVE_START_HIDDEN=1`
while the one-shot `wallpaper-session-effects.service` was inactive after a
manual service restart. Sending the existing `intro` control request restored
the rendered wallpaper immediately.

The Wallpaper Settings restart action now waits for the service restart to
finish and then sends `wallpaper-animation intro`, so a manual recovery no
longer leaves the renderer hidden. The service unit also uses a five-second
stop timeout and `SIGKILL` final signal. The renderer previously blocked in
`eglSwapBuffers` during SIGTERM cleanup for approximately 45 seconds and was
then aborted by systemd; the shorter bounded stop prevents that stale process
from delaying recovery.

The current session has only `HDMI-A-1` connected to Hyprland. `DP-1` is
configured inactive in Orbit settings and therefore correctly has no wallpaper
layer; this is separate from the renderer issue.
