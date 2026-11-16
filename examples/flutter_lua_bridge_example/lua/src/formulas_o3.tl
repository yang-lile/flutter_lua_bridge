-- FormulasO3Api: the shared formulas at safety level O3.
-- Each binding gets its own table: binding wraps the functions in place.
local bridge = require("battle_bridge")
local formulas = require("formulas")

return bridge.bindFormulasO3Api({
  physicalDamage = formulas.physicalDamage,
  magicDamage = formulas.magicDamage,
  heal = formulas.heal,
  actionOrder = formulas.actionOrder,
})
