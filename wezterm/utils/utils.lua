local M = {}

local wezterm = require("wezterm") --[[@as Wezterm]]
-- local lfs = require("lfs")

---@param path string
---@return integer
function M.checkDir(path)
  local isWin = wezterm.target_triple:find("windows")
  local response = false
  if isWin then
    return os.execute('cd "' .. path .. '" >nul 2>nul')
  else
    return os.execute('cd "' .. path .. '" 2>/dev/null')
  end
end

return M
