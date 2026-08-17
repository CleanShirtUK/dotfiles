---
title: Orbit - Visual Validation Log
type: validation-log
tags: [orbit, visual-testing]
---

# Visual Validation Log

## Entry Template

### YYYY-MM-DD - Surface / scenario
- Environment:
- Surface:
- Steps:
- Expected:
- Actual:
- Result: PASS / FAIL / BLOCKED
- Screenshot or log:
- Follow-up issue:

## Required Runtime Matrix

| Surface | Palette | Result | Live / reload / restart | Evidence |
| --- | --- | --- | --- | --- |
| Orbit dock |  |  |  |  |
| Orbit XMB |  |  |  |  |
| Orbit Settings |  |  |  |  |
| GTK3 |  |  |  |  |
| GTK4/libadwaita |  |  |  |  |
| Breeze Qt |  |  |  |  |
| Flatpak Qt |  |  |  |  |
| Terminal |  |  |  |  |
| Zed / Zen / Obsidian |  |  |  |  |
| Hyprland |  |  |  |  |

### 2026-08-17 - ORB-DOCK-MAGNIFICATION-EDGE boundary-entry correction
- Environment: Current Hyprland session; compositor signature matched `hyprctl instances`; no attended pointer pass performed.
- Surface: Orbit dock magnification at the left and right dock boundaries.
- Steps: Add an animated 140 ms `OutCubic` ramp to `dockContent.hoverAmount` while retaining the existing pointer-distance `scaleAt()` calculation; run contract, live, and one-minute soak checks.
- Expected: Boundary entry and exit change magnification continuously rather than jumping to the maximum, while in-dock interpolation remains unchanged.
- Actual: The correction loaded after `orbit-shell.service` restart with the compositor signature unchanged. Contract passed 32/32, live passed 36/36, and soak passed 11/11. The only recent journal warning was an unrelated Qt portal app-ID registration warning; no Orbit QML error was logged. No attended visual recording was performed.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T16-37-50Z-333107`; `/home/josh/.local/state/orbit/tests/2026-08-17T16-37-53Z-333468`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T16-37-56Z-334022`
- Follow-up issue: Complete slow pointer entry from both sides on every connected monitor through `VQ-20260817-10` before closing `ORB-DOCK-MAGNIFICATION-EDGE` / `UI-009`.

### 2026-08-17 - THEME-003 adapter installation coverage
- Environment: Current Hyprland session; compositor signature matched `hyprctl instances`; selected palette `catppuccin-mocha`; GTK3, GTK4, and KDE active adapter files were user-dirty and were not overwritten.
- Surface: Orbit palette generation and cross-toolkit adapter boundary.
- Steps: Add a disposable fixture for `orbit-theme install_active_adapters`; run contract, live, and one-minute soak suites; compare the selected generated palette with current active adapter files without mutating them.
- Expected: GTK3, GTK4, and KDE adapters can be installed atomically from one generated palette; runtime reload/restart behavior is recorded separately for each surface.
- Actual: Disposable adapter installation passed; contract passed 33/33 and soak passed 11/11. Live reached 36/37 twice because unrelated `START-004` Alt+Tab binding validation failed; theme checks passed. Current active adapters do not equal the selected generated palette, consistent with preserved user-dirty files.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T16-49-39Z-415867`; `/home/josh/.local/state/orbit/tests/2026-08-17T16-50-51Z-425923`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T16-49-48Z-417118`.
- Follow-up issue: Complete the attended live/reload/restart matrix through `VQ-20260817-11` without overwriting unrelated adapter customizations; keep `ORB-THEME-PROPAGATION` open until observed results are recorded.

### 2026-08-17 - ORB-DISPLAY-RECOVERY transactional failure fixture
- Environment: Disposable temporary settings and synthetic Hyprland command responses; no real display mutation.
- Surface: Orbit Settings display profile apply and recovery boundary.
- Steps: Stage a changed DP-1 profile, force the first monitor command to fail, then inspect generated settings, `monitors.lua`, and rollback commands.
- Expected: The failed apply restores the prior files and last-known-good runtime topology, and reports rollback failure separately if restoration itself fails.
- Actual: Synthetic apply failed as intended; prior files were restored and the original 1920x1080 topology command was issued. Contract passed 34/34; live 37/38 due unrelated `START-004`; soak passed 10/10. No hardware/live display apply was attempted.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T16-55-27Z-455435`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T16-55-27Z-455436`
- Follow-up issue: Run the disposable two-monitor failed-apply/recovery procedure in `VQ-20260817-12` before closing `ORB-DISPLAY-RECOVERY` / `SET-003`.

Never record a screenshot alone as proof of propagation. Record the action, whether the application was already running, and whether a reload or restart was required.

### 2026-08-17 - START-006 shutdown confirmation worker refresh
- Environment: Current Hyprland session; `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`; `/usr/bin/zenity` installed; `orbit-shell.service` active. No real logout was attempted.
- Surface: Shutdown confirmation guard.
- Steps: Run shell/Python syntax checks, contract/live/one-minute soak suites, and disposable fake-`zenity` cancel plus missing-`zenity` fixtures. The fake cancel path returned success without invoking `loginctl`; the missing-`zenity` path failed closed.
- Expected: Confirmation precedes every shutdown action; Cancel is a no-op; missing confirmation support fails closed; no unattended check terminates the session.
- Actual: Contract passed 35/35, `START-006` passed in live 38/39 (unrelated `START-004` Alt+Tab assertion failed), soak passed 11/11, and both safe fixtures passed without `loginctl`. No real session action ran.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T17-18-45Z-617766`; `/home/josh/.local/state/orbit/tests/2026-08-17T17-18-49Z-618234`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T17-18-56Z-619246`.
- Follow-up issue: Complete the attended cancel check and separately approved confirm/logout/re-login recovery through `VQ-20260817-14`; do not retry a destructive action after an ambiguous result.

### 2026-08-17 - START-006 shutdown confirmation fresh worker refresh
- Environment: Current Hyprland session 38; `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`; `/usr/bin/zenity` installed; `orbit-shell.service` active. No real logout was attempted.
- Surface: Shutdown confirmation guard.
- Steps: Run shell/Python syntax checks, the contract suite, the live suite, and the one-minute soak. Verify the current compositor signature and Orbit service state; do not invoke the destructive confirm path.
- Expected: The guard remains fail-closed and healthy, with no unattended session termination.
- Actual: Syntax/Python compilation passed; contract passed 35/35, live passed 39/39 including `START-004`, and soak passed 11/11. The service remained active and the compositor signature matched. No real logout or session mutation occurred.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T17-28-30Z-684233`; `/home/josh/.local/state/orbit/tests/2026-08-17T17-28-30Z-684296`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T17-28-35Z-684232`.
- Follow-up issue: Complete attended cancel and, only with explicit approval, confirm/logout/re-login through `VQ-20260817-15`; never retry a destructive action after an ambiguous result.

### 2026-08-17 - THEME-004 surface transparency contract
- Environment: Current Hyprland session; `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`; no attended visual pass performed.
- Surface: Orbit dock, dock/XMB morph, XMB, and Settings main surfaces.
- Steps: Inspect the configured `appearance.transparency.shell_opacity` value and run `tests/orbit/run-all`; live validation also attempted with `tests/orbit/run-all --live`.
- Expected: Main Orbit surfaces use the configured 30% shell opacity; the top panel remains transparent and popup/control surfaces are not changed by this feature.
- Actual: Deterministic contract passed 23/23 and source inspection confirms `theme.shellOpacity` is applied at the three shell surface boundaries. Live validation passed 26/27 but failed unrelated `START-004` Alt+Tab binding presence. No screenshot or attended Hyprglass observation was made.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T13-49-31Z-3147429`; `/home/josh/.local/state/orbit/tests/2026-08-17T13-49-38Z-3148418`
- Follow-up issue: Complete attended two-monitor visual validation and confirm Hyprglass behavior; track the unrelated Alt+Tab failure under `START-004`.

### 2026-08-17 - ORB-STARTUP-BINDINGS fail-closed startup correction
- Environment: Current Hyprland session; compositor signature matched `hyprctl instances`; `orbit-shell.service` active after restart.
- Surface: Runtime Alt+Tab binding installation during Orbit startup.
- Steps: Observe the missing-binding live failure, harden `.local/bin/orbit-shell` with a bounded 60-attempt wait and fail-closed guard, restart the service, then run contract, live, and one-minute soak checks.
- Expected: Orbit does not present a healthy shell while its runtime Alt+Tab binding is absent.
- Actual: A disposable fake-`hyprctl` fixture exited 1 without starting QuickShell when binding installation was unavailable. After the real service restart, the binding was present and all checks passed: contract 35/35, live 39/39, soak 11/11. No session or hardware mutation was performed.
- Result: PASS
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T17-24-08Z-654311`; `/home/josh/.local/state/orbit/tests/2026-08-17T17-24-13Z-655070`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T17-24-16Z-654693`.
- Follow-up issue: None; attended Alt-release ownership remains tracked separately by `STATE-005`.

### 2026-08-17 - ORB-APP-CLOSE-DISPATCH application close action
- Environment: Hyprland 0.56.1 current graphical session; disposable WezTerm fixture; no display, audio, network, Bluetooth, or session mutation.
- Surface: Dock and top-panel application close actions.
- Steps: Launch a disposable `orbit-fixture` WezTerm window, record its Hyprland address, compare the legacy close dispatch with the current Lua dispatcher expression, then close only the fixture.
- Expected: The selected application window closes without affecting other clients.
- Actual: The legacy form returned a Hyprland Lua-dispatch parser error and left the fixture open. Focusing the fixture with `hl.dsp.focus({ window = "address:<address>" })` and then running `hl.dsp.window.close()` returned `ok` and closed it; Orbit now uses this sequence.
- Result: PASS
- Screenshot or log: `/tmp/orbit-fixture.log`; `/tmp/orbit-close-dispatch.log`; contract `2026-08-17T17-15-47Z-596641`; live `2026-08-17T17-15-51Z-597112`; soak `soak-2026-08-17T17-15-54Z-597644`.
- Follow-up issue: None for this item.

### 2026-08-17 - Dock-to-XMB morph smoke check
- Environment: Current Hyprland session; `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`; Orbit shell restarted with the new QML.
- Surface: Orbit dock and XMB launcher handoff.
- Steps: Restart `orbit-shell.service`; confirm the XMB state is closed; activate the `Orbit XMB` item from the dock; inspect `hyprctl layers -j` during and after the handoff; close XMB and inspect layers/state again.
- Expected: The dock surface expands and moves into the configured launcher footprint while XMB remains absent; after the morph completes, XMB replaces the dock paint without changing the reserved dock zone. Closing XMB restores the dock.
- Actual: The provided recordings (`Video_2026-08-17_08-56-56.mp4`, `Video_2026-08-17_09-17-10.mp4`, and `Video_2026-08-17_09-26-51.mp4`) demonstrate the intended direction, but the first single-surface build left a second dock stuck because the nested XMB delegate could not restart the root animation. The journal captured the TypeError; the state was closed and the shell restarted after routing the restart through a root function. The single-surface timing still needs an attended dock click, so handoff continuity and visual/user approval are not established.
- Result: MANUAL
- Screenshot or log: `journalctl --user -u orbit-shell.service -n 40 --no-pager`; `hyprctl layers -j`; `/home/josh/.local/state/orbit/tests/2026-08-17T07-48-51Z-4094307`
- Follow-up issue: `ORB-XMB-BLANKING` is a high-level correction needed for full visual continuity; current feature accepted as good enough for this session.

### 2026-08-17 - ORB-XMB-BLANKING handoff overlap correction
- Environment: Current Hyprland session; `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`; QuickShell 0.3.0; `orbit-shell.service` restarted after the QML change.
- Surface: Orbit dock and XMB launcher handoff.
- Steps: Keep `dockMorphSurface` visible for the full `dockMorphing` interval, including `dockHandoff`, while the launcher surface becomes visible; run contract/live checks and a one-minute soak.
- Expected: The compositor never loses the painted morph background at the surface handoff; the launcher appears without a dark or blank interval.
- Actual: The overlap correction loaded successfully. Contract passed 25/25, live passed 29/29, and soak passed 11/11. No attended visual recording was performed in this worker session.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T14-53-19Z-3716300`; `/home/josh/.local/state/orbit/tests/2026-08-17T14-53-25Z-3716878`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T14-53-29Z-3717902`.
- Follow-up issue: Complete attended continuity and interruption validation through `VQ-20260817-02`; do not claim the visual gate from automated evidence alone.

### 2026-08-17 - ORB-APP-LAUNCH-BOUNDARY shared execution contract
- Environment: Current Hyprland session; compositor signature matched `hyprctl instances`; Orbit service remained active.
- Surface: Orbit dock and XMB application launch boundaries.
- Steps: Assert both QML launch paths invoke the shared scope and identity helpers; run contract, live, and one-minute soak suites. No attended launch was performed in this worker session.
- Expected: Both surfaces share scoped launch, captured context, Desktop Entry normalization, and identity observation.
- Actual: Contract passed 29/29, live passed 33/33, and soak passed 11/11. Static source coverage confirms both paths call `orbit-app-launch` and `orbit-app-observe`; no visual or attended routing result was established.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T15-32-16Z-4048673`; `/home/josh/.local/state/orbit/tests/2026-08-17T15-32-17Z-4048738`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T15-32-21Z-4048672`
- Follow-up issue: Complete the disposable dock/XMB comparison in `VQ-20260817-07`; concurrent same-class correlation remains separate work.

### 2026-08-17 - Orbit top panel first-pass smoke check
- Environment: Current Hyprland session; `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`; fresh `orbit-shell.service` restart with QuickShell 0.3.0.
- Surface: Orbit top panel on `DP-1` and `HDMI-A-1`.
- Steps: Restart `orbit-shell.service`; inspect `hyprctl layers -j`; capture the desktop with `grim`; inspect clock, launcher glyph, and right-side tray region.
- Expected: Each monitor has a 42px transparent top surface; launcher glyph is at left, current time is centered, and native tray items populate on the right when registered.
- Actual: `hyprctl layers -j` showed one 1920x42 QuickShell surface per monitor. The screenshot showed both launcher glyphs and centered `10:45` clocks with the wallpaper visible through the panel. After Sunshine was running, the session bus still reported `RegisteredStatusNotifierItems = 0`; no Sunshine tray item was available for Orbit to render or activate.
- Result: MANUAL
- Screenshot or log: `/tmp/orbit-top-panel.png`; `journalctl --user -u orbit-shell.service --since '10 seconds ago' --no-pager`.
- Follow-up issue: Complete `UI-010` with an application that registers a StatusNotifier item; separately define persisted nerd-font icon overrides. Sunshine tray registration is blocked at the application/session-service boundary, not reproduced as an Orbit rendering failure.

### 2026-08-17 - DES-20260817-04 application selection/title validation
- Environment: Current Hyprland session; `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`; `orbit-shell.service` restarted with the application-menu model.
- Surface: Orbit top panel application-menu title/selection.
- Steps: Run `tests/orbit/run-all` and `tests/orbit/run-all --live`; inspect the current window snapshot and the Orbit journal after restart.
- Expected: The model selects the focused monitor's current-workspace application, retains the last-focused application for a non-focused monitor/workspace, and resolves a pretty desktop-entry name before using the final window-class component.
- Actual: Deterministic and live checks passed; the shell loaded the new model. No current client snapshot exposed a global-menu handle or registrar address, so menu rendering/activation could not be attended and was not claimed as a pass.
- Historical evidence: `tests/orbit/run-all` (17/17), `tests/orbit/run-all --live` (21/21), and issue `ORB-TOP-PANEL-GLOBAL-MENU`. Current counts are recorded in [[Orbit - Status]].
- Follow-up issue: Add the protocol bridge and repeat `UI-011` with an application that exports a DBusMenu/global application menu.

### 2026-08-17 - UI-011 per-monitor routing correction
- Environment: Current Hyprland instance `5c9377c15f85c50648f35ca5a213754f95b93ca0_1786957786_784850465`; QuickShell 0.3.0; native Wayland clients.
- Surface: Orbit top panels on `DP-1` and `HDMI-A-1`.
- Steps: Run `tests/orbit/run-all --live`; restart `orbit-shell.service`; inspect `journalctl --user -u orbit-shell.service` and `hyprctl layers -j`; inspect the session bus for `com.canonical.AppMenu.Registrar`.
- Expected: Each panel routes its title and menu candidate by its own monitor; both surfaces load without QML errors; a qualifying protocol handle enables activation.
- Actual: The contract/live checks passed, QuickShell loaded the updated QML, and one 1920x42 QuickShell top surface appeared on each monitor. The session has no appmenu registrar, and current clients expose no menu handle; activation could not be performed.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T10-15-41Z-1166707`; `journalctl --user -u orbit-shell.service`; `hyprctl layers -j`.
- Follow-up issue: `ORB-TOP-PANEL-GLOBAL-MENU` remains open pending a protocol bridge and qualifying application fixture.

### 2026-08-17 - UI-011 application action fallback implementation
- Environment: Current Hyprland session; QuickShell 0.3.0; `orbit-shell.service` restarted successfully.
- Surface: Orbit top-panel application-name control.
- Steps: Inspect the loaded QML and restart the shell; do not activate destructive actions against the current work windows.
- Expected: A selected application name is clickable even without a protocol menu; the fallback offers `Close window` and `Force quit application`.
- Actual: Contract coverage confirms per-monitor candidate selection, address-based close dispatch, and PID-based `SIGKILL` fallback. The shell loaded without a QML error. The destructive click path was not manually exercised.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T10-21-41Z-1218876`; `journalctl --user -u orbit-shell.service --since '5 seconds ago' --no-pager`.
- Follow-up issue: Run attended validation with a disposable test window, then separately add a native/XWayland protocol fixture if DBusMenu activation remains desired.

### 2026-08-17 - UI-011 monitor identity correction
- Environment: Current Hyprland session; clients report numeric monitor IDs and monitors report names; `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`.
- Surface: Orbit top-panel application-name control on `DP-1` and `HDMI-A-1`.
- Steps: Compare `hyprctl monitors -j` with `hyprctl clients -j`; restart `orbit-shell.service`; run deterministic and live Orbit checks.
- Expected: Each panel resolves its client by monitor ID and displays the selected application name.
- Actual: The previous name/ID comparison was corrected. QuickShell loaded successfully; the historical correction run passed 18/18 and the live run passed 22/22. Current totals are recorded in [[Orbit - Status]].
- Result: PASS
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T10-23-52Z-1239085`; `/home/josh/.local/state/orbit/tests/2026-08-17T10-23-52Z-1238643`.
- Follow-up issue: Perform destructive fallback actions only with a disposable test window; protocol-menu support remains separately blocked.

### 2026-08-17 - UI-011 protocol menu placement correction
- Environment: Current Hyprland session; QuickShell 0.3.0; current panel menu reported clipped below the top-panel surface.
- Surface: Orbit top-panel application menu.
- Steps: Replace the generic menu display call with `QsMenuAnchor`; anchor to the application-name button at the bottom-left; enable `PopupAdjustment.All`; restart `orbit-shell.service`.
- Expected: The complete application menu opens as an independent popup below the panel and adjusts to screen boundaries instead of being clipped by the 42px panel.
- Actual: QuickShell loaded successfully with no `QsMenuHandle` assignment warnings after the null-handle correction. Deterministic and live checks passed. A new screenshot-based attended confirmation is still required.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T10-27-23Z-1270074`; `/home/josh/.local/state/orbit/tests/2026-08-17T10-27-23Z-1270073`; `journalctl --user -u orbit-shell.service --since '5 seconds ago' --no-pager`.
- Follow-up issue: Reopen the application menu on Obsidian and confirm all entries are visible and clickable.

### 2026-08-17 - UI-011 protocol bridge feasibility check
- Environment: Current Hyprland instance `5c9377c15f85c50648f35ca5a213754f95b93ca0_1786962557_304583574`; QuickShell 0.3.0; native Wayland clients.
- Surface: Orbit top-panel global application menu.
- Steps: Run `tests/orbit/run-all` and `tests/orbit/run-all --live`; compare `HYPRLAND_INSTANCE_SIGNATURE` with `hyprctl instances`; inspect the session bus for `com.canonical.AppMenu.Registrar`; inspect `hyprctl clients -j` for protocol and menu-handle data.
- Expected: A registrar, application menu service/path, or another usable protocol source is available for the bridge.
- Actual: Contract and live suites passed 20/20 and 24/24. The current signature matched `hyprctl instances`; no appmenu bus name or registrar was present; Obsidian, WezTerm, and Zen all reported `xwayland: false`, with no menu handle in the client snapshot.
- Result: BLOCKED
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T12-04-19Z-2147790`; `/home/josh/.local/state/orbit/tests/2026-08-17T12-04-19Z-2147800`; `gdbus introspect --session --dest com.canonical.AppMenu.Registrar --object-path /com/canonical/AppMenu/Registrar`.
- Follow-up issue: Provide or identify a qualifying DBusMenu/global-menu fixture or protocol bridge source, then repeat `UI-011`; do not claim native menu activation from the current fallback-only behavior.

### 2026-08-17 - UI-011 appmenu package installation
- Environment: Fedora 44/CachyOS; current graphical session; `QT_QPA_PLATFORMTHEME=hyprqt6engine`.
- Surface: Global application-menu protocol prerequisites.
- Steps: Install `appmenu-qt5`, `appmenu-qt5-profile.d`, `dbusmenu-qt5`, and `libdbusmenu-tools`; query installed files and probe the session bus for `com.canonical.AppMenu.Registrar`.
- Expected: The packages provide a usable registrar or otherwise make a qualifying application menu source available.
- Actual: Packages installed successfully. They provide the Qt5 platform plugin, DBusMenu Qt5 library, and test tooling, but no registrar executable/service. The registrar probe still returns `ServiceUnknown`; the current session has no appmenu bus name.
- Result: BLOCKED
- Screenshot or log: `rpm -q appmenu-qt5 appmenu-qt5-profile.d dbusmenu-qt5 libdbusmenu-tools`; `rpm -ql ...`; `gdbus introspect --session --dest com.canonical.AppMenu.Registrar --object-path /com/canonical/AppMenu/Registrar`.
- Follow-up issue: Use the installed `/usr/libexec/dbusmenu-testapp` as a fixture candidate or obtain/build a registrar before changing Orbit integration. Review the Fedora warning before enabling `appmenu-qt5` globally for future Qt5 launches.

### 2026-08-17 - UI-011 existing registrar tooling validation
- Environment: Fedora 44/CachyOS; current graphical session; `Simple-Appmenu-Server` commit `bb5f40fbe35fd18ddde7a0b97d89d76619bef995` built in `/tmp/opencode/Simple-Appmenu-Server`.
- Surface: DBusMenu registrar prerequisite.
- Steps: Build the existing server with its Makefile; launch it; introspect `com.canonical.AppMenu.Registrar`; keep `/usr/libexec/dbusmenu-testapp /usr/share/libdbusmenu/json/test-gtk-label.json` running; register window ID `424242` with `/MenuBar`; retrieve it with `GetMenuForWindow`.
- Expected: The existing registrar publishes the expected DBus interface and stores the fixture's service/path association.
- Actual: Build passed with a deprecation warning for `g_type_init()`. The registrar exported `/com/canonical/AppMenu/Registrar`; registration returned success and retrieval returned the fixture service and `/MenuBar`. The fixture is headless and has no real XWayland window ID, so Orbit end-to-end activation remains unvalidated.
- Result: PASS for dependency/protocol prerequisite; BLOCKED for UI-011 end-to-end integration.
- Screenshot or log: `/tmp/opencode/appmenu-registrar.log`; `gdbus introspect --session --dest com.canonical.AppMenu.Registrar --object-path /com/canonical/AppMenu/Registrar`; `gdbus call ... RegisterWindow 424242 /MenuBar`; `gdbus call ... GetMenuForWindow 424242`.
- Follow-up issue: Run a qualifying Qt5/XWayland application with `appmenu-qt5`, capture its real X11 window ID, and connect that registrar association to Orbit's per-monitor client model.

### 2026-08-17 - UI-011 Qt5 Designer application fixture
- Environment: Fedora 44/CachyOS; current Hyprland/XWayland session; `Simple-Appmenu-Server` running; Qt5 Designer launched with `QT_QPA_PLATFORM=xcb QT_QPA_PLATFORMTHEME=appmenu-qt5`.
- Surface: Qt5 Designer global application menu source.
- Steps: Launch `designer-qt5`; inspect `hyprctl clients -j` and X11 properties; inspect the registrar log; query `GetMenuForWindow` for the registered X11 window.
- Expected: A traditional Qt5 menu application creates an XWayland window and registers a DBusMenu object through the registrar.
- Actual: Qt Designer created XWayland windows `0x40000c` and `0x400019` (`xwayland: true`). The registrar logged `XWindow 4194316: register`; `GetMenuForWindow 4194316` returned service `:1.535134` and object path `/MenuBar/1`. The child form window did not register separately.
- Result: PASS for the external application/registrar fixture; BLOCKED for Orbit end-to-end rendering and activation.
- Screenshot or log: `/tmp/opencode/appmenu-registrar.log`; `hyprctl clients -j`; `xprop -id 0x40000c`; registrar `GetMenuForWindow 4194316` result.
- Follow-up issue: Add a narrow Orbit-side lookup from Hyprland XWayland client window ID to registrar service/object path, then adapt that DBusMenu source to the existing Orbit popup boundary.

### 2026-08-17 - UI-012 Orbit registrar lookup first pass
- Environment: Fedora 44/CachyOS; current Hyprland/XWayland session; Qt5 Designer and `Simple-Appmenu-Server` running.
- Surface: Orbit DBusMenu lookup boundary.
- Steps: Run `.local/bin/orbit-appmenu snapshot`; inspect the returned XWayland window ID, PID, registrar service/path, and DBusMenu layout.
- Expected: Orbit can resolve a registered XWayland window to its DBusMenu source without relying on a hard-coded application or window ID.
- Actual: The helper returned Designer window `4194316`, PID `2398822`, class `Designer`, service `:1.535140`, path `/MenuBar/1`, and a parsed layout with seven top-level entries.
- Result: PASS for deterministic lookup; MANUAL for Orbit rendering and activation.
- Screenshot or log: `.local/bin/orbit-appmenu snapshot`; `/tmp/opencode/appmenu-registrar.log`.
- Follow-up issue: Reload Orbit and exercise the panel menu against Designer, including a leaf action, before expanding support for nested submenu interaction.

### 2026-08-17 - UI-012 Qt5 Designer attended activation
- Environment: Current Hyprland/XWayland session; Qt5 Designer; `Simple-Appmenu-Server`; Orbit shell with the registrar bridge loaded.
- Surface: Orbit top-panel application menu for Qt5 Designer.
- Steps: Focus Qt5 Designer; click the application name in the Orbit top panel; choose `New...` under `File`.
- Expected: Orbit opens the registered DBusMenu and the selected leaf action is delivered to Designer.
- Actual: The Orbit menu opened and `File > New...` activated successfully; Designer responded by opening a new form.
- Result: PASS
- Screenshot or log: User-attended validation reported on 2026-08-17; deterministic run `/home/josh/.local/state/orbit/tests/2026-08-17T12-35-03Z-2426195`.
- Follow-up issue: Keep native Wayland applications on the fallback path until they expose a compatible menu protocol; validate another XWayland Qt5 application before broadening the claim.

### 2026-08-17 - Native Wayland global-menu candidate research: Heaven
- Environment: Repository review of `CuarzoSoftware/Heaven` commit `a8f5027108efdec33dfcf86d3c1637184d3d55aa`; current Orbit Hyprland session.
- Surface: Native Wayland global application-menu architecture.
- Steps: Read Heaven's README, build definition, client example, and compositor example; compare its required integrations with current Orbit ownership and native Wayland clients.
- Expected: Identify an existing tool that can be adopted without replacing application or compositor protocol integration.
- Actual: Heaven supplies `cz-heaven-client`, `cz-heaven-bar`, and `cz-heaven-compositor` libraries over D-Bus. Clients must integrate `HNClient` and receive a private handle through an `lvr-private-handle` Wayland protocol; the compositor must map that handle to a D-Bus client and select the active client. The repository contains no protocol definition or Hyprland integration. Its build also requires `cz-core`, C++20, Meson, and systemd/elogind/basu development dependencies; `cz-core` is not available from the current Fedora repositories.
- Result: BLOCKED for immediate adoption; PROMISING for a staged native-Wayland design.
- Screenshot or log: `/tmp/opencode/Heaven`; README and `meson.build` at the recorded commit.
- Follow-up issue: Prototype Heaven in an isolated bus first, then decide whether to implement a Hyprland plugin/protocol and app-specific client adapters. Keep the working XWayland bridge as fallback.

### 2026-08-17 - Native Wayland global-menu candidate research: noctalia-appmenu
- Environment: Repository review of `yolo-labz/noctalia-appmenu` current main branch; Orbit uses QuickShell and Hyprland rather than Noctalia and niri.
- Surface: Native Wayland global application-menu architecture.
- Steps: Read the project README, compatibility table, architecture notes, and recent maintenance history.
- Expected: Identify an existing implementation with real native-Wayland application coverage that can be adapted rather than designing a new protocol.
- Actual: The project is an active Rust bridge plus QML plugin with a v1.0 release candidate and substantial recent development. It uses AT-SPI as the practical substrate, supports Qt6 and GTK4 when accessibility export is enabled, supports Electron with `--force-accessibility`, and uses niri IPC only for focus tracking. Its README explicitly defers Hyprland/Sway/KWin support, but the bridge/bar boundary is a closer fit for Orbit than Heaven's unimplemented compositor/client protocol.
- Result: PROMISING; recommended primary candidate.
- Screenshot or log: `https://github.com/yolo-labz/noctalia-appmenu`.
- Follow-up issue: Prototype the bridge's AT-SPI walker and atomic JSON/proxy output against Hyprland focus snapshots, beginning with a Qt6 application and preserving the XWayland DBusMenu fallback.

### 2026-08-17 - UI-013 Orbit native AT-SPI first pass
- Environment: Current Hyprland session; native Qt6 Designer launched with `QT_ACCESSIBILITY=1 QT_QPA_PLATFORM=wayland`; AT-SPI bus active; Orbit shell reloaded with the native helper.
- Surface: Native Wayland Qt6 application menu lookup.
- Steps: Enable AT-SPI; launch Qt6 Designer; inspect `hyprctl clients -j`; query the AT-SPI registry; run `.local/bin/orbit-appmenu-atspi snapshot`; reload Orbit.
- Expected: The native Wayland application registers on AT-SPI, Orbit matches it by PID/title, and the menu tree is available to the panel without XWayland or a compositor appmenu protocol.
- Actual: Qt6 Designer appeared as `xwayland: false`; the AT-SPI registry contained a `Designer` application; the helper returned the native client PID, monitor, title, AT-SPI service/path, and seven top-level menu entries. Orbit reloaded successfully with no new QML load errors.
- Result: PASS for lookup/integration load; MANUAL for popup/action activation.
- Screenshot or log: `/tmp/opencode/qt6-designer.log`; `.local/bin/orbit-appmenu-atspi snapshot`; `/home/josh/.local/state/orbit/tests/2026-08-17T13-09-46Z-2752160`.
- Follow-up issue: Focus native Qt6 Designer and activate a safe menu item from the Orbit panel; then test a second native Qt6 application.

### 2026-08-17 - UI-013 native AT-SPI menu rendering correction
- Environment: Current Hyprland session; native Qt6 Designer on Wayland; Orbit shell reloaded with the AT-SPI bridge.
- Surface: Orbit top-panel native Wayland application menu.
- Steps: Focus Qt6 Designer; click its application name; inspect the rendered menu rows after the AT-SPI field-mapping correction.
- Expected: Named menu entries and separators appear instead of placeholder labels.
- Actual: The menu opened with named entries and separators; the user confirmed the corrected rendering works. A safe leaf action has not yet been explicitly exercised in this correction pass.
- Result: PASS for rendering; MANUAL for action activation.
- Screenshot or log: User-attended confirmation on 2026-08-17; `/home/josh/.local/state/orbit/tests/2026-08-17T13-22-22Z-2877294`.
- Follow-up issue: Click `File > New...` and confirm Qt6 Designer responds, then test a second native Qt6 application.

### 2026-08-17 - UI-013 native AT-SPI action activation
- Environment: Current Hyprland session; native Qt6 Designer on Wayland; Orbit shell with the AT-SPI bridge.
- Surface: Orbit top-panel native Wayland application menu.
- Steps: Open the Qt6 Designer menu from Orbit and click `File > New...`.
- Expected: The AT-SPI action is delivered to Qt6 Designer and a new form opens.
- Actual: Qt6 Designer responded successfully and opened a new form.
- Result: PASS
- Screenshot or log: User-attended confirmation on 2026-08-17; `/home/josh/.local/state/orbit/tests/2026-08-17T13-22-22Z-2877294`.
- Follow-up issue: Validate a second native Qt6 or GTK4 application before broadening the support claim.

### 2026-08-17 - UI-014 GTK4 Nautilus coverage check
- Environment: Current Hyprland session; native Nautilus launched with `GDK_BACKEND=wayland`; AT-SPI enabled.
- Surface: GTK4 native application menu.
- Steps: Launch Nautilus; inspect `hyprctl clients -j`; inspect the AT-SPI registry; run `.local/bin/orbit-appmenu-atspi snapshot`.
- Expected: A readable GTK4 menubar is available when the application exposes one.
- Actual: Nautilus registered on AT-SPI and appeared as `xwayland: false`, but its accessible tree exposed no readable `MENU_BAR`; the helper correctly returned no native menu entry.
- Result: BLOCKED for full GTK4 menu extraction; fallback required.
- Screenshot or log: `/tmp/opencode/nautilus.log`; `.local/bin/orbit-appmenu-atspi snapshot`.
- Follow-up issue: Implement or adopt an honest desktop-action/window-control fallback for GTK4 popover-only applications; do not synthesize a fake File/Edit/View tree.

### 2026-08-17 - UI-015 Electron Obsidian accessibility coverage check
- Environment: Fedora Flatpak Obsidian 1.13.7; native Wayland; disposable `--user-data-dir=/tmp/orbit-obsidian-atspi`; `--force-accessibility` and `ELECTRON_ENABLE_ACCESSIBILITY=1` attempted.
- Surface: Electron native application menu.
- Steps: Launch the disposable Obsidian instance with accessibility flags; inspect its native Wayland client and the AT-SPI registry; run `.local/bin/orbit-appmenu-atspi snapshot`.
- Expected: Obsidian registers a usable AT-SPI application/menu tree.
- Actual: Obsidian launched natively but did not appear in the AT-SPI registry and produced no native menu snapshot.
- Result: BLOCKED for native Electron menu extraction in this configuration.
- Screenshot or log: `/tmp/opencode/obsidian-atspi.log`; `.local/bin/orbit-appmenu-atspi snapshot`.
- Follow-up issue: Keep Electron on the honest fallback path and investigate app-specific menu/accessibility flags only when they are known to expose a machine-readable tree.

### 2026-08-17 - UI-016 unsupported-application fallback actions
- Environment: Current Hyprland session; native Nautilus on Wayland; Orbit shell with fallback action sizing correction.
- Surface: Orbit top-panel fallback menu for an application without a readable native menubar.
- Steps: Focus Nautilus; click `Home` in the Orbit top panel; inspect all fallback rows.
- Expected: The fallback menu shows `Open new window`, `Close window`, and `Force quit application` without pretending they are Nautilus's native File/Edit/View menu.
- Actual: All three actions were visible after the popup height correction; the user confirmed the result worked.
- Result: PASS
- Screenshot or log: User-attended confirmation on 2026-08-17; `/home/josh/.local/state/orbit/tests/2026-08-17T13-31-38Z-2970989`.
- Follow-up issue: Validate the individual fallback actions only with disposable windows; keep native-menu and fallback provenance distinct.

### 2026-08-17 - ORB-APP-EXEC-FIELDS desktop-entry launch normalization
- Environment: Current Hyprland session; `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`; Orbit services remained active. No real application was launched by the deterministic fixture.
- Surface: Orbit dock/XMB application launch.
- Steps: Run `sh -n .local/bin/orbit-app-launch`, execute the fake `systemd-run` contract fixture with `nautilus --new-window %U`, then run contract, live, and one-minute soak suites.
- Expected: No-file Desktop Entry field codes are removed before application execution; the launcher remains healthy under live and soak checks.
- Actual: The fixture observed no `%U` in the runner command. Contract passed 26/26, live passed 30/30, and soak passed 11/11. Real Nautilus and Zen relaunches were not attended in this worker session.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T15-04-00Z-3805284`; `/home/josh/.local/state/orbit/tests/2026-08-17T15-04-03Z-3805765`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T15-04-11Z-3806901`.
- Follow-up issue: `VQ-20260817-04` records the disposable Nautilus/Zen attended relaunch gate.

### 2026-08-17 - ORB-DOCK-SETTINGS-ICON synthetic Settings icon correction
- Environment: Current Hyprland session; `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`; QuickShell 0.3.0; `orbit-shell.service` restarted successfully.
- Surface: Orbit dock synthetic `Orbit Settings` entry.
- Steps: Resolve the synthetic entry through `ApplicationModel.qml`; run contract, live, and one-minute soak checks; restart `orbit-shell.service` and verify it remains active.
- Expected: The Settings entry uses the standard `settings-symbolic` icon without changing normal application icon lookup or Settings activation.
- Actual: The fallback is present in the source; contract passed 26/26, live 30/30, and soak 11/11. The service restarted active. No attended visual inspection was performed in this worker session.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T15-07-52Z-3836324`; `/home/josh/.local/state/orbit/tests/2026-08-17T15-07-54Z-3836727`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T15-07-57Z-3837506`; `journalctl --user -u orbit-shell.service`.
- Follow-up issue: Complete attended two-monitor icon and activation inspection through `VQ-20260817-05` before closing `ORB-DOCK-SETTINGS-ICON` / `UI-008`.

### 2026-08-17 - ORB-XMB-DOCK-FOCUS handoff focus correction
- Environment: Current Hyprland session; `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`; QuickShell 0.3.0; `orbit-shell.service` restarted active.
- Surface: Dock-launched Orbit XMB keyboard focus.
- Steps: Correct the handoff state so `dockMorphing` is released after the launcher becomes ready; run contract, live, and one-minute soak checks; restart the shell and inspect service health.
- Expected: The dock-launched XMB satisfies its existing exclusive `WlrLayershell` keyboard-focus guard after handoff, while keybind launch behavior remains unchanged.
- Actual: The correction loaded without a QML error. Contract passed 28/28, live passed 32/32, and soak passed 10/10; no attended typing or Escape recording was performed in this worker session.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T15-21-01Z-3954782`; `/home/josh/.local/state/orbit/tests/2026-08-17T15-21-01Z-3954791`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T15-21-01Z-3954801`; `journalctl --user -u orbit-shell.service` after restart.
- Follow-up issue: Complete attended dock-open keyboard navigation, category/search input, Escape close, and keybind comparison through `VQ-20260817-06` before closing `ORB-XMB-DOCK-FOCUS` / `UI-018`.

### 2026-08-17 - STATE-009 shared Settings client snapshot
- Environment: Current Hyprland session; `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`; QuickShell 0.3.0; `orbit-shell.service` restarted active after the QML change.
- Surface: Orbit Settings application matching.
- Steps: Replace the SettingsModel client process with the shared `HyprlandModel` client signal; run contract, live, and one-minute soak checks; restart Orbit and verify service/signature health.
- Expected: Settings application matching sees current clients without an independent Hyprland poll, while the bounded match timeout remains functional.
- Actual: Contract passed 29/29, live passed 33/33, and soak passed 11/11. The service restarted active and the current compositor signature matched `hyprctl instances`.
- Result: PASS
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T15-35-34Z-4072076`; `/home/josh/.local/state/orbit/tests/2026-08-17T15-35-34Z-4072141`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T15-35-35Z-4072075`.
- Follow-up issue: None for this refactor; remaining attended queue entries are unrelated.

### 2026-08-17 - ORB-APP-CONCURRENT-CORRELATION final deterministic/live evidence
- Environment: Current Hyprland session; `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`; `orbit-shell.service` active after reload.
- Surface: Orbit concurrent application launch correlation.
- Steps: Run the final contract, live, and one-minute soak checks after adding launch-ID inheritance and PID environment matching.
- Expected: Each mapped same-app client can be matched to its own launch ID without consuming another pending record.
- Actual: Contract 30/30, live 34/34, and soak 11/11 passed; the disposable two-record fixture retained the unrelated pending record.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T15-48-16Z-4171928`; `/home/josh/.local/state/orbit/tests/2026-08-17T15-48-17Z-4171926`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T15-48-25Z-4173026`.
- Follow-up issue: Attended two-window confirmation remains `VQ-20260817-08`.

### 2026-08-17 - ORB-APP-CONCURRENT-CORRELATION launch identity correlation
- Environment: Current Hyprland session; compositor signature matched `hyprctl instances`; `orbit-shell.service` restarted active; no real concurrent application launch was performed.
- Surface: Orbit dock/XMB application launch identity observation.
- Steps: Add a unique launch ID to both launch surfaces; pass it through the scoped launch helper; match the mapped client by exact ID and record address/PID/class/title; run contract, live, and one-minute soak checks.
- Expected: Two same-desktop launches cannot consume one another's pending identity record.
- Actual: The disposable two-record fixture matched `launch-a` and retained `launch-b`; contract passed 30/30, live 34/34, and soak 11/11. Service restart was clean with no new QML errors.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T15-45-08Z-4147520`; `/home/josh/.local/state/orbit/tests/2026-08-17T15-45-20Z-4149043`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T15-45-27Z-4150028`.
- Follow-up issue: Run the disposable two-window attended correlation flow in `VQ-20260817-08` before closing `ORB-APP-CONCURRENT-CORRELATION` / `APP-010`.

### 2026-08-17 - ORB-STEAM-TOAST workspace correlation correction
- Environment: Current Hyprland session; `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`; no Steam toast was generated in the worker session.
- Surface: Steam transient menus and notifications.
- Steps: Update `dynamic-app-workspaces` to correlate floating `steam` clients to the visible non-floating Steam client without PID equality; run shell syntax, contract, live, and one-minute soak checks.
- Expected: Floating Steam surfaces remain on Steam's Gaming workspace and monitor even when their helper PID differs from the main Steam client.
- Actual: The implementation now prefers the non-floating client titled `Steam`, then falls back to any non-floating Steam client. Contract passed 30/30, live passed 34/34, and soak passed 11/11. A real toast was not generated because unattended application/network mutation is outside the worker safety boundary.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T15-54-08Z-17457`; `/home/josh/.local/state/orbit/tests/2026-08-17T15-54-08Z-17526`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T15-54-13Z-17455`.
- Follow-up issue: Complete the controlled Steam toast observation through `VQ-20260817-09` before closing `ORB-STEAM-TOAST` / `APP-006`.

### 2026-08-17 - STATE-012 Settings application-matching ownership split
- Environment: Current Hyprland session; `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`; `orbit-shell.service` active.
- Surface: Orbit Settings application matching and shared client observation.
- Steps: Extract the matching boundary into `SettingsApplicationMatching.qml`; run contract, live, and one-minute soak suites; inspect service health and journal warnings/errors.
- Expected: Matching timers, candidate discovery, and client projection have one narrow owner without changing the SettingsModel public API or runtime behavior.
- Actual: Contract passed 30/30, live passed 34/34, and soak passed 10/10. The service remained active; no Orbit QML errors were recorded. Existing portal app-ID warnings are unrelated to this refactor.
- Result: PASS
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T16-07-40Z-117230`; `/home/josh/.local/state/orbit/tests/2026-08-17T16-07-42Z-117595`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T16-07-46Z-118244`.
- Follow-up issue: Draft lifecycle remains parent-owned for a later worker item; no manual gate is required for this deterministic ownership refactor.

### 2026-08-17 - STATE-013 Settings draft lifecycle ownership split
- Environment: Current Hyprland session; `HYPRLAND_INSTANCE_SIGNATURE` remained unchanged; QuickShell 0.3.0; `orbit-shell.service` restarted active.
- Surface: Orbit Settings staged draft, Cancel, Apply, and confirmation timeout lifecycle.
- Steps: Extract staged-state mutation and apply transaction ownership into `SettingsDraftLifecycle.qml`; add contract coverage; run contract, live, and one-minute soak suites; restart Orbit and inspect service journal.
- Expected: Draft edits, cancel/reset, ten-second apply confirmation timeout, apply process, and commit status retain existing behavior through the stable `SettingsModel.qml` API.
- Actual: Contract passed 30/30, live 34/34, and soak 10/10. The service loaded the new component without new Orbit QML errors; no manual or visual gate is required for this ownership-preserving refactor.
- Result: PASS
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T16-13-41Z-163889`; `/home/josh/.local/state/orbit/tests/2026-08-17T16-13-41Z-163970`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T16-13-42Z-163888`; `journalctl --user -u orbit-shell.service --since '10 seconds ago'`.
- Follow-up issue: None for this item.

### 2026-08-17 - START-006 shutdown confirmation worker rerun
- Environment: Current Hyprland session; `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`; `orbit-shell.service` active; `/usr/bin/zenity` available. No real logout was invoked.
- Surface: Shutdown confirmation guard.
- Steps: Run the deterministic contract and live suites, run the one-minute soak, verify the compositor signature and Orbit service state, and retain the existing disposable fake-command ordering evidence.
- Expected: The confirmation guard remains fail-closed and healthy without initiating session termination during unattended validation.
- Actual: Contract 30/30, live 34/34, and soak 10/10 passed. The signature matched `hyprctl instances` and the service remained active. No destructive action was performed.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T16-17-04Z-191390`; `/home/josh/.local/state/orbit/tests/2026-08-17T16-17-04Z-191423`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T16-17-05Z-191475`.
- Follow-up issue: Complete the attended cancel flow and only perform confirm/logout/re-login with explicit approval through `VQ-20260817-01`.

### 2026-08-17 - START-006 shutdown confirmation worker refresh
- Environment: Current Hyprland session; compositor signature matched `hyprctl instances`; `orbit-shell.service` active; `/usr/bin/zenity` installed.
- Surface: Shutdown confirmation guard.
- Steps: Run syntax/compile checks, contract, live, one-minute soak, and the disposable fake-command ordering fixture. Do not invoke real logout.
- Expected: Confirmation is required before termination; cancel/confirm ordering is correct and the real session remains untouched.
- Actual: Contract 34/34, item-specific live `START-006` passed within 37/38, and soak 10/10. The only live failure was unrelated `START-004` Alt+Tab binding presence. No real termination was invoked.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T16-59-05Z-480469`; `/home/josh/.local/state/orbit/tests/2026-08-17T16-59-08Z-480899`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T16-59-08Z-480908`
- Follow-up issue: Complete attended cancel and, only with explicit approval, confirm/logout/re-login through `VQ-20260817-13`.
### 2026-08-17 - START-006 shutdown confirmation current worker refresh
- Environment: Current Hyprland session; `HYPRLAND_INSTANCE_SIGNATURE` matched `hyprctl instances`; `/usr/bin/zenity` installed; `orbit-shell.service` active. No real logout was attempted.
- Surface: Shutdown confirmation guard.
- Steps: Run shell/Python syntax checks, contract/live/one-minute soak suites, and disposable fake-`zenity` cancel plus missing-`zenity` fixtures.
- Expected: Cancel is a no-op; missing confirmation support fails closed; no unattended check terminates the session.
- Actual: Syntax/Python compilation passed; contract 35/35, live 39/39, and soak 10/10 passed. Cancel returned 0 and logged only `zenity`; missing-`zenity` returned 1 with the fail-closed message. No `loginctl` call, logout, or session mutation occurred.
- Result: MANUAL
- Screenshot or log: `/home/josh/.local/state/orbit/tests/2026-08-17T17-33-32Z-719334`; `/home/josh/.local/state/orbit/tests/2026-08-17T17-33-32Z-719339`; `/home/josh/.local/state/orbit/tests/soak-2026-08-17T17-33-32Z-719341`.
- Follow-up issue: Complete attended cancel and, only with explicit approval, confirm/logout/re-login through `VQ-20260817-16`; never retry a destructive action after an ambiguous result.
