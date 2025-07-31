local wezterm = require("wezterm") --[[@as Wezterm]]
local M = {}
---@diagnostic disable: missing-fields
local term_font = wezterm.font_with_fallback({
  {
    family = "MonoLisa Nerd Font",
    scale = 1.005,
    harfbuzz_features = {
      "calt=1",
      "liga=1",
      "zero=1",
      "ss01=1",
      "ss02=0",
      "ss03=1",
      "ss04=1",
      "ss05=1",
      "ss06=1",
      "ss07=1",
      "ss08=1",
      "ss09=1",
      "ss10=1",
      "cv01=2",
      "cv02=1",
      "cv10=0",
      "cv11=0",
      "cv30=1",
      "cv31=1",
      "cv32=0",
      "cv60=0",
      "cv61=0",
      "cv62=0",
    },
  },
  -- { family = "FireCode Nerd Font Mono" },
})

---@class config: Config
function M.setup(config)
  config.freetype_load_target = "HorizontalLcd"
  config.font = term_font
  config.bold_brightens_ansi_colors = "BrightAndBold"
end

return M
