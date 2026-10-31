-- tools/smoke.lua
--
-- 在与 Studio 完全相同的环境里执行一次，确认沙箱路径可用。
--
-- 这个脚本存在的意义：GUI 应用不会回显 stdout，
-- 所以必须用一个非 GUI 的方式证明同样的代码路径能跑通。
-- 跑的每一行都与 lib/sandbox.dart 的 bootstrap 完全一致。
--
-- 用法：lua tools/smoke.lua

package.path = table.concat({
  "assets/lua/?.lua",
  "assets/lua/?/init.lua",
  package.path,
}, ";")

local failures = 0

local function check(name, cond, detail)
  -- detail 可能是 table（模块对象），统一转成可读文本
  local text = nil
  if detail ~= nil then
    text = (type(detail) == "table") and "<table>" or tostring(detail)
  end

  if cond then
    print(string.format("  OK    %s%s", name,
      text and ("  (" .. text .. ")") or ""))
  else
    failures = failures + 1
    print(string.format("  FAIL  %s%s", name,
      text and ("  -> " .. text) or ""))
  end
end

-- 这几行与 sandbox.dart 的 bootstrap 一致
require("host.cli")
require("canvas")

print("=== 能力加载 ===")
local host = require("host")

local ok, canvas = pcall(function() return host.require_cap("canvas") end)
check("canvas 能力可用", ok and canvas ~= nil, ok and nil or tostring(canvas))

local ok2, json = pcall(function() return host.require_cap("json") end)
check("json 能力可用", ok2 and json ~= nil, ok2 and nil or tostring(json))

local missing, all_ok = host.verify()
check("verify() 无缺失", all_ok, #missing .. " missing")

print("\n=== 绘制链路 ===")

-- 这几行与 main.dart 的 buildStudioSource 一致
local c = canvas.new({ width = 360, height = 200, background = "#0f1116" })
c:circle(70, 70, 40, { fill = "#4a9eff" })
c:rect(140, 40, 90, 60, { radius = 10, fill = "#30a46c" })
c:line(30, 130, 330, 130, { stroke = "#2a2f3a" })
c:text(30, 165, "Studio", { size = 14, color = "#e6e9ef" })

local list = c:build()
check("build() 产出显示列表", list ~= nil)
check("图元数为 4", list.op_count == 4, "实际 " .. list.op_count)
check("op_count 与实际一致", list.op_count == #list.ops)

local encoded = json.encode(list)
check("json 编码非空", #encoded > 0, #encoded .. " 字节")

local rt_ok, rt = pcall(function()
  local back = json.decode(encoded)
  return back.op_count == #list.ops
end)
check("json 往返一致", rt_ok, rt_ok and nil or rt)

local hash1 = c:hash()
check("hash 非空", hash1 ~= nil and #hash1 > 0, hash1)

print("\n=== 与 Dart 侧契约一致性 ===")
-- Dart 的 DrawOp.fromJson 期望的键名
local op = list.ops[1]
check("circle 字段名匹配 Dart",
  op.op == "circle" and op.x and op.y and op.r and op.fill,
  string.format("op=%s x=%s fill=%s", tostring(op.op),
    tostring(op.x), tostring(op.fill)))

local text_op = list.ops[4]
check("text 字段名匹配 Dart",
  text_op.op == "text" and text_op.text and text_op.size and text_op.color,
  string.format("op=%s text=%s", tostring(text_op.op), tostring(text_op.text)))

print("\n=== 错误路径 ===")
local eok, err = pcall(function()
  local c2 = canvas.new()
  c2:circle(1, 1, "bad")
end)
check("非法参数被拦截", not eok, err)

print(string.format("\n%s", failures == 0
  and "全部通过 —— Studio 的沙箱路径可用"
  or (failures .. " 项失败")))

os.exit(failures == 0 and 0 or 1)