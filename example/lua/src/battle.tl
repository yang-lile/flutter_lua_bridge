local bridge = require("battle_bridge")
local host = bridge.getHostApi()

local implementation: bridge.BattleApi = {
  calculate_damage = function(attacker: bridge.Fighter, defender: bridge.Fighter): bridge.DamageResult
    local damage = math.max(0, attacker.attack - defender.defense)
    host.log("calculated damage " .. damage)
    return { damage = host.bonus(damage), critical = false }
  end,
}
return bridge.bindBattleApi(implementation)
