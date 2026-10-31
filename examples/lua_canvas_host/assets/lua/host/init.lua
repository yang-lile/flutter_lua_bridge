-- host/init.lua
--
-- 能力契约层。业务 Lua 代码不直接触碰 io / os / 网络，
-- 而是通过这里声明的能力接口访问外部世界。
--
-- 好处：
--   1. 业务代码可测试 —— 换成 mock 宿主即可离线跑
--   2. 依赖显式 —— 启动时就校验能力是否齐全，而不是运行到一半报 nil
--   3. 宿主可替换 —— 同一个业务逻辑能在 OpenResty / 自研宿主 / 测试宿主上跑

local perf = require("perf")   -- perf 不依赖 host，所以这里不成环

-- 能力契约层用到 string.format / table.sort。
perf.declare_libs("host", { "string", "table" })

local M = {}

local registry = {}    -- name -> { impl, version, desc }
local requested = {}   -- name -> { min_version, reason }

local function parse_version(v)
  local parts = {}
  for chunk in tostring(v or "0"):gmatch("%d+") do
    parts[#parts + 1] = tonumber(chunk)
  end
  while #parts < 3 do
    parts[#parts + 1] = 0
  end
  return parts[1], parts[2], parts[3]
end

local function version_gte(a, b)
  local a1, a2, a3 = parse_version(a)
  local b1, b2, b3 = parse_version(b)
  if a1 ~= b1 then return a1 > b1 end
  if a2 ~= b2 then return a2 > b2 end
  return a3 >= b3
end

-- 宿主侧调用：注册一个能力
function M.provide(name, impl, opts)
  opts = opts or {}
  if type(name) ~= "string" or name == "" then
    error("host.provide: name must be a non-empty string", 2)
  end
  if type(impl) ~= "table" and type(impl) ~= "function" then
    error("host.provide: impl for '" .. name .. "' must be table or function", 2)
  end
  if registry[name] then
    error("host.provide: capability already provided: " .. name, 2)
  end
  registry[name] = {
    impl = impl,
    version = opts.version or "0.0.0",
    desc = opts.desc or "",
  }
  return registry[name]
end

-- 业务侧调用：声明必需能力，拿不到就立刻炸，并说明原因
function M.require_cap(name, opts)
  opts = opts or {}
  requested[name] = { min_version = opts.min_version, reason = opts.reason }

  local cap = registry[name]
  if not cap then
    error(
      "host: missing required capability '" .. name .. "'"
        .. (opts.reason and (" (" .. opts.reason .. ")") or ""),
      3
    )
  end
  if opts.min_version and not version_gte(cap.version, opts.min_version) then
    error(
      "host: capability '" .. name .. "' version "
        .. cap.version .. " is older than required "
        .. opts.min_version,
      3
    )
  end
  return cap.impl
end

-- 业务侧调用：可选能力，缺失返回 nil（用于降级分支）
function M.cap(name)
  local cap = registry[name]
  return cap and cap.impl or nil
end

function M.has(name)
  return registry[name] ~= nil
end

-- 校验所有声明过的依赖是否满足。宿主启动时调用一次。
function M.verify()
  local missing = {}
  for name, req in pairs(requested) do
    if not registry[name] then
      missing[#missing + 1] = name .. (req.reason and (" (" .. req.reason .. ")") or "")
    elseif req.min_version and not version_gte(registry[name].version, req.min_version) then
      missing[#missing + 1] = string.format(
        "%s (have %s, need >= %s)",
        name, registry[name].version, req.min_version
      )
    end
  end
  return missing, #missing == 0
end

-- 供诊断/调试：当前宿主提供了什么
function M.snapshot()
  local out = {}
  for name, cap in pairs(registry) do
    out[#out + 1] = {
      name = name,
      version = cap.version,
      desc = cap.desc,
    }
  end
  table.sort(out, function(a, b) return a.name < b.name end)
  return out
end

M._registry = registry
M._version_gte = version_gte

-- ============ 把 perf 挂成能力 ============
--
-- 放在文件末尾：此时 host 已经定义完，可以安全地注册。
M.provide("perf", perf, {
  version = "1.0.0",
  desc = "热点策略注册表 + 标准库需求声明",
})

return M