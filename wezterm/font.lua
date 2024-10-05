local wezterm = require("wezterm") --[[@as Wezterm]]
local M = {}
---@diagnostic disable: missing-fields
local term_font = wezterm.font({
  family = "MonoLisa",
  scale = 1,
  harfbuzz_features = {
    "calt=1",
    "liga=1",
    "ss03=1",
    "zero=1",
    "ss01=0",
    "ss02=0",
    "ss06=1",
    "ss07=0",
    "ss08=1",
    "ss10=1",
    "ss11=1",
    "ss12=1",
    "ss13=1",
    "ss14=1",
    "ss15=0",
    "ss16=0",
    "ss17=1",
  },
})

---@class config: Config
function M.setup(config)
  config.font_size = 12
  config.line_height = 1.1
  config.freetype_load_target = "HorizontalLcd"
  config.font = term_font
  config.bold_brightens_ansi_colors = "BrightAndBold"
  config.font_rules = {
    {
      intensity = "Bold",
      italic = true,
      font = wezterm.font({
        family = "MonoLisa",
        weight = "Bold",
        style = "Oblique",
        scale = 1,
        harfbuzz_features = {
          "calt=1",
          "liga=1",
          "ss03=1",
          "zero=1",
          "ss01=0",
          "ss02=0",
          "ss06=1",
          "ss07=0",
          "ss08=1",
          "ss10=1",
          "ss11=1",
          "ss12=1",
          "ss13=1",
          "ss14=1",
          "ss15=0",
          "ss16=0",
          "ss17=1",
        },
      }),
    },
    {
      italic = true,
      intensity = "Half",
      font = wezterm.font({
        family = "MonoLisa",
        weight = "DemiBold",
        style = "Oblique",
        scale = 1,
        harfbuzz_features = {
          "calt=1",
          "liga=1",
          "ss03=1",
          "zero=1",
          "ss01=0",
          "ss02=0",
          "ss06=1",
          "ss07=0",
          "ss08=1",
          "ss10=1",
          "ss11=1",
          "ss12=1",
          "ss13=1",
          "ss14=1",
          "ss15=0",
          "ss16=0",
          "ss17=1",
        },
      }),
    },
    {
      italic = true,
      intensity = "Normal",
      font = wezterm.font({
        family = "MonoLisa",
        style = "Oblique",
        scale = 1,
        harfbuzz_features = {
          "calt=1",
          "liga=1",
          "ss03=1",
          "zero=1",
          "ss01=0",
          "ss02=0",
          "ss06=1",
          "ss07=0",
          "ss08=1",
          "ss10=1",
          "ss11=1",
          "ss12=1",
          "ss13=1",
          "ss14=1",
          "ss15=0",
          "ss16=0",
          "ss17=1",
        },
      }),
    },
  }
end

return M
