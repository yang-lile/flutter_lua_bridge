-- 复用上一轮 mock 宿主里已验证的 json 能力。
-- 生产环境应换成 cjson。这里单独抽出来，避免依赖 host/mock 的其他部分。

local host = require("host")
local perf = require("perf")

-- json 编码器用到 string.format / table.concat / math.floor / math.type。
perf.declare_libs("json", { "string", "table", "math" })

-- ============ 最小 JSON 实现（够用即可，宿主可换成 cjson） ============

local escape_map = {
  ['"'] = '\\"', ["\\"] = "\\\\", ["\b"] = "\\b",
  ["\f"] = "\\f", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t",
}

local function is_array(t)
  local n = 0
  for k in pairs(t) do
    if type(k) ~= "number" then return false end
    n = n + 1
  end
  return n == #t
end

local encode_value   -- 前向声明：encode_table 会递归调用它

--- 数字 -> JSON 字面量，**保留整数 / 浮点的区别**。
---
--- 为什么必须区分：`%.14g` 会把 40.0 打成 "40"。JSON 解析器于是
--- 把它读成整数，而 rfw 的 `DataSource.v<double>()` 实现是
--- `value is double ? value : null` —— 类型不匹配就**静默返回 null**，
--- 参数被丢弃、控件退回默认值，画面照样正常显示。
---
--- 这个坑真实发生过：`slider(min=0, max=100)` 的 max 被丢掉，
--- Flutter 那边就成了 0..1，拖到最右事件里带的也是 0.9。
---
--- 所以浮点必须带着小数点出去（40.0），让对端解析成 double。
-- 数字编码策略放在注册表里，换实现只动一处（默认见 host/perf.lua）。
local encode_number = perf.get("json_number")

--- 字符串 -> JSON 字面量。
---
--- 先用 find 探一下有没有需要转义的字符：
--- gsub 带表替换即使不命中也要建结果 table、走一遍完整匹配机制，
--- 而契约里绝大多数字符串是普通文本（widget 名、文案）。
local function encode_string(v)
  if v:find('[%z\1-\31\\"]') then
    return '"' .. v:gsub('[%z\1-\31\\"]', escape_map) .. '"'
  end
  return '"' .. v .. '"'
end

local function encode_table(t, out)
  if is_array(t) then
    out[#out + 1] = "["
    for i = 1, #t do
      if i > 1 then out[#out + 1] = "," end
      encode_value(t[i], out)
    end
    out[#out + 1] = "]"
  else
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    out[#out + 1] = "{"
    for i, k in ipairs(keys) do
      if i > 1 then out[#out + 1] = "," end
      out[#out + 1] = '"' .. tostring(k) .. '":'
      encode_value(t[k], out)
    end
    out[#out + 1] = "}"
  end
end

encode_value = function(v, out)
  local tv = type(v)
  if v == nil then
    out[#out + 1] = "null"
  elseif tv == "boolean" then
    out[#out + 1] = v and "true" or "false"
  elseif tv == "number" then
    out[#out + 1] = encode_number(v)
  elseif tv == "string" then
    out[#out + 1] = encode_string(v)
  elseif tv == "table" then
    encode_table(v, out)
  else
    error("json: cannot encode " .. tv)
  end
end

local function skip_ws(s, i)
  while i <= #s and s:find("%s", i) == i do i = i + 1 end
  return i
end

local parse_value

local function parse_string(s, i)
  local buf = {}
  i = i + 1
  while i <= #s do
    local c = s:sub(i, i)
    if c == '"' then
      return table.concat(buf), i + 1
    elseif c == "\\" then
      local n = s:sub(i + 1, i + 1)
      if n == "n" then buf[#buf + 1] = "\n"
      elseif n == "t" then buf[#buf + 1] = "\t"
      elseif n == "r" then buf[#buf + 1] = "\r"
      elseif n == "b" then buf[#buf + 1] = "\b"
      elseif n == "f" then buf[#buf + 1] = "\f"
      elseif n == "u" then
        local cp = tonumber(s:sub(i + 2, i + 5), 16) or 63
        if cp < 0x80 then
          buf[#buf + 1] = string.char(cp)
        elseif cp < 0x800 then
          buf[#buf + 1] = string.char(0xC0 + math.floor(cp / 0x40), 0x80 + cp % 0x40)
        else
          buf[#buf + 1] = string.char(
            0xE0 + math.floor(cp / 0x1000),
            0x80 + math.floor(cp / 0x40) % 0x40,
            0x80 + cp % 0x40)
        end
        i = i + 4
      else
        buf[#buf + 1] = n
      end
      i = i + 2
    else
      buf[#buf + 1] = c
      i = i + 1
    end
  end
  error("json: unterminated string")
end

local function parse_number(s, i)
  local j = i
  while j <= #s and s:find("[%d%.eE%+%-]", j) == j do j = j + 1 end
  local num = tonumber(s:sub(i, j - 1))
  if not num then error("json: bad number at " .. i) end
  return num, j
end

parse_value = function(s, i)
  i = skip_ws(s, i)
  local c = s:sub(i, i)

  if c == "{" then
    local obj = {}
    i = skip_ws(s, i + 1)
    if s:sub(i, i) == "}" then return obj, i + 1 end
    while true do
      i = skip_ws(s, i)
      local key, ni = parse_string(s, i)
      i = skip_ws(s, ni)
      if s:sub(i, i) ~= ":" then error("json: expected ':' at " .. i) end
      local val
      val, i = parse_value(s, i + 1)
      obj[key] = val
      i = skip_ws(s, i)
      local d = s:sub(i, i)
      if d == "}" then return obj, i + 1 end
      if d ~= "," then error("json: expected ',' or '}' at " .. i) end
      i = i + 1
    end
  elseif c == "[" then
    local arr = {}
    i = skip_ws(s, i + 1)
    if s:sub(i, i) == "]" then return arr, i + 1 end
    while true do
      local val
      val, i = parse_value(s, i)
      arr[#arr + 1] = val
      i = skip_ws(s, i)
      local d = s:sub(i, i)
      if d == "]" then return arr, i + 1 end
      if d ~= "," then error("json: expected ',' or ']' at " .. i) end
      i = i + 1
    end
  elseif c == '"' then
    return parse_string(s, i)
  elseif c == "t" and s:sub(i, i + 3) == "true" then
    return true, i + 4
  elseif c == "f" and s:sub(i, i + 4) == "false" then
    return false, i + 5
  elseif c == "n" and s:sub(i, i + 3) == "null" then
    return nil, i + 4
  else
    return parse_number(s, i)
  end
end

local json = {}

function json.encode(v)
  local out = {}
  encode_value(v, out)
  return table.concat(out)
end

function json.decode(s)
  if type(s) ~= "string" then error("json.decode expects string") end
  return parse_value(s, 1)
end

host.provide("json", json,
  { version = "0.8.0", desc = "JSON 编解码（宿主应替换为 cjson）" })

-- ============ 日志 ============

local log_impl = { level = "info", outputs = {} }
local LEVELS = { debug = 1, info = 2, warn = 3, error = 4 }

log_impl.set_output = function(fn) log_impl.outputs = { fn } end
log_impl.debug = function(m) if LEVELS.debug >= LEVELS[log_impl.level] then
  for _, f in ipairs(log_impl.outputs) do f("[DEBUG] " .. m) end end end
log_impl.info  = function(m) if LEVELS.info >= LEVELS[log_impl.level] then
  for _, f in ipairs(log_impl.outputs) do f("[INFO] " .. m) end end end
log_impl.warn  = function(m) if LEVELS.warn >= LEVELS[log_impl.level] then
  for _, f in ipairs(log_impl.outputs) do f("[WARN] " .. m) end end end
log_impl.error = function(m) if LEVELS.error >= LEVELS[log_impl.level] then
  for _, f in ipairs(log_impl.outputs) do f("[ERROR] " .. m) end end end

host.provide("log", log_impl, { version = "1.0.0", desc = "日志" })

return host