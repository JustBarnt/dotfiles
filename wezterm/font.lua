local wezterm = require("wezterm") --[[@as Wezterm]]
local M = {}
local term_font = wezterm.font({
  family = "MonoLisa",
  assume_emoji_presentation = false,
  scale = 1,
  is_fallback = false,
  is_synthetic = false,
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

---@class config Config
function M.setup(config)
  config.font_size = 12
  config.line_height = 1.1
  config.freetype_load_target = "HorizontalLcd"
  ---@diagnostic disable: assign-type-mismatch
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
        assume_emoji_presentation = false,
        scale = 1,
        is_fallback = false,
        is_synthetic = false,
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
        assume_emoji_presentation = false,
        scale = 1,
        is_fallback = false,
        is_synthetic = false,
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
        assume_emoji_presentation = false,
        scale = 1,
        is_fallback = false,
        is_synthetic = false,
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
