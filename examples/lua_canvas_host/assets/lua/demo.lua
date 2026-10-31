-- 终端演示：在没有 Flutter 的情况下验证整条链路
-- 用法：lua demo.lua  输出 out/dashboard.svg

require("bootstrap")
require("host.cli")

local json = require("host").require_cap("json")
local log  = require("host").require_cap("log")
local dashboard = require("render.dashboard")
local svg = require("render.svg")

log.set_output(function(m) io.stdout:write(m .. "\n") end)

math.randomseed(42)

-- 模拟数据源
local data = {
  frame = 0,
  services = {
    { name = "gateway",  latency = 45,  status = "ok" },
    { name = "auth",     latency = 88,  status = "ok" },
    { name = "database", latency = 210, status = "critical" },
    { name = "cache",    latency = 12,  status = "ok" },
    { name = "queue",    latency = 135, status = "warning" },
    { name = "search",   latency = 62,  status = "ok" },
  },
}

-- 预热若干帧，让折线图有历史数据
for _ = 1, 40 do
  dashboard.tick(data)
end

log.info("绘制面板...")
local c = dashboard.draw_dashboard(data, 900, 600)
local list = c:build()

log.info(string.format("显示列表已生成: %d 个图元, hash=%s",
  list.op_count, c:hash()))

-- 验证幂等：同样的输入产出同样的 hash
local c2 = dashboard.draw_dashboard(data, 900, 600)
local same = (c2:hash() == c:hash())
log.info("相同数据 hash 一致: " .. tostring(same))

-- 验证变化检测：改数据后 hash 应该变
local prev_hash = c:hash()
dashboard.tick(data)
local c3 = dashboard.draw_dashboard(data, 900, 600)
log.info("数据变化后 hash 改变: " .. tostring(prev_hash ~= c3:hash()))

-- 输出 SVG
local out = svg.to_svg(list)
local fh = io.open("out/dashboard.svg", "wb")
if fh then
  fh:write(out)
  fh:close()
  log.info("已写入 out/dashboard.svg (" .. #out .. " bytes)")
else
  log.error("无法写入 out/dashboard.svg（目录是否存在？）")
end

-- 输出 JSON，演示宿主可以换不同后端
local jf = io.open("out/dashboard.json", "wb")
if jf then
  jf:write(json.encode(list))
  jf:close()
  log.info("已写入 out/dashboard.json")
end

-- ASCII 预览，确认图元数量和分布合理
local counts = {}
for _, op in ipairs(list.ops) do
  counts[op.op] = (counts[op.op] or 0) + 1
end
local parts = {}
for k, v in pairs(counts) do parts[#parts + 1] = k .. "=" .. v end
table.sort(parts)
log.info("图元统计: " .. table.concat(parts, " "))