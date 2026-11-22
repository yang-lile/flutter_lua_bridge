-- A module of the bundle, loaded with require("greeting").
local M = {}

function M.text(version, taps)
  if taps == 0 then return "来自服务器的 " .. version end
  return version .. "：点了 " .. taps .. " 次"
end

return M
