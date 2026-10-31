-- assets/lua/ui/proto.lua
--
-- 方向验证：让 Lua 直接产出 rfw 文本格式，并且**写起来像子程序**而不是填属性表。
--
-- 这是一个原型，用来回答两个问题（不是最终实现）：
--
--   1. Lua 生成 rfw 文本，可行吗？—— 可行，见 tools/bench_text_vs_json.dart
--      （两条路线产出的库字节完全相同）
--   2. "像写子程序"能不能做到？—— 这一份就是尝试本身
--
-- ## 写法上的变化
--
-- 现在（填属性表）：
--
-- ```lua
-- local app = ui.app({
--   state = { count = 0 },
--   handlers = { inc = function(s, ev) s.count = s.count + 1 end },
--   view = function(b, s) b:column({}, function(b) b:text("x") end) end,
-- })
-- ```
--
-- 这里（写过程）：
--
-- ```lua
-- local page = ui.page()          -- 先开一个"子程序"
-- page:state { count = 0 }         -- 每一行都是一句过程调用
-- page:on("inc", function(s, ev)   -- 不用先声明一张 handlers 表
--   s.count = s.count + 1
-- end)
-- page:body(function(ui, s)         -- 视图也是一个过程
--   ui:column(function()
--     ui:text("当前 " .. s.count)
--     ui:button("加一", ui:on_click("inc"))
--   end)
-- end)
-- return page:emit()               -- 产出 rfw 文本
-- ```
--
-- 差别只是"把配置表摊成一串调用"，但读起来是**从上到下的过程**，
-- 写错哪一步的报错也直接指向那一行。
--
-- ## 为什么值得试
--
-- 交互这块已经定了：**走 rfw 原生状态，不回 Lua**。
-- 于是 Lua 侧只剩两件事——描述结构、描述业务事件。
-- 这两件事都很短，摊成过程调用反而比嵌套的属性表更好读。

local M = {}

local perf = require("perf")

-- make_ui 定义在本文件后面，而 Page:body 会调它。
-- 不做前向声明的话这里解析到的是全局同名（永远 nil）。
local make_ui, state_literal, scalar

-- ============ 文本输出 ============
--
-- rfw 文本格式比 JSON 简单的地方：widget 名不用加引号，
-- 难的地方：参数名**必须**加引号，且一切都是位置无关的命名参数。

local function quote(s)
  local out = s:gsub("\\", "\\\\"):gsub('"', '\\"')
  out = out:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
  return '"' .. out .. '"'
end

-- 浮点必须带小数点，否则 rfw 的解析器会读成整数
local function num(v)
  if math.type(v) == "integer" then return string.format("%d", v) end
  local s = string.format("%.17g", v)
  if not s:find("[%.eE]") then s = s .. ".0" end
  return s
end

local Writer = {}
Writer.__index = Writer

local function new_writer()
  return setmetatable({ buf = {}, depth = 0 }, Writer)
end

function Writer:line(s)
  local pad = string.rep("  ", self.depth)
  self.buf[#self.buf + 1] = pad .. s
end

function Writer:raw(s)
  self.buf[#self.buf + 1] = s
end

function Writer:text()
  return table.concat(self.buf, "\n")
end

--- 输出一个"值"：标量 / 列表 / map / 子节点 / 事件 / set-state
function Writer:value(v, indent)
  local tv = type(v)

  if v == nil then
    self:raw("null")
  elseif tv == "boolean" then
    self:raw(v and "true" or "false")
  elseif tv == "number" then
    self:raw(num(v))
  elseif tv == "string" then
    self:raw(quote(v))
  elseif v.__setstate then
    -- rfw 的 set state：set state.a.b = <值>
    -- rfw 的语法要求完整写成 `set state.x.y = v`，
    -- 这里自动补 "state." 前缀，于是业务侧只写 ui:set("open", true)
    self:raw("set state." .. v.__setstate .. " = ")
    self:value(v.__value, indent)
  elseif v.__event then
    -- rfw 的事件：event "名字" { 参数 }
    self:raw("event " .. quote(v.__event) .. " {")
    if next(v.__arg) ~= nil then
      self.depth = self.depth + 1
      for k, val in pairs(v.__arg) do
        -- line() 已经写了缩进和 "键: "，这里补值和逗号
        self:line(quote(tostring(k)) .. ": ")
        self:value(val, indent .. "  ")
        self.buf[#self.buf] = self.buf[#self.buf] .. ","
      end
      self.depth = self.depth - 1
    end
    self:raw("}")
  elseif v.__widget then
    self:widget(v, indent)
  elseif tv == "table" then
    -- 先判断是数组还是 map
    if #v > 0 or next(v) == nil then
      if next(v) == nil then
        self:raw("[]")
        return
      end
      self:raw("[")
      self.depth = self.depth + 1
      for _, item in ipairs(v) do
        self:line("")
        self:value(item, indent .. "  ")
        self.buf[#self.buf] = self.buf[#self.buf] .. ","
      end
      self.depth = self.depth - 1
      self:raw("]")
    else
      self:raw("{")
      self.depth = self.depth + 1
      local keys = {}
      for k in pairs(v) do keys[#keys + 1] = k end
      table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
      for _, k in ipairs(keys) do
        self:line(quote(tostring(k)) .. ": ")
        self:value(v[k], indent .. "  ")
        self.buf[#self.buf] = self.buf[#self.buf] .. ","
      end
      self.depth = self.depth - 1
      self:raw("}")
    end
  else
    error("ui.proto: 无法输出 " .. tv)
  end
end

function Writer:widget(node, indent)
  self:raw(node.__widget .. "(")
  if next(node.__args) == nil then
    self:raw(")")
    return
  end
  self:raw("")
  self.depth = self.depth + 1
  -- 参数顺序固定：rfw 的解析器对顺序不敏感，但固定顺序让产出稳定可 diff
  local keys = {}
  for k in pairs(node.__args) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  for _, k in ipairs(keys) do
    self:line(quote(tostring(k)) .. ": ")
    self:value(node.__args[k], indent .. "  ")
    self.buf[#self.buf] = self.buf[#self.buf] .. ","
  end
  self.depth = self.depth - 1
  self:raw(")")
end

-- ============ 节点构造 ============

--- 当前正在收集的子节点列表。非 nil 表示"在某个 children 回调里"。
---
--- 这是"语句式"写法的实现：在回调里调用 ui:xxx 创建的节点，
--- 自动成为该回调的子节点，不需要 return、不需要手写数组。
local scope = nil

--- 参数顺序是「属性在前、子节点在后」，但只写子节点很常见
--- （`ui:column(function() ... end)`）。这里允许省掉属性位。
local function swap(a, b)
  if type(a) == "function" then return b or {}, a end
  return a or {}, b
end

local function widget(name, args)
  local n = { __widget = name, __args = args or {} }
  if scope then scope[#scope + 1] = n end
  return n
end

-- ============ Page：像子程序那样写界面 ============

local Page = {}
Page.__index = Page

--- 开一个新页面。
function M.page()
  -- 数据字段一律带下划线前缀。
  --
  -- 否则 `page.state` 会先命中实例上的数据表，`page:state{...}` 就成了
  -- "对一张表调用冒号"——Lua 的 __index 只在字段不存在时才去找方法。
  return setmetatable({
    _state = {},
    _handlers = {},
    _root = nil,
    libs = { "core.widgets", "core.material", "studio" },
    declarations = {},
  }, Page)
end

function Page:state(t)
  self._state = t
  return self
end

--- 读当前状态（view 里也可以用 page:data()）。
function Page:data()
  return self._state
end

function Page:on(name, fn)
  if type(fn) ~= "function" then
    error("ui.page:on 的第 2 个参数必须是函数（事件名 '.. name .. '）", 2)
  end
  self._handlers[name] = fn
  return self
end

function Page:body(fn)
  if type(fn) ~= "function" then
    error("ui.page:body 需要一个函数 (ui, state)", 2)
  end
  local ui = make_ui(self)

  -- 顶层也用收集栈：**不要求 return**。
  --
  -- 这一整份原型的意义就是"像写子程序一样写"——
  -- 如果顶层还得写 return，那它跟填属性表没区别。
  local saved = scope
  scope = {}
  local ok, err = pcall(fn, ui, self._state)
  local made = scope
  scope = saved
  if not ok then error(err, 0) end

  if #made == 0 then
    error("ui.page:body 没有创建任何节点", 2)
  elseif #made > 1 then
    error("ui.page:body 创建了 " .. #made .. " 个顶层节点，界面的根必须只有一个。"
      .. "多个的话用 column 包起来。", 2)
  end

  self._root = made[1]
  return self
end

--- 产出 rfw 文本。
function Page:emit()
  if self._root == nil then
    error("ui.page:emit 之前要先 page:body(...)", 2)
  end

  local w = new_writer()
  for _, lib in ipairs(self.libs) do
    w:line("import " .. lib .. ";")
  end

  -- 业务状态走 rfw 的 state：交互时改它不用回 Lua
  if next(self._state) ~= nil then
    w:line("widget root " .. state_literal(self._state) .. " =")
  else
    w:line("widget root =")
  end
  w.depth = 1
  w:value(self._root, "  ")
  w:raw(";")

  return w:text()
end

--- 状态字面量：`{ count: 0, name: "x" }`
function state_literal(st)
  local parts = {}
  for k, v in pairs(st) do
    parts[#parts + 1] = quote(tostring(k)) .. ": " .. scalar(v)
  end
  table.sort(parts)
  if #parts == 0 then return "" end
  return "{ " .. table.concat(parts, ", ") .. " }"
end

function scalar(v)
  local tv = type(v)
  if tv == "string" then return quote(v) end
  if tv == "number" then return num(v) end
  if tv == "boolean" then return v and "true" or "false" end
  error("ui.page: state 只能是标量（实际是 " .. tv .. "）")
end

-- ============ 造节点的 UI 对象 ============
--
-- 和现有的 Builder 一样是语句式，但方法名更短，且直接返回可嵌套的值。

function make_ui(page)
  local ui = {}

  -- 事件引用：交给宿主，不在 Lua 里执行
  function ui:event(name, arg)
    if page._handlers[name] == nil then
      local names = {}
      for k in pairs(page._handlers) do names[#names + 1] = k end
      table.sort(names)
      error("ui: 引用了未注册的事件 '" .. tostring(name) .. "'。已注册: "
        .. (#names > 0 and table.concat(names, ", ") or "(无)"), 2)
    end
    return { __event = name, __arg = arg or {} }
  end

  --- 本地状态写入：rfw 的 set state，**交互时当场生效，不回 Lua**。
  function ui:set(path, value)
    return { __setstate = path, __value = value }
  end

  local function kids(spec)
    if spec == nil then return {} end

    -- 回调形式：临时接管收集栈，回调里建的节点全部归它
    if type(spec) == "function" then
      local saved = scope
      scope = {}
      local ok, err = pcall(spec, ui)
      local made = scope
      scope = saved
      if not ok then error(err, 0) end
      return made
    end

    if spec.__widget then return { spec } end
    if type(spec) == "table" then return spec end
    error("ui: 子节点必须是函数、节点或节点数组，实际是 " .. type(spec))
  end

  function ui:column(props, children)
    props, children = swap(props, children)
    props = props or {}
    return widget("Column", {
      mainAxisAlignment = props.main,
      crossAxisAlignment = props.align,
      children = kids(children),
    })
  end

  function ui:row(props, children)
    props, children = swap(props, children)
    props = props or {}
    return widget("Row", {
      mainAxisAlignment = props.main,
      crossAxisAlignment = props.align,
      children = kids(children),
    })
  end

  function ui:text(str, props)
    props = props or {}
    local args = { text = tostring(str) }
    if props.style or props.color or props.size then
      local st = {}
      if props.size then st.fontSize = props.size + 0.0 end
      if props.color then st.color = tonumber((props.color:gsub("^#", "")), 16) end
      if props.style then st.fontWeight = props.style end
      args.style = st
    end
    if props.align then args.textAlign = props.align end
    return widget("Text", args)
  end

  function ui:button(label, handler, props)
    props = props or {}
    local kind = props.kind or "ElevatedButton"
    return widget(kind, {
      onPressed = handler,
      child = ui:text(label, { style = "w500" }),
    })
  end

  function ui:card(props, children)
    props, children = swap(props, children)
    props = props or {}
    local args = { child = kids(children)[1] }
    if props.color then args.color = tonumber((props.color:gsub("^#", "")), 16) end
    return widget("Card", args)
  end

  function ui:box(props, children)
    props, children = swap(props, children)
    props = props or {}
    local args = {}
    local k = kids(children)[1]
    if k then args.child = k end
    if props.width then args.width = props.width + 0.0 end
    if props.height then args.height = props.height + 0.0 end
    return widget("Container", args)
  end

  function ui:center(children)
    return widget("Center", { child = kids(children)[1] })
  end

  function ui:pad(props, children)
    props, children = swap(props, children)
    return widget("Padding", { child = kids(children)[1] })
  end

  function ui:expand(children, props)
    props = props or {}
    return widget("Expanded", {
      flex = props.flex or 1,
      child = kids(children)[1],
    })
  end

  function ui:spacer(props)
    props = props or {}
    return widget("SizedBox", {
      width = (props.size or 0) + 0.0,
      height = (props.size or 0) + 0.0,
    })
  end

  function ui:icon(name, props)
    props = props or {}
    local CODES = { add = 0xe145, star = 0xe838, close = 0xe16a }
    return widget("Icon", {
      icon = { icon = CODES[name] or 0xe145, fontFamily = "MaterialIcons" },
      size = (props.size or 20) + 0.0,
    })
  end

  function ui:divider(props)
    props = props or {}
    local args = {}
    if props.thickness then args.thickness = props.thickness + 0.0 end
    return widget("Divider", args)
  end

  function ui:scroll(props, children)
    props, children = swap(props, children)
    props = props or {}
    return widget("SingleChildScrollView", {
      child = widget("Column", {
        mainAxisSize = "min",
        children = kids(children),
      }),
    })
  end

  --- 宿主自定义组件。
  function ui:toggle(value, setPath, label)
    local args = { value = value }
    if setPath then args.onChange = { __setstate = setPath, __value = not value } end
    if label then args.label = label end
    -- 文本格式里 widget 名不接受点号（"studio.Toggle" 解析不过）。
    -- 本地库靠 import 语句区分，不靠名字前缀，所以这里用独立的名字。
    return widget("StudioToggle", args)
  end

  -- ====== 下面这批按 rfw_gen 的 widget_registry 补齐 ======
  --
  -- 参照物是 rfw_gen_builder 的 widget_registry.dart（63 个 widget，
  -- 从 rfw 的实际 API 推导出来的）。它是社区实现、方向相反（Dart AST），
  -- 用不了；但那份"哪些 widget 真正能被 rfw 接受"的对照表是可信的，
  -- 拿来当规范，省得自己一个个试。

  --- Scaffold：整个页面的骨架。textDirection 必须给，否则 Text 会炸。
  function ui:scaffold(props, children)
    props, children = swap(props, children)
    return widget("Scaffold", {
      appBar = kids(children)[1],
      body = kids(children)[2],
      backgroundColor = props.background,
    })
  end

  function ui:appbar(props, children)
    props = props or {}
    return widget("AppBar", {
      title = kids(children)[1],
      backgroundColor = props.background,
      elevation = props.elevation,
    })
  end

  function ui:stack(props, children)
    props, children = swap(props, children)
    return widget("Stack", {
      alignment = props.align,
      children = kids(children),
    })
  end

  function ui:wrap(props, children)
    props, children = swap(props, children)
    return widget("Wrap", {
      alignment = props.align,
      spacing = props.gap,
      children = kids(children),
    })
  end

  function ui:flexible(props, children)
    props, children = swap(props, children)
    return widget("Flexible", {
      flex = props.flex or 1,
      child = kids(children)[1],
    })
  end

  function ui:align(props, children)
    props, children = swap(props, children)
    return widget("Align", {
      alignment = props.align or "center",
      child = kids(children)[1],
    })
  end

  function ui:opacity(children, value)
    local k = kids(children)[1]
    if not k then return widget("Opacity", { opacity = value + 0.0 }) end
    return widget("Opacity", { opacity = value + 0.0, child = k })
  end

  function ui:listview(props, children)
    props, children = swap(props, children)
    return widget("ListView", {
      padding = props.padding,
      children = kids(children),
    })
  end

  function ui:listtile(props, children)
    props, children = swap(props, children)
    return widget("ListTile", {
      title = kids(children)[1],
      subtitle = kids(children)[2],
      onTap = props.on_tap,
    })
  end

  function ui:inkwell(handler, children)
    return widget("InkWell", {
      onTap = handler,
      child = kids(children)[1],
    })
  end

  function ui:gesture(handler, children)
    return widget("GestureDetector", {
      onTap = handler,
      child = kids(children)[1],
    })
  end

  function ui:material(props, children)
    props, children = swap(props, children)
    return widget("Material", {
      color = props.color,
      child = kids(children)[1],
    })
  end

  function ui:linear_progress(value)
    return widget("LinearProgressIndicator", { value = value + 0.0 })
  end

  return ui
end

-- ============ 事件分发 ============
--
-- 交互优先走 rfw 原生状态（不回 Lua）；只有业务事件才回到这里。

function M.dispatch(app_json, event_name, args_json)
  local app = app_json
  local handler = app._handlers[event_name]
  if not handler then
    local names = {}
    for k in pairs(app._handlers) do names[#names + 1] = k end
    table.sort(names)
    error("ui.dispatch: 未注册的事件 '.. tostring(event_name) .. '。已注册: "
      .. (#names > 0 and table.concat(names, ", ") or "(无)"), 2)
  end
  local args = {}
  if args_json and args_json ~= "" then
    args = require("host").require_cap("json").decode(args_json)
  end
  handler(app._state, args)
  return M.page_to_text(app)
end

function M.page_to_text(app)
  local w = new_writer()
  for _, lib in ipairs(app.libs) do w:line("import " .. lib .. ";") end
  if next(app._state) ~= nil then
    w:line("widget root " .. state_literal(app._state) .. " =")
  else
    w:line("widget root =")
  end
  w.depth = 1
  w:value(app._root, "  ")
  w:raw(";")
  return w:text()
end

perf.declare_libs("ui", { "string", "table", "math" })

return M
