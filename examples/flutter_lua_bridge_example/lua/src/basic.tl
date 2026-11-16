local bridge = require("basic_api_bridge")

-- "Lua 5.4" -> 504, the same number as LUA_VERSION_NUM on the C side
local function luaVersionNum(): integer
  local major, minor = _VERSION:match("^Lua (%d+)%.(%d+)")
  return math.tointeger(tonumber(major) * 100 + tonumber(minor))
end

local implementation: bridge.BasicApi = {
  run = function(): bridge.RandomResult
    return {
      luaVersion = luaVersionNum(),
      a = math.random(1, 1024),
      b = math.random(1, 1024),
    }
  end,
}

return bridge.bindBasicApi(implementation)
