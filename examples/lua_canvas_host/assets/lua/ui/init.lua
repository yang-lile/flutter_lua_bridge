-- ui/init.lua
--
-- 用普通 Lua 语法描述 **Flutter widget 树**，产出声明式 UI 契约。
--
-- 契约的形状是给 rfw（Remote Flutter Widgets）准备的：
--   { ["$widget"] = "Column", ["$args"] = { mainAxisAlignment = "center", ... } }
--
-- 事件不是回调，而是**事件名**：
--   { ["$event"] = "increment", ["$arg"] = { amount = 1 } }
--
-- 这么设计的原因：宿主每次执行都重建 Lua state（见 lib/sandbox.dart），
-- 回调函数无法跨执行存活。事件走"名字 + 参数"，宿主把名字送回 Lua，
-- Lua 查表找到处理器执行 —— 状态留在 Lua 里，宿主只负责转发。
--
-- 与 canvas 的关系：canvas 产出绘制指令（宿主用 CustomPaint 画），
-- ui 产出 widget 树（宿主交给 rfw 渲染）。两者共用 guard 的执行预算。

local host = require("host")
local guard = require("guard")
local perf = require("perf")

-- ui 用到 string.format / table.concat / table.sort / math.floor / math.huge。
perf.declare_libs("ui", { "string", "table", "math" })

local json = host.require_cap("json", { reason = "序列化 UI 契约" })

-- 组件登记表。ui.component() 往里写，build 时全部展开成 rfw 声明。
local _components = {}

local ui = {}

-- 前向声明。定义在后面，但被更早定义的函数调用；
-- 不先声明的话那些函数里的引用会解析到全局同名（永远 nil）。
local build_style, merge_color
local hash

-- ============ 内部工具 ============

local function fail(msg, level)
  error("ui: " .. msg, (level or 2) + 1)
end

local function check_table(v, what)
  if type(v) ~= "table" then
    fail(what .. " 必须是 table，实际是 " .. type(v))
  end
  return v
end

local function check_num(v, what)
  if type(v) ~= "number" then
    fail(what .. " 必须是数字，实际是 " .. type(v))
  end
  if v ~= v or v == math.huge or v == -math.huge then
    fail(what .. " 不能是 NaN 或 Inf")
  end
  return v
end

--- #rgb / #rrggbb / #aarrggbb -> 0xAARRGGBB 整数。
---
--- rfw 的 color 解码器读的是整数（0xAARRGGBB），不是十六进制字符串。
--- 这里就地转掉，Dart 侧就不必再解析颜色。
local function to_argb(c, what)
  if type(c) == "number" then
    if c < 0 or c > 0xFFFFFFFF then
      fail(what .. " 颜色整数越界: " .. tostring(c))
    end
    return math.floor(c)
  end
  if type(c) ~= "string" then
    fail(what .. " 颜色必须是 #rgb/#rrggbb/#aarrggbb 字符串，实际是 " .. type(c))
  end
  local s = c:gsub("^#", "")
  if #s ~= 3 and #s ~= 6 and #s ~= 8 then
    fail(what .. " 颜色必须是 #rgb/#rrggbb/#aarrggbb，实际是 " .. c)
  end
  if s:find("%X") then   -- %X 是非十六进制字符
    fail(what .. " 颜色含非十六进制字符: " .. c)
  end
  s = s:lower()
  if #s == 3 then
    s = s:gsub("(%x)", "%1%1")
  end
  if #s == 6 then
    s = "ff" .. s
  end
  return tonumber(s, 16)
end

--- 间距 -> rfw 的 EdgeInsets 表示 [left, top, right, bottom]。
---
--- 接受三种写法：单个数字 / {x=,y=} / {left=,top=,right=,bottom=}。
local function to_insets(v, what)
  -- + 0.0 强制浮点：rfw 用 v<double> 读 insets，整数会被静默丢弃。
  if type(v) == "number" then
    local n = check_num(v, what) + 0.0
    return { n, n, n, n }
  end
  if type(v) ~= "table" then
    fail(what .. " 间距必须是数字或 table，实际是 " .. type(v))
  end
  local l, t, r, b
  if v.x ~= nil or v.y ~= nil then
    l, t = v.x or 0, v.y or 0
    r, b = v.x or 0, v.y or 0
  else
    l, t, r, b = v.left or 0, v.top or 0, v.right or 0, v.bottom or 0
  end
  return {
    check_num(l, what .. ".left") + 0.0,
    check_num(t, what .. ".top") + 0.0,
    check_num(r, what .. ".right") + 0.0,
    check_num(b, what .. ".bottom") + 0.0,
  }
end

-- ============ 文本样式预设 ============
--
-- style 用预设名而不是让业务代码每次都写 fontSize，
-- 但预设可以被覆盖（`{ style = "title", color = "#fff" }`）。

local TEXT_STYLES = {
  display = { fontSize = 32, fontWeight = "w700" },
  title   = { fontSize = 20, fontWeight = "w600" },
  subtitle = { fontSize = 16, fontWeight = "w500" },
  body    = { fontSize = 14 },
  label   = { fontSize = 12, fontWeight = "w500" },
  caption = { fontSize = 11, fontStyle = "italic" },
  mono    = { fontSize = 13, fontFamily = "Menlo" },
}

local FONT_WEIGHT = {
  w100 = "w100", w200 = "w200", w300 = "w300", w400 = "w400",
  w500 = "w500", w600 = "w600", w700 = "w700", w800 = "w800", w900 = "w900",
}

local ALIGN = { left = "left", center = "center", right = "right", justify = "justify" }

-- ============ 图标表 ============
--
-- MaterialIcons 的码点。列常用的一小部分；
-- 需要别的就把码点写进数字，`icon(0xe123)` 也认。

local ICONS = {
  add = 0xe145, remove = 0xe15b, close = 0xe16a, check = 0xe5ca,
  refresh = 0xe5d5, delete = 0xe872, edit = 0xe3c9, search = 0xe8b6,
  star = 0xe838, favorite = 0xe87d, home = 0xe88a, settings = 0xe8b8,
  info = 0xe88e, warning = 0xe002, done = 0xe930, send = 0xe163,
  favorite_border = 0xe87e, arrow_back = 0xe5c4, arrow_forward = 0xe5c5,
}

local function to_icon(v, what)
  if type(v) == "number" then return { icon = math.floor(v), fontFamily = "MaterialIcons" } end
  if type(v) ~= "string" then fail(what .. " 图标名必须是字符串或数字码点") end
  if ICONS[v] then
    return { icon = ICONS[v], fontFamily = "MaterialIcons" }
  end
  if v:match("^0x%x+$") then
    return { icon = tonumber(v:sub(3), 16), fontFamily = "MaterialIcons" }
  end
  local names = {}
  for k in pairs(ICONS) do names[#names + 1] = k end
  table.sort(names)
  fail(what .. " 未知图标 '" .. v .. "'。可用: " .. table.concat(names, ", "))
end

-- ============ 属性规格 ============
--
-- 每个 widget 声明自己接受哪些 Lua 属性、各自转成什么 rfw 参数。
-- 好处是错误信息能列出可用属性名，而不是让宿主渲染出 ErrorWidget。

-- 注意：`end` 是 Lua 关键字，做 table 的 key 时必须加方括号。
local ALIGN_MAIN = {
  start = "start", center = "center", ["end"] = "end",
  between = "spaceBetween", around = "spaceAround", evenly = "spaceEvenly",
}

local ALIGN_CROSS = {
  start = "start", center = "center", ["end"] = "end",
  stretch = "stretch", baseline = "baseline",
}

-- 属性定义：{ to = rfw 参数名, kind = 转换函数名, event = true }
--
-- **num 与 int 不是同义反复**：rfw 的 `DataSource.v<T>()` 是
-- `value is T ? value : null`，类型不符就静默丢参数。
-- `width` / `fontSize` / `padding` 这类用 v<double> 解码的必须是浮点，
-- `maxLines` / `flex` / `divisions` 这类用 v<int> 的必须是整数。
-- 搞错的后果不是报错，是**控件悄悄用默认值**。
local P = {
  -- 产出浮点（供 v<double>）
  num    = function(v, what) return check_num(v, what) + 0.0 end,
  -- 产出整数（供 v<int>）
  int    = function(v, what) return math.floor(check_num(v, what)) end,
  bool   = function(v, what)
    if type(v) ~= "boolean" then fail(what .. " 必须是布尔值，实际是 " .. type(v)) end
    return v
  end,
  str    = function(v, what)
    if type(v) ~= "string" then fail(what .. " 必须是字符串，实际是 " .. type(v)) end
    return v
  end,
  color  = function(v, what) return to_argb(v, what) end,
  inset  = function(v, what) return to_insets(v, what) end,
  align  = function(v, what) return v end,
  icon   = function(v, what) return to_icon(v, what) end,
  -- 声明了但由 widget 方法自己消费的属性（如 variant / arg）。
  noop   = function(v) return v end,
}

-- build_style / merge_color 定义在 Builder 之后，但 Builder:value 会用到它们。
-- 不做前向声明的话这里解析到的是全局同名（永远 nil）。
local build_style, merge_color

-- ============ 文本样式转换 ============

--- 把样式预设名或覆盖表转成 rfw 的 TextStyle map。
---
--- 写在 Builder 之前，但 [apply] 也要用它——所以开头做了前向声明。
build_style = function(v, what)
  local out
  if type(v) == "string" then
    local preset = TEXT_STYLES[v]
    if not preset then
      local names = {}
      for k in pairs(TEXT_STYLES) do names[#names + 1] = k end
      table.sort(names)
      fail(what .. " 未知样式 '" .. v .. "'。可用: " .. table.concat(names, ", "))
    end
    out = {}
    for k, pv in pairs(preset) do out[k] = pv end
  elseif type(v) == "table" then
    out = v
  else
    fail(what .. " 必须是样式名或覆盖 table，实际是 " .. type(v))
  end

  if out.color ~= nil then out.color = to_argb(out.color, what .. ".color") end
  if out.fontWeight ~= nil then
    local w = FONT_WEIGHT[out.fontWeight]
    if not w then
      fail(what .. " 未知字重 '" .. tostring(out.fontWeight) .. "'（可用 w100..w900）")
    end
    out.fontWeight = w
  end
  if out.fontSize ~= nil then
    out.fontSize = check_num(out.fontSize, what .. ".fontSize") + 0.0
  end
  -- letterSpacing / height 同样走 v<double>
  for _, k in ipairs({ "letterSpacing", "wordSpacing", "height" }) do
    if out[k] ~= nil then out[k] = check_num(out[k], what .. "." .. k) + 0.0 end
  end
  return out
end

-- ============ Builder ============
--
-- 视图函数收到它：`view = function(b, s) ... end`
--
-- ## 参数顺序：属性在前，子节点在后
--
-- `b:column({ main = "center" }, function(b) ... end)`
-- `b:card({ color = "#14171f" }, function(b) ... end)`
-- `b:text("你好", { style = "title" })`
--
-- 统一成这一个顺序是有代价的：没有子节点时得写 `b:box({ width = 8 })`
-- 而不是 `b:box(nil, {...})`。换来的是**看方法签名不用查表**——
-- 之前 card/box/pad 是 (children, props)、column/row 是 (props, children)，
-- 混着写迟早会踩。
--
-- ## 子节点写法：语句式
--
-- 容器方法回调里创建的节点自动成为子节点，不需要 return 也不需要手写数组：
--
-- ```lua
-- view = function(b, s)
--   b:column({ align = "center" }, function(b)
--     b:text("计数", { style = "display" })
--     b:button("加一", { on_tap = "inc" })
--   end)
-- end
-- ```
--
-- 代价是"这个节点属于哪个作用域"不再一眼可见，靠一条规则维持：
-- **在 children 回调里创建的节点属于该回调，在回调外创建的属于外层作用域。**
-- 实现是 [Builder.collect] 临时接管收集栈。
--
-- view 本身也遵循同一规则：顶层只允许产出一个根节点。

local Builder = {}

-- 组件可以直接当方法调：`b:RowItem{ id = 3 }`。
--
-- 拼错的名字不会静默变成别的东西 —— [decl_ref] 会报
-- 「引用了未定义的组件 'X'. 已定义: ...」，可读性比"未知方法"好得多。
Builder.__index = function(t, key)
  local method = Builder[key]
  if method ~= nil then return method end
  -- 必须是 (self, props, children)：调用方写的是 `b:RowItem()`，
  -- 冒号会把 builder 传成第一个参数。少写 self 的话，
  -- builder 会被当成 props，于是"组件不支持 props"的报错莫明其妙。
  return function(self_, props, children)
    return Builder.decl(self_, key, props, children)
  end
end

local function new_builder(ctx)
  return setmetatable({ ctx = ctx }, Builder)
end

--- 建一个节点，并计入总数。
---
--- 收集规则：正在 children 回调里（ctx.stack 非 nil）就进 ctx.stack，
--- 否则在 view 顶层（ctx.top 非 nil）就进 ctx.top，
--- 两者都为 nil（容器方法组装自己参数时）就都不进。
local function node(ctx, widget, args)
  ctx.count = ctx.count + 1
  local n = { ["$widget"] = widget, ["$args"] = args }
  local bucket = ctx.stack or ctx.top
  if bucket then bucket[#bucket + 1] = n end
  return n
end

--- 建一个**不进入任何作用域**的内部节点。
---
--- 只给两类场景用：布局实现自己造的节点（gap 的间隔、按钮里的文字、
--- scroll 里的内层 Column）。这些不是用户在回调里写的语句，
--- 不该混进当前作用域的子节点列表里。
---
--- 容器方法自己的返回值**不能**用它——那正是要注册进当前作用域的节点。
local function sub_node(ctx, widget, args)
  local saved_stack, saved_top = ctx.stack, ctx.top
  ctx.stack, ctx.top = nil, nil
  local n = node(ctx, widget, args)
  ctx.stack, ctx.top = saved_stack, saved_top
  return n
end

--- 收集子节点。spec 可以是：
---
---   * 函数   —— 语句式：回调里创建的节点全部收集，返回值也会并入
---   * 节点   —— 单个
---   * 数组   —— 多个
---   * nil    —— 没有子节点
function Builder:collect(spec, what)
  if spec == nil then return {} end

  if type(spec) == "table" then
    if spec["$widget"] then return { spec } end
    for i, v in ipairs(spec) do
      if type(v) ~= "table" or not v["$widget"] then
        fail(what .. " 的子节点数组第 " .. (i + 1) .. " 项不是节点")
      end
    end
    return spec
  end

  if type(spec) ~= "function" then
    fail(what .. " 的子节点必须是函数、节点或节点数组，实际是 " .. type(spec))
  end

  local ctx = self.ctx
  local outer_stack, outer_top = ctx.stack, ctx.top
  ctx.stack = {}
  ctx.top = nil

  -- pcall 保证回调抛错时收集栈一定还原，否则外层作用域会被写脏。
  local results = table.pack(pcall(spec, self))
  local made = ctx.stack
  ctx.stack, ctx.top = outer_stack, outer_top

  if not results[1] then
    error(results[2], 0)   -- 保留原始错误信息，去掉 pcall 的位置噪声
  end

  -- 回调显式 return 的也并进来，两种写法可以混用。
  -- 已创建过的节点不重复计入：spacer 里的 `return b:box(...)` 就是
  -- "既创建又 return"，算一个而不是两个。
  local function append_once(n)
    for _, v in ipairs(made) do
      if v == n then return end
    end
    made[#made + 1] = n
  end

  local r = results[2]
  if r ~= nil then
    if type(r) == "table" and r["$widget"] then
      append_once(r)
    elseif type(r) == "table" then
      for _, v in ipairs(r) do
        if type(v) ~= "table" or not v["$widget"] then
          fail(what .. " 的子节点函数返回了非节点项")
        end
        append_once(v)
      end
    else
      fail(what .. " 的子节点函数返回了 " .. type(r) .. "，应为节点或节点数组")
    end
  end

  return made
end

--- 收集**唯一**的子节点（card / pad / center 这类单槽位）。
function Builder:one(spec, what)
  local kids = self:collect(spec, what)
  if #kids == 0 then return nil end
  if #kids > 1 then
    fail(what .. " 只接受一个子节点，实际有 " .. #kids .. " 个。"
      .. "多个子节点请用 column / row 包一层。")
  end
  return kids[1]
end

--- 事件引用。处理器名必须是已注册的，否则在这里就报错。
--- 引用一个组件（widget 声明）。
---
--- 组件是**本地状态的载体**：状态挂在声明上，交互时由 rfw 自己改，
--- 不回 Lua。所以想做"点一下就变、且不需要业务逻辑"的交互，
--- 组件不是可选项。
local function decl_ref(ctx, name, args)
  -- 组件名按 rfw 的惯例是 PascalCase。小写开头基本可以断定是
  -- 「想调某个 widget 但名字写错了」，直接这么说比
  -- 「未定义的组件」有用得多——后者会让人去翻组件表。
  if not name:match("^%u") then
    fail("'" .. tostring(name) .. "' 不是已定义的组件名（组件名以大写字母开头）。\n"
      .. "如果你是想调一个 widget，widget 请写在对应的 builder 方法上；\n"
      .. "已定义的组件: " .. (#ctx.declarations > 0 and (function()
             local ns = {}
             for k in pairs(ctx.declarations) do ns[#ns + 1] = k end
             table.sort(ns)
             return table.concat(ns, ", ")
           end)() or "(无)"))
  end
  if ctx.declarations[name] == nil then
    local names = {}
    for k in pairs(ctx.declarations) do names[#names + 1] = k end
    table.sort(names)
    fail("引用了未定义的组件 '" .. tostring(name) .. "'。"
      .. "已定义: " .. (#names > 0 and table.concat(names, ", ") or "(无)"))
  end
  -- 必须走 node()：它负责计数**和**注册到当前作用域的收集栈。
  -- 直接造字面量的话，组件引用不会被父节点收集，
  -- 表现是「定义了一堆组件但界面上什么都没有」。
  return node(ctx, name, args or {})
end

--- 本地状态写入：对应 rfw 的 `set state.<path> = <value>`。
---
--- **这个赋值由 rfw 在客户端完成**：不产生事件、不回 Lua、不触发换库，
--- 所以是微秒级的。用它做按下 / 展开 / 选中这类瞬时反馈。
---
--- 与 [event_ref] 的分工：状态有没有业务含义。
--- 要落库、要发请求 -> 走事件回 Lua；只在本次交互内成立 -> 走这里。
local function setstate_ref(ctx, path, value, what)
  if type(path) ~= "string" or path == "" then
    fail(what .. " 的状态路径必须是非空字符串")
  end
  if value == nil then
    fail(what .. " 不能把状态设成 nil（rfw 的状态存不了 nil）")
  end
  return { ["$setstate"] = path, ["$value"] = value }
end

local function event_ref(ctx, name, arg, what)
  if type(name) ~= "string" or name == "" then
    fail(what .. " 的事件名必须是非空字符串")
  end
  if ctx.handlers[name] == nil then
    local names = {}
    for k in pairs(ctx.handlers) do names[#names + 1] = k end
    table.sort(names)
    fail(what .. " 引用了未注册的事件 '" .. name .. "'。已注册: "
      .. (#names > 0 and table.concat(names, ", ") or "(无)"))
  end
  local ref = { ["$event"] = name }
  if arg ~= nil then
    ref["$arg"] = check_table(arg, what .. " 的事件参数")
  end
  return ref
end

--- 应用属性表到节点的参数上。
local function apply(ctx, args, props, spec, what)
  if props == nil then return args end
  if type(props) ~= "table" then
    fail(what .. " 的属性必须是 table，实际是 " .. type(props))
  end
  for k, v in pairs(props) do
    local def = spec.props[k]
    if not def then
      local avail = {}
      for name in pairs(spec.props) do avail[#avail + 1] = name end
      table.sort(avail)
      fail(what .. " 不支持属性 '" .. tostring(k) .. "'。可用: " .. table.concat(avail, ", "))
    end
    if def.event then
      -- 事件槽既能接事件名（回 Lua），也能接一个本地状态写入节点
      -- （rfw 客户端改，不回 Lua）。写法一样，读代码的人不用记两套。
      if type(v) == "table" and v["$setstate"] ~= nil then
        args[def.to] = v
      else
        args[def.to] = event_ref(ctx, v, def.arg and def.arg(props) or nil, what .. "." .. k)
      end
    elseif def.kind == "style" then
      args[def.to] = build_style(v, what .. "." .. k)
    else
      local fn = P[def.kind]
      if not fn then fail(what .. "." .. k .. " 的类型 '" .. def.kind .. "' 未实现") end
      if def.values then
        -- 枚举在这里就拦住并列出可用值，
        -- 否则错误要等到宿主渲染出 ErrorWidget 才看得见。
        if def.values[v] == nil then
          local names = {}
          for name in pairs(def.values) do names[#names + 1] = name end
          table.sort(names)
          fail(what .. "." .. k .. " 只能是 " .. table.concat(names, " / ")
            .. "，实际是 " .. tostring(v))
        end
        v = def.values[v]
      end
      local converted = fn(v, what .. "." .. k)
      -- to == "" 表示该属性只用于参数校验与 widget 方法内部消费
      if def.to ~= "" then args[def.to] = converted end
    end
  end
  return args
end

--- 参数顺序是「属性在前、子节点在后」，但只写子节点回调是极常见的写法
--- （`b:column(function(b) ... end)`）。
--- 这里允许省掉属性位：第一个参数是函数就当作子节点。
local function swap_children(a, b)
  if type(a) == "function" then return b, a end
  return a, b
end

--- 在子节点之间插入间隙。
---
--- Flutter 的 Column / Row 都没有 gap 参数，声明式布局里最常见的妥协：
--- 用固定尺寸的 SizedBox 隔开。
local function add_gaps(ctx, children, gap, vertical)
  if not gap or gap == 0 then return children end
  local out = {}
  for i, child in ipairs(children) do
    if i > 1 then
      local spacer = vertical and { height = gap } or { width = gap }
      out[#out + 1] = sub_node(ctx, "SizedBox", spacer)
    end
    out[#out + 1] = child
  end
  return out
end

-- ---------- 布局 ----------

--- 引用一个组件：`b:RowItem({ title = "x" }, function(b) ... end)`。
---
--- props 里的 `open` / `on_close` 之类会原样传给组件的声明体。
function Builder:decl(name, props, children)
  props, children = swap_children(props, children)
  -- swap_children 会把 nil 归一成 {}，所以这里要同时判空
  if props ~= nil and next(props) ~= nil then
    -- 明确拒绝而不是静默忽略：调用方会以为参数生效了，
    -- 而界面上什么变化都没有 —— 那是最难查的一类 bug。
    fail("组件 '" .. tostring(name) .. "' 还不支持属性（props）。"
      .. "组件只带状态和子节点槽；数据驱动的差异请留在 root 里。"
      .. "（原因见 ui.component 的注释：rfw 的声明体只求值一次）")
  end
  local args = {}
  if children ~= nil then
    args["child"] = children
  end
  return decl_ref(self.ctx, name, args)
end

function Builder:column(props, children)
  props, children = swap_children(props, children)
  props = props or {}
  local ctx = self.ctx
  local kids = self:collect(children, "column")
  local args = apply(ctx, {
    children = add_gaps(ctx, kids, P.num(props.gap or 0, "column.gap"), true),
  }, props, {
    props = {
      main  = { to = "mainAxisAlignment", kind = "align", values = ALIGN_MAIN },
      align = { to = "crossAxisAlignment", kind = "align", values = ALIGN_CROSS },
      size  = { to = "mainAxisSize", kind = "str", values = { max = "max", min = "min" } },
      gap   = { to = "", kind = "num" },
    },
  }, "column")
  return node(ctx, "Column", args)
end

function Builder:row(props, children)
  props, children = swap_children(props, children)
  props = props or {}
  local ctx = self.ctx
  local kids = self:collect(children, "row")
  local args = apply(ctx, {
    children = add_gaps(ctx, kids, P.num(props.gap or 0, "row.gap"), false),
  }, props, {
    props = {
      main  = { to = "mainAxisAlignment", kind = "align", values = ALIGN_MAIN },
      align = { to = "crossAxisAlignment", kind = "align", values = ALIGN_CROSS },
      size  = { to = "mainAxisSize", kind = "str", values = { max = "max", min = "min" } },
      gap   = { to = "", kind = "num" },
    },
  }, "row")
  return node(ctx, "Row", args)
end

--- box = 通用容器（rfw 的 Container）。
function Builder:box(props, children)
  props, children = swap_children(props, children)
  local ctx = self.ctx
  local args = apply(ctx, {}, props, {
    props = {
      width    = { to = "width", kind = "num" },
      height   = { to = "height", kind = "num" },
      padding  = { to = "padding", kind = "inset" },
      margin   = { to = "margin", kind = "inset" },
      color    = { to = "color", kind = "color" },
      align    = { to = "alignment", kind = "str",
                   values = { center = "center", tl = "topLeft", tr = "topRight",
                              bl = "bottomLeft", br = "bottomRight" } },
    },
  }, "box")
  args.child = self:one(children, "box")
  return node(ctx, "Container", args)
end

--- pad = 内边距。props 可以是数字，也可以是 {x=,y=} / {left=,top=,right=,bottom=}。
function Builder:pad(props, children)
  props, children = swap_children(props, children)
  local ctx = self.ctx
  -- 整个 table 交给 to_insets，而不是先取 all/x：
  -- 取 props.x 会把同层的 y 丢掉（{x=4, y=10} 变成四周都是 4）。
  return node(ctx, "Padding", {
    padding = to_insets(props or 0, "pad"),
    child = self:one(children, "pad"),
  })
end

function Builder:center(children)
  return node(self.ctx, "Center", { child = self:one(children, "center") })
end

--- 撑满剩余空间。Row/Column 里用来做右侧对齐的按钮。
function Builder:expand(props, children)
  props, children = swap_children(props, children)
  props = props or {}
  return node(self.ctx, "Expanded", {
    flex = P.int(props.flex or 1, "expand.flex"),
    child = self:one(children, "expand"),
  })
end

--- 空白。`{ flex = 1 }` 在 Row/Column 里是弹性留白，`{ size = 8 }` 是固定 8px。
function Builder:spacer(props)
  props = props or {}
  local n = P.num(props.size or 0, "spacer.size")
  if props.flex then
    return self:expand({ flex = props.flex },
                       function(b) return b:box({ width = n, height = n }) end)
  end
  return self:box({ width = n, height = n })
end

function Builder:scroll(props, children)
  props, children = swap_children(props, children)
  props = props or {}
  local ctx = self.ctx
  local kids = self:collect(children, "scroll")
  local inner = sub_node(ctx, "Column", {
    mainAxisSize = "min",
    children = add_gaps(ctx, kids, P.num(props.gap or 0, "scroll.gap"), true),
  })
  return node(ctx, "SingleChildScrollView", {
    padding = to_insets(props.padding or 0, "scroll.padding"),
    child = inner,
  })
end

-- ---------- 内容 ----------

function Builder:text(str, props)
  -- str 可以是 b:sref(...) 的结果：那是一个状态引用，
  -- 值由 rfw 在客户端填（见 Builder:sref 的说明）。
  if type(str) == "number" then str = tostring(str) end
  if type(str) ~= "string" and not (type(str) == "table" and str["$state"]) then
    fail("text 的内容必须是字符串、数字，或 b:sref(...) 的状态引用，实际是 "
      .. type(str))
  end
  props = props or {}

  -- style 与 color 需要合并：两者在 rfw 里是同一个 TextStyle map 里的字段，
  -- 分开当独立参数会让后写的把先写的整个覆盖掉。
  local style
  if props.style ~= nil or props.color ~= nil then
    style = build_style(props.style or "body", "text.style")
    if props.color ~= nil then
      style.color = to_argb(props.color, "text.color")
    end
  end

  local args = apply(self.ctx, { text = str }, props, {
    props = {
      style = { to = "style", kind = "style" },
      -- color 由上面手工合并进 style，这里只是为了让校验放行
      color = { to = "", kind = "color" },
      align = { to = "textAlign", kind = "align", values = ALIGN },
      lines = { to = "maxLines", kind = "int" },
      dir   = { to = "textDirection", kind = "str", values = { ltr = "ltr", rtl = "rtl" } },
    },
  }, "text")
  if style ~= nil then args.style = style end

  return node(self.ctx, "Text", args)
end

function Builder:icon(name, props)
  local args = apply(self.ctx, {}, props, {
    props = {
      size  = { to = "size", kind = "num" },
      color = { to = "color", kind = "color" },
      label = { to = "semanticLabel", kind = "str" },
    },
  }, "icon")
  args.icon = to_icon(name, "icon")
  return node(self.ctx, "Icon", args)
end

--- 按钮。variant 决定用哪种 Material 按钮。
function Builder:button(label, props)
  props = props or {}
  local variant = props.variant or "elevated"
  local WIDGETS = {
    elevated = "ElevatedButton",
    outlined = "OutlinedButton",
    text     = "TextButton",
  }
  local widget = WIDGETS[variant]
  if not widget then
    local ks = {}
    for k in pairs(WIDGETS) do ks[#ks + 1] = k end
    table.sort(ks)
    fail("button 的 variant '" .. tostring(variant) .. "' 未知。可用: "
      .. table.concat(ks, ", "))
  end

  local ctx = self.ctx
  local args = apply(ctx, {}, props, {
    props = {
      on_tap  = { to = "onPressed", event = true, arg = function(p) return p.arg end },
      on_hold = { to = "onLongPress", event = true, arg = function(p) return p.arg end },
      -- 这三个由本方法自己消费，声明它们只是为了通过属性校验。
      variant = { to = "", kind = "noop" },
      text_style = { to = "", kind = "noop" },
      arg = { to = "", kind = "noop" },
    },
  }, "button")

  args.child = sub_node(ctx, "Text", {
    text = tostring(label),
    style = build_style(props.text_style or "label", "button.text_style"),
  })
  return node(ctx, widget, args)
end

function Builder:card(props, children)
  props, children = swap_children(props, children)
  local ctx = self.ctx
  local args = apply(ctx, {}, props, {
    props = {
      color  = { to = "color", kind = "color" },
      margin = { to = "margin", kind = "inset" },
      lift   = { to = "elevation", kind = "num" },
    },
  }, "card")
  args.child = self:one(children, "card")
  return node(ctx, "Card", args)
end

--- 显示一个值（数字 / 布尔 / 字符串都行）。
---
--- 为什么不直接用 b:text：rfw 自带的 Text 只吃 String，
--- `source.v<String>` 拿到数字会返回 null，**静默渲染成空**。
--- 而组件的本地状态天然是数字（计数器、选中下标），
--- 缺这个控件的话状态引用生效了也看不见。
function Builder:value(v, props)
  props = props or {}
  local args = {}
  -- 状态引用原样传下去，值由 rfw 在客户端填
  if type(v) == "table" and v["$state"] then
    args.text = v
  elseif type(v) == "boolean" then
    args.text = v and "是" or "否"
  else
    args.text = tostring(v)
  end
  if props.style then args.style = build_style(props.style, "value.style") end
  if props.color then args.style = merge_color(args.style, props.color) end
  if props.align then args.textAlign = props.align end
  if props.lines then args.maxLines = P.int(props.lines, "value.lines") end
  return node(self.ctx, "studio.ValueText", args)
end

local function merge_color(style, color)
  local st = style or {}
  st.color = to_argb(color, "value.color")
  return st
end

--- 引用组件的本地状态：`b:sref("hits")`。
---
--- **原生状态能不能生效，全看这个。**
---
--- 只发 `set state.x = v` 是没有用的：rfw 在状态变化时只会**重新解析树里的引用**，
--- 它没法凭空加一个节点。所以状态必须以引用的形式留在树里，
--- 值由 rfw 在客户端填。
---
--- 典型错误（看起来能写、但点了不动）：
---
--- ```lua
--- b:text("x" .. s.hits)          -- 烤成字面量 {text = "x0"}，永远不变
--- b:text(b:sref("hits"))         -- 正确：树里是 state.hits
--- ```
---
--- 组件内部用（state 由 ui.component 的 view 拿到），
--- 或者在声明里跨组件引用自己声明的字段。
function Builder:sref(path)
  if type(path) ~= "string" or path == "" then
    fail("sref 的路径必须是非空字符串")
  end
  return { ["$state"] = path }
end

--- 造一个本地状态写入，可直接当事件处理器用。
function Builder:set_state(path, value)
  return setstate_ref(self.ctx, path, value, "set_state")
end

function Builder:divider(props)
  local args = apply(self.ctx, {}, props, {
    props = {
      thickness = { to = "thickness", kind = "num" },
      color     = { to = "color", kind = "color" },
      indent    = { to = "indent", kind = "num" },
    },
  }, "divider")
  return node(self.ctx, "Divider", args)
end

--- 进度环。value 省略时是未定进度。
function Builder:progress(props)
  local args = apply(self.ctx, {}, props, {
    props = {
      value = { to = "value", kind = "num" },
      color = { to = "color", kind = "color" },
    },
  }, "progress")
  return node(self.ctx, "CircularProgressIndicator", args)
end

-- ---------- 交互控件 ----------
--
-- 这三个走宿主的自定义 widget（rfw 没提供 Switch / Slider / KPI），
-- 用来验证"Lua 也能下发宿主自定义组件"这条路径。

function Builder:toggle(props)
  props = props or {}
  local args = {}
  if props.value ~= nil then args.value = P.bool(props.value, "toggle.value") end
  if props.on_change then
    args.onChange = event_ref(self.ctx, props.on_change, nil, "toggle.on_change")
  end
  if props.label ~= nil then args.label = tostring(props.label) end
  return node(self.ctx, "studio.Toggle", args)
end

function Builder:slider(props)
  props = props or {}
  local args = {}
  -- min/max/value 是 double，divisions 是 int——rfw 侧类型不同，不能一起转。
  for _, k in ipairs({ "min", "max", "value" }) do
    if props[k] ~= nil then args[k] = P.num(props[k], "slider." .. k) end
  end
  if props.divisions ~= nil then
    args.divisions = P.int(props.divisions, "slider.divisions")
  end
  if props.on_change then
    args.onChange = event_ref(self.ctx, props.on_change, nil, "slider.on_change")
  end
  return node(self.ctx, "studio.Slider", args)
end

--- KPI 小卡片。演示"一个 Lua 函数 = 一个组件"。
function Builder:kpi(label, value, props)
  props = props or {}
  local args = apply(self.ctx, {
    label = tostring(label),
    value = tostring(value),
  }, props, {
    props = {
      accent = { to = "accent", kind = "color" },
    },
  }, "kpi")
  return node(self.ctx, "studio.Kpi", args)
end

-- 内容指纹走注册表，与 canvas 共用同一实现。
--
-- 早期 ui 和 canvas 各写了一份：ui 的对每一层 table 做 table.sort 以保证
-- 顺序无关，代价是在 6000 个节点的树上占到 build 总耗时的一大半。
-- 现在只有一个实现，策略（fast / canonical）由宿主决定。
local content_fingerprint = perf.get("fingerprint")

-- ============ 应用 ============

local App = {}
App.__index = App

--- 定义一个可复用组件（rfw 的 widget 声明）。
---
--- ```lua
--- local item = ui.component("RowItem", {
---   state = { open = false, count = 0 },
---   view = function(b, state)
---     b:card(function(b)
---       -- 瞬时交互：rfw 客户端改状态，不回 Lua
---       b:button("展开", b:set_state("open", not state.open))
---       b:button("+1", b:set_state("count", state.count + 1))
---       -- 业务交互：回 Lua
---       b:button("删除", { on_tap = "remove" })
---     end)
---   end,
--- })
--- -- 用法：b:RowItem()
--- ```
---
--- ## 为什么 view 拿不到 props
---
--- rfw 的声明体**只求值一次**（这是它的性能来源：整棵树只绑定一次），
--- 调用点的参数不是按实例绑进去的。要传数据得用
--- `Builder(builder: (scope) => ...)` 的闭包形式，那样写起来很难看。
---
--- 所以这一版组件只带**状态** + 子节点槽 —— 而这恰好就是我们要的东西：
--- 状态是本地状态的载体，交互不回 Lua。
--- 数据驱动的差异留给 root（root 本来就是按当前业务状态重新生成的）。
---
--- @param name string 组件名（rfw 里就是 widget 声明名）
--- @param opts table { state = 初始状态, view = function(builder, state) }
function ui.component(name, opts)
  if type(name) ~= "string" or name == "" then
    fail("ui.component: name 必须是非空字符串", 2)
  end
  opts = check_table(opts, "component '" .. name .. "' 的参数")
  local view = opts.view
  if type(view) ~= "function" then
    fail("ui.component '" .. name .. "': view 必须是函数 (builder, state)", 2)
  end

  _components[name] = _components[name] or {}
  _components[name].state = opts.state or {}
  _components[name].view = view
  return name
end

--- 已定义的组件（诊断用）。
function ui.components()
  local names = {}
  for k in pairs(_components) do names[#names + 1] = k end
  table.sort(names)
  return names
end

--- 创建一个应用。
---
--- ```lua
--- local app = ui.app({
---   state = { count = 0 },          -- 初始值
---   handlers = {
---     inc = function(s, ev) s.count = s.count + 1 end,
---   },
---   view = function(b, s)
---     b:column({ align = "center" }, function(b)
---       b:text(tostring(s.count), { style = "display" })
---       b:button("加一", { on_tap = "inc" })
---     end)
---   end,
--- })
--- return json.encode(app:build())
--- ```
---
--- ## state 是初始值，不是固定值
---
--- 宿主回传的状态（[seed_state]）**优先于** `opts.state`。
---
--- 这条规则是必需的，不是优化：事件触发时宿主会重跑整段代码，
--- 若不优先用回传的状态，每次点击都会把状态拉回初始值——
--- 表现为「点一下归零」，而且界面看上去完全正常。
---
--- @param opts.state table|nil 初始状态（宿主没回传时才用）
--- @param opts.handlers table 事件名 -> function(state, args)
--- @param opts.view function 视图函数 (builder, state) -> node
function ui.app(opts)
  opts = check_table(opts, "app 的参数")

  local handlers = opts.handlers or {}
  if type(handlers) ~= "table" then
    fail("app.handlers 必须是 table，实际是 " .. type(handlers))
  end
  for name, fn in pairs(handlers) do
    if type(fn) ~= "function" then
      fail("app.handlers['" .. tostring(name) .. "'] 必须是函数，实际是 " .. type(fn))
    end
  end

  local view = opts.view
  if type(view) ~= "function" then
    fail("app.view 必须是函数 (builder, state) -> node，实际是 " .. type(view))
  end

  local state = _STUDIO_UI_STATE or opts.state or {}
  if type(state) ~= "table" then
    fail("app.state 必须是 table，实际是 " .. type(state))
  end

  local app = setmetatable({
    state = state,
    handlers = handlers,
    view = view,
    title = opts.title,
  }, App)

  -- 事件分发要能找回这个 app，所以登记到模块级槽位。
  ui._current = app
  return app
end

--- 渲染一次并产出宿主可消费的信封。
function App:build()
  local ctx = {
    handlers = self.handlers,
    count = 0,
    stack = nil,
    top = {},
    declarations = _components,   -- 组件登记表，给 decl_ref 校验用
  }
  local b = new_builder(ctx)

  local results = table.pack(pcall(self.view, b, self.state))
  local made = ctx.top
  ctx.stack, ctx.top = nil, nil   -- 收集结束，之后创建的节点不再自动归属
  if not results[1] then
    error(results[2], 0)
  end

  -- 顶层必须恰好收敛成一个根节点。
  -- 写成 `b:column(...)`（不 return）或 `return b:column(...)` 都可以；
  -- 两条都出现且不是同一个节点则说明结构写错了，直接报出来。
  local root = results[2]
  if type(root) == "table" and root["$widget"] then
    if #made > 1 or (#made == 1 and made[1] ~= root) then
      fail("app.view 顶层创建了 " .. #made .. " 个节点又 return 了另一个，必须收敛成一个根")
    end
  elseif #made == 1 then
    root = made[1]
  elseif #made == 0 then
    fail("app.view 没有创建任何节点。写法：view = function(b, s) b:column(...) end")
  else
    fail("app.view 顶层创建了 " .. #made
      .. " 个节点，无法确定根。请用 column / row 包成一个。")
  end

  -- 把组件展开成声明。每个组件是一个独立的构建上下文，
  -- 所以组件里的节点数不会污染外层的收集栈。
  local declarations = {}
  local names = {}
  for name in pairs(_components) do names[#names + 1] = name end
  table.sort(names)   -- 固定顺序 -> 产出的字节稳定

  for _, name in ipairs(names) do
    local comp = _components[name]
    local cctx = {
      handlers = self.handlers,   -- 组件内部也能发业务事件
      count = 0, stack = nil, top = {},
      declarations = _components,
    }
    local cb = new_builder(cctx)
    -- 组件 view 也是语句式：顶层不用 return，靠收集栈拿根节点。
    -- 与 app.view 同一套规则（见 Builder 的注释）。
    cctx.stack = {}
    local ok, res = pcall(comp.view, cb, comp.state)
    local made = cctx.stack
    cctx.stack = nil
    if not ok then error(res, 0) end
    if res ~= nil and res["$widget"] ~= nil then
      made[#made + 1] = res      -- 既建又 return 的，按一个算
    end
    if #made ~= 1 then
      fail("组件 '" .. name .. "' 的 view 必须恰好产出一个根节点"
        .. "（实际 " .. #made .. " 个）。多个的话用 column 包起来。")
    end
    declarations[#declarations + 1] = {
      name = name,
      state = comp.state,
      node = made[1],
    }
  end

  local events = {}
  for name in pairs(self.handlers) do events[#events + 1] = name end
  table.sort(events)

  return {
    version = 1,
    widget = "root",
    title = self.title,
    state = self.state,
    events = events,
    declarations = declarations,
    tree = root,
    node_count = ctx.count,
    event_count = #events,
    fingerprint = content_fingerprint({
      tree = root, state = self.state, declarations = declarations,
    }),
  }
end

--- 供 json.encode 使用。
function App:__tostring()
  return json.encode(self:build())
end

-- ============ 事件分发 ============

--- 执行一个事件并返回重建后的信封 JSON。
---
--- 宿主在 rfw 的 onEvent 回调里调用它。
--- 每次调用前宿主都会重新执行用户代码，所以这里的 `ui._current`
--- 一定是刚注册好的 app，状态也是宿主回传过来的。
function ui.dispatch(name, args_json)
  local app = ui._current
  if not app then
    fail("dispatch: 还没有创建应用（先调用 ui.app）")
  end

  local handler = app.handlers[name]
  if not handler then
    local names = {}
    for k in pairs(app.handlers) do names[#names + 1] = k end
    table.sort(names)
    fail("dispatch: 未注册的事件 '" .. tostring(name) .. "'。已注册: "
      .. (#names > 0 and table.concat(names, ", ") or "(无)"))
  end

  local args = {}
  if args_json and args_json ~= "" then
    local ok, decoded = pcall(json.decode, args_json)
    if not ok then
      fail("dispatch: 事件参数不是合法 JSON —— " .. tostring(decoded))
    end
    if type(decoded) ~= "table" then
      fail("dispatch: 事件参数必须是 table，实际是 " .. type(decoded))
    end
    args = decoded
  end

  handler(app.state, args)
  return json.encode(app:build())
end

--- 供宿主在执行用户代码前设置：把上一轮的状态喂回来。
function ui.seed_state(json_text)
  if not json_text or json_text == "" then
    _STUDIO_UI_STATE = nil
    return
  end
  local ok, decoded = pcall(json.decode, json_text)
  if not ok then
    fail("seed_state: 状态不是合法 JSON —— " .. tostring(decoded))
  end
  _STUDIO_UI_STATE = decoded
end

function ui.clear()
  ui._current = nil
  _STUDIO_UI_STATE = nil
end

-- ============ 能力注册 ============

host.provide("ui", {
  app = ui.app,
  dispatch = ui.dispatch,
  seed_state = ui.seed_state,
  wrap = guard.wrap,
  run = guard.run,
  styles = TEXT_STYLES,
  icons = ICONS,
}, { version = "1.0.0", desc = "声明式 widget 树（产出 rfw 契约）" })

-- 直接 require("ui") 也能拿到全部能力。
for k, v in pairs({
  app = ui.app,
  dispatch = ui.dispatch,
  seed_state = ui.seed_state,
  wrap = guard.wrap,
  run = guard.run,
  styles = TEXT_STYLES,
  icons = ICONS,
}) do
  ui[k] = v
end

return ui
