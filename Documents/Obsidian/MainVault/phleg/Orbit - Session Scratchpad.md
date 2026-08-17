---
title: Orbit - Session Scratchpad
type: session-input
status: active
tags: [orbit, observations, scratchpad]
---
# Orbit Session Scratchpad

Use this page for raw observations before they are triaged. Write naturally. Do not spend time assigning IDs, choosing implementation details, or deciding whether something is a bug. A new session can parse these entries with the prompt in [[Orbit - Prompt Repository]].

## How To Use

- Add one observation per entry.
- Include the surface, action, and what seemed wrong or desirable when known.
- Mark an entry `Resolved` only after the behavior is verified and recorded elsewhere.
- Do not delete the original wording when an entry is triaged.
- Put screenshots, logs, timestamps, and reproduction clues directly in the entry.

## Entry Template

```markdown
### OBS-YYYYMMDD-## Short observation
- Status: New
- Surface: startup / dock / XMB / overview / settings / routing / appearance / wallpaper / other
- Observation:
- Trigger or steps:
  1.
- Expected behavior:
- Actual behavior:
- Frequency: once / occasional / repeatable / always / unknown
- Severity impression: blocking / disruptive / cosmetic / idea / unknown
- Evidence: screenshot, log, command output, or session timestamp
- Related issue or test ID:
- Notes:
```

## Untriaged Observations

### OBS-20260817-03 Orbit reload session interruption
- Status: New
- Surface: startup / shell
- Observation: During an Orbit shell reload while testing the top-panel menu, the Wayland connection broke and the session was interrupted. The Orbit service then restarted through systemd.
- Trigger or steps:
  1. Reload `orbit-shell.service` while the top-panel menu investigation was active.
  2. Observe the session and `journalctl --user -u orbit-shell.service`.
- Expected behavior: Orbit reloads without interrupting the compositor session.
- Actual behavior: The journal reported `The Wayland connection broke. Did the Wayland compositor die?`; `orbit-shell.service` exited with status 255 and systemd restarted it. No Orbit QML crash was identified in that event.
- Frequency: once
- Severity impression: disruptive
- Evidence: `journalctl --user -u orbit-shell.service` entries at 2026-08-17 11:29:10; service restart counter 1.
- Related issue or test ID: `ORB-TOP-PANEL-GLOBAL-MENU`; investigate separately as a session/compositor event.
- Notes: Keep this evidence separate from the menu-placement defect. The 11:41:49 recording shows the top-panel application title over tiled terminal windows, but no rendered application-menu popup.

### OBS-20260816-01 Scratchpad ready
- Status: Resolved
- Surface: tracking
- Observation: A dedicated freeform input area is available for future sessions.
- Expected behavior: New observations can be parsed into issues, features, tests, or documentation work without relying on conversation history.
- Actual behavior: This scratchpad and [[Orbit - Prompt Repository]] now define the workflow.
- Evidence: `Orbit - Prompt Repository.md`

### OBS-20260816-02 Missing Icon for Settings
- Status: New
- Surface: dock
- Observation: dock icon for settings is non-existant
- Trigger or steps:
  1. see dock
- Expected behavior: standard settings icon from standard icon repo is used
- Actual behavior: no icon set
- Frequency: always
- Severity impression: cosmetic
- Evidence: ![[Pasted image 20260816224737.png]]
- Classification: Bug
- Orbit priority: Priority 6 (Visual Polish And Feature Work)
- Related issue or test ID: `ORB-DOCK-SETTINGS-ICON`, `UI-008`
- Notes:
### OBS-20260816-03 Dock takes a while to populate icons
- Status: Resolved
- Surface: dock
- Observation: dock icons are blank on login to a new session
- Trigger or steps:
  1. see dock
- Expected behavior: dock icons are populated
- Actual behavior: dock is created at the correct dimensions without icons
- Frequency: always
- Severity impression: disruptive
- Evidence: ![[Pasted image 20260816234028.png]]
- Classification: Bug
- Orbit priority: Priority 1 (State And Lifecycle)
- Related issue or test ID: `ORB-DOCK-ICON-STARTUP`, `START-005`
- Notes:

### OBS-20260817-01 App workspace change focused monitor window spawn

- Status: New
- Surface: routing
- Observation: if you launch an application on HDMI-A-1 and then move mouse to DP-1, by the time the window spawns, it spawns on DP-1
- Trigger or steps:
  1. Open an app from dock on HDMI-A-1
  2. Move mouse to DP-1
- Expected behavior: Application spawns on HDMI-A-1
- Actual behavior: Application SPawns on DP-1
- Frequency: repeatable
- Severity impression: disruptive
- Evidence:
- Classification: Bug
- Orbit priority: Priority 3 (Launch And Routing)
- Related issue or test ID: `ORB-APP-FOCUS-RACE`, `APP-007`
- Notes:

### OBS-20260817-01 dock magnification behaviour

- Canonical observation ID: `OBS-20260817-02` (source heading duplicates `OBS-20260817-01` above)
- Status: New
- Surface: dock
- Observation: approaching dock from boundaries does not magnify the same was as navigating around the dock
- Trigger or steps:
  1. slowly move mouse from side of dock into dock focus area
- Expected behavior: magnification mimics the magnification of icons inside the dock
- Actual behavior: magnification jumps instantly to its highest point instead of slowly magnifying
- Frequency: repeatable
- Severity impression: cosmetic
- Evidence: ![[Video_2026-08-17_10-27-45.mp4]]
- Classification: Bug
- Orbit priority: Priority 6 (Visual Polish And Feature Work)
- Related issue or test ID: `ORB-DOCK-MAGNIFICATION-EDGE`, `UI-009`
- Notes:

### OBS-20260817-04 Dock-launched XMB does not accept keyboard input
- Status: Resolved in implementation; attended validation pending
- Surface: XMB
- Observation: The XMB opened from the dock does not appear to grab keyboard focus; typing and all tested keyboard input are ignored. The same XMB opened with the keybind focuses correctly.
- Trigger or steps:
  1. Open the XMB using the dock launcher.
  2. Type into the launcher or use keyboard navigation.
  3. Compare with opening the XMB using the keybind.
- Expected behavior: The dock-launched XMB accepts keyboard input immediately and behaves like the keybind-launched XMB.
- Actual behavior: The dock-launched XMB accepts no keyboard input. The keybind-launched XMB focuses appropriately.
- Frequency: repeatable
- Severity impression: disruptive
- Evidence: `/home/josh/Videos/ScreenCap/recordings/Video_2026-08-17_12-22-22.mp4`
- Related issue or test ID: `ORB-XMB-DOCK-FOCUS`, `UI-018`
- Notes: The failure is specific to the dock-launch path based on the current comparison.

### OBS-20260817-05 XMB category click does not update the highlighted category
- Status: New
- Surface: XMB
- Observation: Clicking an XMB category icon changes the result list but does not change which category appears highlighted.
- Trigger or steps:
  1. Open the XMB using the keybind.
  2. Click a category icon.
  3. Compare the result list with the visually highlighted category.
- Expected behavior: Clicking a category icon updates both the result list and the highlighted category.
- Actual behavior: The result list updates to the clicked category, but the category highlight remains unchanged. Keyboard category switching works.
- Frequency: repeatable
- Severity impression: disruptive
- Evidence: `/home/josh/Videos/ScreenCap/recordings/Video_2026-08-17_12-22-22.mp4`
- Related issue or test ID:
- Notes: This was observed with the keybind-launched XMB; keyboard category switching was functional in that path.

### OBS-20260817-06 Close action does not close applications from dock or top panel
- Status: Resolved
- Surface: dock / top panel
- Observation: The `Close` menu item does not close the selected application window from either the dock menu or the top-panel application menu.
- Trigger or steps:
  1. Open an application menu from the dock or top panel.
  2. Select `Close` for an application window.
  3. Repeat with multiple applications.
- Expected behavior: The selected application window closes.
- Actual behavior: `Close` has no effect. The adjacent `Force quit` action works.
- Frequency: always
- Severity impression: disruptive
- Evidence:
- Related issue or test ID: `ORB-APP-CLOSE-DISPATCH`, `UI-019`
- Notes: Reproduced across multiple applications and both menu surfaces.

### OBS-20260817-07 Panel right-click menu is positioned beside the application name
- Status: New
- Surface: top panel
- Observation: Right-click menus in the panel are positioned beside the application name instead of below it.
- Trigger or steps:
  1. Open the panel application menu with a right-click.
  2. Observe the position of the menu relative to the application name.
- Expected behavior: The right-click menu appears below the application name in the panel.
- Actual behavior: The menu populates next to the application name.
- Frequency: always
- Severity impression: disruptive
- Evidence: `/home/josh/Videos/ScreenCap/recordings/Video_2026-08-17_12-43-58.mp4`
- Related issue or test ID:
- Notes:

### OBS-20260817-08 System-tray highlight exposes application class
- Status: New
- Surface: top panel / system tray
- Observation: Highlighting a system-tray application in the top panel displays the application's class.
- Trigger or steps:
  1. Highlight a system-tray application in the top panel.
  2. Observe the text or identifying information shown for the highlighted item.
- Expected behavior: Highlighting a system-tray application does not expose its application class.
- Actual behavior: The application's class is shown.
- Frequency: always
- Severity impression: cosmetic
- Evidence: `/home/josh/Videos/ScreenCap/recordings/Video_2026-08-17_12-49-17.mp4`
- Related issue or test ID:
- Notes: Reproduced every time the system-tray application is highlighted.

### OBS-20260817-09 Global menu is not formatted as a macOS-style top-bar menu
- Status: New
- Surface: top panel / global menu
- Observation: The basic implementation of global menus does not mimic a macOS-style menu across the top bar.
- Trigger or steps:
  1. Focus an application that supports a global menu.
  2. Use the current global-menu implementation; currently, only XWayland applications are supported.
  3. Click the application name in the top bar.
- Expected behavior: The top bar presents a standard macOS-style menu beginning with `File`, followed by `Edit`, then any other groups exposed by the applicable global-menu specification.
- Actual behavior: Clicking the application name opens a menu populated with all global-menu entries rather than presenting the entries in standard top-bar menu groups.
- Frequency: always
- Severity impression: cosmetic
- Evidence: None available at this time.
- Related issue or test ID:
- Notes: This records the desired completed formatting; no implementation cause is inferred.

### OBS-20260817-10 Application launch passes `%U` as a literal path
- Status: New
- Surface: application launch
- Observation: Opening Nautilus from Orbit produces an error popup stating `could not open /home/josh/%U`. Zen produces a similar error, indicating that application launching is affected beyond Nautilus.
- Trigger or steps:
  1. Launch Nautilus from Orbit.
  2. Observe the resulting error popup.
  3. Launch Zen and observe its launch result.
- Expected behavior: Nautilus and Zen launch normally without treating the desktop-entry `%U` placeholder as a literal path.
- Actual behavior: Nautilus shows an error popup for `/home/josh/%U`; Zen shows a similar error.
- Frequency: repeatable
- Severity impression: disruptive
- Evidence: None available at this time.
- Related issue or test ID:
- Notes: The issue appears to affect application launch handling generally; no implementation cause is inferred.

### OBS-20260817-11 Dock right-click menu disrupts dock animation
- Status: New
- Surface: dock
- Observation: Right-clicking an application in the dock causes the dock to bug out during its animation and appear to jump around. The menu itself appears directly above the dock, which is the correct general placement, but it is not centered on the clicked application icon.
- Trigger or steps:
  1. Right-click an application icon in the dock.
  2. Observe the dock animation and the menu position.
- Expected behavior: The menu appears directly above and centered on the clicked application icon, while the dock animation remains stable.
- Actual behavior: The dock does not relocate cleanly and bugs out during the animation; the menu is not centered on the clicked icon.
- Frequency: always
- Severity impression: cosmetic
- Evidence: `/home/josh/Videos/ScreenCap/recordings/Video_2026-08-17_14-40-17.mp4`
- Related issue or test ID:
- Notes: Menu placement above the dock is generally correct; the observed defects are centering and animation stability.

### OBS-20260817-12 Right-click menus have no connected opening animation
- Status: New
- Surface: dock / top panel / context menus
- Observation: Orbit right-click menus are not animated and do not visually feel connected to the component from which they spawned.
- Trigger or steps:
  1. Right-click an Orbit component that provides a context menu.
  2. Observe the menu opening and closing.
- Expected behavior: Every right-click menu uses an animation that makes the menu feel visually connected to the component that spawned it.
- Actual behavior: Right-click menus appear without a connecting opening or closing animation.
- Frequency: unknown
- Severity impression: cosmetic
- Evidence: None available at this time.
- Related issue or test ID:
- Notes: The desired motion style remains intentionally open; the requirement is visual continuity with the originating component.

### OBS-20260817-13 Missing application icons use a black and purple fallback
- Status: New
- Surface: launcher / dock
- Observation: Applications without an application icon use a black and purple square fallback, including the AppImage installer. A proper fallback icon should instead be a question mark. The behavior may be related to Qt, but that is unverified.
- Trigger or steps:
  1. Open the launcher or dock containing an application without a usable application icon.
  2. Observe the icon rendered for that application.
- Expected behavior: Applications without an application icon display a clear question-mark fallback icon.
- Actual behavior: The application displays a black and purple square.
- Frequency: repeatable
- Severity impression: cosmetic
- Evidence: `/home/josh/Videos/ScreenCap/recordings/Video_2026-08-17_16-21-53.mp4`
- Related issue or test ID:
- Notes: The fallback should apply to all applications lacking an application icon, not only the AppImage installer. The possible Qt relationship is recorded as an unverified observation, not a root-cause assignment.

### OBS-20260817-14 GPU screen recordings produce oversized files
- Status: New
- Surface: screen recording / GPU recorder
- Observation: Recordings produced by the GPU screen recorder are massive and need a way to reduce their transcoded file size.
- Trigger or steps:
  1. Create a recording with the GPU screen recorder.
  2. Inspect the resulting recording size.
- Expected behavior: Recordings can be transcoded to a substantially smaller file size while retaining an appropriate level of quality.
- Actual behavior: GPU screen-recording outputs are excessively large; the available size-reduction workflow is insufficient or absent.
- Frequency: unknown
- Severity impression: unknown
- Evidence: None available at this time.
- Related issue or test ID:
- Notes: Settings and controls for this behavior are recorded separately as `DES-20260817-24`.

### OBS-20260817-15 Screenshot keybind dismisses the launcher
- Status: New
- Surface: screenshot / XMB launcher
- Observation: Triggering the screenshot keybind while the launcher is visible dismisses the launcher instead of capturing the launcher state.
- Trigger or steps:
  1. Open the XMB launcher.
  2. Trigger the screenshot keybind.
  3. Observe the launcher and the resulting screenshot behavior.
- Expected behavior: The screenshot keybind captures the visible launcher without dismissing it.
- Actual behavior: Triggering the keybind dismisses the launcher, preventing a screenshot of the launcher state.
- Frequency: unknown
- Severity impression: disruptive
- Evidence: None available at this time.
- Related issue or test ID:
- Notes: This makes launcher issues harder to document because a video recording is required instead of a screenshot.

### OBS-20260817-16 Quickshell widget scrolling is too slow
- Status: New
- Surface: XMB / settings
- Observation: Scrolling inside Quickshell widgets is slow. The issue is observed in the XMB and Settings, which are currently the only widgets with scrolling functionality.
- Trigger or steps:
  1. Open the XMB or Settings.
  2. Scroll within the available scrollable content.
  3. Observe the scroll movement and response speed.
- Expected behavior: Scrollable Quickshell content responds at a usable, natural scroll speed.
- Actual behavior: Scrolling moves too slowly.
- Frequency: unknown
- Severity impression: disruptive
- Evidence: None available at this time.
- Related issue or test ID:
- Notes: No other Quickshell widgets with scrolling functionality are currently available for comparison.

### OBS-20260817-17 Final visible XMB category is fully transparent
- Status: New
- Surface: XMB / launcher appearance
- Observation: The last visible category in the XMB is completely transparent, creating a discontinuity in the category blur and opacity treatment.
- Trigger or steps:
  1. Open the XMB with enough categories visible to show the final visible category.
  2. Observe the opacity and blur treatment across the visible category stack.
- Expected behavior: The final visible category should initially match the current opacity of the second-to-last XMB category. The transparency and blur values of the remaining categories should then be adjusted to create a seamless blur across the full visible category stack.
- Actual behavior: The final visible category is fully transparent instead of continuing the opacity and blur progression.
- Frequency: always
- Severity impression: cosmetic
- Evidence: Image 1 provided in the session.
- Related issue or test ID:
- Notes: The requested target is a continuous visual transition, not simply making the final category opaque.

### OBS-20260817-18 Top panel is above workspace animations
- Status: New
- Surface: top panel / workspace animations
- Observation: The top panel is rendered above workspace animations, even though it should sit behind everything except the wallpaper.
- Trigger or steps:
  1. Trigger a workspace animation.
  2. Observe the top panel's layering relative to the animation.
- Expected behavior: The top panel is behind all surfaces and animations other than the wallpaper.
- Actual behavior: The top panel remains above the workspace animations.
- Frequency: always
- Severity impression: cosmetic
- Evidence: `/home/josh/Videos/ScreenCap/recordings/Video_2026-08-17_18-04-44.mp4`
- Related issue or test ID:
- Notes:

## Desired Behaviors

Use this section for behavior that is not currently broken but should become an explicit product requirement.

### DES-YYYYMMDD-## Short desired behavior
- Status: New
- Surface:
- Desired behavior:
- Why it matters:
- Example flow:
- Acceptance condition:
- Related documentation:

### DES-20260817-02 top panel and permanent visual indicator of current status
- Status: In progress
- Surface: new
- Desired behavior: a top panel with a magnifying glass icon to launch the xmb launcher to the left, current time in the center, and sys tray with custom icons on the right (icons should be populated with nerd font glyphs, they should be user overrideable but if we can use desktop files to pick a suitable initial icon, we should). background should be non existent so hyprglass does not paint transparency and blur effects
- Why it matters: parity to noctalia
- Example flow:
- Acceptance condition: panel exists.
- Related documentation: [[Orbit - Test Matrix]] (`UI-010`), [[Orbit - Visual Validation Log]], [[Orbit - Refactor Backlog]]

### DES-20260817-03 lower opacity to 30% for background surfaces in the orbit shell that are drawn
- Status: New
- Surface: dock, xmb, settings
- Desired behavior: default orbit panels (with the exception of the top bar) should have their main surface opacity lowered to 30% in a way that will allow hyprglass to affect it
- Why it matters: parity to noctalia
- Example flow:
- Acceptance condition: transparency is dropped for dock, xmb and panel surfaces in a way that triggers hyprglass
- Related documentation:

### DES-20260817-04 global application menus on Orbit panels
- Status: New
- Surface: top panels
- Desired behavior: Both Orbit top panels expose a global application menu for the application associated with the relevant workspace. On the focused monitor, use the currently focused application on the current workspace. On a non-focused monitor, use the last focused application on that monitor's current workspace. Resolve the menu title from the associated desktop file using Orbit's desktop-file-to-window-class tracking; if no desktop file is available, use the window class suffix after the final period, such as `wezterm` for `org.wezfurlong.wezterm`.
- Why it matters: Supercedes Noctalia's global-menu behavior while preserving a stable application identity across focus and monitor changes.
- Example flow: Focus a WezTerm window on the current workspace and see its desktop-file title and application menu in the top panel. Move focus to another monitor and see that monitor's last-focused workspace application remain represented until a new application is focused there. If no desktop identity resolves, show the final window-class component as the menu title.
- Acceptance condition: Each panel always presents the resolved application title when a qualifying application exists; the global menu entries activate the associated application's menu protocol; focus changes update the focused-monitor menu and non-focused panels retain the last-focused application for their current workspace; unresolved identities use the final window-class component; no qualifying application produces an explicit empty/disabled state.
- Classification: Feature
- Orbit priority: Priority 6 (Visual Polish And Feature Work)
- Related documentation: [[Orbit - Architecture]], [[Orbit - Test Matrix]] (`UI-011`), [[Orbit - Refactor Backlog]]

### DES-20260817-05 expanded All launcher category
- Status: New
- Surface: XMB
- Desired behavior: Rename the current `All` category to `All Apps`. Add a new `All` category that includes all applications, settings exposed by the Settings app, and local files. When results are close matches, applications have highest priority, followed by settings, then files. Show all exposed Settings entries in their own adjacent column. Place the `Settings` category immediately to the left of `All`, and select `All` by default whenever the launcher opens.
- Why it matters: Provide one useful default launcher view while keeping settings discoverable and preserving distinct application results.
- Example flow:
  1. Launch the XMB.
  2. See the `All` category selected by default.
  3. Review application, Settings, and local-file results, including a separate Settings column.
- Acceptance condition: The launcher opens on `All`; `Settings` is immediately to its left; the former `All` category is available as `All Apps`; `All` exposes applications, Settings entries, and local files with application-over-settings-over-files priority for close matches; and Settings entries are also listed in their own column.
- Related documentation:
- Notes: Recorded from the user's requested launcher expansion; implementation and source-of-truth boundaries remain to be defined.

### DES-20260817-06 non-wrapping launcher category navigation
- Status: New
- Surface: XMB
- Desired behavior: Changing launcher categories must stop at the first and last category instead of wrapping around.
- Why it matters: Category navigation should have predictable boundaries, especially with the new `Settings` and `All` ordering.
- Example flow:
  1. Launch the XMB and observe `All` selected by default.
  2. Navigate left or right through the categories.
  3. Continue navigating beyond either edge.
- Acceptance condition: Navigation reaches the first and last categories and remains there when moving beyond either boundary; it never jumps from one edge to the opposite edge.
- Related documentation:
- Notes: Recorded as a separate behavior so category ordering and navigation bounds can be validated independently.

### DES-20260817-07 spatial workspace Alt+Tab overview
- Status: New
- Surface: overview
- Desired behavior: Alt+Tab should present the windows on the current workspace as an animated view, shrinking them to approximately 66% of their normal size. Workspaces above and below the current workspace should be shown physically above and below with the same treatment, so moving through Alt+Tab feels like navigating through the workspace stack.
- Why it matters: Make workspace navigation spatial and visually understandable rather than presenting Alt+Tab as an isolated window switcher.
- Example flow:
  1. Press Alt+Tab on a workspace with open windows.
  2. Observe the current workspace windows animate to approximately 66% scale.
  3. Observe neighboring workspaces positioned above and below with their windows similarly represented.
  4. Continue Alt+Tab navigation through the workspace view.
- Acceptance condition: Opening Alt+Tab produces a stable spatial overview centered on the current workspace; current-workspace windows animate to approximately 66% scale; adjacent workspaces appear above and below with equivalent scaled window representations; and navigation through the view visibly corresponds to moving between workspaces.
- Related documentation:
- Notes: Recorded as a desired visual and interaction behavior; exact workspace range, selection model, and animation timing remain to be defined.

### DES-20260817-08 expanded shader wallpaper styles
- Status: New
- Surface: wallpaper
- Desired behavior: Expand the wallpaper system to offer multiple visual styles, preferably by integrating pre-existing shader wallpapers created by others where their licensing and technical compatibility permit it.
- Why it matters: Provide more wallpaper variety without limiting Orbit to a single visual treatment.
- Example flow:
  1. Open the wallpaper configuration or settings surface.
  2. Choose among multiple available shader wallpaper styles.
  3. Apply a selected style and see it render as the desktop wallpaper.
- Acceptance condition: Orbit exposes multiple selectable shader wallpaper styles, including suitable pre-existing shaders where licensing allows, and the selected style can be applied without disrupting the session.
- Related documentation:
- Notes: Source provenance, license compatibility, packaging, and the wallpaper selection/persistence contract remain to be defined.

### DES-20260817-09 configurable audio-reactive wallpapers
- Status: New
- Surface: wallpaper / audio
- Desired behavior: Support optional audio reactivity for shader wallpapers, with a user-configurable setting to enable or disable the reaction.
- Why it matters: Allow wallpapers to respond dynamically to the user's audio environment while preserving a non-reactive mode.
- Example flow:
  1. Select a shader wallpaper that supports audio reactivity.
  2. Enable or disable audio reactivity in the wallpaper configuration.
  3. Play audio and observe the wallpaper only when the option is enabled.
- Acceptance condition: Audio reactivity is configurable on or off, applies only when enabled, and disabling it prevents audio input from changing the wallpaper.
- Related documentation:
- Notes: Audio source, permissions, performance budget, supported wallpaper styles, and persistence behavior remain to be defined.

### DES-20260817-10 Quickshell GPU screen-recorder display picker
- Status: New
- Surface: other / screen recording
- Desired behavior: Migrate the GPU screen recorder's launch picker from Zenity to a Quickshell overlay while preserving the existing behavior. Instead of listing recording devices, the overlay should show a visual representation of each screen, using a live feed or static screenshot of that screen's current contents, so the user can choose the intended display.
- Why it matters: Provide a clearer, Orbit-native display-selection experience without changing the recorder's established launch behavior.
- Example flow:
  1. Launch the GPU screen recorder.
  2. See a Quickshell overlay containing one visual preview for each connected screen.
  3. Select the screen to record, or cancel using the existing interaction semantics.
  4. Confirm that recording starts with the selected screen using the existing recorder flow.
- Acceptance condition: The Zenity picker is replaced by a Quickshell overlay; each connected screen has a distinguishable live or static preview; selecting a preview records the corresponding screen; and existing selection, cancellation, and error behavior is preserved.
- Related documentation:
- Notes: Preview source, refresh rate, privacy handling, monitor hotplug behavior, and the exact existing Zenity interaction contract remain to be defined.

### DES-20260817-11 screen-recording monitor edge indication
- Status: New
- Surface: screen recording / monitor
- Desired behavior: While a monitor is being recorded, show a subtle visual indication around that monitor's edge so the user can tell which display is currently captured.
- Why it matters: Provide clear recording awareness without obstructing the recorded content or creating a distracting overlay.
- Example flow:
  1. Start recording a selected monitor.
  2. Observe a subtle indication around that monitor's screen edge.
  3. Stop recording and confirm the indication disappears.
- Acceptance condition: The indication appears only around the monitor currently being recorded, remains subtle and non-obstructive, and is removed when recording stops or fails.
- Related documentation:
- Notes: Indicator style, compositor-layer behavior, multi-monitor handling, and whether the indicator is included in the captured output remain to be defined.

### DES-20260817-12 configurable control-center widget
- Status: New
- Surface: settings / control center
- Desired behavior: Develop a Control Center-style widget that provides user-configurable access to core system features.
- Why it matters: Centralize frequently used system controls in an Orbit-native, customizable surface.
- Example flow:
  1. Open the Control Center widget.
  2. View the configured core feature controls.
  3. Customize which core features are shown and/or their arrangement.
  4. Use the controls directly from the widget.
- Acceptance condition: Orbit provides a Control Center-style widget with a documented set of core controls and a persisted user configuration for the controls exposed by the widget.
- Related documentation:
- Notes: The initial core-feature set, layout, invocation method, persistence schema, permissions, and live-apply behavior remain to be defined.

### DES-20260817-13 clock calendar and event widget
- Status: New
- Surface: top panel / calendar
- Desired behavior: Clicking the time in the top panel should open a calendar and time widget. The widget should also read and display calendar events from configured calendar applications.
- Why it matters: Make the panel clock a useful time-and-schedule entry point while integrating with the user's existing calendar tools.
- Example flow:
  1. Click the time in the top panel.
  2. View the calendar and current time in the widget.
  3. View events retrieved from configured calendar applications.
- Acceptance condition: Clicking the time opens the calendar/time widget, and events from configured calendar applications are read and displayed with appropriate dates and times without requiring an unrelated application window to be opened.
- Related documentation:
- Notes: Calendar provider discovery, supported applications/protocols, refresh behavior, event privacy, permissions, and interaction capabilities remain to be defined.

### DES-20260817-14 Apple-style system menu
- Status: New
- Surface: top panel / session lifecycle / settings
- Desired behavior: Add a top-panel button with functionality similar to the macOS Apple menu. It should provide `About This Computer`, `System Settings`, a configurable `Task Manager`, `Lock`, `Log Out`, `Shut Down`, and `Restart` actions.
- Why it matters: Provide a single, discoverable entry point for system information, settings, session controls, and common administration tasks.
- Example flow:
  1. Open the system menu button in the top panel.
  2. Choose `About This Computer` to launch `fastfetch` in a floating terminal sized only as large as needed to show the relevant information.
  3. Choose `System Settings` to open Orbit Settings.
  4. Choose `Task Manager` to launch the application configured by the user in Orbit Settings.
  5. Choose `Lock`, `Log Out`, `Shut Down`, or `Restart` to invoke the corresponding session action.
- Acceptance condition: The top-panel system menu exposes all listed actions; `About This Computer` opens the configured floating terminal presentation; `System Settings` opens Orbit Settings; `Task Manager` uses a user-configurable associated application; and lifecycle actions invoke the correct commands with existing safety and confirmation protections preserved.
- Related documentation:
- Notes: Menu icon and placement, fastfetch terminal choice and sizing, task-manager configuration schema, command implementations, confirmation behavior, and privilege boundaries remain to be defined.

### DES-20260817-15 left-aligned top-panel menu controls
- Status: New
- Surface: top panel
- Desired behavior: Move the application menu button out of its centered padded capsule and align it to the left side of the top panel. Place it with sensible spacing relative to the Apple-style system menu, which should occupy the far-left position.
- Why it matters: Establish a coherent left-side hierarchy for system and application controls instead of centering the application control in an isolated capsule.
- Example flow:
  1. View the top panel.
  2. See the system menu button at the far left.
  3. See the application menu button left-aligned beside it with intentional spacing.
- Acceptance condition: The system menu is the far-left top-panel control; the application menu is left-aligned rather than center-aligned; the existing capsule padding does not force it into the panel center; and spacing between the two controls is visually consistent.
- Related documentation:
- Notes: Exact spacing, capsule styling, behavior when no application is selected, and per-monitor layout remain to be defined.

### DES-20260817-16 per-monitor vertical workspace indicators
- Status: New
- Surface: top panel / workspaces
- Desired behavior: Add workspace indicators to each monitor. Following the vertical monitor format, display the open workspaces on that monitor as a vertically aligned series of dots, with the current workspace visibly distinguished. Clicking a dot should change to the corresponding workspace on that monitor.
- Why it matters: Make per-monitor workspace state visible and directly navigable in a way that matches the physical vertical monitor arrangement.
- Example flow:
  1. View the top panel on each monitor.
  2. See a vertical series of dots representing that monitor's open workspaces.
  3. Identify the current workspace from its distinct dot state.
  4. Click another dot and switch to that workspace on the selected monitor.
- Acceptance condition: Every monitor displays its own vertically aligned workspace indicators; dots represent the open workspaces associated with that monitor; the current workspace is distinguishable; and clicking an indicator changes workspace on the intended monitor without affecting unrelated monitor state.
- Related documentation:
- Notes: A search of the current Session Scratchpad found no duplicate entry for per-monitor workspace dots or click-to-switch indicators. Exact dot styling, empty-workspace representation, dynamic workspace creation/removal, and keyboard/accessibility behavior remain to be defined.

### DES-20260817-17 transparent fullscreen XMB presentation
- Status: New
- Surface: XMB / overview
- Desired behavior: The fullscreen XMB launcher should temporarily disperse or remove open windows from view, then render the XMB scaled up to occupy most of the screen while leaving the wallpaper visible through the surrounding area. Only in this fullscreen presentation should text and icon shadows be added to preserve readability against arbitrary wallpaper.
- Why it matters: Create an immersive launcher view that uses the wallpaper as its backdrop without sacrificing legibility.
- Example flow:
  1. Open the fullscreen XMB launcher.
  2. Observe that open windows are dispersed or hidden from the launcher view.
  3. Observe the XMB enlarged to fit most of the screen with no opaque backdrop.
  4. Confirm that the wallpaper remains visible around the launcher.
  5. Confirm that text and icon shadows are present in this view only.
- Acceptance condition: Fullscreen XMB activation removes open windows from the presented view, scales the launcher to occupy most of the screen, leaves the wallpaper visible without an opaque backdrop, and applies readability shadows only during this fullscreen presentation; closing the XMB restores the normal window view and styling.
- Related documentation:
- Notes: The exact window dispersal mechanism, scale bounds, animation, backdrop alpha, shadow style, and distinction from the dock-launched XMB remain to be defined.

### DES-20260817-18 application window information action
- Status: New
- Surface: top panel / global menu
- Desired behavior: Add a `View App/Window Info` action to the standard menu bar shown under an application's name. The action should open a window containing information about the selected application window gathered from `hyprctl`.
- Why it matters: Make window and application state inspectable from the Orbit menu without requiring a separate terminal command.
- Example flow:
  1. Focus an application window with a supported global menu.
  2. Open the application's standard menu bar under its name.
  3. Select `View App/Window Info`.
  4. View and copy the resulting window information.
- Acceptance condition: The action opens a readable window-specific information view populated from `hyprctl`, and the information can be copied and pasted.
- Related documentation:
- Notes: The exact `hyprctl` command and fields remain to be defined.

### DES-20260817-19 Hyprland system information action
- Status: New
- Surface: top panel / system menu
- Desired behavior: Add a system-menu action similar to `View App/Window Info` that opens a readable, copyable view of broader Hyprland and session information gathered from `hyprctl`.
- Why it matters: Provide an Orbit-native way to inspect and share compositor and session state.
- Example flow:
  1. Open the Orbit system menu.
  2. Select the Hyprland information action.
  3. View and copy the resulting compositor and session information.
- Acceptance condition: The system-menu action opens a readable Hyprland information view populated from `hyprctl`, and the information can be copied and pasted.
- Related documentation:
- Notes: The exact `hyprctl` command and fields remain to be defined.

### DES-20260817-20 unified configurable Hyprland and Orbit borders
- Status: New
- Surface: appearance / settings
- Desired behavior: Align all drawn borders between Hyprland and Orbit, with separate configuration options for active borders, inactive borders, and Orbit shell components. Active and inactive borders should support configurable width/size, color, and border type. Border type should offer `line` for a standard drawn border and `glow` for a subtle glow, with color selection exposed through a picker using the colors defined by the relevant theme/options.
- Why it matters: Keep Hyprland window borders and Orbit shell borders visually consistent while allowing users to configure active, inactive, and shell-component treatments independently.
- Example flow:
  1. Open Orbit appearance settings.
  2. Choose active, inactive, or shell-component border settings.
  3. Adjust width/size and choose a color from the defined color palette.
  4. Select `line` or `glow` as the border type.
  5. Observe the corresponding Hyprland and Orbit borders update consistently.
- Acceptance condition: Orbit exposes separate active, inactive, and shell-component border configuration; active and inactive borders support width/size, color-picker, and `line`/`glow` type options; and the selected settings produce aligned border rendering across Hyprland and Orbit.
- Related documentation:
- Notes: The exact ownership of settings, theme color schema, glow rendering parameters, and live-apply/persistence behavior remain to be defined.

### DES-20260817-21 light/dark/automatic appearance modes
- Status: New
- Surface: appearance / settings
- Desired behavior: Orbit should support `Light`, `Dark`, and `Auto` appearance choices instead of assuming dark mode exclusively. In `Auto` mode, users should select two times: one time to switch from light to dark and one time to switch from dark to light.
- Why it matters: Allow Orbit and the surrounding Hyprland desktop to support light environments and predictable scheduled theme changes.
- Example flow:
  1. Open appearance settings.
  2. Choose `Light`, `Dark`, or `Auto`.
  3. If `Auto` is selected, configure the light-to-dark and dark-to-light times.
  4. Observe the configured appearance apply at the selected times.
- Acceptance condition: Users can select `Light`, `Dark`, or `Auto`; Light and Dark apply the corresponding appearance directly; and Auto switches between them at two user-configured times.
- Related documentation:
- Notes: The scope of synchronized Hyprland settings, persistence, timezone handling, and behavior when the system is asleep at a switch time remain to be defined.

### DES-20260817-22 configurable follow-mouse focus mode
- Status: New
- Surface: settings / focus
- Desired behavior: Add follow-mouse focus settings to the Orbit settings panel as a dropdown menu. The dropdown should expose the available Hyprland follow-mouse modes and provide a short description for each mode.
- Why it matters: Make focus behavior discoverable and configurable without editing Hyprland configuration manually.
- Example flow:
  1. Open the Orbit settings panel.
  2. Open the follow-mouse focus dropdown.
  3. Review the short descriptions of the available modes.
  4. Select the desired mode.
- Acceptance condition: The settings panel provides a dropdown containing the supported follow-mouse modes, each with a concise description, and selecting a mode applies and persists the corresponding focus behavior.
- Related documentation:
- Notes: The exact supported mode list and live-apply behavior should follow the current Hyprland contract.

### DES-20260817-23 Control Center caffeinate toggle
- Status: New
- Surface: control center / session lifecycle
- Desired behavior: Add a `Caffeinate` toggle to the Control Center. When activated, it should inhibit system sleep until the toggle is deactivated.
- Why it matters: Provide a quick, discoverable way to prevent sleep during long-running tasks without changing persistent power settings.
- Example flow:
  1. Open the Control Center.
  2. Activate the `Caffeinate` toggle.
  3. Leave the session idle and confirm sleep is inhibited.
  4. Deactivate the toggle and confirm normal sleep behavior is restored.
- Acceptance condition: The Control Center exposes a clearly indicated Caffeinate toggle; activation inhibits system sleep; deactivation releases the inhibition; and the active state remains visible while enabled.
- Related documentation:
- Notes: The inhibition mechanism, lock-screen behavior, suspend/hibernate scope, and behavior across Orbit restarts remain to be defined.

### DES-20260817-24 configurable GPU recorder transcoding
- Status: New
- Surface: settings / GPU recorder / screen recording
- Desired behavior: Add a GPU Recorder section to the settings menu. It should expose basic FFmpeg transcoding options, a `Transcode recordings` toggle, and customization for Orbit's existing screen-recording identifier feature. Users should also be able to provide a custom FFmpeg command when the basic options are insufficient.
- Why it matters: Reduce recording file sizes through an accessible workflow while supporting advanced users who need control beyond the standard transcoding presets.
- Example flow:
  1. Open the GPU Recorder settings.
  2. Enable or disable `Transcode recordings`.
  3. Configure the basic FFmpeg transcode options and screen-recording identifier behavior.
  4. Optionally provide a custom FFmpeg command.
  5. Create a recording and confirm the configured transcode workflow is used.
- Acceptance condition: GPU Recorder settings include a `Transcode recordings` toggle, a curated basic subset of FFmpeg options, customization for the screen-recording identifier, and an advanced custom-command option; recordings follow the selected configuration and can be reduced in size.
- Related documentation:
- Notes: The basic FFmpeg option set, custom-command variable/placeholder contract, validation, security restrictions, and identifier customization fields remain to be defined.

### DES-20260817-25 configurable widget workspace
- Status: New
- Surface: persistent workspace / widgets / settings
- Desired behavior: The blank persistent workspace should support a selection of user-configurable widgets, such as time, currently playing song, calendar, and weather. Orbit should use an existing widget system or a project with a substantial repository of designed widgets where practical; it should not require rewriting those widgets or explicitly require Quickshell as the implementation. Users should be able to edit and arrange the workspace graphically, with as many widget settings as practical exposed through the Orbit settings menu.
- Why it matters: Turn the otherwise blank persistent workspace into a useful, customizable information surface while leveraging existing widget ecosystem work.
- Example flow:
  1. Open the persistent workspace customization view.
  2. Browse available widgets such as time, currently playing song, calendar, and weather.
  3. Add, remove, arrange, and configure widgets graphically.
  4. Open Orbit settings to adjust the exposed widget and workspace options.
  5. Return to the persistent workspace and confirm the configured layout remains available.
- Acceptance condition: The persistent workspace can display a user-selected set of widgets; users can configure and arrange them through a graphical interface; widget settings are exposed in Orbit settings where practical; and the implementation may integrate an established widget ecosystem without requiring a rewrite or a Quickshell-specific solution.
- Related documentation:
- Notes: The target widget ecosystem, integration boundary, persistence schema, available widget catalog, isolation/security model, and per-monitor behavior remain to be defined.

### DES-20260817-26 recently used ordering for XMB All
- Status: New
- Surface: XMB / launcher
- Desired behavior: The default ordering of the `All` section in the XMB should prioritize recently used applications.
- Why it matters: Make the default launcher view immediately useful by placing the applications the user most recently used first.
- Example flow:
  1. Launch several applications in sequence.
  2. Open the XMB and select or observe the `All` section.
  3. Confirm that recently used applications appear before less recently used applications.
- Acceptance condition: The `All` section uses a clearly defined recent-use ordering by default, updates as applications are used, and preserves the existing result behavior for applications without recent-use history.
- Related documentation:
- Notes: The recency definition, persistence duration, tie-breaking rules, and interaction with search relevance remain to be defined.

### DES-20260817-27 screenshot overlay excluded from Hyprglass
- Status: New
- Surface: screenshot / Hyprglass integration
- Desired behavior: The screenshot-selection overlay should be excluded from Hyprglass effects while the screenshot keybind captures the visible launcher.
- Why it matters: Keep screenshot controls from altering the launcher appearance or being visually processed by the compositor's glass effects during capture.
- Example flow:
  1. Open the XMB launcher.
  2. Trigger the screenshot keybind.
  3. Confirm the launcher remains visible in the capture.
  4. Confirm the screenshot-selection overlay is ignored by Hyprglass.
- Acceptance condition: The screenshot flow captures the launcher without dismissing it, and the screenshot overlay is excluded from Hyprglass processing.
- Related documentation:
- Notes: The precise overlay surface/layer identity and whether the overlay is included in the final screenshot remain to be defined.

### DES-20260817-28 Settings transparency follows dock and XMB
- Status: New
- Surface: settings / appearance
- Desired behavior: The Settings panel should inherit the transparency behavior and visual treatment used by the dock and XMB.
- Why it matters: Keep Orbit surfaces visually consistent and ensure Settings participates in the same compositor transparency and glass effects.
- Example flow:
  1. Configure or observe the dock and XMB transparency behavior.
  2. Open the Settings panel.
  3. Compare the Settings panel's transparency and compositor treatment with the dock and XMB.
- Acceptance condition: The Settings panel uses the same transparency model as the dock and XMB, responds consistently to the relevant appearance settings, and receives the intended compositor effects.
- Related documentation:
- Notes: The exact shared setting ownership, opacity values, and Hyprglass interaction remain to be defined.

### DES-20260817-29 Settings panel removes unnecessary outer border space
- Status: New
- Surface: settings / layout
- Desired behavior: Remove the unnecessary blank space around the thin border of the Settings panel so the border sits directly around the panel content.
- Why it matters: Make the Settings panel use its space efficiently and keep its visual boundary precise.
- Example flow:
  1. Open the Settings panel.
  2. Observe the space between the content and the thin outer border.
  3. Confirm the content boundary and border are aligned without unnecessary blank padding.
- Acceptance condition: The Settings panel has no unnecessary outer blank space around its thin border, while intentional internal spacing remains intact.
- Related documentation:
- Notes:

### DES-20260817-30 Settings panel top-right close button
- Status: New
- Surface: settings / window controls
- Desired behavior: Add a close button to the top-right corner of the Settings panel.
- Why it matters: Provide an obvious, local way to dismiss Settings without relying on a keybind or external window control.
- Example flow:
  1. Open the Settings panel.
  2. Click the close button in the top-right corner.
  3. Confirm that the Settings panel closes.
- Acceptance condition: A clearly identifiable close button is positioned at the top right of the Settings panel and closes the panel when activated.
- Related documentation:
- Notes: The button's icon, hover state, keyboard accessibility, and animation remain to be defined.

### DES-20260817-31 configurable Orbit sound themes
- Status: New
- Surface: settings / sound / session lifecycle / notifications / XMB
- Desired behavior: Allow users to change the Orbit shell's sound theme. A sound theme should provide a unified set of UI sounds for login and logout, notifications, and XMB navigation. The current login and logout sounds are hardcoded and should become part of the selectable sound-theme system.
- Why it matters: Give the shell a coherent, user-selectable audio identity across session lifecycle events, notifications, and launcher interaction.
- Example flow:
  1. Open Orbit sound settings.
  2. Select a sound theme.
  3. Log in or out, receive a notification, and navigate the XMB.
  4. Confirm that each event uses the selected theme's corresponding sound.
- Acceptance condition: Orbit exposes selectable sound themes that provide coordinated sounds for login, logout, notifications, and XMB navigation; changing the theme updates those sound sources, including the currently hardcoded login/logout sounds.
- Related documentation:
- Notes: No duplicate sound-theme requirement was found in the current Session Scratchpad. The sound-theme package format, preview behavior, missing-sound fallback, volume/mute controls, and licensing/provenance remain to be defined.

### DES-20260816-01 Create a transtion from the dock to XMB to enable them to appear as one cohesive unit
- Status: New
- Surface: XMB/Dock
- Desired behavior: when launching the launcher from the dock, the dock should animate in a way that the user perceives that the dock has now become the XMB
- Why it matters: User Experience
- Example flow: User clicks launcher on dock, dock morphs into xmb, xmb ready to use straight away
- Acceptance condition: User approval that abstract expectation is met
- Classification: Behavior clarification / feature
- Orbit priority: Priority 6 (Visual Polish And Feature Work)
- Related documentation: [[Orbit - Issues and Corrections]] (`ORB-XMB-TRANSITION`, `ORB-XMB-BLANKING`), [[Orbit - Test Matrix]] (`UI-007`), [[Orbit - Refactor Backlog]]
### DES-20260816-03 make orbit surfaces transparent in a way the compositor recognises
- Canonical triage ID: `DES-20260816-05`
- Status: New
- Surface: XMB/Dock
- Desired behavior: surfaces are transparent in a way that matches our GTK styling, which invokes hyprglass effects
- Why it matters: User Experience
- Example flow: N/A
- Acceptance condition: Orbit visually matches GTK styles
- Classification: Behavior clarification / documentation gap
- Orbit priority: Priority 6 (Visual Polish And Feature Work)
- Related documentation: [[Orbit - Issues and Corrections]] (`ORB-SURFACE-TRANSPARENCY`), [[Orbit - Test Matrix]] (`THEME-004`), [[Orbit - Refactor Backlog]]

### DES-20260816-04 keybinds in settings
- Canonical triage ID: `DES-20260816-04`
- Status: New
- Surface: settings
- Desired behavior: add the ability to view and change keybinds in orbit settings
- Why it matters: directly supports overarching goals of a single systemwide settings panel for a hyprland environment
- Example flow: user open settings window and finds the keybind tab. then they should see an easy to read list of existing keybinds. adding keybinds should follow the same process as window rules - abstract specifics for standard keybinds, but add a custom keybind option to write it in full lua
- Acceptance condition:
- Classification: Feature / behavior clarification
- Orbit priority: Priority 4 (Settings)
- Related documentation: [[Orbit - Refactor Backlog]], [[Orbit - Test Matrix]] (`SET-004`); acceptance and persistence contract remain to be defined
- Notes: Original source label duplicates `DES-20260816-03` used by the transparency request; canonical triage ID is `DES-20260816-04`.

### DES-20260817-01 Dock settings in settings panel
- Status: New
- Surface: Settings
- Desired behavior: Allow users to change dock size, magnification scale, opacity, internal and external padding in the
- Why it matters:
- Example flow:
- Acceptance condition:
- Classification: Feature / behavior clarification
- Orbit priority: Priority 4 (Settings)
- Related documentation: [[Orbit - Refactor Backlog]], [[Orbit - Test Matrix]] (`SET-005`); acceptance and persistence contract remain to be defined
## Quirks And Questions

Use this section for things that may be intentional, hardware-specific, or not yet understood. They still need triage.

### Q-YYYYMMDD-## Short quirk
- Status: New
- Context:
- What happens:
- Why it may be intentional:
- What would disambiguate it:
- Evidence:

## Resolved And Archived Entries

Move only the short reference here after the full result has been recorded in the issue tracker, test matrix, visual log, or change log.
