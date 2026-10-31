local bridge = require("basic_bridge")

local implementation = {
   run = function()
      return {
         luaVersion = 504,
         a = math.random(1, 1024),
         b = math.random(1, 1024),
      }
   end,
}

return bridge.bindBasicApi(implementation)
