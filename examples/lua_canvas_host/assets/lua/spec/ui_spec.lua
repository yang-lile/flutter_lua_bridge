-- assets/lua/spec/ui_spec.lua
--
-- ui 模块的单元测试。零依赖，直接 `lua assets/lua/spec/ui_spec.lua`。
--
-- 路径自解析，所以从任意工作目录跑都行。
--
-- 这些用例只测 Lua 侧：契约的形状与事件语义。
-- 跨语言那一段（契约能不能被 Dart / rfw 消费）在
-- tools/verify_ui_ast.dart 里。

local here = arg and arg[0] and arg[0]:match("^(.*)/spec/[^/]+$") or "assets/lua"
if here == "" then here = "." end
package.path = table.concat({
  here .. "/?.lua",
  here .. "/?/init.lua",
  package.path,
}, ";")

require("host.cli")

local ui = require("ui")
local host = require("host")
local json = host.require_cap("json")

-- 宿主沙箱里 ui 是全局（见 lib/sandbox.dart 的 uiPrelude），
-- 而这里上面拿到的是局部变量。后面 section 6 用 load() 重新执行用户代码，
-- 那个 chunk 的 _ENV 只能看到全局，所以这里补一个。
_G.ui = ui
_G.json = json

-- ============ 迷你测试框架 ============

local passed, failed = 0, 0
local current = "?"

local function ok(name, cond, detail)
  if cond then
    passed = passed + 1
    io.write(string.format("  PASS  %s%s\n", name,
      detail and ("  (" .. detail .. ")") or ""))
  else
    failed = failed + 1
    io.write(string.format("  FAIL  %s%s\n", name,
      detail and ("  -> " .. detail) or ""))
  end
end

local function eq(name, got, want)
  ok(name, got == want,
    got == want and nil or ("got " .. tostring(got) .. ", want " .. tostring(want)))
end

local function section(title)
  io.write("\n" .. title .. "\n")
end

--- 断言一段代码会报错，且错误信息里含 [needle]。
---
--- 错误信息质量直接决定编辑器好不好用，所以这些断言是有意义的：
--- 报错必须能指出**哪个属性 / 哪个事件**错了，而不是只说"参数不合法"。
local function raises(name, code, needle)
  local okRun, err = pcall(code)
  if okRun then
    ok(name, false, "没有报错")
    return
  end
  local msg = tostring(err)
  if not needle then
    ok(name, true)
    return
  end
  -- 不能写成 `find(...) and nil or "缺少..."`：
  -- find 命中时 `x and nil` 得到 nil（假值），于是 or 分支照样执行，
  -- 每次都打出"缺少"。用 if 写清楚。
  local found = msg:find(needle, 1, true) ~= nil
  if found then
    ok(name, true)
  else
    ok(name, false, "缺少 '" .. needle .. "'，实际: " .. msg)
  end
end

-- ============ 基础构建 ============

section("=== 1. 基本构建 ===")

do
  local app = ui.app({
    state = { n = 3 },
    view = function(b, s)
      b:column(function(b)
        b:text("n = " .. s.n)
      end)
    end,
  })
  local env = app:build()

  eq("版本", env.version, 1)
  eq("入口 widget", env.widget, "root")
  eq("根节点类型", env.tree["$widget"], "Column")
  eq("节点数", env.node_count, 2)
  eq("状态", env.state.n, 3)
  ok("没有事件时清单为空", env.event_count == 0)

  local child = env.tree["$args"].children[1]
  eq("子节点是 Text", child["$widget"], "Text")
  eq("文本内容", child["$args"].text, "n = 3")
end

section("\n=== 2. 语句式子节点 ===")

do
  -- 子节点回调里的语句不需要 return，也不需要手写数组
  local app = ui.app({
    state = {},
    view = function(b)
      b:row(function(b)
        b:text("a")
        b:text("b")
        b:text("c")
      end)
    end,
  })
  local kids = app:build().tree["$args"].children
  eq("三个子节点", #kids, 3)
  eq("按顺序", kids[2]["$args"].text, "b")
end

do
  -- 嵌套三层，验证收集栈的还原
  local app = ui.app({
    state = {},
    view = function(b)
      b:column(function(b)
        b:text("外")
        b:row(function(b)
          b:text("内1")
          b:text("内2")
        end)
        b:text("外尾")
      end)
    end,
  })
  local kids = app:build().tree["$args"].children
  eq("外层三个子节点", #kids, 3)
  eq("中间是 Row", kids[2]["$widget"], "Row")
  eq("Row 里两个", #kids[2]["$args"].children, 2)
end

do
  -- 回调里抛错不能把收集栈写脏，否则后续渲染全是错的
  local app = ui.app({
    state = {},
    view = function(b)
      b:column(function(b)
        b:text("保留")
        b:pad(function()
          error("故意炸")
        end)
      end)
    end,
  })
  local env
  raises("子节点回调报错会冒泡", function() env = app:build() end, "故意炸")
end

do
  -- 语句式与 return 可以混用，但同一个节点只能算一次
  local app = ui.app({
    state = {},
    view = function(b)
      b:column(function(b)
        b:text("x")
        return b:text("y")
      end)
    end,
  })
  eq("显式 return 也算子节点",
    #app:build().tree["$args"].children, 2)
end

section("\n=== 3. 顶层根节点规则 ===")

raises("顶层没建节点", function()
  ui.app({ state = {}, view = function() end }):build()
end, "没有创建任何节点")

raises("顶层多个节点", function()
  ui.app({
    state = {},
    view = function(b)
      b:text("a")
      b:text("b")
    end,
  }):build()
end, "顶层创建了 2 个节点")

do
  -- return 根节点也可以
  local app = ui.app({
    state = {},
    view = function(b) return b:text("唯一") end,
  })
  eq("return 根节点", app:build().tree["$widget"], "Text")
end

raises("view 不是函数", function()
  ui.app({ state = {}, view = "nope" })
end, "app.view 必须是函数")

raises("handler 不是函数", function()
  ui.app({ state = {}, handlers = { a = 1 }, view = function(b) b:text("x") end })
end, "必须是函数")

section("\n=== 4. 属性与校验 ===")

do
  local app = ui.app({
    state = {},
    view = function(b)
      b:column({ main = "between", align = "center", gap = 12 }, function(b)
        b:text("x")
        b:text("y")
        b:text("z")
      end)
    end,
  })
  local args = app:build().tree["$args"]
  eq("mainAxisAlignment 已映射", args.mainAxisAlignment, "spaceBetween")
  eq("crossAxisAlignment 已映射", args.crossAxisAlignment, "center")

  -- gap 靠 SizedBox 实现：3 个子节点 + 2 个间隔 = 5
  local kids = args.children
  eq("gap 插入了间隔节点", #kids, 5)
  eq("间隔是 SizedBox", kids[2]["$widget"], "SizedBox")
  eq("竖向 gap 用 height", kids[2]["$args"].height, 12)
  eq("内容节点仍按顺序", kids[3]["$args"].text, "y")
end

raises("未知属性会列出可用属性", function()
  ui.app({
    state = {},
    view = function(b) b:column({ gapp = 4 }) end,
  }):build()
end, "不支持属性 'gapp'")

raises("未知属性名带可用列表", function()
  ui.app({
    state = {},
    view = function(b) b:column({ gapp = 4 }) end,
  }):build()
end, "align, gap, main, size")

raises("枚举值非法", function()
  ui.app({
    state = {},
    view = function(b) b:column({ main = "middle" }) end,
  }):build()
end, "column.main 只能是")

raises("颜色非十六进制", function()
  ui.app({
    state = {},
    view = function(b) b:text("x", { color = "red" }) end,
  }):build()
end, "非十六进制")

raises("未知样式", function()
  ui.app({
    state = {},
    view = function(b) b:text("x", { style = "huge" }) end,
  }):build()
end, "未知样式 'huge'")

do
  -- 颜色在这里就转成 rfw 要的整数，Dart 侧不必再解析
  local app = ui.app({
    state = {},
    view = function(b)
      b:box({ color = "#ff0000" })
    end,
  })
  eq("颜色转成 0xAARRGGBB", app:build().tree["$args"].color, 0xFFFF0000)
end

do
  local app = ui.app({
    state = {},
    view = function(b)
      b:box({ color = "#abc" })
    end,
  })
  eq("#rgb 展开", app:build().tree["$args"].color, 0xFFAABBCC)
end

do
  -- 间距的三种写法
  local function insets(props)
    local app = ui.app({
      state = {},
      view = function(b) b:pad(props, function(b) b:text("x") end) end,
    })
    local a = app:build().tree["$args"].padding
    -- 逐项检查类型而不只是拼字符串：整数在这里是**错**的，
    -- rfw 读 insets 用 v<double>，整数会被静默丢成默认值 0。
    for i, v in ipairs(a) do
      if math.type(v) ~= "float" then
        return string.format("第 %d 项是 %s 不是 float", i, math.type(v))
      end
    end
    return table.concat(a, ",")
  end
  eq("数字间距", insets(8), "8.0,8.0,8.0,8.0")
  eq("x/y 间距", insets({ x = 4, y = 10 }), "4.0,10.0,4.0,10.0")
  eq("四边间距", insets({ left = 1, top = 2, right = 3, bottom = 4 }), "1.0,2.0,3.0,4.0")
end

section("\n=== 5. 事件 ===")

do
  local seen
  local app = ui.app({
    state = { n = 0 },
    handlers = {
      add = function(s, ev)
        s.n = s.n + (ev.amount or 1)
        seen = ev
      end,
    },
    view = function(b, s)
      b:button("加", { on_tap = "add", arg = { amount = 5 } })
    end,
  })

  local env = app:build()
  eq("事件清单", env.events[1], "add")
  eq("事件清单按字母序", #env.events, 1)
  eq("按钮带事件引用",
    env.tree["$args"].onPressed["$event"], "add")
  eq("事件参数带上了",
    env.tree["$args"].onPressed["$arg"].amount, 5)
  eq("按钮标签是子 Text", env.tree["$args"].child["$args"].text, "加")
  eq("事件清单与实际引用一致", env.event_count, 1)

  ui.dispatch("add", json.encode({ amount = 3 }))
  -- 注意：build() 返回的 env.state 与 app.state 是**同一张表**，
  -- 不是快照。事件改状态后 env.state.n 也会跟着变。
  eq("状态是引用不是快照", env.state.n, 3)
  -- dispatch 返回的是 JSON 字符串，不是 table
  local env2 = json.decode(ui.dispatch("add", json.encode({ amount = 3 })))
  eq("重新构建后能看到新状态", env2.state.n, 6)
  ok("事件参数传到了 handler", seen ~= nil and seen.amount == 3)
end

raises("引用未注册的事件", function()
  ui.app({
    state = {},
    handlers = {},
    view = function(b) b:button("x", { on_tap = "nope" }) end,
  }):build()
end, "未注册的事件 'nope'")

raises("分发未注册的事件", function()
  ui.dispatch("根本不存在", nil)
end, "未注册的事件")

raises("事件参数不是合法 JSON", function()
  -- 先建一个带 add 的应用：ui._current 是最近一次 ui.app 注册的，
  -- 前面的报错用例可能已经换过应用了。
  ui.app({
    state = {},
    handlers = { add = function() end },
    view = function(b) b:text("x") end,
  })
  ui.dispatch("add", "{不是 json")
end, "不是合法 JSON")

section("\n=== 6. 状态注入（事件累积的关键）===")

do
  local code = [[
    local app = ui.app({
      state = { n = 0 },
      handlers = { bump = function(s) s.n = s.n + 1 end },
      view = function(b, s) b:text(tostring(s.n)) end,
    })
    return json.encode(app:build())
  ]]

  local function load_with_state(json_text)
    local chunk = assert(load(code, "spec"))
    ui.seed_state(json_text)
    local out = chunk()
    return json.decode(out)
  end

  local env1 = load_with_state(nil)
  eq("首次用初始值", env1.state.n, 0)

  -- 宿主回传的状态必须**优先于**代码里写的初始值。
  -- 否则每次点按钮状态都会回到 0，且界面看上去完全正常。
  local env2 = load_with_state(json.encode({ n = 7 }))
  eq("回传状态优先", env2.state.n, 7)

  ui.clear()
end

section("\n=== 7. 指纹 ===")

do
  local function build(n)
    local app = ui.app({
      state = { n = n },
      view = function(b, s) b:text(tostring(s.n)) end,
    })
    return app:build().fingerprint
  end

  eq("同样的内容指纹相同", build(1), build(1))
  ok("内容变了指纹就变", build(1) ~= build(2))
  ok("指纹是 16 位十六进制", build(1):match("^%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil,
    build(1))
end

section("\n=== 8. 内置控件 ===")

do
  -- view 收到的 builder 必须有全部容器方法。
  -- 少一个就是"某个控件没法用"，而这类缺失往往只在运行时才暴露。
  local captured
  ui.app({
    state = {},
    view = function(b)
      captured = b
      b:text("x")
    end,
  }):build()

  local methods = {
    "column", "row", "box", "pad", "center", "expand", "spacer", "scroll",
    "text", "icon", "button", "card", "divider", "progress",
    "toggle", "slider", "kpi",
  }
  local missing = {}
  for _, name in ipairs(methods) do
    if type(captured[name]) ~= "function" then missing[#missing + 1] = name end
  end
  eq("builder 方法齐全", #missing, 0)
end

do
  local app = ui.app({
    state = { on = true },
    handlers = { flip = function(s) s.on = not s.on end },
    view = function(b, s)
      b:column(function(b)
        b:toggle({ value = s.on, on_change = "flip", label = "开" })
        b:slider({ value = 3, min = 0, max = 10, on_change = "flip" })
        b:kpi("标签", "值")
        b:icon("add", { size = 20 })
        b:divider()
        b:progress({ value = 0.5 })
        b:scroll({ padding = 4 }, function(b) b:text("内容") end)
        b:spacer({ size = 8 })
        b:expand(function(b) b:text("撑开") end)
        b:center(function(b) b:text("居中") end)
      end)
    end,
  })
  local env = app:build()
  local names = {}
  for _, n in ipairs(env.events) do names[#names + 1] = n end
  ok("全部控件都建出来了", env.node_count > 10, env.node_count .. " 个节点")
  eq("自定义组件走 studio 前缀", env.tree["$args"].children[1]["$widget"], "studio.Toggle")
end

raises("未知图标会列出可用的", function()
  ui.app({
    state = {},
    view = function(b) b:icon("不存在的图标") end,
  }):build()
end, "未知图标")

section("\n=== 8b. 数值类型（rfw 会静默丢弃类型不符的参数）===")

do
  -- 返回根节点的参数表（不是节点本身）
  local function args_of(build)
    local app = ui.app({ state = {}, view = build })
    return app:build().tree["$args"]
  end

  local function type_of(v)
    return math.type(v)
  end

  eq("gap 是 float", type_of(args_of(function(b)
    b:column({ gap = 12 }, function(b) b:text("a") b:text("b") end)
  end).children[2]["$args"].height), "float")

  eq("box.width 是 float", type_of(args_of(function(b)
    b:box({ width = 8 })
  end).width), "float")

  eq("divider.thickness 是 float", type_of(args_of(function(b)
    b:divider({ thickness = 2 })
  end).thickness), "float")

  eq("icon.size 是 float", type_of(args_of(function(b)
    b:icon("add", { size = 20 })
  end).size), "float")

  eq("slider.divisions 是 int", type_of(args_of(function(b)
    b:slider({ value = 5, min = 0, max = 10, divisions = 10 })
  end).divisions), "integer")

  local sl = args_of(function(b)
    b:slider({ value = 5, min = 0, max = 10, divisions = 10 })
  end)
  eq("slider.min 是 float", type_of(sl.min), "float")
  eq("slider.max 是 float", type_of(sl.max), "float")
  eq("slider.max 的值没丢", sl.max, 10.0)

  eq("text 的 fontSize 是 float", type_of(args_of(function(b)
    b:text("x", { style = "display" })
  end).style.fontSize), "float")

  eq("颜色是 integer（rfw 用 v<int> 读）", type_of(args_of(function(b)
    b:box({ color = "#4A9EFF" })
  end).color), "integer")

  eq("text.lines 是 int（rfw 用 v<int> 读 maxLines）", type_of(args_of(function(b)
    b:text("x", { lines = 2 })
  end).maxLines), "integer")

  eq("expand.flex 是 int", type_of(args_of(function(b)
    b:expand({ flex = 2 }, function(b) b:text("x") end)
  end).flex), "integer")
end

section("\n=== 9. 单槽位容器 ===")

raises("center 塞两个子节点", function()
  ui.app({
    state = {},
    view = function(b)
      b:center(function(b)
        b:text("a")
        b:text("b")
      end)
    end,
  }):build()
end, "只接受一个子节点")

section("\n=== 10. 能力契约 ===")

do
  local snapshot = {}
  for _, cap in ipairs(host.snapshot()) do snapshot[cap.name] = cap.version end
  eq("ui 已注册", snapshot.ui, "1.0.0")
  ok("guard 由 ui 复用而非复制", ui.wrap ~= nil and ui.run ~= nil)
end

section("\n=== 11. 组件与本地状态（交互不回 Lua）===")

do
  -- 组件 = rfw 的 widget 声明，状态挂在声明上
  ui.component("RowItem", {
    state = { open = false, count = 0 },
    view = function(b, state)
      b:card(function(b)
        b:column(function(b)
          b:button("展开", { on_tap = b:set_state("open", not state.open) })
          b:button("+1", { on_tap = b:set_state("count", state.count + 1) })
          b:button("删除", { on_tap = "del" })
        end)
      end)
    end,
  })
  ok("组件已登记", #ui.components() >= 1, table.concat(ui.components(), ","))

  local app = ui.app({
    state = {},
    handlers = { del = function() end },
    view = function(b)
      b:column(function(b)
        b:RowItem()
        b:RowItem()
      end)
    end,
  })
  local env = app:build()

  eq("产出一个组件声明", #env.declarations, 1)
  eq("声明名", env.declarations[1].name, "RowItem")
  eq("声明带初始状态 open", env.declarations[1].state.open, false)
  eq("声明带初始状态 count", env.declarations[1].state.count, 0)

  -- 组件在 root 里被引用了两次
  local refs = 0
  for _, n in ipairs(env.tree["$args"].children) do
    if n["$widget"] == "RowItem" then refs = refs + 1 end
  end
  eq("组件被引用两次", refs, 2)
  eq("引用计入节点数", env.node_count >= 3, true)

  -- 分流：本地状态 vs 业务事件。
  -- 递归扫整棵组件体，不写死层级——组件以后加了包装层这里也不用改。
  local set_states, evts = 0, 0
  local function scan(node)
    if type(node) ~= "table" then return end
    if node["$setstate"] then set_states = set_states + 1 end
    if node["$event"] then evts = evts + 1 end
    -- 数组（children）和节点（$args）都要走，
    -- 只认 $args 的话整棵 children 数组都被跳过了
    if node["$args"] then
      for _, v in pairs(node["$args"]) do scan(v) end
    end
    for _, v in ipairs(node) do scan(v) end
  end
  scan(env.declarations[1].node)

  eq("两个本地状态写入", set_states, 2)
  eq("一个业务事件", evts, 1)
end

raises("引用未定义的组件", function()
  ui.app({
    state = {}, handlers = {},
    view = function(b) b:NoSuchComponent() end,
  }):build()
end, "未定义的组件")

raises("组件不接受 props", function()
  ui.app({
    state = {}, handlers = {},
    view = function(b) b:RowItem({ id = 1 }) end,
  }):build()
end, "还不支持属性")

raises("set_state 不能设成 nil", function()
  ui.app({
    state = {}, handlers = {},
    view = function(b) b:set_state("x", nil) end,
  }):build()
end, "不能把状态设成 nil")

raises("组件 view 必须恰好一个根节点", function()
  ui.component("Bad", {
    state = {},
    view = function(b)
      b:text("a")
      b:text("b")
    end,
  })
  ui.app({
    state = {}, handlers = {},
    view = function(b) b:column(function() b:Bad() end) end,
  }):build()
end, "恰好产出一个根节点")

-- ============ 汇总 ============

io.write(string.format("\n%d passed, %d failed\n", passed, failed))
os.exit(failed == 0 and 0 or 1)
