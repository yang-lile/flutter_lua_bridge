local bridge = require("battle_bridge")
local host = bridge.getHostApi()

local implementation = {
   calculate_damage = function(attacker, defender)
      local damage = math.max(0, attacker.attack - defender.defense)
      host.log("calculated damage " .. damage)
      return { damage = host.bonus(damage), critical = false }
   end,
}
return bridge.bindBattleApi(implementation)
