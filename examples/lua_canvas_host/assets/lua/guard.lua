-- guard.lua
--
-- 协作式执行预算。canvas 与 ui 两个能力都依赖它。
--
-- ## os.clock() 是 CPU 时间，不是墙钟
--
-- 这里用 os.clock() 计时，因为它有亚毫秒精度；os.time() 只有整秒，
-- 而 Lua 标准库里没有别的墙钟（要亚秒墙钟得从宿主注册原生函数，
-- 那是 FFI 回调，state 销毁后指针会变野）。
--
-- 代价必须写清楚：**机器繁忙时 1500ms 的 CPU 可能对应好几秒的墙钟**。
-- 实测在 loadavg 40+ 的开发机上，guard 的 1500ms 预算会比宿主那
-- 2000ms 墙钟超时更晚到，于是走"丢弃 worker"那条路——
-- 测试里对这两种结果都做了断言，不假设 guard 一定赢。
--
-- 所以分工是：**guard 是快路径，宿主的墙钟超时才是真正的兜底。**
-- 单次执行真正会被卡住多久，取决于宿主那个 timeout。
--
-- 为什么单独抽出来：这两个能力都不该依赖对方，
-- 但都需要同一套中断机制。放在一起比互相 require 干净。

local host = require("host")
local perf = require("perf")

-- guard 用 os.clock 计时、debug.sethook 装钩子、table.pack/unpack 传递返回值。
perf.declare_libs("guard", { "os", "debug", "string", "table" })

local M = {}

local DEFAULT_BUDGET_MS = 2000

-- 每 1000 万条指令查一次时钟。
--
-- 实测本机 Lua 空循环约 4 亿条指令/秒，1000 万条约 25ms 一跳——
-- 既不会漏掉秒级超时，正常代码的钩子开销也可忽略。
-- （曾用 10 万一跳，画一个圆就会触发上万次钩子调用，反而拖慢执行。）
local CHECK_INTERVAL = 10000000

--- 把 fn 包成受预算限制的函数。**返回函数本身，不执行。**
---
--- 宿主用这个：它在调用用户函数**之前**就完成包装，
--- 所以 `__studio_fn = guard.wrap(__studio_fn, 1500)`
--- 之后 `__studio_fn` 仍是个函数，调用时才真正开始计时。
---
--- 业务代码想直接执行就用 [guard.run]。
---
--- @param fn function 要包装的函数
--- @param ms number|nil 时间预算，默认 [DEFAULT_BUDGET_MS]
function M.wrap(fn, ms)
  if type(fn) ~= "function" then
    error("guard.wrap: 需要一个函数作为参数", 2)
  end

  local limit = ms or DEFAULT_BUDGET_MS

  return function(...)
    -- 裁剪版 Lua 没有 debug 库，跳过保护直接执行
    if not debug or not debug.sethook then
      return fn(...)
    end

    -- 预算很小时缩短检查间隔，否则会明显超时才被发现
    local interval = limit <= 100 and CHECK_INTERVAL / 10 or CHECK_INTERVAL
    local start = os.clock()
    local limit_s = limit / 1000

    debug.sethook(function()
      if os.clock() - start > limit_s then
        debug.sethook()
        error(string.format(
          "执行超时（预算 %dms），已中断。检查是否有死循环。", limit), 0)
      end
    end, "", interval)

    local results = table.pack(pcall(fn, ...))
    debug.sethook()

    if not results[1] then
      error(results[2], 0)   -- 保留原始错误，但丢掉 pcall 的位置信息
    end
    return table.unpack(results, 2, results.n)
  end
end

--- 在指定毫秒数内**立即执行** fn，超预算则抛错。
--- @param fn function 要执行的函数
--- @param ms number|nil 时间预算，默认 [DEFAULT_BUDGET_MS]
function M.run(fn, ms)
  return M.wrap(fn, ms)()
end

M.DEFAULT_BUDGET_MS = DEFAULT_BUDGET_MS

host.provide("guard", {
  wrap = M.wrap,
  run = M.run,
  DEFAULT_BUDGET_MS = DEFAULT_BUDGET_MS,
}, { version = "1.0.0", desc = "协作式执行预算（debug.sethook 计数）" })

return M
