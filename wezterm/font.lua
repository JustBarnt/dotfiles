local wezterm = require("wezterm") --[[@as Wezterm]]
local M = {}

---@class config: Config
function M.setup(config)
  config.font_size = 11.5

  if wezterm.target_triple:find("darwin") then
    config.font_size = 16
  end
  config.freetype_load_target = "Light"
  config.freetype_load_flags = "NO_HINTING|FORCE_AUTOHINT"
  config.font = wezterm.font_with_fallback({
    {
      family = "Lilex Nerd Font Mono", 
      weight = "Medium",
      harfbuzz_features = { 'ss02', 'cv08', 'zero', 'cv15', 'cv06' }
    },
    { family = "SymbolsNerdFontMono" }
  })
  config.bold_brightens_ansi_colors = "BrightAndBold"
  end

return M
