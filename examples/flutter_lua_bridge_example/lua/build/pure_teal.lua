local bridge = require("scenarios_bridge")

local implementation = {
   calculate = function(input)
      return {
         value = input.base * input.multiplier + input.add,
         implementation = "pure-teal",
      }
   end,
}

return bridge.bindPureTealApi(implementation)
