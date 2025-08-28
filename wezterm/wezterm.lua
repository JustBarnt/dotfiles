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
config.launch_menu = {
  { label = "Wezterm Config", args = { "nvim", home .. "/.config/wezterm/" } },
  { label = "Dev Drive", args = { "yazi", "D:/CommSys" } },
}

config.max_fps = 120
config.animation_fps = 60

config.color_scheme = "tokyonight_night"

if wezterm.target_triple:find("darwin") then
  config.dpi = 144
end

if wezterm.target_triple:find("windows") then
  local pc_name = wezterm.hostname();
  config.default_prog = { "nu.exe" }

  table.insert(config.launch_menu, { label = "PowerShell", args = { "pwsh.exe", "-NoLogo" } })

  if pc_name == "commsys-PC58" then
    local cmd_args_path = "C:/Program Files/Microsoft Visual Studio/2022/Professional/Common7/Tools/VsDevCmd.bat"

    -- CMD Prompt
    local cmd_str = "cmd.exe /k %s -arch=%s"
    table.insert(config.launch_menu, { label = "x64 Native Tools Developer Command Prompt (2022)", args = { cmd_str:format(cmd_args_path, "x64") }})
    table.insert(config.launch_menu, { label = "x86 Native Tools Developer Command Prompt (2022)", args = { cmd_str:format(cmd_args_path, "x64") }})

    -- PWSH 
    local pwsh_str = "powershell.exe -NoExit -Command -Invoke-Expression '. %s -arch=%s'"
    table.insert(config.launch_menu, { label = "x64 Native Tools Developer Powershell (2022)", args = { pwsh_str:format(cmd_args_path, "x64") }})
    table.insert(config.launch_menu, { label = "x86 Native Tools Developer Powershell (2022)", args = { pwsh_str:format(cmd_args_path, "x86") }})
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
else
  config.term = "wezterm"
  config.window_decorations = "NONE"
end

-- Cursor
config.scrollback_lines = 10000

--- Command Pallete
config.command_palette_font_size = 13
config.command_palette_rows = 15
config.command_palette_fg_color = "#ebfafa"
config.command_palette_bg_color = "#323449"

-- UI Settings
config.window_padding = { left = 4, right = 4, top = 0, bottom = 0 }
-- config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_decorations = "RESIZE|TITLE"

-- config.hyperlink_rules = wezterm.default_hyperlink_rules()
-- table.insert(config.hyperlink_rules, {
--   regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
--   format = "https://github.com/$1/$3",
-- })
return config
