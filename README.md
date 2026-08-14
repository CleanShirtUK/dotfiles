# CleanShirtUK Dotfiles

Personal Hyprland and Noctalia configuration.

## Dependencies

- Hyprland and Hypridle
- Noctalia
- `hyprglass` plugin
- HyprWindowShade plugin, built by `.local/bin/install-hyprwindowshade`
- `bash`, `flock`, `jq`, `socat`, `grim`, `slurp`, and `wl-copy`
- LocalSend, installed system-wide from Flathub as `org.localsend.localsend_app`
- GPU Screen Recorder, installed system-wide from Flathub as
  `com.dec05eba.gpu_screen_recorder`
- The separate [`ps3-wave-wallpaper`](https://github.com/CleanShirtUK/ps3-wave-wallpaper) project, running in live-wallpaper-only mode

The wallpaper project is installed and built by
allow-listed through `.gitignore`; only reviewed configuration files are
tracked.

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

## GPU Screen Recorder

Install GPU Screen Recorder system-wide from Flathub:

```sh
.local/bin/install-gpu-screen-recorder
```

The `.local/bin/gpu-screen-recorder-control` helper starts one recorder on the
currently active Hyprland monitor, captures desktop output audio only, and
maintains a five-minute replay buffer. Recordings are saved under
`~/Videos/ScreenCap`.

- `SUPER + SHIFT + R` toggles a normal recording.
- `SUPER + SHIFT + Z` saves the previous five minutes as an instant replay.

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
to individual windows for 2 seconds after opening. The local patch adds an
address-targeted shader API, an event-relative `effect_time` uniform, and a
fallback for clients whose surfaces do not directly resolve to a top-level
window. The ripple starts tightly at the center and decays exponentially with
diffraction and chromatic separation. Steam game windows
(`steam_app_*`) and Affinity are excluded because their existing compatibility
rules disable animation and decoration behavior. The event listener applies the
shader once per `openwindow` event after waiting for the target address to exist;
window-title changes do not retrigger it.

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
