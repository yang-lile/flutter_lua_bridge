-- spec/canvas_spec.lua
--
-- 显示列表的测试。全部脱离 Flutter 运行——
-- 这正是方案 B 的核心收益。
--
-- 路径自解析：从本文件位置反推 assets/lua 目录，
-- 所以从任意工作目录执行都能跑。

local function script_dir()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then
    return src:sub(2):match("^(.*)[/\\][^/\\]*$") or "."
  end
  return "."
end

local lua_root = script_dir() .. "/.."
package.path = table.concat({
  lua_root .. "/?.lua",
  lua_root .. "/?/init.lua",
  package.path,
}, ";")

require("host.cli")
require("canvas")        -- 注册 canvas 能力
require("render.svg")

local host    = require("host")
local canvas  = host.require_cap("canvas")
local svg     = require("render.svg")
local dashboard = require("render.dashboard")

local log = host.require_cap("log")
log.set_output(function() end)

local passed, failed = 0, 0
local failures = {}

local function check(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    io.write(".")
  else
    failed = failed + 1
    failures[#failures + 1] = name .. ": " .. tostring(err)
    io.write("F")
  end
end

local function eq(a, b, msg)
  if a ~= b then
    error(string.format("%s: expected %s, got %s",
      msg or "assert", tostring(b), tostring(a)), 2)
  end
end

local function truthy(v, msg)
  if not v then error(msg or "expected truthy", 2) end
end

-- ============ 画布基础 ============

check("canvas has correct dimensions", function()
  local c = canvas.new({ width = 800, height = 600 })
  local list = c:build()
  eq(list.width, 800)
  eq(list.height, 600)
end)

check("circle produces one op", function()
  local c = canvas.new()
  c:circle(10, 20, 5)
  local list = c:build()
  eq(list.op_count, 1)
  eq(list.ops[1].op, "circle")
  eq(list.ops[1].x, 10)
  eq(list.ops[1].r, 5)
end)

check("ops preserve z-order", function()
  local c = canvas.new()
  c:circle(1, 1, 1)
  c:rect(0, 0, 10, 10)
  c:text(5, 5, "hi")
  local list = c:build()
  eq(list.ops[1].op, "circle")
  eq(list.ops[2].op, "rect")
  eq(list.ops[3].op, "text")
end)

check("line stores both endpoints", function()
  local c = canvas.new()
  c:line(0, 0, 100, 50, { stroke = "#fff", stroke_width = 2 })
  local op = c:build().ops[1]
  eq(op.x1, 0); eq(op.y2, 50)
  eq(op.stroke_width, 2)
end)

-- ============ 参数校验（越界必须在 Lua侧拦住） ============

check("rejects non-number coordinate", function()
  local c = canvas.new()
  local ok = pcall(function() c:circle("x", 0, 1) end)
  eq(ok, false)
end)

check("rejects NaN coordinate", function()
  local c = canvas.new()
  local ok = pcall(function() c:circle(0/0, 0, 1) end)
  eq(ok, false)
end)

check("rejects malformed color", function()
  local c = canvas.new()
  local ok = pcall(function() c:circle(0, 0, 1, { fill = "red" }) end)
  eq(ok, false)
end)

check("rejects polygon with too few points", function()
  local c = canvas.new()
  local ok = pcall(function() c:polygon({{x=0,y=0},{x=1,y=1}}) end)
  eq(ok, false)
end)

check("rejects non-string text", function()
  local c = canvas.new()
  local ok = pcall(function() c:text(0, 0, 123) end)
  eq(ok, false)
end)

-- ============ hash：变化检测 ============

check("hash is deterministic for same content", function()
  local c1 = canvas.new({ width = 100, height = 100 })
  local c2 = canvas.new({ width = 100, height = 100 })
  c1:circle(10, 10, 5, { fill = "#ff0000" })
  c2:circle(10, 10, 5, { fill = "#ff0000" })
  eq(c1:hash(), c2:hash())
end)

check("hash changes when geometry changes", function()
  local c1 = canvas.new()
  local c2 = canvas.new()
  c1:circle(10, 10, 5)
  c2:circle(11, 10, 5)
  truthy(c1:hash() ~= c2:hash(), "hash should differ")
end)

check("hash changes when color changes", function()
  local c1 = canvas.new()
  local c2 = canvas.new()
  c1:circle(10, 10, 5, { fill = "#ff0000" })
  c2:circle(10, 10, 5, { fill = "#00ff00" })
  truthy(c1:hash() ~= c2:hash(), "hash should differ")
end)

check("hash changes when text changes", function()
  local c1 = canvas.new()
  local c2 = canvas.new()
  c1:text(0, 0, "A")
  c2:text(0, 0, "B")
  truthy(c1:hash() ~= c2:hash(), "hash should differ")
end)

check("hash changes when op count changes", function()
  local c1 = canvas.new()
  local c2 = canvas.new()
  c1:circle(1, 1, 1)
  c2:circle(1, 1, 1)
  c2:circle(2, 2, 2)
  truthy(c1:hash() ~= c2:hash())
end)

check("clear resets ops but keeps size", function()
  local c = canvas.new({ width = 300, height = 200 })
  c:circle(1, 1, 1)
  c:clear()
  local list = c:build()
  eq(list.op_count, 0)
  eq(list.width, 300)
end)

-- ============ 业务：dashboard ============

local function sample_data()
  return {
    frame = 0,
    services = {
      { name = "a", latency = 50, status = "ok" },
      { name = "b", latency = 150, status = "warning" },
    },
  }
end

check("dashboard produces display list", function()
  local c = dashboard.draw_dashboard(sample_data(), 900, 600)
  local list = c:build()
  truthy(list.op_count > 0, "should have ops")
  eq(list.width, 900)
end)

check("dashboard is deterministic for same data", function()
  local c1 = dashboard.draw_dashboard(sample_data(), 900, 600)
  local c2 = dashboard.draw_dashboard(sample_data(), 900, 600)
  eq(c1:hash(), c2:hash())
end)

check("dashboard draws one card per service", function()
  local data = {
    frame = 0,
    services = {
      { name = "a", latency = 50, status = "ok" },
      { name = "b", latency = 60, status = "ok" },
      { name = "c", latency = 70, status = "ok" },
      { name = "d", latency = 80, status = "ok" },
    },
  }
  local list = dashboard.draw_dashboard(data, 900, 600):build()
  -- 每卡：底 rect + 状态条 rect + 名称 text + 数值 text = 4
  local rects = 0
  for _, op in ipairs(list.ops) do
    if op.op == "rect" then rects = rects + 1 end
  end
  -- 4 卡 x 2 rect = 8
  eq(rects, 8)
end)

check("dashboard handles empty data without crash", function()
  local c = dashboard.draw_dashboard({ frame = 0, services = {} }, 900, 600)
  truthy(c:build() ~= nil, "should not crash")
end)

check("tick increments frame", function()
  local data = sample_data()
  local before = data.frame
  dashboard.tick(data)
  eq(data.frame, before + 1)
end)

check("tick maintains history window", function()
  local data = sample_data()
  for _ = 1, 100 do dashboard.tick(data) end
  for _, s in ipairs(data.services) do
    truthy(#s.history <= 40,
      "history should cap at 40, got " .. #s.history)
  end
end)

check("tick updates status by latency", function()
  local data = { frame = 0, services = { { name = "x", latency = 500, status = "ok" } } }
  dashboard.tick(data)
  eq(data.services[1].status, "critical")
end)

-- ============ 多后端：同一份场景图输出不同格式 ============

check("svg backend renders display list", function()
  local list = dashboard.draw_dashboard(sample_data(), 900, 600):build()
  local out = svg.to_svg(list)
  truthy(out:find("<svg", 1, true), "should contain svg tag")
  truthy(out:find("</svg>", 1, true), "should be closed")
  truthy(out:find('width="900"', 1, true), "should carry size")
end)

check("svg escapes html in text", function()
  local c = canvas.new()
  c:text(0, 0, "a<b&c")
  local out = svg.to_svg(c:build())
  truthy(out:find("&lt;", 1, true), "should escape <")
  truthy(out:find("&amp;", 1, true), "should escape &")
end)

check("svg escapes xml entities in attribute", function()
  local c = canvas.new()
  c:text(0, 0, '"quote"')
  local out = svg.to_svg(c:build())
  truthy(not out:find('>"quote"', 1, true), "quote should not break attribute")
end)

check("display list is plain data (no functions)", function()
  local list = dashboard.draw_dashboard(sample_data(), 900, 600):build()
  for _, v in pairs(list) do
    eq(type(v), type(v))  -- 确保可序列化
    if type(v) == "function" then
      error("display list must not contain functions", 2)
    end
  end
  -- ops 里的每个字段也都应是原始类型
  for _, op in ipairs(list.ops) do
    for k, v in pairs(op) do
      local tv = type(v)
      truthy(tv == "string" or tv == "number" or tv == "boolean"
        or tv == "table" or tv == "nil",
        "unexpected type " .. tv .. " in field " .. k)
    end
  end
end)

-- ============ guard：协作式中断 ============
--
-- 宿主无法从外部强制中断 Lua（FFI 同步，isolate 的 kill 打断不了
-- 正在执行的原生代码），所以 canvas_guard 用 debug.sethook 做协作式检查。
-- 它是防"手滑写出死循环"的第一道防线。

check("guard executes normally and returns value", function()
  local r = canvas.guard(function()
    local c = canvas.new({ width = 100, height = 100 })
    c:circle(50, 50, 20, { fill = "#4a9eff" })
    return c:build().op_count
  end, 2000)
  eq(r, 1)
end)

check("guard forwards multiple return values", function()
  local a, b, c = canvas.guard(function() return 1, 2, 3 end, 2000)
  eq(a, 1)  eq(b, 2)  eq(c, 3)
end)

check("guard interrupts infinite loop", function()
  local ok, err = pcall(canvas.guard, function()
    local x = 0
    while true do x = x + 1 end
  end, 200)
  eq(ok, false)
  truthy(err and err:find("超时"),
    "应报超时，实际: " .. tostring(err))
end)

check("guard lets inner errors propagate", function()
  local ok, err = pcall(canvas.guard, function()
    error("内部错误")
  end, 2000)
  eq(ok, false)
  truthy(err and err:find("内部错误"),
    "应保留原错误，实际: " .. tostring(err))
end)

check("hook cleared after guard so later code unaffected", function()
  canvas.guard(function()
    local c = canvas.new({ width = 100, height = 100 })
    for i = 1, 500 do c:circle(i % 100, 50, 1, { fill = "#fff" }) end
  end, 2000)

  -- hook 没清掉的话，这段也会被算进上一轮的预算
  local c = canvas.new({ width = 200, height = 200 })
  for i = 1, 5000 do c:circle(i % 200, 100, 1, { fill = "#fff" }) end
  eq(c:build().op_count, 5000)
end)

check("guard rejects non-function argument", function()
  local ok, err = pcall(canvas.guard, "not a function")
  eq(ok, false)
  truthy(err and err:find("函数"), tostring(err))
end)

check("guard is exposed as module member too", function()
  truthy(type(require("canvas").guard) == "function")
  truthy(type(require("canvas").wrap) == "function")
end)

-- guard 与 wrap 的区别很关键：宿主用 wrap 来包装用户的顶层函数，
-- 如果 wrap 的语义是"立即执行"，__studio_fn 会从函数变成它的返回值，
-- 后面调用就报 "attempt to call a X value"。
check("wrap returns a function without executing it", function()
  local executed = false
  local wrapped = canvas.wrap(function()
    executed = true
    return "result"
  end, 2000)

  eq(type(wrapped), "function")
  eq(executed, false, "wrap 不应该立即执行")

  -- 真正的执行发生在调用时
  eq(wrapped(), "result")
  eq(executed, true)
end)

check("wrapped function still interrupts infinite loop", function()
  local wrapped = canvas.wrap(function()
    local x = 0
    while true do x = x + 1 end
  end, 200)

  local ok, err = pcall(wrapped)
  eq(ok, false)
  truthy(err and err:find("超时"), tostring(err))
end)

check("wrapped function forwards args and multiple returns", function()
  local wrapped = canvas.wrap(function(a, b)
    return a + b, a * b
  end, 2000)
  local sum, product = wrapped(3, 4)
  eq(sum, 7)  eq(product, 12)
end)

-- ============ 画布所有权 ============
--
-- canvas.new 每次都返回一块**独立**的画布。在辅助函数里新建画布，
-- 画的东西全进那块临时画布，返回值一被丢弃外面就什么都没有——
-- 表现为「示例运行了但画面空白」。
-- 正确做法是把画布当参数传进去。

check("辅助函数里 canvas.new 会导致外层画布为空", function()
  local function bad(cx)
    local inner = canvas.new({ width = 100, height = 100 })
    inner:circle(cx, 50, 20, { fill = "#4a9eff" })
    return inner
  end

  local outer = canvas.new({ width = 100, height = 100 })
  bad(50)
  eq(outer:build().op_count, 0, "外层画布不该有图元")
  -- 被丢弃的那块里有内容——这正是问题所在
end)

check("把画布作为参数传入则共用同一块", function()
  local function good(c, cx)
    c:circle(cx, 50, 20, { fill = "#4a9eff" })
  end

  local c = canvas.new({ width = 200, height = 100 })
  good(c, 50)
  good(c, 150)
  eq(c:build().op_count, 2, "两次调用都应落在同一块画布上")
end)

check("每块画布彼此独立", function()
  local a = canvas.new({ width = 100, height = 100 })
  local b = canvas.new({ width = 100, height = 100 })
  a:circle(50, 50, 20, { fill = "#4a9eff" })
  eq(a:build().op_count, 1)
  eq(b:build().op_count, 0, "b 不该被 a 的绘制影响")
  truthy(a:build().fingerprint ~= b:build().fingerprint)
end)

-- ============ 指纹：宿主重绘的依据 ============
--
-- build() 必须输出 fingerprint。宿主侧的 CustomPaint.shouldRepaint
-- 用它判断要不要重绘，少了这个字段会退化成 `nil != nil` = false，
-- 画面永远停在第一次，但界面看起来完全正常。
-- 这个 bug 曾真实发生过：build() 漏了 fingerprint，
-- 而 gen_gallery.lua 手动补上，所以画廊能刷新、Studio 不能。

check("build() outputs fingerprint", function()
  local c = canvas.new({ width = 100, height = 100 })
  c:circle(50, 50, 20, { fill = "#4a9eff" })
  local list = c:build()
  truthy(type(list.fingerprint) == "string" and #list.fingerprint > 0,
    "build() 必须输出 fingerprint")
end)

check("fingerprint changes when content changes", function()
  local c = canvas.new({ width = 100, height = 100 })
  c:circle(50, 50, 20, { fill = "#4a9eff" })
  local a = c:build().fingerprint

  c:circle(30, 30, 10, { fill = "#30a46c" })
  local b = c:build().fingerprint

  truthy(a ~= b, "加了图元后指纹必须变")
end)

check("fingerprint changes when only text changes", function()
  local c = canvas.new({ width = 200, height = 100 })
  c:text(10, 50, "before", { size = 12, color = "#ffffff" })
  local a = c:build().fingerprint
  c:text(10, 50, "after!", { size = 12, color = "#ffffff" })
  local b = c:build().fingerprint
  truthy(a ~= b, "改文本后指纹必须变（ipairs 会在 nil 处停止，hash 曾漏掉 text）")
end)

check("fingerprint changes when only size changes", function()
  local c1 = canvas.new({ width = 100, height = 100 })
  local c2 = canvas.new({ width = 200, height = 100 })
  truthy(c1:build().fingerprint ~= c2:build().fingerprint)
end)

check("fingerprint changes when only background changes", function()
  local c1 = canvas.new({ width = 100, height = 100, background = "#000000" })
  local c2 = canvas.new({ width = 100, height = 100, background = "#ffffff" })
  truthy(c1:build().fingerprint ~= c2:build().fingerprint)
end)

check("fingerprint stable for identical content", function()
  local function build()
    local c = canvas.new({ width = 150, height = 90, background = "#101010" })
    c:rect(10, 10, 50, 30, { fill = "#4a9eff" })
    c:text(10, 60, "hi", { size = 11, color = "#eeeeee" })
    return c
  end
  eq(build():build().fingerprint, build():build().fingerprint)
end)

check("fingerprint survives JSON round trip", function()
  local json = host.require_cap("json")
  local c = canvas.new({ width = 120, height = 80 })
  c:circle(60, 40, 25, { fill = "#4a9eff" })
  local encoded = json.encode(c:build())
  local back = json.decode(encoded)
  eq(back.fingerprint, c:hash(),
    "经过 JSON 往返后指纹必须还在，否则宿主拿不到它")
end)

-- ============ 输出 ============

print("")
print(string.format("%d passed, %d failed", passed, failed))
for _, f in ipairs(failures) do
  print("  FAIL " .. f)
end

os.exit(failed == 0 and 0 or 1)