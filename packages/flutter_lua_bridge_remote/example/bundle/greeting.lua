local M = {}

function M.text(taps)
  if taps == 0 then return "Hello from a Lua bundle" end
  return "Tapped " .. taps .. " times"
end

return M
