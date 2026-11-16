local bridge = require("basic_api_bridge")


local function luaVersionNum()
   local major, minor = _VERSION:match("^Lua (%d+)%.(%d+)")
   return math.tointeger(tonumber(major) * 100 + tonumber(minor))
end

local implementation = {
   run = function()
      return {
         luaVersion = luaVersionNum(),
         a = math.random(1, 1024),
         b = math.random(1, 1024),
      }
   end,
}

return bridge.bindBasicApi(implementation)
