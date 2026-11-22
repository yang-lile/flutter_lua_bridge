-- The home screen. Each tile pushes a route with Navigator.pushNamed, a
-- Dart function of the core library. The handler waits for the route's
-- result like `await` in Dart, then records it.
local demos = {
  { route = "/core", icon = Icons.widgets, title = "Core 组件",
    subtitle = "布局、值类型、1000 项 ListView.builder" },
  { route = "/material", icon = Icons.palette, title = "Material",
    subtitle = "按钮、开关、滑块、输入框、Chip、颜色" },
  { route = "/cupertino", icon = Icons.phone_iphone, title = "Cupertino",
    subtitle = "导航栏、分组列表、分段控件、开关、输入框" },
  { route = "/routes", icon = Icons.alt_route, title = "路由跳转",
    subtitle = "Lua 调 Dart 的 Navigator，每个页面是独立的 Lua 实例" },
  { route = "/remote", icon = Icons.cloud_download, title = "远程下发",
    subtitle = "本地 HTTP 服务下发 bundle：校验、缓存、坏版本回退" },
}

local function describe(result)
  if result == nil then return "没有返回值" end
  if type(result) == "table" then
    local parts = {}
    for k, v in pairs(result) do parts[#parts + 1] = tostring(k) .. "=" .. tostring(v) end
    table.sort(parts)
    return "{" .. table.concat(parts, ", ") .. "}"
  end
  return tostring(result)
end

return App {
  store = { opened = 0, last = "还没有打开过页面" },
  view = function(store)
    local tiles = {}
    for _, demo in ipairs(demos) do
      tiles[#tiles + 1] = Card { key = demo.route, child = ListTile {
        leading = Icon { demo.icon, color = Colors.indigo },
        title = Text { demo.title },
        subtitle = Text { demo.subtitle },
        trailing = Icon { Icons.chevron_right },
        onTap = function()
          local result = Navigator.pushNamed(demo.route)
          store.opened = store.opened + 1
          store.last = demo.title .. " 返回：" .. describe(result)
        end,
      } }
    end
    return Scaffold {
      appBar = AppBar { title = Text { "flutter_lua_bridge gallery" } },
      body = ListView { padding = EdgeInsets.all(12), children = tiles },
      bottomNavigationBar = SafeArea { child = Padding {
        padding = EdgeInsets.all(16),
        child = Text {
          "已打开 " .. store.opened .. " 次。" .. store.last,
          style = TextStyle { color = Colors.grey[700] },
        },
      } },
    }
  end,
}
