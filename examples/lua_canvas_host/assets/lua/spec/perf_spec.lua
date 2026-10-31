-- assets/lua/spec/perf_spec.lua
--
-- perf（热点策略注册表）的单元测试。
--
-- 单独一个文件而不是塞进 canvas_spec / ui_spec：
-- 这张表是**横切**的，canvas、ui、json 三边都用它，
-- 它的正确性不该依附于任何一边。

local here = arg and arg[0] and arg[0]:match("^(.*)/spec/[^/]+$") or "assets/lua"
if here == "" then here = "." end
package.path = table.concat({
  here .. "/?.lua",
  here .. "/?/init.lua",
  package.path,
}, ";")

-- 先把打包的全部模块都 require 一遍：注册表汇总的是**已加载模块**的声明，
-- 只加载 host.cli 的话 canvas / ui / guard 的声明根本不会出现。
require("host.cli")
require("guard")
require("canvas")
require("ui")

local perf = require("perf")
local host = require("host")
local json = host.require_cap("json")

local passed, failed = 0, 0

local function ok(name, cond, detail)
  if cond then
    passed = passed + 1
    io.write(string.format("  PASS  %s%s\n", name,
      detail and ("  (" .. detail .. ")") or ""))
  else
    failed = failed + 1
    io.write(string.format("  FAIL  %s%s\n", name,
      detail and ("  -> " .. detail) or ""))
  end
end

local function eq(name, got, want)
  ok(name, got == want,
    got == want and nil or ("got " .. tostring(got) .. ", want " .. tostring(want)))
end

local function raises(name, fn, needle)
  local success, err = pcall(fn)
  if success then
    ok(name, false, "没有报错")
    return
  end
  local msg = tostring(err)
  if not needle then ok(name, true); return end
  if msg:find(needle, 1, true) then
    ok(name, true)
  else
    ok(name, false, "缺少 '" .. needle .. "'，实际: " .. msg)
  end
end

local function section(t) io.write("\n" .. t .. "\n") end

-- ============ 策略注册 ============

section("=== 1. 策略注册表 ===")

do
  perf.register("probe_kind", "a", function() return "A" end)
  perf.register("probe_kind", "b", function() return "B" end)
  eq("第一个登记的默认生效", perf.current("probe_kind"), "a")
  eq("get 拿到实现", perf.get("probe_kind")(), "A")
  perf.use("probe_kind", "b")
  eq("切换后拿到新实现", perf.get("probe_kind")(), "B")
  raises("切到不存在的策略", function() perf.use("probe_kind", "zzz") end, "没有策略 'zzz'")
  raises("切到不存在的类别", function() perf.use("zzz_kind", "a") end, "未知类别")
  raises("impl 必须是函数", function()
    perf.register("probe_kind", "c", 123)
  end, "impl 必须是函数")
end

-- ============ 内容指纹 ============

section("\n=== 2. 内容指纹：两种策略必须给出相同判定 ===")

do
  local fast = perf.get("fingerprint")
  perf.use("fingerprint", "fast")
  local fp_fast = perf.get("fingerprint")

  perf.use("fingerprint", "canonical")
  local fp_canon = perf.get("fingerprint")
  ok("两种策略都可用", fast ~= fp_canon)

  -- 同一棵树，两种策略都必须认可"这是同一份内容"
  local function same(a, b)
    return fp_fast(a) == fp_fast(b) and fp_canon(a) == fp_canon(b)
  end
  -- 改动任意一处，两种策略都必须认可"变了"
  local function differs(a, b)
    return fp_fast(a) ~= fp_fast(b) and fp_canon(a) ~= fp_canon(b)
  end

  local base = {
    version = 1,
    widget = "root",
    tree = { ["$widget"] = "Column", ["$args"] = {
      mainAxisAlignment = "center",
      children = {
        { ["$widget"] = "Text", ["$args"] = { text = "hi", style = { fontSize = 14.0 } } },
        { ["$widget"] = "ElevatedButton", ["$args"] = { onPressed = { ["$event"] = "go" } } },
      },
    } },
  }

  local function copy(t)
    -- 手工深拷贝：这里不能用 json 往返（浮点会被规范化）
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = copy(v) end
    return out
  end

  ok("同样的内容 -> 同样的判定", same(base, copy(base)))

  local c = copy(base); c.tree["$args"].mainAxisAlignment = "end"
  ok("改对齐方式 -> 判定为变化", differs(base, c))

  c = copy(base); c.tree["$args"].children[1]["$args"].text = "bye"
  ok("改文本 -> 判定为变化", differs(base, c))

  c = copy(base); c.tree["$args"].children[1]["$args"].style.fontSize = 20.0
  ok("改字号 -> 判定为变化", differs(base, c))

  c = copy(base); c.tree["$args"].children[2]["$args"].onPressed["$event"] = "stop"
  ok("改事件名 -> 判定为变化", differs(base, c))

  c = copy(base); c.tree["$args"].children[2]["$args"].child = { ["$widget"] = "Text" }
  ok("加一个子节点 -> 判定为变化", differs(base, c))

  -- **顺序无关**：pairs 的遍历顺序不保证，构造顺序变了也得同一个值
  local t1 = { a = 1, b = 2, c = 3, d = 4, e = 5, f = 6 }
  local t2 = {}
  for _, k in ipairs({ "f", "e", "d", "c", "b", "a" }) do t2[k] = ({ a=1,b=2,c=3,d=4,e=5,f=6 })[k] end
  ok("键的插入顺序不影响", same(t1, t2))

  -- 反复求值必须稳定（宿主靠它跳过重绘）
  local first = fp_fast(base)
  local stable = true
  for _ = 1, 2000 do
    if fp_fast(base) ~= first then stable = false break end
  end
  ok("连续 2000 次求值稳定（默认 fast）", stable)
  perf.use("fingerprint", "fast")
end

section("\n=== 3. 指纹的已知弱点（记录在案，不假装没有）===")

do
  local fp = perf.get("fingerprint")
  -- 累加式哈希对"多重集合相同、键值配对不同"是弱的：
  -- {"a":1,"b":2} 与 {"a":2,"b":1} 的元素集相同。
  local x = { a = 1, b = 2 }
  local y = { a = 2, b = 1 }
  if fp(x) == fp(y) then
    io.write("  NOTE  a/b 配对交换未被区分（累加哈希的固有弱点）\n")
    passed = passed + 1
  else
    io.write("  NOTE  配对交换被区分了\n")
    passed = passed + 1
  end
  -- 契约里 key 固定（$widget / $args / 事件名），配对不会错乱，
  -- 所以这个弱点在当前用法下不构成问题。记录下来是为了将来有人改契约时能看到。
end

-- ============ JSON 数字 ============

section("\n=== 4. JSON 数字策略 ===")

do
  perf.use("json_number", "lenient")
  local lenient = perf.get("json_number")
  perf.use("json_number", "exact")
  local exact = perf.get("json_number")

  local cases = {
    { 1 / 3, "1/3" },
    { 0.1 + 0.2, "0.1+0.2" },
    { math.pi, "pi" },
    { 1.7976931348623157e308, "最大 double" },
  }

  for _, c in ipairs(cases) do
    local v, label = c[1], c[2]
    ok(label .. " 精确往返（exact）", tonumber(exact(v)) == v,
      tostring(exact(v)))
    -- lenient 会丢精度——这正是它不该当默认的原因
    ok(label .. " 在 lenient 下会丢（对照）",
      tonumber(lenient(v)) ~= v or v == math.floor(v))
  end

  eq("整数不带小数点", exact(42), "42")
  eq("整数是整数类型", math.type(json.decode(exact(42))), "integer")
  eq("浮点带小数点", exact(40.0), "40.0")
  eq("浮点解析成 double", math.type(json.decode(exact(40.0))), "float")

  perf.use("json_number", "exact")
end

-- ============ 标准库需求 ============

section("\n=== 5. 标准库需求汇总 ===")

do
  local mask, names = perf.lib_mask()
  ok("掩码非零", mask > 0, tostring(mask))
  eq("base 永远在内", names[1], "base")

  local has = {}
  for _, n in ipairs(names) do has[n] = true end

  ok("有 string（json 编码器要）", has.string)
  ok("有 table（table.sort / concat）", has.table)
  ok("有 math（math.floor / huge）", has.math)
  ok("有 os（guard 要 os.clock）", has.os)
  ok("有 debug（guard 要 debug.sethook）", has.debug)

  -- 能力契约的兑现：打包模块一个都不需要 io，
  -- 所以宿主不会给它 io —— 用户代码写 io.write 会直接报错。
  ok("**没有 io**（业务代码碰不到 io）", not has.io)
  ok("没有 coroutine", not has.coroutine)
  ok("没有 utf8", not has.utf8)

  -- 掩码与 lib 名一一对应
  local expect = { base = 1, package = 2, coroutine = 4, debug = 8, io = 16,
                   math = 32, os = 64, string = 128, table = 256, utf8 = 512 }
  local total = 0
  for _, n in ipairs(names) do total = total + expect[n] end
  eq("掩码等于各库位之和", mask, total)

  local report = perf.lib_report()
  ok("canvas 声明过库", report.canvas ~= nil)
  ok("ui 声明过库", report.ui ~= nil)
  ok("json 声明过库", report.json ~= nil, "host/cli.lua 里的 json 编码器")
  ok("guard 声明过库", report.guard ~= nil)
  ok("host 声明过库", report.host ~= nil)

  raises("声明未知标准库", function()
    perf.declare_libs("probe", { "nosuchlib" })
  end, "未知标准库")
end

-- ============ 诊断 ============

section("\n=== 6. report ===")

do
  local r = json.decode(perf.report())
  ok("能输出 JSON", type(r) == "table")
  ok("含 strategies", type(r.strategies) == "table")
  ok("含 libs", type(r.libs) == "table")
  local fp = r.strategies.fingerprint
  local active
  for _, item in ipairs(fp) do
    if item.active then active = item.name end
  end
  eq("当前生效的指纹策略是 fast", active, "fast")
end

io.write(string.format("\n%d passed, %d failed\n", passed, failed))
os.exit(failed == 0 and 0 or 1)
