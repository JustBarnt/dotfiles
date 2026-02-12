local wezterm = require("wezterm") --[[@as Wezterm]]
local M = {}

---@class config: Config
function M.setup(config)
  config.font_size = 11

  if wezterm.target_triple:find("darwin") then
    config.font_size = 16
  end

  config.custom_block_glyphs = false
  config.freetype_load_target = "Light"
  config.freetype_load_flags = "NO_HINTING|FORCE_AUTOHINT"
  config.font = wezterm.font_with_fallback({
    { family = "MonoLisa", weight = "Medium" },
    { family = "SymbolsNerdFontMono" }
  })
  config.bold_brightens_ansi_colors = "BrightAndBold"
  end

return M
