-- The combat formulas without the app:
--   dart run flutter_lua_bridge_codegen:run lua/test/formulas_test.tl
local type bridge = require("battle_bridge")
local formulas = require("formulas")

local function fighter(speed: integer, hp: integer): bridge.Fighter
  return {
    name = "f", hp = hp, maxHp = 1000,
    attack = 100, magicAttack = 100,
    physicalDefense = 100, magicDefense = 80, speed = speed,
    critRate = 0.1, critDamage = 2.0, magicCritRate = 0.1,
  }
end

local a, d = fighter(50, 1000), fighter(50, 1000)

-- 100 attack against 100 defense with softness 100 halves the damage;
-- variance 0.5 is the neutral roll.
local hit = formulas.physicalDamage(a, d, 1.0, { crit = 0.99, variance = 0.5 })
assert(hit.amount == 50 and not hit.critical, "plain hit: " .. hit.amount)

local crit = formulas.physicalDamage(a, d, 1.0, { crit = 0.0, variance = 0.5 })
assert(crit.amount == 100 and crit.critical, "critical hit: " .. crit.amount)

local magic = formulas.magicDamage(a, d, 2.0, { crit = 0.99, variance = 0.0 })
assert(magic.amount == 90, "magic hit: " .. magic.amount)

assert(formulas.heal(a, 100) == 150, "heal")

-- Faster first, ties by position, defeated fighters skipped; 0-based.
local order = formulas.actionOrder({
  fighter(50, 10), fighter(95, 10), fighter(99, 0), fighter(95, 10),
})
assert(#order == 3 and order[1] == 1 and order[2] == 3 and order[3] == 0,
  "action order: " .. table.concat(order, ","))
