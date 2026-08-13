# CleanShirtUK Dotfiles

Personal Hyprland and Noctalia configuration.

## Dependencies

- Hyprland, Hypridle, and Hyprlock
- Noctalia
- `hyprglass` plugin
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

Hyprshell is launched by `.config/hypr/scripts/hyprshell-start` and uses the
tracked configuration in `.config/hyprshell/`. Its stylesheet imports the
Noctalia GTK4 palette from `.config/gtk-4.0/noctalia.css`.
