local bridge = require("scenarios_bridge")

return bridge.bindPureLuaApi({
  calculate = function(input)
    return {
      value = input.base * input.multiplier + input.add,
      implementation = "pure-lua",
    }
  end,
})
