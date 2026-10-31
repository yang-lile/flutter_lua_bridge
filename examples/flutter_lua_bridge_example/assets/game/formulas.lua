-- 战斗计算公式配置

-- 物理伤害公式
-- attacker: 攻击者属性表
-- defender: 防御者属性表
-- skillMultiplier: 技能倍率 (普攻为 1.0)
function calculatePhysicalDamage(attacker, defender, skillMultiplier)
    local baseDamage = attacker.attack * (skillMultiplier or 1.0)
    local defense = defender.physicalDefense
    
    -- 防御减免公式: 防御越高减免越多，但收益递减
    local damageReduction = defense / (defense + 100)
    local finalDamage = baseDamage * (1 - damageReduction)
    
    -- 暴击判定
    local isCrit = math.random() < (attacker.critRate or 0.1)
    if isCrit then
        finalDamage = finalDamage * (attacker.critDamage or 1.5)
    end
    
    -- 随机波动 (90% - 110%)
    local variance = 0.9 + math.random() * 0.2
    finalDamage = finalDamage * variance
    
    return math.floor(finalDamage), isCrit
end

-- 法术伤害公式
function calculateMagicDamage(attacker, defender, skillMultiplier)
    local baseDamage = attacker.magicAttack * (skillMultiplier or 1.0)
    local defense = defender.magicDefense
    
    -- 法术防御减免
    local damageReduction = defense / (defense + 80)
    local finalDamage = baseDamage * (1 - damageReduction)
    
    -- 法术暴击
    local isCrit = math.random() < ((attacker.magicCritRate or 0.05))
    if isCrit then
        finalDamage = finalDamage * (attacker.critDamage or 1.5)
    end
    
    -- 随机波动
    local variance = 0.9 + math.random() * 0.2
    finalDamage = finalDamage * variance
    
    return math.floor(finalDamage), isCrit
end

-- 治疗公式
function calculateHeal(caster, baseHealAmount)
    local healAmount = baseHealAmount * (1 + caster.magicAttack / 200)
    return math.floor(healAmount)
end

-- 战斗速度判定 (决定出手顺序)
function getActionOrder(monsters)
    -- 复制表避免修改原数据
    local order = {}
    for i, monster in ipairs(monsters) do
        table.insert(order, {
            index = i,
            speed = monster.speed,
            name = monster.name
        })
    end
    
    -- 按速度降序排序
    table.sort(order, function(a, b) return a.speed > b.speed end)
    
    return order
end

-- 战斗结果判定
function checkBattleResult(teamA, teamB)
    local teamAAlive = false
    local teamBAlive = false
    
    for _, m in ipairs(teamA) do
        if m.hp > 0 then
            teamAAlive = true
            break
        end
    end
    
    for _, m in ipairs(teamB) do
        if m.hp > 0 then
            teamBAlive = true
            break
        end
    end
    
    if teamAAlive and not teamBAlive then
        return "TEAM_A_WIN"
    elseif teamBAlive and not teamAAlive then
        return "TEAM_B_WIN"
    elseif not teamAAlive and not teamBAlive then
        return "DRAW"
    else
        return "ONGOING"
    end
end

-- 打印战斗日志
function logBattle(message)
    print("[BATTLE] " .. message)
end

return {
    calculatePhysicalDamage = calculatePhysicalDamage,
    calculateMagicDamage = calculateMagicDamage,
    calculateHeal = calculateHeal,
    getActionOrder = getActionOrder,
    checkBattleResult = checkBattleResult,
    logBattle = logBattle
}
