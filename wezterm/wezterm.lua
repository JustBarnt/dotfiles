local wezterm = require("wezterm") --[[@as Wezterm]]
local config = wezterm.config_builder()
local home = os.getenv("HOME") and os.getenv("HOME") or os.getenv("HOMEPATH")

require("tabs").setup(config)
require("mouse").setup(config)
require("links").setup(config)
require("keys").setup(config)
require("font").setup(config)

config.status_update_interval = 5000

-- Base
config.webgpu_power_preference = "HighPerformance"
config.automatically_reload_config = true
config.default_prog = { "nu.exe" }
config.launch_menu = {
  { label = "Wezterm Config", args = { "nvim", home .. "/.config/wezterm/" } },
  { label = "Dev Drive", args = { "yazi", "D:/CommSys" } },
}

-- Watch for colorscheme changes
config.color_scheme_dirs = { wezterm.home_dir .. "/colors" }
config.color_scheme = "Tokyo Night Moon"
wezterm.add_to_config_reload_watch_list(config.color_scheme_dirs[1] .. config.color_scheme .. ".toml")

config.underline_thickness = 3
config.underline_position = -6

if wezterm.target_triple:find("windows") then
  -- table.insert(config.launch_menu, { label = "PowerShell", args = { "pwsh.exe", "-NoLogo" } })

  -- Find installed visual studio version(s) and add their compilation
  -- environment command prompts to the menu
  -- for _, vsvers in ipairs(wezterm.glob("Microsoft Visual Studio/20*", "C:/Program Files")) do
  --   local year = vsvers:gsub("Microsoft Visual Studio/", "")
  --   local archs = { "amd64", "x86" }
  --
  --   for _, arch in ipairs(archs) do
  --     table.insert(config.launch_menu, {
  --       label = (arch == "amd64" and "x64" or "x86") .. " Native Tools Developer Command Prompt " .. year,
  --       args = {
  --         "cmd.exe",
  --         "/k",
  --         "C:/Program Files/" .. vsvers .. "/Professional/Common7/Tools/VsDevCmd.bat",
  --         "-arch=" .. arch,
  --       },
  --     })
  --   end
  -- end

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

-- Cursor
config.scrollback_lines = 10000

--- Command Pallete
config.command_palette_font_size = 13
config.command_palette_rows = 15
config.command_palette_fg_color = "#ebfafa"
config.command_palette_bg_color = "#323449"

-- UI Settings
config.window_padding = { left = 4, right = 4, top = 4, bottom = 4 }
-- config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_decorations = "RESIZE|TITLE"

config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, {
  regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
  format = "https://github.com/$1/$3",
})

wezterm.on("update-status", function(window, pane)
  local dpi = window:get_dimensions().dpi
  local font_scale = dpi / 96
  local base_font_size = font_scale > 1 and 10 or 12

  ---@diagnostic disable-next-line: missing-fields
  window:set_config_overrides({
    font_size = math.ceil(base_font_size * font_scale),
    line_height = math.floor(font_scale),
  })
end)

return config
