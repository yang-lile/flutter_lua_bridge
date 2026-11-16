-- A deliberately broken replacement for formulas.lua, loaded under the same
-- module name by the safety level page and the tests. It shows what each
-- level does with a script that has a bug: plain Lua, so that Teal does not
-- reject the bugs at build time.
local formulas = {}

-- Wrong result type: the amount is a string.
function formulas.physicalDamage(attacker, defender, multiplier, roll)
  return { amount = tostring(attacker.attack), critical = false }
end

-- A runtime error.
function formulas.magicDamage(attacker, defender, multiplier, roll)
  error("magic formula crashed: " .. attacker.name)
end

-- A float where the contract says int.
function formulas.heal(caster, base)
  return base * 1.5
end

-- Correct.
function formulas.actionOrder(fighters)
  local order = {}
  for i = 1, #fighters do order[i] = i - 1 end
  return order
end

return formulas
