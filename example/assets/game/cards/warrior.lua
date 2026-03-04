-- 战士卡牌配置

return {
    id = "warrior_001",
    name = "狂暴战士",
    description = "高血量高物理攻击的坦克型怪物",
    rarity = "SR",  -- N, R, SR, SSR, UR
    
    -- 基础属性
    baseStats = {
        hp = 1200,
        attack = 85,           -- 物理攻击
        magicAttack = 10,      -- 法术攻击 (战士很低)
        physicalDefense = 60,  -- 物理防御
        magicDefense = 20,     -- 法术防御
        speed = 50,
        critRate = 0.15,       -- 暴击率
        critDamage = 2.0,      -- 暴击伤害倍率
        magicCritRate = 0.0,
    },
    
    -- 普通攻击
    normalAttack = {
        name = "重击",
        description = "造成100%物理伤害",
        type = "PHYSICAL",  -- PHYSICAL / MAGIC
        multiplier = 1.0,   -- 伤害倍率
        target = "SINGLE",  -- SINGLE / ALL
    },
    
    -- 技能
    skill = {
        name = "旋风斩",
        description = "造成150%物理伤害，并有30%概率眩晕目标",
        type = "PHYSICAL",
        multiplier = 1.5,
        target = "SINGLE",
        cooldown = 2,  -- 冷却回合
        specialEffect = function(caster, target)
            -- 30%概率眩晕
            if math.random() < 0.3 then
                target.stunned = true
                return "stunned"
            end
            return nil
        end
    },
    
    -- 被动技能
    passive = {
        name = "狂战士之血",
        description = "血量低于30%时，攻击力提升50%",
        trigger = "ON_HP_CHANGE",
        effect = function(monster)
            if monster.hp < monster.maxHp * 0.3 then
                if not monster.berserkActive then
                    monster.attack = monster.attack * 1.5
                    monster.berserkActive = true
                    return "berserk_activated"
                end
            else
                if monster.berserkActive then
                    monster.attack = monster.attack / 1.5
                    monster.berserkActive = false
                end
            end
        end
    }
}
