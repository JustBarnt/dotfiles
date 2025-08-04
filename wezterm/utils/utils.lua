local M = {}

local wezterm = require("wezterm") --[[@as Wezterm]]
-- local lfs = require("lfs")

function M.file_exists(file)
  -- Theme / Background
  local f = io.open(file, "rb")
  if f then
    f:close()
  end
  return f ~= nil
end

---@param path string
---@return boolean?  suc
---@return exitcode? exitcode
---@return integer?  code
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
