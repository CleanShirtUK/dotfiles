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
config.keys = {
  {
    key = 'c',
    mods = 'ALT',
    action = wezterm.action.SendKey { key = 'c', mods = 'CTRL' },
  },
  {
    key = 'c',
    mods = 'CTRL',
    action = wezterm.action.CopyTo 'Clipboard',
  },
  {
    key = 'v',
    mods = 'CTRL',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
}

return config
