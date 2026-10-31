-- 治疗者卡牌配置

return {
    id = "healer_001",
    name = "圣光牧师",
    description = "提供治疗和支援的辅助型怪物",
    rarity = "SR",
    
    baseStats = {
        hp = 900,
        attack = 30,
        magicAttack = 60,
        physicalDefense = 35,
        magicDefense = 45,
        speed = 60,
        critRate = 0.05,
        critDamage = 1.5,
        magicCritRate = 0.1,
    },
    
    normalAttack = {
        name = "圣光惩戒",
        description = "造成80%法术伤害",
        type = "MAGIC",
        multiplier = 0.8,
        target = "SINGLE",
    },
    
    skill = {
        name = "群体治疗",
        description = "为全队恢复150+50%法强的生命值",
        type = "HEAL",  -- 特殊类型：治疗
        multiplier = 0, -- 不适用
        target = "ALL_ALLY",
        cooldown = 3,
        healBase = 150,
        specialEffect = nil
    },
    
    passive = {
        name = "救赎",
        description = "当队友血量低于20%时，自动为其恢复10%最大生命值（每场战斗触发一次）",
        trigger = "ON_ALLY_LOW_HP",
        used = false,
        effect = function(monster, ally)
            if not monster.passive.used and ally.hp < ally.maxHp * 0.2 then
                local heal = math.floor(ally.maxHp * 0.1)
                ally.hp = math.min(ally.maxHp, ally.hp + heal)
                monster.passive.used = true
                return "emergency_heal_" .. heal
            end
            return nil
        end
    }
}
