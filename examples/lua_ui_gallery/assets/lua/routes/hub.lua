-- The routing case. Navigator.* are Dart functions registered by the core
-- library: Lua calls them, Dart pushes a route, and the app builds a new
-- LuaPage for it, a new script run in a new LuaRuntime. Pushing this
-- route again therefore starts another, independent instance of this very
-- script; its result comes back when that instance pops.
local function describe(result)
  if type(result) == "table" then
    return "第 " .. tostring(result.depth) .. " 层，计数 " .. tostring(result.count)
  end
  return result == nil and "没有返回值" or tostring(result)
end

local function button(label, icon, onPressed)
  return SizedBox { width = 320, child = FilledButton.icon {
    icon = Icon { icon }, label = Text { label }, onPressed = onPressed,
  } }
end

return App {
  store = { count = 0, color = nil, colorName = "未选择", alive = "", log = {} },
  view = function(store, props)
    local args = props.arguments or {}
    local depth = args.depth or 1
    local function note(line)
      table.insert(store.log, 1, line)
      store.alive = table.concat(Gallery.instances(), "  →  ")
    end
    local log = {}
    for i, line in ipairs(store.log) do log[i] = Text { line, key = i } end

    return Scaffold {
      appBar = AppBar { title = Text { "路由：第 " .. depth .. " 层" } },
      body = ListView {
        padding = EdgeInsets.all(16),
        children = {
          Text { "来自：" .. (args.from or "首页") .. "，canPop = " .. tostring(Navigator.canPop()) },
          Text { "存活的 Lua 实例：" .. (store.alive == "" and "（点按钮后刷新）" or store.alive) },
          Container {
            margin = EdgeInsets.symmetric { vertical = 12 },
            padding = EdgeInsets.all(12),
            decoration = BoxDecoration {
              color = store.color or Colors.grey[200],
              borderRadius = BorderRadius.circular(8),
            },
            child = Text { "这个实例的计数：" .. store.count .. "，颜色：" .. store.colorName },
          },
          Wrap { spacing = 8, runSpacing = 8, children = {
            button("计数 +1（只影响本实例）", Icons.add, function()
              store.count = store.count + 1
            end),
            button("再开一层：同一脚本的新实例", Icons.layers, function()
              local result = Navigator.pushNamed("/routes", {
                arguments = { depth = depth + 1, from = "第 " .. depth .. " 层" },
              })
              note("第 " .. (depth + 1) .. " 层返回：" .. describe(result))
            end),
            button("选颜色：等另一个实例返回", Icons.color_lens, function()
              local picked = Navigator.pushNamed("/routes/picker", {
                arguments = { current = store.colorName },
              })
              if picked then
                store.color = picked.value
                store.colorName = picked.name
              end
              note("选色页返回：" .. (picked and picked.name or "取消"))
            end),
            button("替换为新实例（pushReplacementNamed）", Icons.swap_horiz, function()
              Navigator.pushReplacementNamed("/routes", {
                arguments = { depth = depth, from = "替换前的第 " .. depth .. " 层" },
                result = "被替换了",
              })
            end),
            button("返回上一层，带回计数", Icons.arrow_back, function()
              Navigator.pop({ depth = depth, count = store.count })
            end),
          } },
          Padding { padding = EdgeInsets.only { top = 16 }, child = Text {
            "日志", style = TextStyle { fontWeight = FontWeight.w600 },
          } },
          Column { crossAxisAlignment = CrossAxisAlignment.start, children = log },
        },
      },
    }
  end,
}
