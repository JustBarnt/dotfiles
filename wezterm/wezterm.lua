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
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.default_prog = { "nu.exe" }
config.launch_menu = {
  { label = "Wezterm Config", args = { "nvim", home .. "/.config/wezterm/" } },
  { label = "Dev Drive", args = { "yazi", "D:/CommSys" } },
}

config.max_fps = 120
config.animation_fps = 60

config.color_scheme_dirs = { 'colors' }
config.color_scheme = "tokyonight"

config.underline_thickness = "0.1cell"
config.cursor_thickness = "1cell"

if wezterm.target_triple:find("windows") then
  table.insert(config.launch_menu, { label = "PowerShell", args = { "pwsh.exe", "-NoLogo" } })

  -- Find installed visual studio version(s) and add their compilation
  -- environment command prompts to the menu
  for _, vsvers in ipairs(wezterm.glob("Microsoft Visual Studio/20*", "C:/Program Files")) do
    -- Remove 'Microsoft Visual Studio/' from the matched path so we
    -- only get '2019' or '2022' or similar
    local year = vsvers:gsub("Microsoft Visual Studio/", "")

    -- The architectures you want to support
    local archs = { "amd64", "x86" }

    for _, arch in ipairs(archs) do
      -- 1) CMD-based Developer Command Prompt
      table.insert(config.launch_menu, {
        label = string.format("%s Native Tools Developer Command Prompt %s", (arch == "amd64" and "x64" or "x86"), year),
        args = {
          "cmd.exe",
          "/k",
          -- Adjust edition below if you're using Community, Enterprise, etc.
          "C:/Program Files/"
            .. vsvers
            .. "/Professional/Common7/Tools/VsDevCmd.bat",
          "-arch=" .. arch,
        },
      })

      -- 2) PowerShell-based Developer Command Prompt
      table.insert(config.launch_menu, {
        label = string.format("%s Native Tools Developer PowerShell %s", (arch == "amd64" and "x64" or "x86"), year),
        args = {
          "powershell.exe",
          "-NoExit",
          "-Command",
          -- We use Invoke-Expression so that VsDevCmd.bat modifies the
          -- current PowerShell session environment.
          "Invoke-Expression '. \"C:/Program Files/"
            .. vsvers
            .. '/Professional/Common7/Tools/VsDevCmd.bat" -arch='
            .. arch
            .. "'",
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

-- config.hyperlink_rules = wezterm.default_hyperlink_rules()
-- table.insert(config.hyperlink_rules, {
--   regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
--   format = "https://github.com/$1/$3",
-- })
return config
