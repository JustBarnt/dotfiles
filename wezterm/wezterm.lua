local wezterm = require("wezterm") --[[@as Wezterm]]
local action = wezterm.action
local config = wezterm.config_builder()
local picture_path = "C:\\Users\\bwilliams\\Pictures\\"
local utils = require("utils.utils")
local home = os.getenv("HOME") and os.getenv("HOME") or os.getenv("HOMEPATH")

-- Other modules for wezterm
require("tabs").setup(config)
require("mouse").setup(config)
require("links").setup(config)
require("keys").setup(config)

-- Base
config.automatically_reload_config = true
config.default_prog = { "nu.exe" }
config.default_cwd = utils.checkDir("D:/CommSys") and "D:/CommSys" or "D:/Github"
config.launch_menu = {
  { label = "Wezterm Config", args = { "nvim", home .. "/.config/wezterm/" } },
  { label = "Dev Drive", args = { "yazi", "D:/CommSys" } },
}

local eldritch_wallpaper = utils.file_exists(picture_path .. "Eldritch1920x1080.png") and "Eldritch1920x1080.png" or "eldritch.png"

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

-- Watch for colorscheme changes
config.color_scheme_dirs = { wezterm.home_dir .. "/colors/Eldritch" }
config.color_scheme = "Eldritch"
wezterm.add_to_config_reload_watch_list(config.color_scheme_dirs[1] .. config.color_scheme .. ".toml")

config.underline_thickness = 3
config.underline_position = -6

if wezterm.target_triple:find("windows") then
  table.insert(config.launch_menu, { label = "PowerShell", args = { "pwsh.exe", "-NoLogo" } })

  -- Find installed visual studio version(s) and add their compilation
  -- environment command prompts to the menu
  for _, vsvers in ipairs(wezterm.glob("Microsoft Visual Studio/20*", "C:/Program Files")) do
    local year = vsvers:gsub("Microsoft Visual Studio/", "")
    local archs = { "amd64", "x86" }

    for _, arch in ipairs(archs) do
      table.insert(config.launch_menu, {
        label = (arch == "amd64" and "x64" or "x86") .. " Native Tools Developer Command Prompt " .. year,
        args = {
          "cmd.exe",
          "/k",
          "C:/Program Files/" .. vsvers .. "/Professional/Common7/Tools/VsDevCmd.bat",
          "-arch=" .. arch,
        },
      })
    end
  end

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

-- Font Settings
config.font_size = 11.25
config.freetype_load_target = "HorizontalLcd"
---@diagnostic disable-next-line: assign-type-mismatch, missing-fields
config.font = wezterm.font({ family = "MonoLisaCustom Nerd Font", scale = 1, weight = "Medium" })
config.bold_brightens_ansi_colors = "BrightAndBold"
config.line_height = 1.1

-- Cursor
config.scrollback_lines = 10000

--- Command Pallete
config.command_palette_font_size = 13
config.command_palette_rows = 15
config.command_palette_fg_color = "#ebfafa"
config.command_palette_bg_color = "#323449"

-- UI Settings
config.window_padding = { left = 0, right = 0, top = 0, bottom = 2 }
config.integrated_title_buttons = { "Maximize", "Close" }
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

-- Hyperlink configs
config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, {
  regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
  format = "https://github.com/$1/$3",
})

return config
