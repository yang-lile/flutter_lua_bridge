-- The combat formulas, shared by the three FormulasO*Api bindings
-- (formulas_o1.tl, formulas_o2.tl and formulas_o3.tl).
--
-- They are pure functions: the random numbers come in as a Roll, so a
-- battle with the same seed gives the same result at every safety level,
-- and DartFormulas (lib/game/formulas.dart) can mirror them exactly.
-- Types only: this module does not need the bridge at run time.
local type bridge = require("battle_bridge")

local type Damage = bridge.Damage
local type Fighter = bridge.Fighter
local type Roll = bridge.Roll

local function damage(base: number, defense: integer, softness: number, critRate: number, critDamage: number, roll: Roll): Damage
  local amount = base * (1 - defense / (defense + softness))
  local critical = roll.crit < critRate
  if critical then amount = amount * critDamage end
  amount = amount * (0.9 + roll.variance * 0.2)
  return { amount = math.max(1, math.floor(amount)), critical = critical }
end

local function physicalDamage(attacker: Fighter, defender: Fighter, multiplier: number, roll: Roll): Damage
  return damage(attacker.attack * multiplier, defender.physicalDefense, 100,
    attacker.critRate, attacker.critDamage, roll)
end

local function magicDamage(attacker: Fighter, defender: Fighter, multiplier: number, roll: Roll): Damage
  return damage(attacker.magicAttack * multiplier, defender.magicDefense, 80,
    attacker.magicCritRate, attacker.critDamage, roll)
end

local function heal(caster: Fighter, base: integer): integer
  return math.floor(base * (1 + caster.magicAttack / 200))
end

local function actionOrder(fighters: {Fighter}): {integer}
  local order: {integer} = {}
  for i, fighter in ipairs(fighters) do
    if fighter.hp > 0 then order[#order + 1] = i - 1 end
  end
  -- table.sort is not stable: break speed ties by position.
  table.sort(order, function(a: integer, b: integer): boolean
    local sa, sb = fighters[a + 1].speed, fighters[b + 1].speed
    if sa ~= sb then return sa > sb end
    return a < b
  end)
  return order
end

return {
  physicalDamage = physicalDamage,
  magicDamage = magicDamage,
  heal = heal,
  actionOrder = actionOrder,
}
