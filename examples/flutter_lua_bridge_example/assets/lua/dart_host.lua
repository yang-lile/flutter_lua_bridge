local bridge = require("scenarios_bridge")
local host = bridge.getScenarioHostApi()

return bridge.bindDartHostLuaApi({
  calculate = function(input)
    local raw = input.base * input.multiplier + input.add
    local value = host.clamp(raw, 0, 100)
    return {
      value = value,
      implementation = host.label("dart-host"),
    }
  end,
})
