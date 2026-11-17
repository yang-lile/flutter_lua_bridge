-- A scratch entry: change it freely to try the Lua side out.
--   dart run flutter_lua_bridge_codegen:run lua/test/main.tl -- warrior_001
-- Arguments after `--` arrive as `...`.
local type bridge = require("battle_bridge")
local cards = require("cards")
local formulas = require("formulas")

local wanted = select(1, ...) as string

for _, card in ipairs(cards.catalog()) do
  if wanted == nil or card.id == wanted then
    local s = card.stats
    local me: bridge.Fighter = {
      name = card.name, hp = s.hp, maxHp = s.hp,
      attack = s.attack, magicAttack = s.magicAttack,
      physicalDefense = s.physicalDefense, magicDefense = s.magicDefense,
      speed = s.speed, critRate = s.critRate, critDamage = s.critDamage,
      magicCritRate = s.magicCritRate,
    }
    local hit = formulas.physicalDamage(me, me, card.skill.multiplier,
      { crit = 0.99, variance = 0.5 })
    print(("%-12s %-4s %s hits itself for %d"):format(
      card.id, card.rarity, card.skill.name, hit.amount))
  end
end
