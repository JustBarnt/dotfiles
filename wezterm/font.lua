local wezterm = require("wezterm") --[[@as Wezterm]]
local M = {}

---@class config: Config
function M.setup(config)
  config.font_size = 13

  if wezterm.target_triple:find("darwin") then
    config.font_size = 16
  end

  config.freetype_load_target = "Light"
  config.freetype_load_flags = "NO_HINTING|FORCE_AUTOHINT"
  config.font = wezterm.font({ family = "Maple Mono NF" })
  config.bold_brightens_ansi_colors = "BrightAndBold"
  config.font_rules = {
    {
      intensity = "Bold",
      italic = true,
      font = wezterm.font({ family = "Maple Mono NF", weight = "DemiBold", style = "Italic" }),
    },
    {
      italic = true,
      intensity = "Half",
      font = wezterm.font({ family = "Maple Mono NF", weight = "Light", style = "Italic" }),
    },
    {
      italic = true,
      intensity = "Normal",
      font = wezterm.font({ family = "Maple Mono NF", style = "Italic", weight = "Bold" }),
    },
  }
end

return M
