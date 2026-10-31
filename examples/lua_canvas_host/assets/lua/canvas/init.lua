-- canvas/init.lua
--
-- 画布能力契约。关键设计：Lua 只产出**声明式显示列表**，
-- 不直接调用任何"立即绘制"的函数。
--
-- 为什么不做"逐条调用"模式：
--   1. 每个图元一次 FFI 跨界调用，60fps 下开销无法接受
--   2. 无法脱离 Flutter 做单元测试
--   3. 无法缓存、无法 diff、无法回放
--
-- 显示列表是纯数据，所以 Lua 侧可以完整测试，
-- Dart 侧也能在数据没变时跳过重绘。

local host = require("host")
local guard = require("guard")
local perf = require("perf")

-- canvas 用到 string.format（错误信息）与 table.concat。
perf.declare_libs("canvas", { "string", "table" })

local Canvas = {}
Canvas.__index = Canvas

local OP = {
  circle  = "circle",
  rect= "rect",
  line    = "line",
  text    = "text",
  polygon = "polygon",
}

Canvas.OP = OP

-- ============ 执行预算 ============
--
-- 宿主无法从外部强制中断一段 Lua 代码：FFI 调用是同步的，
-- isolate 的 kill 也打断不了正在执行的原生代码。所以只能**协作式**——
-- 由 Lua 自己定期检查预算，超了就抛错跳出。实现见 [guard]，
-- canvas 与 ui 共用同一份，避免两个能力互相依赖。
--
-- 这不是安全边界，只是防止"用户不小心写了个死循环把编辑器卡住"。
-- 真正的安全边界在宿主侧（worker isolate + 超时 + 丢弃）。

--- 把 fn 包成受预算限制的函数。**返回函数本身，不执行。** 宿主用这个。
local canvas_wrap = guard.wrap

--- 在指定毫秒数内**立即执行** fn，超预算则抛错。业务代码用这个。
local canvas_guard = guard.run

-- ============ 场景图构建 ============

-- 创建画布。width/height 是逻辑尺寸，宿主负责按 DPR 缩放。
function Canvas.new(opts)
  opts = opts or {}
  return setmetatable({
    w = opts.width or 800,
    h = opts.height or 600,
    bg = opts.background or "#0f1116",
    ops = {},
    -- 绘制统计，用于诊断性能
    stats = { ops = 0 },
  }, Canvas)
end

-- 参数校验：越界和非法值在这里拦住，不留给 Dart 侧崩溃
local function check_num(v, name)
  if type(v) ~= "number" then
    error("canvas: " .. name .. " must be a number, got " .. type(v), 3)
  end
  if v ~= v then
    error("canvas: " .. name .. " is NaN", 3)
  end
  return v
end

local function check_color(c, name)
  if c == nil then return nil end
  -- 只接受 #rgb / #rrggbb / #aarrggbb 三种十六进制形式。
  -- Lua 模式 ^#%x%x%x%x%x%x$ 会被 #abc 之外的格式漏过，
  -- 所以这里显式列出长度并逐字符校验，避免 "red" 这类值混进来。
  local s = c:gsub("^#", "")
  if #s ~= 3 and #s ~= 6 and #s ~= 8 then
    error("canvas: " .. name .. " must be #rgb/#rrggbb/#aarrggbb hex string", 3)
  end
  if s:find("%X") then     -- %X 是非十六进制字符
    error("canvas: " .. name .. " contains non-hex characters", 3)
  end
  return "#" .. s:lower()
end

function Canvas:circle(x, y, r, style)
  style = style or {}
  self.ops[#self.ops + 1] = {
    op = OP.circle,
    x = check_num(x, "x"), y = check_num(y, "y"), r = check_num(r, "r"),
    fill = check_color(style.fill, "fill"),
    stroke = check_color(style.stroke, "stroke"),
    stroke_width = style.stroke_width or 0,
  }
  return self
end

function Canvas:rect(x, y, w, h, style)
  style = style or {}
  self.ops[#self.ops + 1] = {
    op = OP.rect,
    x = check_num(x, "x"), y = check_num(y, "y"),
    w = check_num(w, "w"), h = check_num(h, "h"),
    radius = style.radius or 0,
    fill = check_color(style.fill, "fill"),
    stroke = check_color(style.stroke, "stroke"),
    stroke_width = style.stroke_width or 0,
  }
  return self
end

function Canvas:line(x1, y1, x2, y2, style)
  style = style or {}
  self.ops[#self.ops + 1] = {
    op = OP.line,
    x1 = check_num(x1, "x1"), y1 = check_num(y1, "y1"),
    x2 = check_num(x2, "x2"), y2 = check_num(y2, "y2"),
    stroke = check_color(style.stroke or "#ffffff", "stroke"),
    stroke_width = style.stroke_width or 1,
  }
  return self
end

function Canvas:text(x, y, str, style)
  style = style or {}
  if type(str) ~= "string" then
    error("canvas: text expects string, got " .. type(str), 3)
  end
  self.ops[#self.ops + 1] = {
    op = OP.text,
    x = check_num(x, "x"), y = check_num(y, "y"),
    text = str,
    size = style.size or 14,
    color = check_color(style.color or "#ffffff", "color"),
    align = style.align or "left",
  }
  return self
end

function Canvas:polygon(points, style)
  style = style or {}
  if type(points) ~= "table" or #points < 3 then
    error("canvas: polygon needs at least 3 points", 3)
  end
  self.ops[#self.ops + 1] = {
    op = OP.polygon,
    points = points,
    fill = check_color(style.fill, "fill"),
    stroke = check_color(style.stroke, "stroke"),
    stroke_width = style.stroke_width or 0,
  }
  return self
end

-- ============ 输出显示列表 ============

-- fingerprint 必须由 build() 自己输出：宿主的 CustomPaint 用它决定要不要重绘。
-- 少了这个字段，宿主侧的判断会退化成 `nil != nil` = false，
-- 于是画布**永远不刷新**——但看起来一切正常，只是画面停在第一次。
--- 画布内容，**不含 fingerprint**。
---
--- build 与 hash 都基于它。之前 hash 直接调 build()，而 build 又调 hash()，
--- 是无限递归——拆出这一层才能让两边共用同一份指纹实现。
function Canvas:content()
  return {
    version = 1,
    width = self.w,
    height = self.h,
    background = self.bg,
    ops = self.ops,
    op_count = #self.ops,
  }
end

--- 生成内容指纹。宿主用它判断是否需要重绘。
--
-- 实现放在注册表里，ui 与 canvas 共用一份。
--
-- 早期这里是**另一份实现**，对每个图元无条件 mix 18 个字段
-- （不管字段存不存在），所以 10 万图元的画布，光算指纹就要跑
-- 180 万次字符串转换。换成结构遍历后只碰真实存在的字段。
function Canvas:hash()
  return perf.get("fingerprint")(self:content())
end

--- 产出宿主可消费的结构。这是 Lua 与宿主之间唯一的契约。
function Canvas:build()
  local content = self:content()
  -- 先算指纹再放进结果：指纹只覆盖内容本身，不覆盖它自己
  content.fingerprint = perf.get("fingerprint")(content)
  return content
end

-- 清空画布，保留尺寸和背景
function Canvas:clear()
  self.ops = {}
  return self
end

-- 产出宿主能力
host.provide("canvas", {
  new = function(opts) return Canvas.new(opts) end,
  OP = OP,
  -- 协作式中断
  guard = canvas_guard,   -- 立即执行：业务代码用
  wrap = canvas_wrap,     -- 返回包装函数：宿主用
  -- 宿主侧注册的回调：Lua 不直接调用，由宿主在合适时机消费
  _commit = nil,
}, { version = "1.1.0", desc = "声明式画布（产出显示列表）" })

-- 同时作为模块成员暴露，业务代码可以直接
-- `local guard = require("canvas").guard`。
--
-- 注意不要在这里再赋 Canvas.new —— Canvas.new 已经是真正的构造函数
-- （定义在本文件上文），重新赋值会造成无限递归。
Canvas.guard = canvas_guard
Canvas.wrap = canvas_wrap

return Canvas
