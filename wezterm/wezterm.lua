local wezterm = require("wezterm") --[[@as Wezterm]]
local config = wezterm.config_builder()

require("tabs").setup(config)
require("mouse").setup(config)
require("links").setup(config)
require("keys").setup(config)
require("font").setup(config)

config.status_update_interval = 5000

-- Base
config.webgpu_power_preference = "HighPerformance"
config.automatically_reload_config = true
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

config.enable_kitty_graphics = true;

-- Colorscheme
config.color_scheme_dirs = { wezterm.home_dir .. ".config\\wezterm\\colors" }
config.color_scheme = "onedark"
wezterm.add_to_config_reload_watch_list(config.color_scheme_dirs[1] .. config.color_scheme .. ".toml")

config.colors = {
  indexed = { [241] = "#65bcff" },
}

config.underline_thickness = 3
config.cursor_thickness = 4
config.underline_position = -6

if wezterm.target_triple:find("darwin") then
  config.dpi = 144
end

if wezterm.target_triple:find("windows") then
  local pc_name = wezterm.hostname()
  config.window_decorations = "RESIZE|TITLE"
  config.default_prog = { "nu.exe" }

  wezterm.on("gui-startup", function(cmd)
    local screen = wezterm.gui.screens().active
    local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
    local gui = window:gui_window()
    local width = 0.7 * screen.width
    local height = 0.7 * screen.height
    gui:set_inner_size(width, height)
    gui:set_position((screen.width - width) / 2, (screen.height - height) / 2)
  end)
else
  config.term = "wezterm"
  config.window_decorations = "NONE"
end

-- Cursor
config.default_cursor_style = "BlinkingBar"
config.force_reverse_video_cursor = true
config.scrollback_lines = 10000

--- Command Pallete
config.command_palette_font_size = 13
config.command_palette_rows = 15
config.command_palette_bg_color = "#394b70"
config.command_palette_fg_color = "#828bb8"

-- UI Settings
config.window_padding = { left = 4, right = 4, top = 0, bottom = 0 }
return config
