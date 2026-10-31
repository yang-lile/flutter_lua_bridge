-- 法师卡牌配置

return {
    id = "mage_001",
    name = "元素法师",
    description = "高法术伤害但脆弱的输出型怪物",
    rarity = "SSR",
    
    baseStats = {
        hp = 700,
        attack = 20,           -- 物理攻击很低
        magicAttack = 120,     -- 法术攻击很高
        physicalDefense = 15,  -- 物理防御很低
        magicDefense = 50,     -- 法术防御
        speed = 70,
        critRate = 0.05,
        critDamage = 1.5,
        magicCritRate = 0.20,  -- 法术暴击率
    },
    
    normalAttack = {
        name = "魔法弹",
        description = "造成100%法术伤害",
        type = "MAGIC",
        multiplier = 1.0,
        target = "SINGLE",
    },
    
    skill = {
        name = "陨石术",
        description = "造成220%法术伤害",
        type = "MAGIC",
        multiplier = 2.2,
        target = "SINGLE",
        cooldown = 3,
        specialEffect = nil
    },
    
    passive = {
        name = "元素亲和",
        description = "每回合开始时恢复5%最大法力值（这里简化为小量回血）",
        trigger = "ON_TURN_START",
        effect = function(monster)
            local heal = math.floor(monster.maxHp * 0.05)
            monster.hp = math.min(monster.maxHp, monster.hp + heal)
            return "heal_" .. heal
        end
    }
}
