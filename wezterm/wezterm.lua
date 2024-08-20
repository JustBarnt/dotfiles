local wezterm = require("wezterm") --[[@as Wezterm]]
local action = wezterm.action
local config = wezterm.config_builder()
local picture_path = "C:\\Users\\bwilliams\\Pictures\\"

require("tabs").setup(config)
require("mouse").setup(config)
require("links").setup(config)
require("keys").setup(config)

config.webgpu_power_preference = "HighPerformance"
config.automatically_reload_config = true

local function file_exists(file)
  local f = io.open(file, "rb")
  if f then
    f:close()
  end
  return f ~= nil
end

local eldritch_wallpaper = file_exists(picture_path .. "Eldritch1920x1080.png") and "Eldritch1920x1080.png" or "eldritch.png"

config.background = {
  {
    source = {
      Color = "#212337",
      -- Color = "#def678",
    },
    height = "100%",
    width = "100%",
  },
  {
    source = {
      File = picture_path .. eldritch_wallpaper,
    },
    width = "Cover",
    horizontal_align = "Center",
    opacity = 0.05,
  },
}

-- Default Shell / Theme
config.default_prog = { "nu.exe" }

if wezterm.target_triple:find("windows") then
  wezterm.on("gui-startup", function(cmd)
    local screen = wezterm.gui.screens().active
    local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
    local gui = window:gui_window()
    local width = 0.7 * screen.width
    local height = 0.7 * screen.height
    gui:set_inner_size(width, height)
    gui:set_position((screen.width - width) / 2, (screen.height - height) / 2)
  end)
end

-- Watch for colorscheme changes
config.color_scheme_dirs = { wezterm.home_dir .. "/colors/Eldritch" }
config.color_scheme = "Eldritch"
wezterm.add_to_config_reload_watch_list(config.color_scheme_dirs[1] .. config.color_scheme .. ".toml")

config.underline_thickness = 3
config.underline_position = -6

-- Font Settings
config.font_size = 11.25
---@diagnostic disable-next-line: assign-type-mismatch, missing-fields
config.font = wezterm.font({ family = "MonoLisaCustom Nerd Font", scale = 1, weight = "Medium" })
config.bold_brightens_ansi_colors = "BrightAndBold"

-- Cursor
config.cursor_blink_ease_in = "EaseIn"
config.cursor_blink_ease_out = "EaseOut"
config.default_cursor_style = "BlinkingBar"
config.window_padding = { left = 0, right = 0, top = 0, bottom = 2 }
config.scrollback_lines = 10000

--- Command Pallete
config.command_palette_font_size = 13
config.command_palette_fg_color = "#394b70"
config.command_palette_fg_color = "#828bb8"

-- UI Settings
config.window_decorations = "RESIZE|TITLE"

return config
