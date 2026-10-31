-- tools/gen_gallery.lua
--
-- 生成对照页面的数据：每个示例的 Lua 源码 + 真实渲染出的 SVG。
--
-- 关键：SVG 是由 Lua 跑出来的，不是手画的。
-- 所以页面上的每一张图都真的经过了 canvas -> display list -> 后端 这条链路。
--
-- 用法（必须在 examples/lua_canvas_host 目录下执行）：
--   lua tools/gen_gallery.lua

-- package.path 指向 assets/lua，后续都用短模块名 require，
-- 保证同一模块只被加载一次（否则能力会重复注册而报错）。
package.path = table.concat({
  "assets/lua/?.lua",
  "assets/lua/?/init.lua",
  package.path,
}, ";")

require("host.cli")
require("canvas")

local host    = require("host")
local canvas  = host.require_cap("canvas")
local json    = host.require_cap("json")
local svg     = require("render.svg")

local out_dir = "assets/lua/out"
os.execute("mkdir -p " .. out_dir)

-- 统一的示例数据
local SAMPLE = {
  series = { 42, 55, 48, 71, 66, 84, 79, 95, 88, 102, 97, 110 },
  bars   = { 62, 88, 45, 73, 95, 58 },
}

local THEME = {
  bg = "#0f1116", panel = "#1a1d24", grid = "#2a2f3a",
  text = "#e6e9ef", muted = "#8b93a3",
  blue = "#4a9eff", green = "#30a46c",
  amber = "#f5a524", red = "#e5484d", purple = "#a78bfa",
}

-- ============ 示例定义 ============
-- 每个示例给出：id、标题、说明、Lua 源码（用于展示）、构建函数

local EXAMPLES = {}

-- 1. 基础图元
EXAMPLES[#EXAMPLES + 1] = {
  id = "primitives",
  title = "基础图元",
  desc = "五种图元的基本用法。每种都是一次纯数据追加，不涉及任何绘制调用。",
  code = [==[
local c = canvas.new({
  width = 400, height = 220, background = "#0f1116",
})

-- 圆形
c:circle(70, 70, 40, { fill = "#4a9eff" })

-- 矩形（圆角）
c:rect(140, 40, 100, 60, {
  radius = 10, fill = "#30a46c",
})

-- 描边矩形
c:rect(270, 40, 100, 60, {
  radius = 10, stroke = "#f5a524", stroke_width = 2,
})

-- 直线
c:line(40, 140, 360, 140, {
  stroke = "#2a2f3a", stroke_width = 1,
})

-- 多边形
c:polygon({
  { x = 70,  y = 195 },
  { x = 100, y = 155 },
  { x = 130, y = 195 },
}, { fill = "#a78bfa" })

-- 文本
c:text(160, 185, "Hello Lua", { size = 18, color = "#e6e9ef" })
c:text(160, 205, "rendered as data", { size = 12, color = "#8b93a3" })

return c:build()
]==],
  build = function()
    local c = canvas.new({ width = 400, height = 220, background = THEME.bg })
    c:circle(70, 70, 40, { fill = THEME.blue })
    c:rect(140, 40, 100, 60, { radius = 10, fill = THEME.green })
    c:rect(270, 40, 100, 60, { radius = 10, stroke = THEME.amber, stroke_width = 2 })
    c:line(40, 140, 360, 140, { stroke = THEME.grid, stroke_width = 1 })
    c:polygon({
      { x = 70, y = 195 }, { x = 100, y = 155 }, { x = 130, y = 195 },
    }, { fill = THEME.purple })
    c:text(160, 185, "Hello Lua", { size = 18, color = THEME.text })
    c:text(160, 205, "rendered as data", { size = 12, color = THEME.muted })
    return c
  end,
}

-- 2. 折线图（带坐标轴）
EXAMPLES[#EXAMPLES + 1] = {
  id = "linechart",
  title = "折线图与坐标轴",
  desc = "完整的图表绘制。数值到坐标的映射是纯函数，因此可以单独测试。",
  code = [==[
local W, H, pad = 400, 240, 40

-- 求数值范围
local function range(values)
  local lo, hi = values[1], values[1]
  for _, v in ipairs(values) do
    lo, hi = math.min(lo, v), math.max(hi, v)
  end
  return lo, hi
end

local lo, hi = range(series)

-- 数值 -> 坐标，纯函数
local function to_x(i, n)
  return pad + (i - 1) * ((W - pad * 2) / (n - 1))
end

local function to_y(v)
  return H - pad - (v - lo) / (hi - lo) * (H - pad * 2)
end

local c = canvas.new({ width = W, height = H, background = "#0f1116" })

-- 横向网格线
for i = 0, 4 do
  local y = pad + (H - pad * 2) * i / 4
  c:line(pad, y, W - pad, y, { stroke = "#2a2f3a", stroke_width = 0.5 })
end

-- 折线
local pts = {}
for i, v in ipairs(series) do
  pts[#pts + 1] = { x = to_x(i, #series), y = to_y(v) }
end
c:polygon(pts, { stroke = "#4a9eff", stroke_width = 2 })

-- 数据点
for i, v in ipairs(series) do
  c:circle(to_x(i, #series), to_y(v), 3, { fill = "#4a9eff" })
end

-- 轴标签
c:text(pad, H - 12, tostring(lo), { size = 10, color = "#8b93a3" })
c:text(W - pad, H - 12, tostring(hi),
  { size = 10, color = "#8b93a3", align = "right" })

return c:build()
]==],
  build = function()
    local W, H, pad = 400, 240, 40
    local lo, hi = SAMPLE.series[1], SAMPLE.series[1]
    for _, v in ipairs(SAMPLE.series) do
      lo, hi = math.min(lo, v), math.max(hi, v)
    end

    local function to_x(i, n)
      return pad + (i - 1) * ((W - pad * 2) / (n - 1))
    end
    local function to_y(v)
      return H - pad - (v - lo) / (hi - lo) * (H - pad * 2)
    end

    local c = canvas.new({ width = W, height = H, background = THEME.bg })
    for i = 0, 4 do
      local y = pad + (H - pad * 2) * i / 4
      c:line(pad, y, W - pad, y, { stroke = THEME.grid, stroke_width = 0.5 })
    end

    local pts = {}
    for i, v in ipairs(SAMPLE.series) do
      pts[#pts + 1] = { x = to_x(i, #SAMPLE.series), y = to_y(v) }
    end
    c:polygon(pts, { stroke = THEME.blue, stroke_width = 2 })

    for i, v in ipairs(SAMPLE.series) do
      c:circle(to_x(i, #SAMPLE.series), to_y(v), 3, { fill = THEME.blue })
    end

    c:text(pad, H - 12, tostring(lo), { size = 10, color = THEME.muted })
    c:text(W - pad, H - 12, tostring(hi),
      { size = 10, color = THEME.muted, align = "right" })
    return c
  end,
}

-- 3. 柱状图
EXAMPLES[#EXAMPLES + 1] = {
  id = "barchart",
  title = "柱状图",
  desc = "柱高按比例缩放。超过阈值时改用警示色——这是业务规则，不是渲染细节。",
  code = [==[
local W, H, pad = 400, 220, 30
local max_v = 100

local c = canvas.new({ width = W, height = H, background = "#0f1116" })

local slot = (W - pad * 2) / #bars
local bw = slot * 0.6

for i, v in ipairs(bars) do
  local h = v / max_v * (H - pad * 2)
  local x = pad + (i - 1) * slot + (slot - bw) / 2
  local y = H - pad - h

  -- 业务规则：超过 80 视为告警
  local color = v > 80 and "#e5484d" or "#4a9eff"

  c:rect(x, y, bw, h, { radius = 4, fill = color })
  c:text(x + bw / 2, y - 6, tostring(v),
    { size = 10, color = "#8b93a3", align = "center" })
end

-- 基线
c:line(pad, H - pad, W - pad, H - pad,
  { stroke = "#2a2f3a", stroke_width = 1 })

return c:build()
]==],
  build = function()
    local W, H, pad = 400, 220, 30
    local c = canvas.new({ width = W, height = H, background = THEME.bg })
    local slot = (W - pad * 2) / #SAMPLE.bars
    local bw = slot * 0.6

    for i, v in ipairs(SAMPLE.bars) do
      local h = v / 100 * (H - pad * 2)
      local x = pad + (i - 1) * slot + (slot - bw) / 2
      local y = H - pad - h
      local color = v > 80 and THEME.red or THEME.blue
      c:rect(x, y, bw, h, { radius = 4, fill = color })
      c:text(x + bw / 2, y - 6, tostring(v),
        { size = 10, color = THEME.muted, align = "center" })
    end

    c:line(pad, H - pad, W - pad, H - pad,
      { stroke = THEME.grid, stroke_width = 1 })
    return c
  end,
}

-- 4. 动画帧
EXAMPLES[#EXAMPLES + 1] = {
  id = "animation",
  title = "动画：只改数据",
  desc = "同一份代码，只改数据。指纹变化 -> 宿主重绘。这就是 tick() 的完整语义。",
  code = [==[
local data = { t = 0, pulses = {} }

-- 推进一帧：只更新数据，完全不碰渲染
local function tick(data)
  data.t = data.t + 1

  -- 每 6 帧生成一个新脉冲
  if data.t % 6 == 0 then
    data.pulses[#data.pulses + 1] = {
      x = 60 + (data.t * 7) % 280,
      r = 8 + (data.t % 5) * 3,
    }
  end

  -- 窗口上限，避免无限增长
  if #data.pulses > 12 then
    table.remove(data.pulses, 1)
  end

  return data
end

-- 渲染：把当前数据画出来
local function draw(data)
  local c = canvas.new({
    width = 400, height = 180, background = "#0f1116",
  })

  c:text(16, 24, "tick " .. data.t,
    { size = 14, color = "#e6e9ef" })

  for i, p in ipairs(data.pulses) do
    -- 越早的数据越淡（用 alpha）
    local alpha = i / #data.pulses
    c:circle(p.x, 110, p.r, {
      stroke = string.format("#4a9eff%02x", math.floor(alpha * 255)),
      stroke_width = 2,
    })
  end

  return c
end

-- 跑 12 帧后返回
for _ = 1, 12 do tick(data) end
return draw(data)
]==],
  build = function()
    local data = { t = 0, pulses = {} }
    for _ = 1, 8 do
      data.t = data.t + 1
      if data.t % 6 == 0 then
        data.pulses[#data.pulses + 1] = {
          x = 60 + (data.t * 7) % 280,
          r = 8 + (data.t % 5) * 3,
        }
      end
      if #data.pulses > 12 then table.remove(data.pulses, 1) end
    end

    local c = canvas.new({ width = 400, height = 180, background = THEME.bg })
    c:text(16, 24, "tick " .. data.t, { size = 14, color = THEME.text })
    for i, p in ipairs(data.pulses) do
      local alpha = i / #data.pulses
      c:circle(p.x, 110, p.r, {
        stroke = string.format("#4a9eff%02x", math.floor(alpha * 255)),
        stroke_width = 2,
      })
    end
    return c
  end,
}

-- 5. 完整仪表盘
EXAMPLES[#EXAMPLES + 1] = {
  id = "dashboard",
  title = "完整仪表盘",
  desc = "六个服务卡片 + 状态色。实际项目里的典型场景。",
  code = [==[
-- 网格布局：按数据量自动分列
local function layout_grid(n, W, H, pad)
  local cols = math.ceil(math.sqrt(n))
  local rows = math.ceil(n / cols)
  local cw = (W - pad * (cols + 1)) / cols
  local ch = (H - pad * (rows + 1)) / rows

  local cells = {}
  for i = 1, n do
    local col = (i - 1) % cols
    local row = math.floor((i - 1) / cols)
    cells[i] = {
      x = pad + col * (cw + pad),
      y = pad + row * (ch + pad),
      w = cw, h = ch,
    }
  end
  return cells
end

-- 状态 -> 颜色：业务规则
local function status_color(status)
  if status == "critical" then return "#e5484d" end
  if status == "warning"  then return "#f5a524" end
  return "#30a46c"
end

local c = canvas.new({
  width = 900, height = 600, background = "#0f1116",
})
local cells = layout_grid(#services, 900, 600, 16)

for i, s in ipairs(services) do
  local cell = cells[i]

  c:rect(cell.x, cell.y, cell.w, cell.h, {
    radius = 8, fill = "#1a1d24",
    stroke = "#2a2f3a", stroke_width = 1,
  })
  c:rect(cell.x, cell.y, 3, cell.h, {
    fill = status_color(s.status), radius = 1.5,
  })
  c:text(cell.x + 14, cell.y + 22, s.name,
    { size = 14, color = "#e6e9ef" })
  c:text(cell.x + cell.w - 14, cell.y + 22, tostring(s.latency), {
    size = 14, color = status_color(s.status), align = "right",
  })
end

return c:build()
]==],
  build = function()
    local dashboard = require("render.dashboard")
    local data = {
      frame = 12,
      services = {
        { name = "gateway",  latency = 45.2,  status = "ok" },
        { name = "auth",     latency = 88.7,  status = "ok" },
        { name = "database", latency = 210.4, status = "critical" },
        { name = "cache",    latency = 12.1,  status = "ok" },
        { name = "queue",    latency = 135.9, status = "warning" },
        { name = "search",   latency = 62.3,  status = "ok" },
      },
    }
    for _ = 1, 12 do dashboard.tick(data) end
    return dashboard.draw_dashboard(data, 900, 600)
  end,
}

-- 6. 参数校验
EXAMPLES[#EXAMPLES + 1] = {
  id = "validation",
  title = "参数校验：错误在 Lua 侧被拦住",
  desc = "非法输入在 Lua 就抛错，不会带着脏数据跨到 Dart。错误发生在离现场最近的地方。",
  code = [==[
-- 非数字坐标
c:circle("100", 50, 30)
-- → canvas: x must be a number, got string

-- NaN
c:circle(0/0, 50, 30)
-- → canvas: x is NaN

-- 非十六进制颜色
c:rect(0, 0, 10, 10, { fill = "red" })
-- → canvas: fill must be #rgb/#rrggbb/#aarrggbb hex string

-- 多边形点数不足
c:polygon({ {x=0,y=0}, {x=1,y=1} })
-- → canvas: polygon needs at least 3 points

-- 文本不是字符串
c:text(0, 0, 123)
-- → canvas: text expects string, got number
]==],
  build = function()
    -- 真实跑一遍，捕获真实错误信息
    local c = canvas.new({ width = 400, height = 220, background = THEME.bg })

    local cases = {
      { 'c:circle("100", 50, 30)', function() c:circle("100", 50, 30) end },
      { "c:circle(0/0, 50, 30)",   function() c:circle(0/0, 50, 30) end },
      { 'c:rect(0,0,10,10,{fill="red"})',
        function() c:rect(0, 0, 10, 10, { fill = "red" }) end },
      { "c:polygon({2 points})",
        function() c:polygon({ {x=0,y=0}, {x=1,y=1} }) end },
      { "c:text(0, 0, 123)",       function() c:text(0, 0, 123) end },
    }

    c:text(16, 26, "实际运行结果",
      { size = 15, color = THEME.text })

    local y = 50
    for _, case in ipairs(cases) do
      local ok, err = pcall(case[2])
      c:circle(22, y - 4, 3.5, { fill = ok and THEME.green or THEME.red })
      c:text(36, y, case[1], { size = 11, color = THEME.text })
      local msg = tostring(err):gsub("^.*: canvas:", "canvas:")
      c:text(36, y + 15, msg, { size = 10, color = THEME.red })
      y = y + 36
    end

    return c
  end,
}

-- ============ 生成 ============

local gallery = {}
math.randomseed(7)

for _, ex in ipairs(EXAMPLES) do
  local ok, c = pcall(ex.build)
  if not ok then
    io.write(string.format("[ERR] %s: %s\n", ex.id, tostring(c)))
    c = canvas.new({ width = 320, height = 120, background = THEME.bg })
    c:text(16, 40, "build failed", { size = 14, color = THEME.red })
    c:text(16, 60, tostring(c):sub(1, 40),
      { size = 10, color = THEME.muted })
  end

  local list = c:build()
  local counts = {}
  for _, op in ipairs(list.ops) do
    counts[op.op] = (counts[op.op] or 0) + 1
  end
  local parts = {}
  for k, v in pairs(counts) do parts[#parts + 1] = k .. "=" .. v end
  table.sort(parts)

  gallery[#gallery + 1] = {
    id = ex.id,
    title = ex.title,
    desc = ex.desc,
    code = ex.code,
    svg = svg.to_svg(list),
    -- 原始显示列表：契约验证需要它来逐字段检查，
    -- 不能只给 SVG 字符串或统计数字
    ops = list.ops,
    op_count = list.op_count,
    width = list.width,
    height = list.height,
    background = list.background,
    -- 指纹直接取 build() 的产出。这里曾经手动写 c:hash()，
    -- 正好掩盖了 build() 自身漏掉 fingerprint 的问题。
    fingerprint = list.fingerprint,
    breakdown = table.concat(parts, "  "),
  }

  io.write(string.format("[GEN] %-12s %3d ops  %-18s %s\n",
    ex.id, list.op_count, c:hash(), table.concat(parts, " ")))
end

local fh = io.open(out_dir .. "/gallery.json", "wb")
fh:write(json.encode({ examples = gallery }))
fh:close()
io.write("[GEN] wrote " .. out_dir .. "/gallery.json\n")
