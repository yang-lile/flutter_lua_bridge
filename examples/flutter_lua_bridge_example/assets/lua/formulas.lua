












local function damage(base, defense, softness, critRate, critDamage, roll)
   local amount = base * (1 - defense / (defense + softness))
   local critical = roll.crit < critRate
   if critical then amount = amount * critDamage end
   amount = amount * (0.9 + roll.variance * 0.2)
   return { amount = math.max(1, math.floor(amount)), critical = critical }
end

local function physicalDamage(attacker, defender, multiplier, roll)
   return damage(attacker.attack * multiplier, defender.physicalDefense, 100,
   attacker.critRate, attacker.critDamage, roll)
end

local function magicDamage(attacker, defender, multiplier, roll)
   return damage(attacker.magicAttack * multiplier, defender.magicDefense, 80,
   attacker.magicCritRate, attacker.critDamage, roll)
end

local function heal(caster, base)
   return math.floor(base * (1 + caster.magicAttack / 200))
end

local function actionOrder(fighters)
   local order = {}
   for i, fighter in ipairs(fighters) do
      if fighter.hp > 0 then order[#order + 1] = i - 1 end
   end

   table.sort(order, function(a, b)
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
