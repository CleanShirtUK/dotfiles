-- Hyprland configuration

local home = os.getenv("HOME")
package.path = home .. "/.config/hypr/?.lua;" .. package.path

local noctalia = require("noctalia-colors")
local terminal = "wezterm"
local fileManager = "nautilus"
local launcher = "noctalia msg panel-toggle launcher"
local scripts = home .. "/.config/hypr/scripts"
local gpuScreenRecorder = home .. "/.local/bin/gpu-screen-recorder-control"
local animateLock = scripts .. "/animate-lock"
local animateShutdown = scripts .. "/animate-shutdown"
local moveWindowWorkspace = scripts .. "/move-window-workspace"
local focusWorkspace = scripts .. "/focus-workspace"
local mainMod = "SUPER"
local hyprGlassPlugin = home .. "/.local/share/hyprland/plugins/hyprglass.so"
local hyprWindowShadePlugin = home .. "/.local/share/hyprland/plugins/HyprWindowShade.so"

require("monitors")
dofile(home .. "/.config/hypr/noctalia.lua")

-- Environment and permissions

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "hyprqt6engine")
hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-- Session lifecycle

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start plasma-polkit-agent.service")
    hl.exec_cmd(scripts .. "/restore-minimized")
    hl.exec_cmd(scripts .. "/float-bitwarden-popup &")
    hl.exec_cmd(scripts .. "/dynamic-app-workspaces &")
    hl.exec_cmd("systemctl --user restart hyprshell.service")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE QT_QPA_PLATFORMTHEME")
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    -- Restart after importing the session environment so hypridle can reach Wayland.
    hl.exec_cmd("systemctl --user restart hypridle.service")
    hl.exec_cmd("systemctl --user restart localsend.service")
    hl.exec_cmd("systemctl --user start xdg-desktop-portal-hyprland")
    hl.exec_cmd([[sh -c 'hyprpm reload 2>/dev/null || true; hyprctl plugin load ]] .. hyprGlassPlugin .. [[ 2>/dev/null || true; hyprctl plugin load ]] .. hyprWindowShadePlugin .. [[ 2>/dev/null || true; systemctl --user restart window-shader-events.service; sleep 0.5; hyprctl reload config-only']])
end)

hl.on("hyprland.shutdown", function()
    os.execute("systemctl --user stop hyprland-session.target")
end)

-- Core behaviour and appearance

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 20,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(59595900)",
        },
        resize_on_border = true,
        extend_border_grab_area = 20,
        allow_tearing = false,
        layout = "master",
    },

    decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 0.95,
        inactive_opacity = 0.9,
        shadow = { enabled = true, range = 2, render_power = 5, color = 0xee1a1a1a },
    },

    animations = { enabled = true },

    input = {
        kb_layout = "us",
--	follow_mouse = 2,
        mouse_refocus = false,
        sensitivity = 0,
        touchpad = { natural_scroll = false },
    },

    cursor = {
        no_warps = true,
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        focus_on_activate = true,
        animate_manual_resizes = true,
    },

    binds = {
        window_direction_monitor_fallback = true,
        pass_mouse_when_bound = true,
    },

    -- The master layout gives the first window a fixed main area and stacks
    -- subsequent windows in the remaining column.
    master = {
        mfact = 0.7,
        new_status = "slave",
        orientation = "left",
    },
    scrolling = { fullscreen_on_one_column = true },
})


-- Hyprglass

if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.config({
        default_theme = "dark",
        default_preset = "glass",
        layers = { enabled = 1 },
    })

    hg.preset("glass", {
        glass_opacity = 1,
        blur_strength = 0.7,
        blur_iterations = 3,
        refraction_strength = 1,
        chromatic_aberration = 0.5,
        edge_thickness = 0.1,
        lens_distortion = 0.9,
        brightness = 1.1,
        contrast = 1.4,
    })

    hg.layer("hyprshell_switch", { exclude = true })

end

-- Animations

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
-- Keep window geometry changes smooth so they do not fight workspace slides.
hl.animation({ leaf = "windows", enabled = true, speed = 2.9, bezier = "almostLinear" })
    -- Keep the client surface fixed; fadeIn handles opacity.
hl.animation({ leaf = "windowsIn", enabled = false, speed = 4.1, spring = "easy", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.95, bezier = "linear", style = "slide" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.5, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.25, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.85, bezier = "almostLinear", style = "slide" })
-- Workspaces are arranged vertically, so workspace changes slide vertically
-- instead of fading between unrelated views.
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.0, bezier = "almostLinear", style = "slidefadevert -100%" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 2.45, bezier = "almostLinear", style = "slidefadevert -100%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2.0, bezier = "almostLinear", style = "slidefadevert -100%" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

-- Keybindings
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(animateLock))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(animateShutdown))
hl.bind("ALT + Return", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy --type image/png]]))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(gpuScreenRecorder .. " record"))
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.exec_cmd(gpuScreenRecorder .. " replay"))
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("flatpak run io.missioncenter.MissionCenter"))

-- Focus windows horizontally. The monitor fallback lets focus continue
-- naturally across the two outputs.
for _, direction in ipairs({ "left", "right" }) do
    hl.bind(mainMod .. " + " .. direction, hl.dsp.focus({ direction = direction }))
end

-- Focus vertically through tiled windows, then switch one workspace at an edge.
for key, direction in pairs({ up = "u", down = "d" }) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.exec_cmd(focusWorkspace .. " " .. direction))
end

for key, direction in pairs({ mouse_up = "u", mouse_down = "d" }) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.exec_cmd(focusWorkspace .. " " .. direction), { mouse = true })
end

-- Move windows within the current workspace horizontally.
for _, direction in ipairs({ "left", "right" }) do
    hl.bind(mainMod .. " + SHIFT + " .. direction, hl.dsp.window.move({ direction = direction }), { repeating = true })
end

-- Move a window exactly one workspace vertically on its current monitor.
for key, direction in pairs({ up = "u", down = "d" }) do
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.exec_cmd(moveWindowWorkspace .. " " .. direction), { repeating = true })
end

-- Resize the active window with SUPER + CTRL + arrows.
for key, delta in pairs({
    left = { x = -40, y = 0 },
    right = { x = 40, y = 0 },
    up = { x = 0, y = -40 },
    down = { x = 0, y = 40 },
}) do
    hl.bind(mainMod .. " + CTRL + " .. key, hl.dsp.window.resize({ x = delta.x, y = delta.y, relative = true }), { repeating = true })
end

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("mouse:272", hl.dsp.exec_cmd(scripts .. "/toggle-float-double-click"), { mouse = true })

-- Window rules


hl.window_rule({
    name = "steam-games",
    match = { class = "^steam_app_.*" },
    immediate = true,
    no_anim = true,
    no_blur = true,
    no_shadow = true,
    decorate = false,
    content = "game",
    no_follow_mouse = true,
    focus_on_activate = false,
})

hl.window_rule({
    name = "leave-dialog-sizes-alone",
    match = { title = "^(Open File|Save File|Choose File|Preferences|Settings)$" },
    size = { 0, 0 },
    center = false,
})

-- Utility and control-panel applications are more useful as floating windows
-- than as full-sized tiled clients.
for _, class in ipairs({
    "^io\\.missioncenter\\.MissionCenter$",
    "^pavucontrol$",
    "^blueman-manager$",
    "^blueman-adapters$",
    "^nm-connection-editor$",
    "^nwg-displays$",
    "^nwg-look$",
    "^qt6ct$",
    "^partitionmanager$",
    "^org\\.kde\\.discover$",
    "^org\\.kde\\.ark$",
    "^org\\.gnome\\.DiskUtility$",
    "^gnome-disk-utility$",
    "^zenity$",
    "^bitwarden$",
    "^com\\.rustdesk\\.RustDesk$",
    "^net\\.davidotek\\.pupgui2$",
    "^dev\\.noctalia\\.Noctalia$",
    "^xdg-desktop-portal-gtk$",
    "^org\\.gnome\\.Software$",
    }) do
    hl.window_rule({
        name = "float-utility-" .. class,
        match = { class = class },
        float = true,
        center = true,
    })
end

hl.window_rule({
    name = "top-right-bitwarden",
    match = { class = "^bitwarden$" },
    float = true,
    max_size = { 99999, 800 },
     move = {
         "(monitor_w-window_w-20)",
         "20",
     },
 })

hl.window_rule({
    name = "constrain-gtk-file-chooser",
    match = { class = "^xdg-desktop-portal-gtk$" },
    max_size = { 1248, 700 },
})

hl.window_rule({
    name = "float-dolphin",
    match = { class = "^(org\\.gnome\\.Nautilus|Nautilus)$" },
    float = true,
})

hl.window_rule({
    name = "float-obsidian-settings",
    match = { title = "^Settings.*$" },
    float = true,
    center = true,
})

hl.window_rule({
    name = "float-bitwarden-popup",
    match = { title = "^Extension:.*Bitwarden.*" },
    float = true,
    center = true,
})

hl.window_rule({
    name = "float-gpu-screen-recorder-monitor-picker",
    match = { class = "^zenity$" },
    float = true,
})

hl.window_rule({
    name = "affinity-fix",
    match = {
        class = "^(Affinity|affinity).*",
        xwayland = true,
    },
    float = true,
    center = true,
    -- Affinity needs a larger canvas than the normal 60% window limit.
    size = { 1500, 900 },
    keep_aspect_ratio = true,
    persistent_size = true,
    suppress_event = "maximize",
    no_anim = true,
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name = "float-steam-transient-windows",
    match = { class = "^steam$" },
    float = true,
})

hl.window_rule({
    name = "keep-steam-main-window-tiled",
    match = { class = "^steam$", title = "^Steam$" },
    float = false,
    decorate = false,
})

hl.window_rule({
    name = "wezterm-no-hyprbar",
    match = { class = "^org\\.wezfurlong\\.wezterm$" },
    size = { 800, 600 },
    center = true,
    persistent_size = true,
})

hl.window_rule({ name = "move-hyprland-run", match = { class = "hyprland-run" }, move = "20 monitor_h-120", float = true })

local suppressMaximizeRule = hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})
suppressMaximizeRule:set_enabled(false)

-- Keep one default workspace per monitor; application workspaces are dynamic.
hl.workspace_rule({ workspace = "1", monitor = "DP-1", default = true, persistent = true })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-1", default = true, persistent = true })

require("noctalia").apply_theme()

hl.layer_rule({
  name = "noctalia",
  match = {
    namespace = "^noctalia-(bar-.+|notification|panel|osd|window-switcher)$",
  },
  no_anim = true,
  ignore_alpha = 0.5,
})
