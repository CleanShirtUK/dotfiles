---
title: Orbit - Issues and Corrections
type: issue-tracker
tags: [orbit, issues]
---

# Issues And Corrections

Use one entry per issue. Do not bury unresolved defects in status prose.

### ORB-APP-CLOSE-DISPATCH Application close actions used obsolete Hyprland dispatch syntax
- Status: Closed
- Severity: Medium
- Area: shell / routing
- Classification: Bug
- Reproduction:
  1. Open an application action menu from the dock or top panel.
  2. Select `Close` / `Close window`.
- Expected: The selected application window closes.
- Actual: The action returned a Hyprland dispatch parser error on Hyprland 0.56.1 and left the window open; force quit still worked.
- Evidence: Disposable WezTerm fixture; legacy `hyprctl dispatch closewindow address:<address>` failed, while focusing the target with `hl.dsp.focus({ window = "address:<address>" })` followed by `hl.dsp.window.close()` closed it.
- Suspected cause: Hyprland 0.56.1 routes `dispatch` through its Lua dispatcher API.
- Fix: Focus the selected client with the version-current Lua dispatcher, then close the focused window, in both dock and top-panel close paths.
- Validation: Disposable close fixture passed. Contract 35/35 (`2026-08-17T17-15-47Z-596641`), live 38/39 (`2026-08-17T17-15-51Z-597112`, unrelated `START-004` Alt+Tab failure), and one-minute soak 11/11 (`soak-2026-08-17T17-15-54Z-597644`) passed. No unrelated window or session state changed.

### ORB-SETTINGS-ACTIONS-BOUNDARY Settings CLI owned mutating runtime actions
- Status: Closed
- Severity: Medium
- Area: settings / hardware
- Classification: Refactor
- Reproduction:
  1. Inspect `.local/bin/orbit-settings` for transient audio, network, Bluetooth, power, and hypridle commands.
  2. Observe those mutations mixed with persistence, validation, artifact generation, and snapshot observation.
- Expected: Mutating runtime actions have one narrow owner while the CLI preserves its public action command and validation semantics.
- Actual: The CLI directly owned mutating runtime command construction and execution.
- Evidence: Source inspection before this worker session; action commands were embedded in `run_system_action` and `write_hypridle`.
- Suspected cause: Settings features accumulated in one executable as the settings surface expanded.
- Fix: Added `.local/lib/orbit_settings_actions.py`; the CLI delegates through compatibility wrappers. The module supports injected runners for deterministic validation, while real device actions remain owned by desktop tools.
- Validation: Python compilation passed; `SET-010` contract passed 35/35, live passed 38/39 with unrelated `START-004` binding failure, and one-minute soak passed 10/10. No real display, audio, network, Bluetooth, or session mutation was performed. No manual gate applies.

### ORB-SETTINGS-VALIDATION-BOUNDARY Settings CLI owned validation rules
- Status: Closed
- Severity: Low
- Area: settings
- Classification: Refactor
- Reproduction:
  1. Inspect `.local/bin/orbit-settings` for application-policy, appearance, and display-profile validation.
  2. Observe those rejection rules mixed with persistence, artifact generation, and runtime adapter responsibilities.
- Expected: Settings validation has one narrow owner while the CLI preserves its command surface and rejection behavior.
- Actual: Validation rules were embedded in the CLI update functions.
- Evidence: Source inspection before this worker session; policy, appearance, and display-profile checks were defined in `.local/bin/orbit-settings`.
- Suspected cause: Settings features accumulated in one executable as the settings surface expanded.
- Fix: Added `.local/lib/orbit_settings_validation.py` and delegated validation from the CLI without changing error semantics or generated formats.
- Validation: `python -m py_compile` passed; contract 32/32 (`2026-08-17T16-33-23Z-302845`), live 36/36 (`2026-08-17T16-33-28Z-303410`), and one-minute soak 10/10 (`soak-2026-08-17T16-33-28Z-303422`) passed. No display, audio, network, Bluetooth, or session mutation was performed. Runtime-adapter extraction remains separate backlog work.

### ORB-SETTINGS-RUNTIME-OBSERVATION Settings CLI owned read-only runtime snapshot adapters
- Status: Closed
- Severity: Low
- Area: settings
- Classification: Refactor
- Reproduction:
  1. Inspect `.local/bin/orbit-settings` for audio, network, Bluetooth, and power snapshot parsing.
  2. Observe those read-only runtime adapters mixed with settings persistence, validation, artifact generation, and compatibility command handling.
- Expected: Read-only runtime observation has one narrow owner while the CLI preserves its snapshot command and output shape.
- Actual: The CLI directly owned all runtime snapshot parsing and command probing.
- Evidence: Source inspection before this worker session; `system_snapshot()` and its device parsers were defined in `.local/bin/orbit-settings`.
- Suspected cause: Settings features accumulated in one executable as the system snapshot expanded.
- Fix: Added `.local/lib/orbit_settings_runtime.py` for read-only audio, network, Bluetooth, and power observation. The CLI delegates through a compatibility wrapper and retains the hypridle projection and mutating action boundary.
- Validation: `python -m py_compile` passed; contract 32/32 (`2026-08-17T16-44-01Z-374527`), live 36/36 (`2026-08-17T16-44-04Z-374955`), and one-minute soak 11/11 (`soak-2026-08-17T16-44-12Z-375938`) passed. No display, audio, network, Bluetooth, or session mutation was performed. Mutating runtime actions remain explicitly separate work.

### ORB-SETTINGS-PERSISTENCE-BOUNDARY Settings CLI owned shared persistence primitives
- Status: Closed
- Severity: Low
- Area: settings
- Classification: Refactor
- Reproduction:
  1. Inspect `.local/bin/orbit-settings` for atomic file replacement, TOML/JSON loading, and TOML serialization helpers.
  2. Observe those generic persistence mechanics mixed with settings read models, validation, artifact generation, and runtime adapters.
- Expected: Generic settings persistence has one narrow owner while the CLI preserves its existing command and compatibility boundaries.
- Actual: The CLI directly owned the shared atomic-write and config serialization primitives.
- Evidence: Source inspection before this worker session; `atomic_write`, `read_toml`, `read_json`, and `toml_value` were defined in `.local/bin/orbit-settings`.
- Suspected cause: Settings features accumulated in one executable as the settings surface expanded.
- Fix: Added `.local/lib/orbit_settings_persistence.py` and imported its primitives into the CLI without changing the public command surface or file formats.
- Validation: `python -m py_compile` passed; contract 31/31 (`2026-08-17T16-28-50Z-272290`), live 35/35 (`2026-08-17T16-28-54Z-272765`), and one-minute soak 10/10 (`soak-2026-08-17T16-28-54Z-272766`) passed. No display, audio, network, Bluetooth, or session mutation was performed. Validation and runtime-adapter extraction remain separate backlog work.

### ORB-SETTINGS-PYTHON-BOUNDARIES Settings artifact generation was coupled to the CLI adapter
- Status: Closed
- Severity: Low
- Area: settings
- Classification: Refactor
- Reproduction:
  1. Inspect `.local/bin/orbit-settings` and compare persistence, validation, artifact generation, and runtime adapter responsibilities.
  2. Observe that generated Hyprland and appearance artifacts were assembled directly inside the CLI adapter.
- Expected: Artifact serialization has one narrow owner while the CLI preserves its existing command and compatibility boundaries.
- Actual: Artifact writers were embedded in the settings CLI and shared its mutable runtime context.
- Evidence: Source inspection before this worker session; `write_window_rules`, `write_monitors_lua`, and `write_appearance_artifacts` were defined in `.local/bin/orbit-settings`.
- Suspected cause: Settings features accumulated in one executable without a generation module boundary.
- Fix: Added `.local/lib/orbit_settings_artifacts.py` for atomic window-rule, monitor, and appearance artifact generation. The CLI delegates through compatibility wrappers and retains validation, persistence, and runtime adapter ownership for later bounded workers.
- Validation: `python -m py_compile` passed; contract 31/31 (`2026-08-17T16-24-50Z-244811`), live 35/35 (`2026-08-17T16-24-53Z-245194`), and one-minute soak 11/11 (`soak-2026-08-17T16-25-01Z-246161`) passed. No display, audio, network, Bluetooth, or session mutation was performed.

### ORB-SETTINGS-MODEL-BOUNDARIES SettingsModel owned unrelated settings state
- Status: Closed
- Severity: Medium
- Area: settings / shell
- Classification: Refactor
- Reproduction:
  1. Inspect `SettingsModel.qml` and compare draft editing, application matching, and system-action process ownership.
  2. Observe that system actions were implemented directly beside settings draft and matching state.
- Expected: Settings state is split into narrow ownership boundaries without changing the public `settingsData` API or action refresh behavior.
- Actual: The monolithic model owned all three concerns in one QML item.
- Evidence: Source inspection of `.config/quickshell/orbit/SettingsModel.qml` before this worker session; the model was 677 lines and directly owned `systemActionProcess`.
- Suspected cause: Settings features accumulated in one model as separate pages were added.
- Fix: Extracted system-action execution into `SettingsSystemActions.qml`, application matching into `SettingsApplicationMatching.qml`, and staged draft/apply/cancel lifecycle into `SettingsDraftLifecycle.qml`; `SettingsModel.qml` retains the compatibility API and delegates each boundary.
- Validation: Contract 30/30 (`2026-08-17T16-13-41Z-163889`), live 34/34 (`2026-08-17T16-13-41Z-163970`), and one-minute soak 10/10 (`soak-2026-08-17T16-13-42Z-163888`) passed. `orbit-shell.service` restarted active and loaded the new QML without new Orbit QML errors; the current compositor signature remained unchanged.

### ORB-APP-POLICY-FORMATS Legacy and modern application policies used separate matching paths
- Status: Closed
- Severity: Medium
- Area: routing
- Classification: Refactor
- Reproduction:
  1. Resolve an application against legacy `[[policy]]` and settings-generated `[[rule]]` entries with equivalent match criteria.
  2. Compare routing fields and precedence.
- Expected: Both schemas use the same matching semantics and return the same routing fields; modern rule priority remains ahead of legacy policies.
- Actual: The resolver had separate matching and result-update paths, so schema-specific behavior could diverge.
- Evidence: Source inspection of `.local/bin/orbit-app-policy`; tracked configuration contains both schemas.
- Suspected cause: The settings-generated rule format was added without normalizing the older policy format at the resolver boundary.
- Fix: Added `normalize_rules()` and one shared matcher for both formats, retaining modern priority ordering and legacy fallback order.
- Validation: Contract `tests/orbit/run-all` passed 30/30 (`2026-08-17T15-58-47Z-49050`), live passed 34/34 (`2026-08-17T15-58-51Z-49525`), one-minute soak passed 10/10 (`soak-2026-08-17T15-58-51Z-49526`), and `python -m py_compile .local/bin/orbit-app-policy` passed.

### ORB-BLANK-WORKSPACE-RESOLUTION Persistent blank workspace only followed one monitor
- Status: Open; implementation complete, attended validation pending
- Severity: Medium
- Area: startup / routing
- Classification: Bug
- Reproduction:
  1. Enter the configured persistent blank-workspace state with both `DP-1` and `HDMI-A-1` connected.
  2. Observe the active workspace on each monitor.
- Expected: Each connected configured monitor enters its role's reserved workspace (`home.workspace` or `gaming.workspace`).
- Actual: The persistent blank workspace was only reliably active on `HDMI-A-1`; the other monitor could retain its normal workspace.
- Evidence: User report on 2026-08-17; `.config/hypr/scripts/blank-special-workspaces` still contained connector-specific workspace selection after the monitor/workspace source refactor.
- Suspected cause: The blanking helper retained its own hard-coded `DP-1 -> 1` / `HDMI-A-1 -> 6` resolver instead of using `orbit-monitor workspace-for-monitor`.
- Fix: Resolve each monitor's blank workspace through the shared Orbit monitor/workspace source and skip outputs with no configured reserved workspace.
- Validation: Contract and live suites passed after the resolver correction; attended two-monitor blank/restore validation remains pending.

### ORB-MONITOR-WORKSPACE-SOURCE Monitor roles and reserved workspaces had separate sources
- Status: Closed
- Severity: Medium
- Area: routing / startup
- Classification: Refactor
- Reproduction:
  1. Inspect `dynamic-app-workspaces` and the Hyprland workspace rules.
  2. Observe that reserved workspaces were selected by a connector-name case statement while monitor roles came from Orbit settings.
- Expected: Monitor role identity and its reserved workspace are resolved from one Orbit configuration source.
- Actual: The dynamic workspace daemon hard-coded `DP-1 -> 1` and `HDMI-A-1 -> 6`, independently of the role resolver.
- Evidence: Source inspection before this session; `orbit-monitor` already owned stable monitor identity resolution.
- Suspected cause: Reserved workspace routing predated the role resolver and retained machine-specific connector literals.
- Fix: Store each role's reserved workspace in `[monitors.<role>]`; add `orbit-monitor workspace-for-monitor`, and route the daemon through it.
- Validation: Contract `tests/orbit/run-all` passed 29/29 (`2026-08-17T15-39-26Z-4101010`); live passed 33/33 (`2026-08-17T15-39-26Z-4101027`); one-minute soak passed 10/10 (`soak-2026-08-17T15-39-26Z-4101028`). Live resolution returned `DP-1=1` and `HDMI-A-1=6`; shell service remained active and the compositor signature was unchanged.

## Template

```markdown
### ORB-YYYYMMDD-01 Short title
- Status: Open
- Severity: High / Medium / Low
- Area: startup / shell / routing / settings / appearance / hardware
- Reproduction:
  1.
- Expected:
- Actual:
- Evidence:
- Suspected cause:
- Fix:
- Validation:
```

## Active Issues

### ORB-RUNTIME-SNAPSHOT-POLLING Core shell models duplicated Hyprland polling
- Status: Closed
- Severity: Medium
- Area: shell / routing
- Classification: Refactor
- Reproduction:
  1. Inspect the core QuickShell models for monitor, client, workspace, and active-workspace state.
  2. Observe that each model starts its own `hyprctl` process and timer.
- Expected: Core shell consumers share one bounded runtime snapshot source.
- Actual: `MonitorModel`, `WindowModel`, and `OverviewModel` independently polled overlapping Hyprland state.
- Evidence: Source inspection before this refactor; no runtime behavior change was intended.
- Suspected cause: Models were introduced independently around separate surface features.
- Fix: Added `HyprlandModel.qml`, which owns one 500 ms refresh boundary for monitors, clients, workspaces, and active workspace; the core models consume its properties.
- Validation: Contract 28/28 (`2026-08-17T15-25-12Z-3994500`), live 32/32 (`2026-08-17T15-25-18Z-3995303`), and one-minute soak 11/11 (`soak-2026-08-17T15-25-21Z-3994937`) passed. `orbit-shell.service` restarted active; the current compositor signature matched `hyprctl instances`, and no new QML errors were logged.

### ORB-RUNTIME-INDEPENDENT-POLLING Settings model duplicated Hyprland client polling
- Status: Closed
- Severity: Low
- Area: shell / settings
- Classification: Refactor
- Reproduction:
  1. Inspect `SettingsModel.qml` while the shared `HyprlandModel.qml` already owns the core client snapshot.
  2. Observe the settings application-match flow starting a second `hyprctl clients -j` process on its timer.
- Expected: Settings consumes the shared client snapshot; only the feature-specific settings helper snapshot remains independently owned.
- Actual: Settings started an independent client poll for application matching, duplicating the core runtime snapshot boundary.
- Evidence: Source inspection before this session; `SettingsModel.qml` contained a dedicated `clientProcess` and `finishClientPoll` path.
- Suspected cause: The application-match flow predated the shared `HyprlandModel.qml` boundary.
- Fix: Pass `HyprlandModel` into `SettingsModel`, update its matching client list from `snapshot.clients`, and retain the existing 400 ms match timer only as a bounded timeout/check cadence.
- Validation: `tests/orbit/run-all` passed 29/29 (`2026-08-17T15-35-34Z-4072076`), live passed 33/33 (`2026-08-17T15-35-34Z-4072141`), and one-minute soak passed 11/11 (`soak-2026-08-17T15-35-35Z-4072075`). After `orbit-shell.service` restart, service was active and `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`.

### ORB-APP-CGROUP-LIFECYCLE Orbit-launched applications were killed by shell restart
- Status: Closed
- Severity: High
- Area: startup / shell / routing
- Classification: Bug
- Reproduction:
  1. Launch WezTerm or Zen from the Orbit dock/XMB.
  2. Restart `orbit-shell.service`.
- Expected: Restarting the shell replaces only Orbit surfaces; launched applications remain open.
- Actual: Applications launched through Orbit inherited `/user.slice/.../app.slice/orbit-shell.service`. Because the service uses `KillMode=control-group`, restarting Orbit killed those application processes. The Hyprland session itself remained alive.
- Evidence: After the reproduced restart, `ps` and `/proc/<pid>/cgroup` showed WezTerm in `app.slice/orbit-shell.service`; the shell journal showed a normal service stop/start with no compositor or session termination. Zen exhibited the same user-visible behavior.
- Suspected cause: `desktop.execute()` and Orbit `Quickshell.execDetached` launch paths inherit the parent service cgroup.
- Fix: Route dock and XMB application command strings through `orbit-app-launch`, which starts each application in an independent `systemd-run --user --scope --collect` scope.
- Validation: `tests/orbit/run-all` passed 20/20. A fresh Zen launch entered `run-p1593565-i35125453.scope` and survived an Orbit restart. A fresh WezTerm launch entered `run-p1610427-i35168122.scope` and survived a second Orbit restart; the Hyprland signature remained unchanged and Orbit reported `NRestarts=0`. `START-007` passed on 2026-08-17. Existing applications launched before this fix may still belong to the old Orbit cgroup and must be relaunched once.

### ORB-SESSION-TERMINATION-GUARD Accidental shutdown shortcut terminated the graphical session
- Status: Open; implementation complete, attended validation pending
- Severity: High
- Area: startup / shell
- Classification: Bug
- Reproduction:
  1. Invoke the `SUPER + M` Hyprland shutdown shortcut.
  2. Observe that `animate-shutdown` immediately runs `loginctl terminate-session` after the wallpaper exit animation.
- Expected: A destructive session termination requires explicit user confirmation.
- Actual: The shortcut could terminate the entire Hyprland session without a confirmation prompt. On 2026-08-17 at 11:29:10, the session scope killed Hyprland and all Wayland clients; Orbit then reported the resulting broken Wayland connection and systemd restarted it.
- Evidence: `journalctl` showed `session-34.scope` killing Hyprland and clients, `obsidian` receiving `SIGTRAP`, and shutdown-script `sleep`/audio processes in the same scope. `.config/hypr/scripts/animate-shutdown` contained the direct `loginctl terminate-session` call.
- Suspected cause: The shutdown keybinding had no confirmation guard, allowing an accidental `SUPER + M` invocation during Orbit testing to end the graphical session.
- Fix: Require a `zenity` confirmation before any shutdown animation or `loginctl terminate-session` call; fail closed when `zenity` is unavailable.
- Validation: `sh -n .config/hypr/scripts/animate-shutdown`, the disposable fake-`zenity`/fake-`loginctl` fixture, and the current worker rerun all pass. Contract 30/30 (`2026-08-17T16-17-04Z-191390`), live 34/34 (`2026-08-17T16-17-04Z-191423`), and one-minute soak 10/10 (`soak-2026-08-17T16-17-05Z-191475`) passed without touching the real session. `zenity` is installed, `orbit-shell.service` is active, and `HYPRLAND_INSTANCE_SIGNATURE` matches `hyprctl instances`. Attended cancel and confirmed shutdown/re-login flows remain to be run; no destructive live action was performed.

- Worker refresh 2026-08-17: syntax and Python compilation passed; contract 34/34 (`2026-08-17T16-59-05Z-480469`) and item-specific live `START-006` passed within 37/38 (`2026-08-17T16-59-08Z-480899`), while unrelated `START-004` failed; one-minute soak passed 10/10 (`soak-2026-08-17T16-59-08Z-480908`). `zenity` is `/usr/bin/zenity`, the service is active, and the compositor signature matches. No real logout or session mutation occurred. The attended cancel and explicitly approved confirm/re-login gate is handed off in `VQ-20260817-13`.
- Worker refresh 2026-08-17 18:20 +01: syntax and Python compilation passed; contract 35/35 (`2026-08-17T17-18-45Z-617766`) and item-specific live `START-006` passed within 38/39 (`2026-08-17T17-18-49Z-618234`), while unrelated `START-004` failed; one-minute soak passed 11/11 (`soak-2026-08-17T17-18-56Z-619246`). Safe cancel and missing-`zenity` fixtures passed without invoking `loginctl`; `/usr/bin/zenity`, active `orbit-shell.service`, and the matching compositor signature were confirmed. No real logout or session mutation occurred. The attended cancel and explicitly approved confirm/re-login gate is handed off in `VQ-20260817-14`.

- Worker refresh 2026-08-17: syntax/Python compilation passed; contract 35/35 (`2026-08-17T17-28-30Z-684233`), live 39/39 (`2026-08-17T17-28-30Z-684296`), and one-minute soak 11/11 (`soak-2026-08-17T17-28-35Z-684232`) passed. `/usr/bin/zenity`, active `orbit-shell.service`, and the matching compositor signature were confirmed. No real logout or session mutation occurred. The attended cancel and explicitly approved confirm/re-login gate is handed off in `VQ-20260817-15`.

### ORB-STARTUP-READINESS-TESTING Duplicate-process and startup readiness coverage gap
- Status: Closed
- Severity: Low
- Area: startup / shell
- Classification: Test gap
- Reproduction:
  1. Inspect the startup contract tests for the Orbit shell launch boundary.
  2. Compare the tested behavior with the shell's duplicate-process and compositor-readiness guards.
- Expected: Contract coverage protects the bounded session-prerequisite wait, fail-closed startup path, and QuickShell duplicate-instance guard.
- Actual: The implementation had these protections, but no dedicated test asserted them.
- Evidence: `.local/bin/orbit-shell` contains the 30-attempt readiness loop and `phleg-quickshell --no-duplicate`; prior contract coverage did not identify either guarantee.
- Suspected cause: Startup lifecycle tests focused on Hyprland configuration and service presence, not the shell executable's launch boundary.
- Fix: Added `START-008` deterministic contract coverage for the readiness loop, missing-environment failure, and `--no-duplicate` invocation.
- Validation: Contract 27/27 (`2026-08-17T15-12-08Z-3873183`), live 31/31 (`2026-08-17T15-12-08Z-3873248`), and one-minute soak 11/11 (`soak-2026-08-17T15-12-13Z-3873178`) passed after adding `START-008`. No runtime behavior was changed.

### ORB-DOCK-ICON-STARTUP Dock icons can be blank after login
- Status: Closed
- Severity: Medium
- Area: startup / shell
- Classification: Bug
- Reproduction:
  1. Log into a new Hyprland session.
  2. Observe the dock before interacting with it.
- Expected: Dock icons are populated when the dock appears.
- Actual: The dock can appear at the correct dimensions while its icons are blank.
- Evidence: `OBS-20260816-03`, `Pasted image 20260816234028.png`.
- Suspected cause: Desktop-entry/icon loading is not ready or is not reconciled after shell startup.
- Fix: Add a bounded startup reconciliation pass in `ApplicationModel.qml` that re-evaluates desktop entries and icon paths for up to 10 seconds, without changing dock persistence or launch semantics. Synthetic Orbit entries are excluded from readiness checks.
- Validation: `tests/orbit/run-all` passed 16/16 and `tests/orbit/run-all --live` passed 20/20 on 2026-08-17. `orbit-shell.service` restarted and loaded the updated QML without a new QML error. Attended confirmation on 2026-08-17 verified that dock icons populate correctly; `START-005` passed.

### ORB-DOCK-SETTINGS-ICON Settings dock entry has no standard icon
- Status: Open; implementation complete, attended validation pending
- Severity: Low
- Area: shell / appearance
- Classification: Bug
- Reproduction:
  1. Observe the Orbit Settings entry in the dock.
- Expected: The entry displays the standard settings icon.
- Actual: The settings dock entry has no configured/resolved icon.
- Evidence: `OBS-20260816-02`, `Pasted image 20260816224737.png`.
- Suspected cause: The synthetic `orbit-settings` desktop identity has no icon adapter or fallback.
- Fix: `ApplicationModel.qml` now resolves the synthetic `orbit-settings` entry to the standard `settings-symbolic` icon without changing desktop-entry lookup for normal applications.
- Validation: Contract `tests/orbit/run-all` passed 26/26 (`2026-08-17T15-07-52Z-3836324`); live checks passed 30/30 (`2026-08-17T15-07-54Z-3836727`) and the one-minute soak passed 11/11 (`soak-2026-08-17T15-07-57Z-3837506`). `orbit-shell.service` restarted active with the current compositor signature. Attended dock inspection remains queued as `VQ-20260817-05`.

### ORB-TOP-PANEL-TRAY-ALIASES Top-panel tray aliases have no persistence contract
- Status: Open
- Severity: Low
- Area: shell / appearance
- Classification: Feature / behavior clarification
- Reproduction:
  1. Inspect the Orbit top-panel tray implementation.
  2. Attempt to replace a native tray icon with a user-selected nerd-font glyph.
- Expected: Users can persist a per-tray-item glyph override while retaining native tray activation and menus.
- Actual: The first-pass top panel renders native StatusNotifier icons and has no override schema.
- Evidence: `DES-20260817-02`, `UI-010`, and the 2026-08-17 top-panel visual log entry.
- Suspected cause: The feature request does not define stable tray identity, configuration location, fallback rules, or editor/apply behavior.
- Fix: Define the alias schema and persistence/apply contract before adding user overrides.
- Validation: Add deterministic schema coverage and an attended tray alias edit/reload pass.

### ORB-TOP-PANEL-GLOBAL-MENU Global application-menu protocol source is not exposed by current window snapshots
- Status: Open
- Severity: Medium
- Area: shell / routing
- Classification: Integration blocker
- Reproduction:
  1. Inspect `hyprctl clients -j` for a running application.
  2. Look for a DBusMenu service/path or registrar address that Orbit can bind to.
- Expected: Each panel always displays the current application name. Clicking it opens the application menu when protocol data exists, otherwise provides `Close window` and `Force quit application` actions.
- Actual: Orbit now selects independently per panel: focused monitor uses its current-workspace focus history and the other monitor retains its last-focused client for its current workspace. The fallback actions operate on the selected client address/PID. The current `WindowModel.qml` snapshot still exposes no menu handle or registrar address, so native Wayland protocol menus remain unavailable.
- Evidence: `ApplicationMenuModel.qml`, `WindowModel.qml`, and QuickShell DBusMenu documentation reviewed 2026-08-17.
- Suspected cause: The appmenu registrar/window association is not part of the current Hyprland client snapshot or Orbit integration boundary. A separate implementation bug compared numeric Hyprland monitor IDs with monitor names, leaving the application candidate empty; that mapping is now corrected.
- Fix: Keep per-monitor selection in `ApplicationMenuModel.qml`. Use a real menu handle when available; otherwise expose per-window close and per-process force-quit actions. The XWayland DBusMenu bridge now covers registered X11 windows. For native Wayland, evaluate Heaven as an existing client/bar/compositor library before creating Orbit-specific protocol code; do not treat its D-Bus menu transport as a compositor or application integration by itself.
- Validation: Numeric monitor-ID mapping correction validated by QuickShell restart and current clients (`monitor: 0/1`) alongside monitor names (`DP-1`/`HDMI-A-1`). `tests/orbit/run-all` passed 20/20 and `tests/orbit/run-all --live` passed 24/24 on 2026-08-17 at 12:04 UTC. `appmenu-qt5`, `appmenu-qt5-profile.d`, `dbusmenu-qt5`, and `libdbusmenu-tools` were subsequently installed. The existing `Simple-Appmenu-Server` tooling was cloned at commit `bb5f40fbe35fd18ddde7a0b97d89d76619bef995`, built with `xxd` plus GLib/GIO development tooling, and exposed `com.canonical.AppMenu.Registrar`; a manual `RegisterWindow`/`GetMenuForWindow` round trip succeeded for the running `org.dbusmenu.test` fixture at `/MenuBar`. Qt5 Designer is the qualifying application fixture: launched with `QT_QPA_PLATFORM=xcb QT_QPA_PLATFORMTHEME=appmenu-qt5`, it created native XWayland windows (`0x40000c` and `0x400019`), and the registrar logged `XWindow 4194316: register`; `GetMenuForWindow 4194316` returned service `:1.535134` and `/MenuBar/1`. Orbit UI activation remains unintegrated. The Fedora package documentation warns that globally enabling the Qt5 platform can hide Qt5 menubars outside Plasma/KDE.
- Validation: Numeric monitor-ID mapping correction validated by QuickShell restart and current clients (`monitor: 0/1`) alongside monitor names (`DP-1`/`HDMI-A-1`). `tests/orbit/run-all` passed 20/20 and `tests/orbit/run-all --live` passed 24/24 on 2026-08-17 at 12:04 UTC. `appmenu-qt5`, `appmenu-qt5-profile.d`, `dbusmenu-qt5`, and `libdbusmenu-tools` were subsequently installed. The existing `Simple-Appmenu-Server` tooling was cloned at commit `bb5f40fbe35fd18ddde7a0b97d89d76619bef995`, built with `xxd` plus GLib/GIO development tooling, and exposed `com.canonical.AppMenu.Registrar`; a manual `RegisterWindow`/`GetMenuForWindow` round trip succeeded for the running `org.dbusmenu.test` fixture at `/MenuBar`. Qt5 Designer is the qualifying application fixture: launched with `QT_QPA_PLATFORM=xcb QT_QPA_PLATFORMTHEME=appmenu-qt5`, it created native XWayland windows (`0x40000c` and `0x400019`), and the registrar logged `XWindow 4194316: register`; `GetMenuForWindow 4194316` returned service `:1.535134` and `/MenuBar/1`. The new `orbit-appmenu` lookup returned the real window, registrar association, and seven top-level menu entries. The attended Orbit popup and `File > New...` activation passed on 2026-08-17. The bridge is validated for this XWayland Qt5 fixture; native Wayland applications remain outside its scope. Heaven was reviewed at commit `a8f5027108efdec33dfcf86d3c1637184d3d55aa`: it provides client/bar/compositor C++ libraries over D-Bus, but requires application-side Heaven client integration and a compositor-side private Wayland-handle protocol that the repository does not provide. Native Wayland support therefore remains a design/integration item, not an install-only fix. `yolo-labz/noctalia-appmenu` was then identified as the stronger existing implementation: its active v1.0 release-candidate bridge uses AT-SPI to support Qt6 and GTK4 native Wayland applications, with documented Electron accessibility flags and a QML plugin; its current focus backend is niri-only, so Hyprland adaptation is still required. The Fedora package documentation warns that globally enabling the Qt5 platform can hide Qt5 menubars outside Plasma/KDE.
- Additional correction: Protocol menus are now opened through QuickShell `QsMenuAnchor` with bottom-left anchoring and `PopupAdjustment.All`, rather than using the 42px panel as the popup surface.
- Native Wayland correction: `orbit-appmenu-atspi` now supplies the native path for Hyprland clients that register AT-SPI menus. Native Qt6 Designer rendering and `File > New...` activation passed on 2026-08-17. This does not yet establish GTK4 or Electron coverage.
- Current correction: remembered per-monitor selections are matched against the current client address before reuse, preventing stale titles or actions after a window closes or moves. The panel availability state now also reflects DBusMenu and AT-SPI sources, not only QuickShell-native menu handles. Contract and live suites passed 22/22 and 26/26 on 2026-08-17 at 13:35 UTC; attended two-monitor and destructive fallback validation remain open.

### ORB-APP-FOCUS-RACE Application launch can follow a later focused monitor
- Status: Open; implementation complete, attended validation pending
- Severity: Medium
- Area: routing
- Classification: Bug
- Reproduction:
  1. Launch an application from the dock while focused on `HDMI-A-1`.
  2. Move the pointer/focus to `DP-1` before the application window appears.
- Expected: The application opens on the monitor that was focused when launch started.
- Actual: The application can spawn on the later-focused `DP-1` monitor.
- Evidence: `OBS-20260817-01`.
- Suspected cause: Launch routing resolves the focused monitor at window creation instead of preserving launch context.
- Fix: Capture the focused monitor and active workspace at launch time. `orbit-app-launch` snapshots existing clients, starts the application in its independent user scope, then moves the newly mapped matching client to the captured workspace; dock and XMB launches pass the context and expected startup class without changing unrelated routing policy.
- Validation: `tests/orbit/run-all` passed 25/25 (`2026-08-17T14-58-44Z-3762377`), the service restarted cleanly, `tests/orbit/run-all --live` passed 29/29 (`2026-08-17T15-00-42Z-3779691`), and the one-minute soak passed 11/11 (`soak-2026-08-17T14-58-50Z-3763514`). A controlled delayed-start fixture with focus movement remains the attended `APP-007` gate in `VQ-20260817-03`.

### ORB-APP-LAUNCH-BOUNDARY Dock and XMB launches used separate execution paths
- Status: Open; implementation complete, attended validation pending
- Severity: Medium
- Area: shell / routing
- Classification: Refactor
- Reproduction:
  1. Inspect the dock application's launch path and the XMB application's launch path.
  2. Compare their process scope, launch context, and application identity observation.
- Expected: Both surfaces use one launch boundary for independent service scopes, captured monitor/workspace context, Desktop Entry normalization, and launch identity observation.
- Actual: The prior paths called desktop-entry execution directly from QML, so scope, context capture, and identity observation were not shared.
- Evidence: Current `ApplicationModel.qml` and `XmbModel.qml` both invoke `.local/bin/orbit-app-launch` and `.local/bin/orbit-app-observe`; deterministic contract coverage asserts the shared boundary.
- Suspected cause: Dock and XMB were implemented as separate surface features with duplicated launch calls.
- Fix: Route both surfaces through `orbit-app-launch` and record the desktop identity through `orbit-app-observe`; retain the existing direct helper boundary for new-window launches.
- Validation: Contract 29/29 (`2026-08-17T15-32-16Z-4048673`), live 33/33 (`2026-08-17T15-32-17Z-4048738`), and one-minute soak 11/11 (`soak-2026-08-17T15-32-21Z-4048672`) passed on 2026-08-17. Attended disposable launches from both surfaces remain queued as `APP-009`.

### ORB-APP-CONCURRENT-CORRELATION Concurrent same-application launches could consume the wrong identity record
- Status: Open; implementation complete, attended validation pending
- Severity: Medium
- Area: routing / shell
- Classification: Bug
- Reproduction:
  1. Start two launches of the same desktop entry before either window maps.
  2. Observe the launch records consumed by `orbit-app-observe match`.
- Expected: Each mapped client is correlated with the launch that created it, including its launch ID, PID, and Hyprland address.
- Actual: The observer previously consumed the newest pending record, so concurrent same-app launches could attach the later client's class/title observation to the wrong desktop launch.
- Evidence: Source inspection of `.local/bin/orbit-app-observe`; pending records had no unique ID and `match_window` always selected `usable[-1]`. Final evidence: contract/live/soak runs `4171928` / `4171926` / `4173026` all passed; launch IDs are inherited through `/proc/<pid>/environ`.
- Suspected cause: Launch recording and client matching were separate asynchronous operations without a shared correlation token.
- Fix: Dock and XMB generate a unique launch ID; the observer stores it, `orbit-app-launch` carries it through the map wait and application environment, and the exact record is consumed with mapped client address/PID/class/title.
- Validation: Contract `tests/orbit/run-all` passed 30/30 (`2026-08-17T15-45-08Z-4147520`); a disposable two-record fixture matched `launch-a` while retaining `launch-b`; live passed 34/34 (`2026-08-17T15-45-20Z-4149043`); one-minute soak passed 11/11 (`soak-2026-08-17T15-45-27Z-4150028`). `orbit-shell.service` restarted active with the current Hyprland signature and no new QML errors. Attended concurrent same-app launch validation remains queued as `VQ-20260817-08`.

### ORB-XMB-DOCK-FOCUS Dock-launched XMB does not receive keyboard focus
- Status: Open; implementation complete, attended validation pending
- Severity: High
- Area: shell
- Classification: Bug
- Reproduction:
  1. Open the XMB using the dock launcher entry.
  2. Type or use keyboard navigation before clicking the surface.
  3. Compare with opening the XMB using its keybind.
- Expected: The dock-launched XMB receives exclusive keyboard focus after the morph handoff, just like the keybind-launched XMB.
- Actual: The dock-launched XMB opens but ignores keyboard input; the keybind path focuses correctly.
- Evidence: `OBS-20260817-04`, `/home/josh/Videos/ScreenCap/recordings/Video_2026-08-17_12-22-22.mp4`.
- Suspected cause: `WlrLayershell.keyboardFocus` was gated by `!dockMorphing`, but the dock handoff only set `dockHandoff` and left `dockMorphing` true indefinitely.
- Fix: Release `dockMorphing` at the completed handoff so the existing exclusive-focus guard becomes true without changing the keybind path.
- Validation: Contract 28/28 (`2026-08-17T15-21-01Z-3954782`), live 32/32 (`2026-08-17T15-21-01Z-3954791`), and one-minute soak 10/10 (`soak-2026-08-17T15-21-01Z-3954801`) passed after the shell reload. Attended dock-open keyboard navigation and Escape recovery remain queued as `VQ-20260817-06`.

### ORB-DOCK-MAGNIFICATION-EDGE Dock boundary entry jumps to maximum magnification
- Status: Open
- Severity: Low
- Area: shell / appearance
- Classification: Bug
- Reproduction:
  1. Move the pointer slowly from either side of the dock into its focus area.
  2. Compare the boundary entry with pointer movement between dock icons.
- Expected: Magnification increases continuously from the boundary using the same interpolation as navigation within the dock.
- Actual: Entering the dock focus area jumps immediately to the highest magnification.
- Evidence: `OBS-20260817-02` (source heading `OBS-20260817-01`), `Video_2026-08-17_10-27-45.mp4`.
- Suspected cause: Boundary hover handling uses a discontinuous initial hover value or threshold rather than the same pointer-distance mapping used by icon navigation.
- Fix: Unify boundary entry and in-dock magnification calculations without changing dock geometry or launch behavior.
- Validation: Contract 32/32 (`2026-08-17T16-37-50Z-333107`), live 36/36 after shell restart (`2026-08-17T16-39-49Z-347788`), and one-minute soak 11/11 (`soak-2026-08-17T16-37-56Z-334022`) pass. `dockContent.hoverAmount` now uses a 140 ms `OutCubic` animation, so boundary entry and exit ramp through the same `scaleAt()` calculation as in-dock movement. Attended slow entry from both sides on each connected monitor remains queued as `VQ-20260817-10`.

### ORB-APP-EXEC-FIELDS Desktop-entry launch passes field codes as literal arguments
- Status: Open; implementation complete, attended validation pending
- Severity: Medium
- Area: shell / routing
- Classification: Bug
- Reproduction:
  1. Launch Nautilus or Zen from the Orbit dock or XMB.
  2. Observe the application error referring to `/home/josh/%U`.
- Expected: Desktop-entry field codes are expanded or removed according to the launch context; launching without files does not pass `%U` as a path.
- Actual: Orbit passed `DesktopEntry.execString` verbatim to `/bin/sh -lc`, so `%U` reached applications as a literal path.
- Evidence: `OBS-20260817-10` in [[Orbit - Session Scratchpad]].
- Suspected cause: QuickShell's `execString` retains Desktop Entry field codes and Orbit supplied no file/URI arguments.
- Fix: Normalize Desktop Entry field codes at the shared `orbit-app-launch` boundary, removing unsupported no-file substitutions and preserving `%%`.
- Validation: Contract fixture confirms `nautilus --new-window %U` reaches the runner without `%U`; live application relaunch and attended error-popup confirmation remain pending.

### ORB-SETTINGS-KEYBINDS Editable keybind behavior lacks an acceptance and persistence contract
- Status: Open
- Severity: Low
- Area: settings
- Classification: Feature / behavior clarification
- Reproduction:
  1. Open Orbit Settings and look for a keybind view or editor.
  2. Compare the desired standard/custom keybind flow with the current settings contract.
- Expected: Orbit Settings defines a readable keybind list, an editable standard-keybind flow, and a safe custom Lua-keybind path with explicit persistence and apply behavior.
- Actual: The desired behavior is recorded, but its acceptance condition and backend persistence/apply contract are unspecified; no implementation is claimed.
- Evidence: Original scratchpad label `DES-20260816-03` (keybinds in settings), canonical triage ID `DES-20260816-04`.
- Suspected cause: The product request was recorded without defining the settings schema, validation, conflict handling, or runtime application boundary.
- Fix: Define the contract before implementation, including readback, validation, conflict handling, persistence, and runtime verification.
- Validation: Update `SET-004` with the accepted contract, then run an attended read/edit/apply/reload pass.

### ORB-SETTINGS-DOCK-CONTROLS Dock appearance settings lack an acceptance and persistence contract
- Status: Open
- Severity: Low
- Area: settings / appearance
- Classification: Feature / behavior clarification
- Reproduction:
  1. Open Orbit Settings and look for dock size, magnification, opacity, and padding controls.
  2. Attempt to determine the expected units, bounds, persistence, and live-apply behavior.
- Expected: Orbit Settings defines bounded controls for dock size, magnification, opacity, internal padding, and external padding, with documented persistence and runtime effect.
- Actual: The desired behavior is recorded, but the acceptance condition, units, bounds, and persistence/apply contract are unspecified; no implementation is claimed.
- Evidence: `DES-20260817-01` in `Orbit - Session Scratchpad`.
- Suspected cause: The request is an incomplete product requirement rather than a confirmed rendering defect.
- Fix: Define the control schema, bounds, persistence, and live/reload behavior before implementation.
- Validation: Update `SET-005` with the accepted contract, then run an attended edit/apply/reload pass.

### ORB-XMB-TRANSITION Dock-to-XMB transition is not defined or validated
- Status: Closed for current feature scope; follow-up correction open
- Severity: Low
- Area: shell
- Classification: Feature / behavior clarification
- Reproduction:
  1. Open the Orbit dock on a monitor.
  2. Activate the launcher entry.
  3. Observe the transition into the XMB and whether the dock visually becomes or hands off to it.
- Expected: The dock-to-XMB transition makes the launcher feel like one cohesive surface, with the XMB ready for immediate use.
- Actual: The dock launcher now morphs inside the XMB `PanelWindow`; the first single-surface build failed to start its animation because a nested delegate could not access the root animation ID, leaving the morph dock stuck.
- Evidence: `Orbit - Session Scratchpad`, `DES-20260816-01 Create a transtion from the dock to XMB to enable them to appear as one cohesive unit`.
- Suspected cause: Not established; this is a feature request rather than a confirmed implementation defect.
- Fix: Keep the real dock panel at its normal bottom geometry with fixed `exclusiveZone: 58`. Open one XMB `PanelWindow` for the entire handoff, paint the dock morph inside it first, then switch that same surface to the launcher content. Route animation restart through a root function so nested XMB delegates do not dereference a root-local QML ID. Copied icons grow while fading out; no second full-screen morph surface is handed to the compositor.
- Validation: The failure was reproduced in the journal as `shell.qml:416 TypeError: Cannot call method 'restart' of undefined`; `orbit-xmb close` recovered the stuck state. After the fix, `tests/orbit/run-all` passed 15/15, `tests/orbit/run-all --live` passed 19/19, QuickShell reloaded successfully, and the dock layers returned to `352x96` on both monitors with XMB closed. The current interaction was accepted as good enough for this feature session; remaining blanking is tracked as `ORB-XMB-BLANKING`.

### ORB-XMB-BLANKING High-level correction needed for dock-to-XMB surface continuity
- Status: Open; implementation complete, attended validation pending
- Severity: High
- Area: shell / appearance
- Classification: Follow-up correction
- Reproduction:
  1. Activate the Orbit XMB launcher from the dock.
  2. Watch the transition between the dock morph and the ready launcher surface.
- Expected: The launcher-shaped surface remains visually continuous with no dark or blank interval.
- Actual: The current implementation is usable and accepted as good enough for the feature session, but a brief blanking/dark interval remains during the surface handoff.
- Evidence: `Video_2026-08-17_09-26-51.mp4`; latest attended feedback on 2026-08-17.
- Suspected cause: Remaining compositor/frame-paint timing or surface-content realization gap during the single-surface handoff.
- Fix: Keep the morph background surface alive through the handoff so the launcher surface can become visible without removing the only painted content for a compositor frame.
- Validation: `.config/quickshell/orbit/shell.qml` now keeps `dockMorphSurface` visible while `dockMorphing` is true, including the `dockHandoff` overlap. Contract `tests/orbit/run-all` passed 25/25, live checks passed 29/29 after an `orbit-shell.service` restart, and the one-minute soak passed 11/11. Attended visual continuity and interruption validation remain pending.

### ORB-STEAM-TOAST Steam toast monitor mismatch
- Status: Open; implementation complete, attended validation pending
- Severity: Medium
- Area: routing
- Expected: Steam toast remains with Steam's monitor and workspace.
- Actual: Toast can appear on the wrong monitor while focus moves to Steam's workspace. The routing path also required a non-floating Steam window with the same PID, which is not guaranteed for Steam helper/toast windows.
- Evidence: Existing `APP-006` history.
- Fix: Keep floating Steam surfaces on the visible non-floating Steam window's workspace, preferring the main `title == "Steam"` client and falling back to any non-floating Steam client without requiring PID equality.
- Validation: `bash -n .config/hypr/scripts/dynamic-app-workspaces`; contract `tests/orbit/run-all` passed 30/30 (`2026-08-17T15-54-08Z-17457`); live passed 34/34 (`2026-08-17T15-54-08Z-17526`); one-minute soak passed 11/11 (`soak-2026-08-17T15-54-13Z-17455`). No Steam toast was generated because unattended network/application mutation is outside the worker safety boundary; attended controlled toast validation remains `VQ-20260817-09`.

### ORB-DISPLAY-RECOVERY Display disable/apply recovery is incomplete
- Status: Open; correction and hardware validation required
- Severity: High
- Area: settings / hardware
- Expected: Failed display apply restores the last-known-good topology.
- Actual: Apply is sequential and rollback is not yet safety-proven. A disabled output disappears from the Settings widget because normal monitor enumeration excludes it, so it cannot be re-enabled there. The apply path also invokes legacy `hyprctl keyword monitor`, which Hyprland 0.56.1's non-legacy Lua parser rejects.
- Evidence: `SET-003`.
- Suspected cause: Display commands and generated topology files were updated sequentially without a transaction boundary or post-apply verification.
- Fix: Display profile and role applies now snapshot the generated files and live Hyprland topology, verify the requested active dimensions, and restore both runtime monitors and files when any command or reload fails. Rollback failures are surfaced explicitly.
- Current evidence: On 2026-08-17, HDMI-A-1 was disabled intentionally. `hyprctl monitors` and Orbit Settings omitted it while `hyprctl monitors all` retained it as disabled. Legacy `hyprctl keyword monitor ...` returned `keyword can't work with non-legacy parsers. Use eval.` Manual recovery succeeded only after `hyprctl eval` supplied `disabled = false` and the saved mode, position, scale, and VRR values.
- Validation: Deterministic synthetic failure fixture passed `SET-003`; full contract passed 34/34. Live passed 37/38 with unrelated `START-004` Alt+Tab binding failure; one-minute soak passed 10/10. Add deterministic disabled-output retention and Lua-parser command fixtures, then perform the disposable two-monitor failed-apply/recovery check.

### ORB-THEME-PROPAGATION Palette propagation is not uniformly live
- Status: Open
- Severity: Medium
- Area: appearance
- Expected: Each toolkit's live/reload/restart behavior is known.
- Actual: Running surfaces can retain old colors.
- Evidence: The disposable adapter-install contract now proves GTK3, GTK4, and KDE active files are atomically generated from one selected palette. Contract 33/33 (`2026-08-17T16-49-39Z-415867`) and one-minute soak 11/11 (`soak-2026-08-17T16-49-48Z-417118`) pass. The live suite reached 36/37 twice because unrelated `START-004` Alt+Tab binding validation failed; the theme checks passed. Current selected palette is `catppuccin-mocha`, while user-dirty active GTK/KDE files are preserved and do not match the selected generated adapters.
- Next action: Complete the attended palette runtime matrix without overwriting unrelated dirty adapter customizations; use `VQ-20260817-11`.

### ORB-SURFACE-TRANSPARENCY Orbit surfaces do not yet have an explicit compositor transparency contract
- Status: Open; implementation complete, attended validation pending
- Severity: Low
- Area: appearance
- Classification: Feature / behavior clarification
- Reproduction:
  1. Compare Orbit dock and XMB surfaces with GTK surfaces using the configured compositor effects.
- Expected: Orbit dock, XMB, and Settings main surfaces use the configured `appearance.transparency.shell_opacity` value, defaulting to 30%; the transparent top panel and popup/control surfaces remain unchanged.
- Actual: The main shell surfaces now use the configured shell opacity. Attended visual confirmation with Hyprglass remains pending.
- Evidence: Original scratchpad label `DES-20260816-03` (surface transparency), canonical triage ID `DES-20260816-05`.
- Suspected cause: No explicit surface alpha, blur, and compositor-effect acceptance matrix exists.
- Fix: Parse the existing shell opacity setting in `Theme.qml` and apply it only to the dock, dock/XMB morph, and XMB main surfaces. Keep the top panel transparent and do not change popup/control opacity.
- Validation: `tests/orbit/run-all` passed after implementation; run attended two-monitor dock, XMB, and Settings inspection and record whether Hyprglass recognizes the surfaces.

### ORB-INPUT-PERMISSIONS Input helper is broader than necessary
- Status: Closed
- Severity: Medium
- Area: security
- Expected: Input state helper reads only the intended keyboard device.
- Actual: The service uses `/usr/bin/sg input`, granting the helper access to every input-group device. Removing that elevation left the actual keyboard devices inaccessible after logout/login and made Alt+Tab unresponsive.
- Fix: Reverted the unproven ACL-only change. Keep the existing access path until a device-specific ACL or privileged helper design is implemented and validated.
- Validation: Historical ACL regression reproduced after logout/login before this correction. After the allowlist change, the user logged out and back in and confirmed Alt+Tab still works as expected. `tests/orbit/run-all --live` passed 28/28 on 2026-08-17; the helper restarted from the fresh session as `josh:input` and wrote `alt-held=0`. Attended Alt-release behavior passed by user report.
- Next action: Revisit the service-scoped group only if a future device-specific ACL mechanism can be validated without breaking fresh-login keyboard access.
- Current correction: The helper requires `pyudev` and a non-empty `.config/orbit/input-devices.toml` serial allowlist, opens only matching keyboard event nodes, fails closed without the dependency or allowlist, and removes handles for disconnected devices. Fresh-login and attended Alt-release validation passed on 2026-08-17.

### ORB-STARTUP-BINDINGS Runtime Alt+Tab bindings can be lost during compositor transition
- Status: Open; durable correction implemented, live and attended validation pending
- Severity: Medium
- Area: startup / shell
- Reproduction:
  1. Log out and log back into Hyprland.
  2. Inspect `hyprctl binds` for the Orbit `ALT + TAB` and Alt-release bindings.
  3. Try Alt+Tab if the bindings are absent.
- Expected: Orbit installs its runtime bindings after the new Hyprland control socket is ready.
- Actual: After the fresh login on 2026-08-16, the shell and input services were active but `hyprctl binds` contained no Orbit `TAB`, `Alt_L`, or `Alt_R` bindings. Direct eval commands returned `ok` and restored them.
- Evidence: Fresh-login command output; shell journal showed `Configuration Loaded` but no binding evidence. `tests/orbit/run-all --live` initially passed because it did not inspect bindings. Manual binding restoration made `START-004` pass in the current session.
- Suspected cause: The final Hyprland `reload config-only` in the startup hook can erase bindings installed by the earlier Orbit service start.
- Fix: Keep `orbit-shell` as the runtime binding owner for the lifetime of QuickShell. It now validates exactly one non-repeating, press-only Alt+Tab Lua trigger with no legacy Alt-release actions, watches for loss after startup, performs bounded reinstallation, and stops QuickShell so systemd can fail closed if recovery is impossible.
- Validation: Fresh-login verification on 2026-08-17 found all three bindings present without manual restoration; `tests/orbit/run-all` PASS (14 checks), `tests/orbit/run-all --live` PASS (18 checks), and repeated attended Alt+Tab testing passed after shell reload. A fresh live check at 17:23 UTC exposed a transient missing-binding state; the worker now gives the bounded installer 60 attempts and fails closed instead of starting QuickShell without the binding. After service restart, contract 35/35 (`2026-08-17T17-24-08Z-654311`), live 39/39 (`2026-08-17T17-24-13Z-655070`), and one-minute soak 11/11 (`soak-2026-08-17T17-24-16Z-654693`) passed. No display, audio, network, Bluetooth, or session mutation was performed.
- Current evidence: A direct live audit with the current compositor signature on 2026-08-17 found zero `TAB` bindings while `orbit-shell.service` remained active. `START-004` is open again. Determine which reload removes the runtime binding and make ownership durable before re-closing it.
- Current correction evidence: A disposable fake-Hyprland transition removes the trigger after initial startup and confirms the running owner installs it a second time. Shell/Python syntax checks and the full deterministic suite pass 51/51 (`2026-08-17T21-09-55Z-2135925`). The active compositor and service were not reloaded or mutated; current live binding-table and attended Alt+Tab/Alt-release evidence remain `VQ-20260817-18`.

### ORB-ALT-RAPID-CYCLE Rapid Alt+Tab can issue duplicate workspace cycles
- Status: Closed
- Severity: Medium
- Area: shell
- Reproduction:
  1. Hold `Alt` and use a rapid `Tab` press or rapid Tab sequence.
  2. Observe the active workspace while the overview is open.
- Expected: Each physical Tab press that began while Alt was held advances the overview exactly once, even if Alt is released before Tab; releasing Alt closes the overview without cancelling or duplicating that committed cycle.
- Actual: User reproduced the double workspace switch again after a fresh login. It remains intermittent and only occurs with very rapid Alt+Tab; slower chords do not reproduce it.
- Evidence: Prior timing capture in `/tmp/orbit-keys-full.log` and `/tmp/orbit-hypr-events-precise.log`; new attended reproduction after lifecycle validation.
- Suspected cause: Both the trigger path and the file-state open transition could focus the selected workspace, allowing asynchronous MRU changes to issue a second focus request.
- Fix: `OverviewModel.qml` gives the authoritative overview state file ownership of visibility and cycle requests, while the allowlisted `orbit-input-state` helper owns the physical Alt `1 → 0` release transition. Hyprland retains only the `Alt+Tab` trigger; legacy `Alt_L`/`Alt_R` release actions are removed. Added `STATE-002`, `STATE-004`, and `STATE-005` coverage.
- Validation: `sh -n .local/bin/orbit-overview .local/bin/orbit-shell`; `tests/orbit/run-all` PASS (25 checks); `tests/orbit/run-all --live` PASS (29 checks). After reloading `orbit-shell.service`, `hyprctl binds -j` contained the `TAB` trigger and no `Alt_L`/`Alt_R` release actions. Attended rapid Alt-down/Tab press-release/Alt-up validation remains to be repeated for this ownership change.

### ORB-OVERVIEW-STATE-REFRESH Overview repeatedly refocuses during normal cycling
- Status: Closed
- Severity: Medium
- Area: shell
- Classification: Bug
- Reproduction:
  1. Open the overview normally.
  2. Cycle at ordinary rather than rapid Alt+Tab speed.
  3. Observe the overlay focus/selection behavior.
- Expected: Each state revision is consumed once; unchanged state reads do not refocus or reselect the overlay.
- Actual: The overlay appears to repeatedly refocus during normal cycling.
- Evidence: `/home/josh/Videos/ScreenCap/recordings/Video_2026-08-17_15-19-26.mp4` (88.1 seconds); user report on 2026-08-17.
- Suspected cause: QML consumed the same revision repeatedly because the state guard rejected only older revisions, not equal revisions. Each 50 ms state poll therefore reran visibility/selection handling.
- Fix: Consume a state file only when `revision > stateRevision`; preserve cycle processing for newly committed revisions.
- Validation: QuickShell restarted cleanly; contract passed 25/25 and live passed 29/29. Attended normal-speed cycling retest passed on 2026-08-17; the user reported the behavior is rock solid.

### ORB-OVERVIEW-FLOATING-CYCLE Overview loses keyboard focus after cycling to a floating-window workspace
- Status: Closed
- Severity: Medium
- Area: shell
- Classification: Bug
- Reproduction:
  1. Open the overview with a floating client present on one workspace.
  2. Cycle at ordinary Alt+Tab speed.
  3. Observe that the overlay stops accepting further Tab cycles after the first workspace change.
- Expected: The overview retains exclusive keyboard focus while the selected workspace changes, including when the destination workspace focuses a floating client.
- Actual: Cycling can become stuck after one Tab cycle when a floating window is present.
- Evidence: User reports on 2026-08-17 and `/home/josh/Videos/ScreenCap/recordings/Video_2026-08-17_15-31-31.mp4`; the focus pulse is visible, but later Tab presses can repeatedly refocus workspace 2 and sometimes cycle correctly.
- Suspected cause: Each new cycle revision called `selectFocused()` before applying its cycle delta, resetting the selected index from the current workspace. Floating-client focus loss was a contributing red herring, not the complete cause.
- Fix: Initialize selection only when the overview opens; cycle revisions preserve the current selection and advance it once. Retain the focus-grab pulse for floating-client transitions and remove the duplicate QML Alt-release handler.
- Validation: QuickShell restarted without QML errors; contract 25/25 and live 29/29 passed. Attended standard-speed cycling with and without floating windows passed on 2026-08-17; the user reported the behavior is rock solid.

### ORB-SETTINGS-DRAFT-REFRESH Immediate actions can discard staged Settings edits
- Status: Open
- Severity: High
- Area: settings / data integrity
- Classification: Bug
- Reproduction: Stage an appearance, display, or application-rule edit, then perform an immediate audio, network, or Bluetooth action.
- Expected: The immediate action refreshes only observed runtime state and preserves unrelated staged edits.
- Actual: `SettingsSystemActions.qml` invokes the full refresh callback; `SettingsDraftLifecycle.loadSnapshot()` then replaces the draft and clears `dirty`.
- Evidence: Current source inspection of `SettingsSystemActions.qml:27-37` and `SettingsDraftLifecycle.qml:38-46`.
- Next action: Define and test a merge/refresh boundary that cannot erase staged state.

### ORB-SETTINGS-APPLY-ATOMICITY Settings Apply can leave partial mutations
- Status: Open
- Severity: High
- Area: settings / recovery
- Classification: Bug / contract gap
- Reproduction: Submit a draft that changes more than one subsystem and make a later operation fail.
- Expected: Apply either commits the declared transaction or reports exactly which earlier operations remain applied with a safe recovery path.
- Actual: Audio, network, Bluetooth, power, theme, appearance, display, policy, and identity changes execute sequentially; only display changes have rollback.
- Evidence: `.local/bin/orbit-settings:1151-1228`.
- Next action: Define transaction groups and failure semantics before changing implementation.

### ORB-SETTINGS-RUNTIME-PARSERS Runtime observation parsers do not match command output reliably
- Status: Open
- Severity: Medium
- Area: settings / runtime adapters
- Classification: Bug
- Reproduction: Parse normal `wpctl get-volume`, `bluetoothctl show`, or `nmcli` output containing labels, capitalized keys, or escaped delimiters.
- Expected: Snapshot fields reflect the real command output and malformed data fails explicitly.
- Actual: Volume parsing reads the `Volume:` token as a number, Bluetooth compares capitalized keys against lowercase dictionary keys, and `nmcli --escape no` output is split on colons.
- Evidence: `.local/lib/orbit_settings_runtime.py:23-31,70-112`; malformed TOML handling also references `tomllib` without importing it in `.local/bin/orbit-settings`.
- Next action: Add realistic fixtures, correct parsers, and verify malformed-config error handling.

### ORB-MONITOR-IDENTITY-CONNECTOR Stable identity still requires the old connector
- Status: Open
- Severity: Medium
- Area: monitors / routing
- Classification: Bug
- Reproduction: Move a configured physical monitor to another connector while retaining its serial, make, model, and description.
- Expected: Stable EDID identity resolves the role; connector is only a fallback.
- Actual: `orbit-monitor` requires every configured field, including connector, to match.
- Evidence: `.local/bin/orbit-monitor:75-84`; conflicts with the stable-identity decision.
- Next action: Add connector-change fixtures and implement ordered stable-identity/fallback matching.

### ORB-APP-OBSERVE-CORRELATION Unscoped observation can consume the wrong pending launch
- Status: Open
- Severity: High
- Area: application launch / identity
- Classification: Bug
- Reproduction: Keep one pending launch record, then map an unrelated routed window before exact-ID launch observation completes.
- Expected: A no-ID observation cannot consume an ID-bearing launch belonging to another application.
- Actual: The routing daemon calls `orbit-app-observe match` without an ID, which selects the newest usable pending record. Current identities contain cross-application classes and titles.
- Evidence: `dynamic-app-workspaces:121`, `orbit-app-observe:61-94`, and `.config/orbit/application-identities.toml`.
- Next action: Add race fixtures, lock pending-record updates, and require defensible correlation before mutating identities.

### ORB-OVERVIEW-CANCEL-SEMANTICS Escape does not cancel the workspace selection
- Status: Open
- Severity: Medium
- Area: overview / interaction
- Classification: Behavior defect
- Reproduction: Open overview, cycle to another workspace, then press Escape.
- Expected: The behavior matches the displayed `Esc to cancel` contract, either by restoring the original selection or by changing the copy and acceptance contract.
- Actual: Cycling focuses each workspace immediately and Escape only closes the overlay.
- Evidence: `OverviewModel.qml:228-271` and `Overview.qml:53-67,93-99`.
- Next action: Define cancel versus live-preview semantics, then add deterministic and attended coverage.
