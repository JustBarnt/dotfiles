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
  config.font = wezterm.font_with_fallback({
    { family = "JetBrainsMono Nerd Font", weight = "Medium" },
    { family = "Maple Mono NF" }
  })
  config.bold_brightens_ansi_colors = "BrightAndBold"
  end

return M
