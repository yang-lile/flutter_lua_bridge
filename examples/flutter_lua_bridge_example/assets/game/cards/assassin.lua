-- 刺客卡牌配置

return {
    id = "assassin_001",
    name = "暗影刺客",
    description = "高速度高暴击的爆发型怪物",
    rarity = "SSR",
    
    baseStats = {
        hp = 650,
        attack = 100,
        magicAttack = 15,
        physicalDefense = 25,
        magicDefense = 25,
        speed = 95,            -- 速度极快
        critRate = 0.30,       -- 高暴击率
        critDamage = 2.5,      -- 高暴击伤害
        magicCritRate = 0.05,
    },
    
    normalAttack = {
        name = "背刺",
        description = "造成110%物理伤害",
        type = "PHYSICAL",
        multiplier = 1.1,
        target = "SINGLE",
    },
    
    skill = {
        name = "暗影突袭",
        description = "造成180%物理伤害，无视30%防御",
        type = "PHYSICAL",
        multiplier = 1.8,
        target = "SINGLE",
        cooldown = 2,
        ignoreDefense = 0.3,  -- 无视30%防御
        specialEffect = nil
    },
    
    passive = {
        name = "隐身",
        description = "首回合隐身，受到的伤害减少50%",
        trigger = "ON_BATTLE_START",
        effect = function(monster)
            monster.stealth = true
            monster.damageReduction = 0.5
            return "stealth_activated"
        end
    }
}
