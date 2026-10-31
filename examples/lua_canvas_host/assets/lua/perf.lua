-- host/perf.lua
--
-- 热点策略注册表。
--
-- ## 为什么要有这个表
--
-- 整条链路上有三处"每次执行都要跑一遍"的热点，它们的实现各有各的优化空间，
-- 而且改一处很容易漏掉另一处（canvas 和 ui 各写了一份内容指纹，
-- 只是碰巧长得不一样）。集中注册之后：
--
--   1. 优化只写一遍，canvas / ui 共用
--   2. 宿主可以按需切换策略（快 vs 可读），不必改业务代码
--   3. **各能力声明自己需要哪些标准库，宿主据此只开那几个**——
--      这一条不是性能优化，是把能力契约层落到实处：
--      `host/init.lua` 一直声称"业务代码不直接碰 io / os"，
--      但 `openLibs()` 把 io 也开了，契约只是一句空话。
--
-- ## 用法
--
-- ```lua
-- local perf = require("perf")
--
-- perf.register("fingerprint", "fast", impl, { desc = "..." })
-- perf.use("fingerprint", "fast")            -- 可省略，登记时给 default
-- local fp = perf.get("fingerprint")          -- 拿到当前实现
--
-- perf.declare_libs("ui", { "string", "table", "math" })
-- perf.lib_mask()                             -- 宿主据此开库
-- ```
--
-- 注册表本身是纯 Lua，宿主（Dart）通过 `perf.report()` 拿一份 JSON。

-- perf 刻意**不 require host**。
--
-- host/init.lua 需要 perf 来登记标准库需求，而 perf 若反过来 require host
-- 就成了循环依赖（Lua 会直接报 "loop or previous error loading module"）。
-- 保持 perf 是纯模块，由 host 在自己加载完��把它挂成能力（见 host/init.lua 末尾）。

local perf = {}

perf._strategies = {}   -- kind -> { name -> impl }
perf._defaults = {}     -- kind -> name
perf._meta = {}         -- kind -> name -> { desc, since }
perf._libs = {}         -- 模块名 -> 提供它的能力（可能多个）
perf._order = {}        -- 声明顺序，只为让 report 输出稳定

local LIB_MASKS = {
  base      = 1,        -- LUA_GLIBK
  package   = 2,        -- LUA_LOADLIBK
  coroutine = 4,        -- LUA_COLIBK
  debug     = 8,        -- LUA_DBLIBK
  io        = 16,       -- LUA_IOLIBK
  math      = 32,       -- LUA_MATHLIBK
  os        = 64,       -- LUA_OSLIBK
  string    = 128,      -- LUA_STRLIBK
  table     = 256,      -- LUA_TABLIBK
  utf8      = 512,      -- LUA_UTF8LIBK
}

-- ============ 策略 ============

--- 登记一个策略实现。
---
--- @param kind string 类别，例如 "fingerprint" / "json_number"
--- @param name string 策略名
--- @param impl function 实现
--- @param opts table|nil { desc = ..., default = true }
function perf.register(kind, name, impl, opts)
  if type(kind) ~= "string" or kind == "" then
    error("perf.register: kind 必须是非空字符串", 2)
  end
  if type(name) ~= "string" or name == "" then
    error("perf.register: name 必须是非空字符串", 2)
  end
  if type(impl) ~= "function" then
    error("perf.register: impl 必须是函数，实际是 " .. type(impl), 2)
  end

  perf._strategies[kind] = perf._strategies[kind] or {}
  perf._meta[kind] = perf._meta[kind] or {}
  perf._strategies[kind][name] = impl
  perf._meta[kind][name] = {
    desc = (opts and opts.desc) or "",
    since = opts and opts.since or "",
  }

  -- 第一个登记的默认生效，之后除非显式指定不再改——
  -- 默认值必须是确定的，否则行为取决于模块加载顺序。
  if opts and opts.default then
    perf._defaults[kind] = name
  elseif perf._defaults[kind] == nil then
    perf._defaults[kind] = name
  end
end

--- 切换某类别的当前策略。
function perf.use(kind, name)
  local pool = perf._strategies[kind]
  if not pool then
    error("perf.use: 未知类别 '" .. tostring(kind) .. "'", 2)
  end
  if not pool[name] then
    local names = {}
    for k in pairs(pool) do names[#names + 1] = k end
    table.sort(names)
    error("perf.use: " .. kind .. " 没有策略 '" .. tostring(name)
      .. "'。可用: " .. table.concat(names, ", "), 2)
  end
  perf._defaults[kind] = name
end

--- 取当前策略的实现。类别不存在时返回 nil——
--- 调用方自己决定"没有指纹"该怎么办（canvas 和 ui 的选择就不同）。
function perf.get(kind)
  local name = perf._defaults[kind]
  if not name then return nil end
  return perf._strategies[kind][name]
end

function perf.current(kind)
  return perf._defaults[kind]
end

-- ============ 内容指纹 ============
--
-- 用途只有一个：宿主判断"这一帧和上一帧内容是否一样"。
-- 所以要求是：
--   1. 同样的内容必须得到同样的值（否则每次都重绘）
--   2. 任何字段变化都必须改变它（否则漏更新）
--   3. **不能依赖 pairs 的遍历顺序**（Lua 的 hash 顺序不保证）
--
-- 早期实现为了满足第 3 条，对**每一层 table 都做一次 table.sort**。
-- 在 6000 个节点的 UI 树上，光这一项就占 build 总耗时的一大半。

local function mix_str(h, s)
  for i = 1, #s do
    h = (h * 33 + s:byte(i)) & 0xFFFFFFFF
  end
  return h
end

-- 顺序无关的累加：加法而不是异或。
--
-- 异或有个讨厌的性质：出现两次的项会互相抵消（a^b^a == b），
-- 于是 {"a":1,"a":1} 和 {} 会得到同一个值。加法不会。
local function fast_impl(value)
  -- 顺序无关的累加：加法而不是异或。
  --
  -- 异或有个讨厌的性质：出现两次的项会互相抵消（a^b^a == b），
  -- 于是 {"a":1,"a":1} 和 {} 会得到同一个值。加法不会。
  --
  -- 每个表用**自己的**元素个数，不能用全局累加器：
  -- pairs 的遍历顺序不保证，全局计数会让同一个表在不同遍历里得到不同的值
  -- ——表现为“同一份内容连续 build 两次，指纹不一样”，宿主于是白白重绘。
  local function walk(v)
    local tv = type(v)
    if tv == "table" then
      local acc = 0x811C9DC5        -- FNV 偏移基
      local n = 0
      for k, val in pairs(v) do
        local e = mix_str(0x01000193, tostring(k))
        e = (e + walk(val)) & 0xFFFFFFFF
        acc = (acc + e) & 0xFFFFFFFF
        n = n + 1
      end
      return (acc + n * 0x9E3779B1) & 0xFFFFFFFF
    elseif tv == "string" then
      return mix_str(0x01000193, v)
    elseif tv == "number" then
      -- tostring 对整数和浮点的表示不同（"1" vs "1.0"），
      -- 这正是我们要的：契约里 int / double 是有区别的。
      return mix_str(0x01000193, tostring(v))
    elseif tv == "boolean" then
      return v and 0x5BF03635 or 0x27D4EB2F
    elseif v == nil then
      return 0x165667B1
    end
    -- 函数 / userdata / thread 出现在契约里就是 bug，
    -- 给一个稳定但独特的值，至少不会误判成"没变"。
    return mix_str(0x01000193, "<" .. tv .. ">")
  end

  local h = walk(value)
  return string.format("%08x%08x", h, 0)
end

local function canonical_impl(value)
  -- 原来的实现：逐层排序。慢，但结构上更直白，
  -- 保留作为对照与回归基准——两种实现必须对同一棵树给出相同判定。
  local function walk(h, v)
    local tv = type(v)
    if tv == "table" then
      local keys = {}
      for k in pairs(v) do keys[#keys + 1] = k end
      table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
      for _, k in ipairs(keys) do
        h = mix_str(h, tostring(k))
        h = walk(h, v[k])
      end
      return h
    elseif tv == "string" then
      return mix_str(h, v)
    elseif tv == "number" then
      return mix_str(h, tostring(v))
    elseif tv == "boolean" then
      h = mix_str(h, v and "true" or "false")
      return h
    elseif v == nil then
      return mix_str(h, "nil")
    end
    return mix_str(h, "<" .. tv .. ">")
  end
  local h = walk(0x811C9DC5, value)
  return string.format("%08x%08x", h, 0)
end

perf.register("fingerprint", "canonical", canonical_impl, {
  desc = "逐层 table.sort，可读、逐位确定（回归基准用）",
})
perf.register("fingerprint", "fast", fast_impl, {
  desc = "顺序无关累积，无排序。默认",
  default = true,
  since = "1.1.0",
})

-- ============ JSON 数字 ============
--
-- JSON 没有"整数 / 浮点"的区分，解析端只能靠字面量形态还原。
-- 纯 Lua 的 json 一直用 %.14g，而 binary64 需要 **17 位有效数字**
-- 才保证精确往返：0.1+0.2 会被打成 0.3，1/3 变成 0.33333333333333。
-- 对端若用 v<double>() 之类的类型判定，丢的就是精度本身。

local function number_14g(v)
  if v ~= v or v == math.huge or v == -math.huge then
    error("json: cannot encode " .. tostring(v))
  end
  return string.format("%.14g", v)
end

local function number_17g(v)
  if v ~= v or v == math.huge or v == -math.huge then
    error("json: cannot encode " .. tostring(v))
  end
  return string.format("%.17g", v)
end

local function number_exact(v)
  if v ~= v or v == math.huge or v == -math.huge then
    error("json: cannot encode " .. tostring(v))
  end
  -- 整数走 %d：JSON 里没有 int 概念，但不带小数点能让对端解析成整数，
  -- 而 rfw 的 v<int>() 对 double 返回 null —— 带不带 ".0" 是有意义的。
  if math.type(v) == "integer" then
    return string.format("%d", v)
  end
  local s = string.format("%.17g", v)
  -- %.17g 可能吐出 "40" 这种形态，补 ".0" 让它仍然是浮点
  if not s:find("[%.eE]") then s = s .. ".0" end
  return s
end

perf.register("json_number", "lenient", number_14g,
  { desc = "%.14g，体积最小，会丢浮点精度" })
perf.register("json_number", "exact", number_exact,
  { desc = "整数 %d / 浮点 %.17g 并补 .0，精确往返。默认", default = true })

-- ============ 标准库需求声明 ============

--- 声明某能力需要哪些标准库。
---
--- 宿主据此只开这几个，`io` 之类不在任何声明里就永远不会被打开。
--- 这同时是一道防线：`host/init.lua` 声称业务代码不该直接碰 io，
--- 那就别给它 io。
function perf.declare_libs(module, libs)
  if type(module) ~= "string" or module == "" then
    error("perf.declare_libs: module 必须是非空字符串", 2)
  end
  if type(libs) ~= "table" then
    error("perf.declare_libs: libs 必须是 table，实际是 " .. type(libs), 2)
  end
  perf._libs[module] = perf._libs[module] or {}
  perf._order[#perf._order + 1] = module
  for _, name in ipairs(libs) do
    if not LIB_MASKS[name] then
      local names = {}
      for k in pairs(LIB_MASKS) do names[#names + 1] = k end
      table.sort(names)
      error("perf.declare_libs: 未知标准库 '" .. tostring(name)
        .. "'。可用: " .. table.concat(names, ", "), 2)
    end
    perf._libs[module][name] = true
  end
end

--- 汇总所有声明，返回掩码与库名列表（有序）。
---
--- @return int mask, string[] names
function perf.lib_mask()
  local mask = LIB_MASKS.base       -- base 是语言本身，永远需要
  local names = { "base" }
  -- 按名字排，保证输出稳定（测试要断言它）
  local all = {}
  for lib in pairs(LIB_MASKS) do all[#all + 1] = lib end
  table.sort(all)

  for _, lib in ipairs(all) do
    if lib ~= "base" then
      for _, mod in ipairs(perf._order) do
        if perf._libs[mod] and perf._libs[mod][lib] then
          mask = mask + LIB_MASKS[lib]      -- 位掩码互不相交，所以加等价于 or
          names[#names + 1] = lib
          break
        end
      end
    end
  end
  return mask, names
end

--- 供诊断：谁声明了哪些库。
function perf.lib_report()
  local out = {}
  for _, mod in ipairs(perf._order) do
    local libs = {}
    for lib in pairs(perf._libs[mod]) do libs[#libs + 1] = lib end
    table.sort(libs)
    out[mod] = libs
  end
  return out
end

-- ============ 诊断输出 ============

--- 一份 JSON 快照，宿主在调试面板 / 测试里用。
function perf.report()
  local json = require("host").require_cap("json")
  local strategies = {}
  for kind, pool in pairs(perf._strategies) do
    local names = {}
    for name in pairs(pool) do names[#names + 1] = name end
    table.sort(names)
    local items = {}
    for i, name in ipairs(names) do
      local meta = perf._meta[kind][name] or {}
      items[i] = {
        name = name,
        desc = meta.desc or "",
        since = meta.since or "",
        active = (perf._defaults[kind] == name),
      }
    end
    strategies[kind] = items
  end
  local mask, names = perf.lib_mask()
  return json.encode({
    strategies = strategies,
    lib_mask = mask,
    libs = names,
    lib_report = perf.lib_report(),
  })
end

-- 能力登记由 host 完成，这里只导出表本身。
-- perf.fingerprint 直接暴露当前策略的实现，省得调用方再 get 一次。
function perf.fingerprint(value)
  return fast_impl(value)
end

perf.strategies = perf._strategies
perf.defaults = perf._defaults
perf.LIB_MASKS = LIB_MASKS

return perf
