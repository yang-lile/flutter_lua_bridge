-- A module that calls Dart (@DartApi ScenarioHostApi). Outside the app,
-- getScenarioHostApi() returns a stub table: assign stand-ins for the Dart
-- functions it uses. Calling one that is not assigned raises an error.
local bridge = require("scenarios_bridge")
local host = bridge.getScenarioHostApi()
host.clamp = function(value, low, high)
  return math.max(low, math.min(high, value))
end
host.label = function(name) return "stub:" .. name end

local api = require("dart_host")
local result = api.calculate({ base = 30, multiplier = 4, add = 5 })
assert(result.value == 100, "clamped to 100, got " .. result.value)
assert(result.implementation == "stub:dart-host", result.implementation)
