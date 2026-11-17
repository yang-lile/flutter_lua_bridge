-- The card catalog and passives. Outside the app `bindCardApi` is a stub that
-- returns the table unchanged, so the functions are called directly.
local type bridge = require("battle_bridge")
local cards = require("cards")

local function fighter(hp: integer): bridge.Fighter
  return {
    name = "f", hp = hp, maxHp = 1000,
    attack = 100, magicAttack = 100,
    physicalDefense = 50, magicDefense = 50, speed = 50,
    critRate = 0.1, critDamage = 2.0, magicCritRate = 0.1,
  }
end

local catalog = cards.catalog()
assert(#catalog == 4, "catalog size: " .. #catalog)
local ids: {string: boolean} = {}
for _, card in ipairs(catalog) do
  assert(not ids[card.id], "duplicate id " .. card.id)
  ids[card.id] = true
  assert(card.stats.hp > 0 and card.skill.cooldown >= 0, card.id)
end

-- Berserk fires once below 30% HP, and only on its own trigger.
local full, low = fighter(1000), fighter(200)
assert(cards.passive("warrior_001", "TURN_START", full, full) == nil)
local berserk = cards.passive("warrior_001", "TURN_START", low, low)
assert(berserk and berserk.attackScale == 1.5 and berserk.once, "berserk")
assert(cards.passive("warrior_001", "BATTLE_START", low, low) == nil)

-- The mage regenerates only when hurt.
assert(cards.passive("mage_001", "TURN_START", full, full) == nil)
assert(cards.passive("mage_001", "TURN_START", low, low).heal == 50)

-- Whirlwind stuns below a 0.3 roll.
assert(cards.skillEffect("warrior_001", full, 0.1).stun)
assert(cards.skillEffect("warrior_001", full, 0.5) == nil)

print(("%d cards, passives ok"):format(#catalog))
