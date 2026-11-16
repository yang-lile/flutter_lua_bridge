

local bridge = require("battle_bridge")
local formulas = require("formulas")

return bridge.bindFormulasO2Api({
   physicalDamage = formulas.physicalDamage,
   magicDamage = formulas.magicDamage,
   heal = formulas.heal,
   actionOrder = formulas.actionOrder,
})
