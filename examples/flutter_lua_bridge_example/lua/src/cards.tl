-- The card catalog, passives and skill effects of the battle game.
-- Implements CardApi from lib/bridge/battle.dart.
local bridge = require("battle_bridge")

local type CardSpec = bridge.CardSpec
local type Effect = bridge.Effect
local type Fighter = bridge.Fighter

local function effect(note: string): Effect
  return {
    note = note,
    heal = 0,
    attackScale = 1.0,
    damageReduction = 0.0,
    stun = false,
    once = false,
  }
end

local catalog: {CardSpec} = {
  {
    id = "warrior_001",
    name = "狂暴战士",
    description = "高血量高物理攻击的坦克型怪物",
    rarity = "SR",
    stats = {
      hp = 1200, attack = 85, magicAttack = 10,
      physicalDefense = 60, magicDefense = 20, speed = 50,
      critRate = 0.15, critDamage = 2.0, magicCritRate = 0.0,
    },
    normalAttack = {
      name = "重击", description = "造成 100% 物理伤害",
      damageType = "PHYSICAL", multiplier = 1.0, target = "SINGLE", cooldown = 0,
    },
    skill = {
      name = "旋风斩", description = "造成 150% 物理伤害，30% 概率眩晕目标",
      damageType = "PHYSICAL", multiplier = 1.5, target = "SINGLE", cooldown = 2,
    },
    passive = {
      name = "狂战士之血", description = "生命低于 30% 时攻击力提升 50%（每场一次）",
      trigger = "TURN_START",
    },
  },
  {
    id = "mage_001",
    name = "元素法师",
    description = "高法术伤害但脆弱的输出型怪物",
    rarity = "SSR",
    stats = {
      hp = 700, attack = 20, magicAttack = 120,
      physicalDefense = 15, magicDefense = 50, speed = 70,
      critRate = 0.05, critDamage = 1.5, magicCritRate = 0.2,
    },
    normalAttack = {
      name = "魔法弹", description = "造成 100% 法术伤害",
      damageType = "MAGIC", multiplier = 1.0, target = "SINGLE", cooldown = 0,
    },
    skill = {
      name = "陨石术", description = "造成 220% 法术伤害",
      damageType = "MAGIC", multiplier = 2.2, target = "SINGLE", cooldown = 3,
    },
    passive = {
      name = "元素亲和", description = "每回合开始时恢复 5% 最大生命",
      trigger = "TURN_START",
    },
  },
  {
    id = "healer_001",
    name = "圣光牧师",
    description = "提供治疗和支援的辅助型怪物",
    rarity = "SR",
    stats = {
      hp = 900, attack = 30, magicAttack = 60,
      physicalDefense = 35, magicDefense = 45, speed = 60,
      critRate = 0.05, critDamage = 1.5, magicCritRate = 0.1,
    },
    normalAttack = {
      name = "圣光惩戒", description = "造成 80% 法术伤害",
      damageType = "MAGIC", multiplier = 0.8, target = "SINGLE", cooldown = 0,
    },
    skill = {
      name = "群体治疗", description = "为全队恢复 150 点基础生命，受法术攻击加成",
      damageType = "HEAL", multiplier = 0.0, target = "ALL_ALLIES", cooldown = 3,
      healBase = 150,
    },
    passive = {
      name = "救赎", description = "队友生命低于 20% 时为其恢复 10% 最大生命（每场一次）",
      trigger = "ALLY_LOW_HP",
    },
  },
  {
    id = "assassin_001",
    name = "暗影刺客",
    description = "高速度高暴击的爆发型怪物",
    rarity = "SSR",
    stats = {
      hp = 650, attack = 100, magicAttack = 15,
      physicalDefense = 25, magicDefense = 25, speed = 95,
      critRate = 0.3, critDamage = 2.5, magicCritRate = 0.05,
    },
    normalAttack = {
      name = "背刺", description = "造成 110% 物理伤害",
      damageType = "PHYSICAL", multiplier = 1.1, target = "SINGLE", cooldown = 0,
    },
    skill = {
      name = "暗影突袭", description = "造成 180% 物理伤害，无视 30% 物理防御",
      damageType = "PHYSICAL", multiplier = 1.8, target = "SINGLE", cooldown = 2,
      ignoreDefense = 0.3,
    },
    passive = {
      name = "隐身", description = "进入战斗时隐身，受到的伤害减少 50%",
      trigger = "BATTLE_START",
    },
  },
}

local triggers: {string: bridge.PassiveTrigger} = {}
for _, card in ipairs(catalog) do
  if card.passive then triggers[card.id] = card.passive.trigger end
end

local passives: {string: function(Fighter, Fighter): Effect} = {
  warrior_001 = function(self: Fighter, _: Fighter): Effect
    if self.hp < self.maxHp * 0.3 then
      local e = effect("狂暴：攻击力 +50%")
      e.attackScale = 1.5
      e.once = true
      return e
    end
    return nil
  end,
  mage_001 = function(self: Fighter, _: Fighter): Effect
    if self.hp >= self.maxHp then return nil end
    local e = effect("元素亲和")
    e.heal = math.floor(self.maxHp * 0.05)
    return e
  end,
  healer_001 = function(_: Fighter, ally: Fighter): Effect
    if ally.hp > 0 and ally.hp < ally.maxHp * 0.2 then
      local e = effect("救赎")
      e.heal = math.floor(ally.maxHp * 0.1)
      e.once = true
      return e
    end
    return nil
  end,
  assassin_001 = function(_: Fighter, _: Fighter): Effect
    local e = effect("隐身：受到伤害 -50%")
    e.damageReduction = 0.5
    return e
  end,
}

return bridge.bindCardApi({
  catalog = function(): {CardSpec}
    return catalog
  end,
  passive = function(cardId: string, trigger: bridge.PassiveTrigger, self: Fighter, target: Fighter): Effect
    local fire = passives[cardId]
    if fire == nil or triggers[cardId] ~= trigger then return nil end
    return fire(self, target)
  end,
  skillEffect = function(cardId: string, _: Fighter, roll: number): Effect
    if cardId == "warrior_001" and roll < 0.3 then
      local e = effect("眩晕")
      e.stun = true
      return e
    end
    return nil
  end,
})
