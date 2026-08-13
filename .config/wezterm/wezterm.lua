local wezterm = require 'wezterm'
local config = {}

config.color_scheme = 'Noctalia'
config.enable_tab_bar = false
config.font = wezterm.font 'JetBrains Mono'
config.font_size = 10.0
config.window_decorations = 'NONE'
config.window_padding = {
  left = 30,
  right = 30,
  top = 30,
  bottom = 30,
}
config.window_background_opacity = 0.4

return config
