# CleanShirtUK Dotfiles

Personal Hyprland and Noctalia configuration.

## Dependencies

- Hyprland, Hypridle, and Hyprlock
- Noctalia
- `hyprglass` plugin
- HyprWindowShade plugin, built by `.local/bin/install-hyprwindowshade`
- HyprWobbly plugin, built from the downloaded source against matching Hyprland headers
- `bash`, `flock`, `jq`, `socat`, `grim`, `slurp`, and `wl-copy`
- The separate [`ps3-wave-wallpaper`](https://github.com/CleanShirtUK/ps3-wave-wallpaper) project

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

HyprWobbly is loaded from
`~/.local/share/hyprland/plugins/hyprwobbly.so`. Its source currently lives
outside this repository because it was downloaded from upstream; its build
needs the Hyprland 0.56 header layout (`render/transformer/Transformer.hpp`,
`animation/AnimationManager.hpp`, and `output/Monitor.hpp`) and the hyprpm
header include path. The startup hook loads the resulting plugin after it has
been built.
