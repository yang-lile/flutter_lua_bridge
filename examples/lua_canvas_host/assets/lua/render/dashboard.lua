-- render/dashboard.lua
--
-- 业务侧示例：用 Lua 编排一个监控面板的绘制逻辑。
-- 注意这里没有任何 Flutter 相关代码——只是描述"画什么"。

local host= require("host")
local Canvas = require("canvas")

local log   = host.require_cap("log", { reason = "绘制流程需要可观测" })
local canvas = host.require_cap("canvas", { min_version = "1.0.0", reason = "输出显示列表" })

local M = {}

-- 调色板（数据，不是代码）
local THEME = {
  bg= "#0f1116",
  panel    = "#1a1d24",
  grid     = "#2a2f3a",
  text     = "#e6e9ef",
  muted    = "#8b93a3",
  accent   = "#4a9eff",
  warn     = "#f5a524",
  danger   = "#e5484d",
  ok= "#30a46c",
}

-- ============ 纯函数：数据 -> 绘制指令 ============

-- 把数据集切成网格布局
local function layout_grid(data, canvas_w, canvas_h, pad)
  local cells = {}
  local n = #data
  if n == 0 then return cells end

  local cols = math.ceil(math.sqrt(n))
  local rows = math.ceil(n / cols)
  local cw = (canvas_w - pad * (cols + 1)) / cols
  local ch = (canvas_h - pad * (rows + 1)) / rows

  for i, item in ipairs(data) do
    local c = (i - 1) % cols
    local r = math.floor((i - 1) / cols)
    cells[#cells + 1] = {
      x = pad + c * (cw + pad),
      y = pad + r * (ch + pad),
      w = cw,
      h = ch,
      item = item,
    }
  end
  return cells
end

-- 折线点位：把数值序列映射到画布坐标
local function sparkline_points(values, x, y, w, h, min_v, max_v)
  local pts = {}
  local n = #values
  if n == 0 then return pts end

  local range = (max_v - min_v) or 1
  for i, v in ipairs(values) do
    pts[#pts + 1] = {
      x = x + (i - 1) * (w / math.max(n - 1, 1)),
      y = y + h - ((v - min_v) / range) * h,
    }
  end
  return pts
end

local function status_color(status)
  if status == "critical" then return THEME.danger end
  if status == "warning"  then return THEME.warn end
  if status == "ok"       then return THEME.ok end
  return THEME.muted
end

-- ============ 主绘制 ============
--
-- 这是"纯业务"：输入数据集，输出显示列表。
-- 不依赖 Flutter、不依赖设备、可单元测试、可回放。

function M.draw_dashboard(data, canvas_w, canvas_h)
  canvas_w = canvas_w or 900
  canvas_h = canvas_h or 600

  local c = canvas.new({ width = canvas_w, height = canvas_h, background = THEME.bg })

  local pad = 16
  local header_h = 44

  -- 背景网格
  for gx = 0, canvas_w, 60 do
    c:line(gx, header_h, gx, canvas_h, { stroke = THEME.grid, stroke_width = 0.5 })
  end

  -- 标题
  c:text(pad, 28, "服务健康面板", { size = 20, color = THEME.text })
  c:text(canvas_w - pad, 28, "帧 #" .. (data.frame or 0),
    { size = 13, color = THEME.muted, align = "right" })

  -- 数据卡片
  local cells = layout_grid(data.services or {}, canvas_w, canvas_h - header_h - pad, pad)
  local body_top = header_h + pad

  for _, cell in ipairs(cells) do
    local s = cell.item

    -- 卡片底
    c:rect(cell.x, body_top + cell.y, cell.w, cell.h,
      { radius = 8, fill = THEME.panel, stroke = THEME.grid, stroke_width = 1 })

    -- 状态条
    local bar_w = 3
    c:rect(cell.x, body_top + cell.y, bar_w, cell.h,
      { fill = status_color(s.status), radius = 1.5 })

    -- 服务名与数值
    c:text(cell.x + 14, body_top + cell.y + 22, s.name,
      { size = 14, color = THEME.text })
    c:text(cell.x + cell.w - 14, body_top + cell.y + 22,
      string.format("%.1f%%", s.latency or 0),
      { size = 14, color = status_color(s.status), align = "right" })

    -- 迷你趋势线
    local series = s.history or {}
    if #series > 1 then
      local min_v, max_v = series[1], series[1]
      for _, v in ipairs(series) do
        min_v = math.min(min_v, v)
        max_v = math.max(max_v, v)
      end

      local pts = sparkline_points(series,
        cell.x + 14, body_top + cell.y + 38,
        cell.w - 28, cell.h - 48, min_v, max_v)

      c:polygon(pts, { stroke = THEME.accent, stroke_width = 1.5 })
    end
  end

  -- 底部汇总
  if #cells > 0 then
    local bad = 0
    for _, s in ipairs(data.services or {}) do
      if s.status ~= "ok" then bad = bad + 1 end
    end
    c:text(pad, canvas_h - pad,
      string.format("%d 个服务  |  %d 个异常", #cells, bad),
      { size = 12, color = bad > 0 and THEME.warn or THEME.muted })
  end

  return c
end

-- ============ 动画：只改数据，不碰渲染 ============
--
-- 每帧只需更新数据然后重新产出显示列表。
-- Lua 侧没有"重绘"的概念，宿主比较 hash 决定是否重绘。

function M.tick(data, dt)
  data.frame = (data.frame or 0) + 1

  for _, s in ipairs(data.services or {}) do
    s.history = s.history or {}
    -- 模拟一次采样
    local base = s.latency or 50
    local noise = (math.random() - 0.5) * base * 0.15
    s.latency = math.max(1, base + noise)

    s.history[#s.history + 1] = s.latency
    if #s.history > 40 then
      table.remove(s.history, 1)
    end

    -- 状态随延迟演化
    if s.latency > 200 then s.status = "critical"
    elseif s.latency > 120 then s.status = "warning"
    else s.status = "ok" end
  end

  return data
end

return M