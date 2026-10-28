local bridge = require("scenarios_bridge")

local implementation: bridge.PureTealApi = {
  calculate = function(input: bridge.CalculationInput): bridge.CalculationResult
    return {
      value = input.base * input.multiplier + input.add,
      implementation = "pure-teal",
    }
  end,
}

return bridge.bindPureTealApi(implementation)
