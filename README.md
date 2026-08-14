# CleanShirtUK Dotfiles

Personal Hyprland and Noctalia configuration.

## Dependencies

- Hyprland, Hypridle, and Hyprlock
- Noctalia
- `hyprglass` plugin
- HyprWindowShade plugin, built by `.local/bin/install-hyprwindowshade`
- `bash`, `flock`, `jq`, `socat`, `grim`, `slurp`, `wl-copy`, and `zenity`
- `paplay` or `aplay` for session transition sounds
- LocalSend, installed system-wide from Flathub as `org.localsend.localsend_app`
- GPU Screen Recorder, installed system-wide from Flathub as
  `com.dec05eba.gpu_screen_recorder`
- The separate [`ps3-wave-wallpaper`](https://github.com/CleanShirtUK/ps3-wave-wallpaper) project, running in live-wallpaper-only mode
- GameMode, with `gamemoded` and `gamemoderun` available
- The `adw-gtk3-dark` GTK theme and `kora` icon theme
- Actions For Nautilus `v2.0.1`, installed by
  `.local/bin/install-actions-for-nautilus`

Zen Browser customization is installed with:

```sh
.local/bin/configure-zen
```

The helper discovers Zen's active profile from its profile registries, copies
the tracked `.config/zen/phleg-userChrome.css` override into that profile, and
adds one marker-managed import to `chrome/userChrome.css`. It preserves other
profile CSS and is safe to run repeatedly. The override makes only Zen's
application sidebar transparent; browser content and popup menus remain
opaque.

## Nautilus Actions

Actions For Nautilus adds these top-level Nautilus context-menu actions:

- **Open as Administrator** opens files and directories through GVfs' native
  `admin://` backend and Polkit. It does not run Nautilus as root.
- **Copy Path** copies selected filesystem paths with `wl-copy`.

Install the pinned upstream extension and tracked configuration with:

```sh
.local/bin/install-actions-for-nautilus
```

The installer verifies upstream tag `v2.0.1` against commit
`3b518ac02fe92f8f0a4733e799b0689f505fea95` before installing it for the current
user. Fedora dependencies are `nautilus-python`, `python3-gobject`,
`procps-ng`, and `js-jquery`.

## Zed

The tracked Zed configuration uses the `Noctalia Dark Transparent` theme. Its
title bar, toolbar, tab surface, status bar, and docked panels are transparent
so the wallpaper remains visible, while editor and terminal surfaces use a
4% Noctalia color wash with fully opaque text. The theme is selected in
`.config/zed/settings.json`
and is kept separate from Zed's machine-specific state.

The Hyprland rule for Zed (`dev.zed.Zed`) keeps the client opaque, removes its
compositor shadow, and applies the same 10px rounding used by the desktop.
After deploying the dotfiles, restart Zed or run `zed: reload window` from the
command palette to load the tracked theme.

GTK shadow handling is kept in the tracked `.config/gtk-3.0/shadow-overrides.css`
and `.config/gtk-4.0/shadow-overrides.css` files. They remove GTK-rendered
shadows and shadow gradients so transparent GTK surfaces do not produce box
outlines when Hyprland composites them. The generated Noctalia CSS is not
modified. Hyprland compositor shadows remain configured separately.

The wallpaper project is installed and built by the helper above. Its source
is allow-listed through `.gitignore`; only reviewed configuration files are
tracked.

## PS3 Wallpaper

Install or update the dedicated wallpaper project with:

```sh
.local/bin/dotfiles-install-wallpaper
```

This builds the project in `~/.local/src/ps3-wave-wallpaper`. Hyprland starts
the user service after importing the current Wayland session environment,
renders one continuous shader wallpaper across the configured monitors, and
restarts it after a compositor session change. It runs in live-wallpaper-only
mode: snapshot generation is disabled and the wallpaper starts hidden until
the session-effects service triggers the single startup intro.

The renderer receives transition requests through
`~/.cache/ps3-wave-wallpaper/control`. The session-effects service sends:

- `intro` at graphical-session startup and after unlock
- `exit` when locking or shutting down

These transitions hide the Noctalia bar and dock first. Startup and unlock
intros reveal them again; lock and shutdown exits also blank the configured
special workspaces. Session transitions play the tracked login/logout sounds.
On unlock, the previous workspaces are restored after the wallpaper and shell
reveal has settled.

The renderer writes the current wallpaper background configuration to
`~/.cache/ps3-wave-wallpaper/hyprlock-background.conf`, which is sourced by
Hyprlock. Hyprland also reads that file for its no-wallpaper background color,
so the startup blank and lock screen use the same generated color.

The wallpaper's resource governor may freeze normal wallpaper motion under
load, but explicit transition requests always thaw it so `intro` and `exit`
remain visible. Steam game mode uses the FIFO directly: it sends `exit` while
any `steam_app_*` client is open and `intro` after the last one closes. Those
game transitions deliberately omit session sounds and workspace changes.

## Session Sounds

The tracked sounds in `.local/share/session-sounds/` play asynchronously when
the wallpaper transition changes: `session-login.wav` plays during an intro
and `session-logout.wav` plays during an exit. This covers graphical session
startup, lock/unlock transitions, and the existing shutdown animation. The
helper prefers `paplay` and falls back to `aplay`; if neither is available,
the transition continues without sound.

## Mission Center

Mission Center is installed from Flathub and runs in a sandbox with its own
GTK configuration directory. Apply the same GTK theme and icon theme used by
the other desktop applications, including the tracked GTK4 color and
transparency overrides, with:

```sh
.local/bin/configure-mission-center
```

The helper links the tracked GTK4 configuration into Mission Center's
per-user Flatpak configuration and applies a per-user Flatpak override. It is
safe to run repeatedly and does not modify the system-wide Flatpak
installation.

Application workspace routing is handled by
`.config/hypr/scripts/dynamic-app-workspaces`. It allocates a live workspace
on the launching monitor for each managed application process tree and routes
child windows to that workspace. Empty nonpersistent workspaces are removed
by Hyprland. Hyprshell provides the Alt+Tab switcher and selects workspaces on
the current monitor using its live Hyprland integration.

Hyprshell is managed by the user service
`.config/systemd/user/hyprshell.service`, which runs
`.config/hypr/scripts/hyprshell-start` with automatic restart-on-failure. The
tracked configuration is in `.config/hyprshell/`, and its stylesheet imports
the Noctalia GTK4 palette from `.config/gtk-4.0/noctalia.css`.

## GameMode

The user service `.config/systemd/user/game-mode.service` watches Hyprland for
Steam game clients (`steam_app_*`). When the first game opens, it holds a
standard `gamemoderun` client for the lifetime of the game session. When the
last game closes, that client exits and GameMode releases its settings. Existing
GameMode clients are not disturbed.

The watcher also sends `exit` and `intro` directly to the PS3 wallpaper
control FIFO. These transitions intentionally omit session sounds and
workspace changes. Enable the service after installing GameMode with:

```sh
systemctl --user daemon-reload
systemctl --user enable --now game-mode.service
```

## GPU Screen Recorder

Install GPU Screen Recorder system-wide from Flathub:

```sh
.local/bin/install-gpu-screen-recorder
```

The `.local/bin/gpu-screen-recorder-control` helper maintains a dedicated
five-minute replay buffer for `HDMI-A-1` and uses a monitor-selection dialog
for normal recordings. Recordings are saved under `~/Videos/ScreenCap` and
capture desktop output audio only.

- `SUPER + SHIFT + R` opens a monitor chooser and starts a recording; pressing
  it again stops the active normal recording.
- `SUPER + SHIFT + Z` saves the previous five minutes from `HDMI-A-1`.

GPU Screen Recorder captures realtime H.264 MP4 files. On stop or replay save,
the helper also creates a Resolve-ready DNxHR HQ MOV with PCM audio under
`~/Videos/ScreenCap/resolve/`, preserving the original MP4.

The helper can also be controlled over SSH:

```sh
.local/bin/gpu-screen-recorder-control start
.local/bin/gpu-screen-recorder-control stop
```

The recorder log is written to `~/Videos/ScreenCap/gpu-screen-recorder.log`.

HyprWindowShade is pinned to upstream commit
`40b756befa36cfd5cbed65d554c719141a65c420`. Run
`.local/bin/install-hyprwindowshade` after installing matching Hyprland plugin
headers. The installer verifies the build against the running compositor using
the upstream build script and places the plugin at
`~/.local/share/hyprland/plugins/HyprWindowShade.so`.

`.config/hypr/scripts/window-shader-events` applies the tracked ripple shader
to individual windows for 2 seconds after opening and the subtler
`focus-ripple.glsl` shader for 0.7 seconds after focus changes. The local patch
adds an address-targeted shader API, an event-relative `effect_time` uniform,
and a fallback for clients whose surfaces do not directly resolve to a
top-level window. The opening ripple starts at the nearest window edge and
decays inward with diffraction and chromatic separation; the focus ripple uses
a shorter, reduced-strength edge effect. Steam game windows
(`steam_app_*`), Affinity, DaVinci Resolve, Darktable, OBS, and Inkscape are
excluded from both effects because their rendering workflows benefit from
avoiding compositor shader work. The event listener applies the opening shader
once per `openwindow` event after
waiting for the target address to exist, and applies the focus shader on
`activewindowv2` events, resolving the class from live client data. WezTerm
uses moderate spawn and focus-specific variants to remain visible through its
configured transparency; the shader does not modify WezTerm's normal opacity.
A newly opened window's focus event does not replace its spawn effect.
The WezTerm variants temporarily raise fragment alpha within the effect
envelope so blank transparent terminals can show the animation; normal
transparency returns when the effect ends. Window-title changes do not
retrigger either effect.

The patch is applied to the pinned HyprWindowShade checkout from
`.config/hypr/patches/hyprwindowshade-per-window-effects.patch` before each
build.

The event listener runs as the user service
`.config/systemd/user/window-shader-events.service` and is restarted as part
of the Hyprland startup hook.

## LocalSend

Install LocalSend system-wide with:

```sh
sudo flatpak install --system flathub org.localsend.localsend_app
```

The application-menu entry is provided by Flatpak. LocalSend is started hidden
by Hyprland because its GUI process owns both discovery and the transfer
server; there is no separate daemon to launch. Its network service uses TCP and
UDP port `53317`.

After launching LocalSend once, set this machine's advertised device name with:

```sh
.local/bin/configure-localsend
```

The helper updates only LocalSend's alias in its Flatpak preferences and leaves
its generated security keys unchanged. It requires `jq`, which is already a
dotfiles dependency.

Hyprland starts LocalSend hidden through
`.config/systemd/user/localsend.service`, so the device remains discoverable
without opening a tiled window. Allow LocalSend through the active Fedora
firewall zone with:

```sh
.local/bin/configure-localsend-firewall
```

The helper prompts for the sudo password in the current SSH terminal and is
safe to run repeatedly.

When a transfer needs approval, show the existing hidden LocalSend window with
this SSH-safe command:

```sh
.local/bin/show-localsend
```
