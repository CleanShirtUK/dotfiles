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
by Hyprland, while navigation and Alt+Tab derive their workspace lists from
the live Hyprland state.

Alt+Tab is implemented by `.config/hypr/scripts/workspace-mru`. The
`.config/hypr/scripts/workspace-mru-overlay` wrapper invokes that script first,
then displays its unchanged monitor-specific workspace MRU through Hyprland's
built-in notification layer. The overlay is display-only and requires no
additional project or service.
