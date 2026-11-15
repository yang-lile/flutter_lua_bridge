local bridge = require("scenarios_bridge")

-- The selected formula is runtime data. Dart calls one typed method; Lua can
-- replace or extend this table without changing the Dart contract.
local formulas = {
  double = function(input)
    return input.base * 2
  end,
  affine = function(input)
    return input.base * input.multiplier + input.add
  end,
  clamp_candidate = function(input)
    return input.base * input.multiplier + input.add
  end,
}

return bridge.bindDynamicLuaApi({
  calculate = function(input)
    local formula = formulas[input.operation]
    assert(formula, "unknown dynamic formula: " .. input.operation)
    return {
      value = formula(input),
      implementation = "dynamic:" .. input.operation,
    }
  end,
})
