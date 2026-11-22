-- Widgets of package:flutter/widgets.dart and the value types, then a
-- ListView.builder of 1000 items. Each item is a component of its own:
-- tapping it renders only that item. Favorites live in the store and
-- survive scrolling; the per-item tap count is local state and is gone
-- when the item scrolls away, because Lua releases items Flutter disposed.
local Item = ui.component(function(props)
  local local_state = ui.state { taps = 0 }
  return function(props)
    local i = props.index
    local favorite = props.store.favorites[i] == true
    return GestureDetector {
      onTap = function() local_state.taps = local_state.taps + 1 end,
      child = Container {
        height = 56,
        padding = EdgeInsets.symmetric { horizontal = 16 },
        decoration = BoxDecoration {
          color = i % 2 == 0 and Colors.indigo[50] or Colors.white,
        },
        child = Row { spacing = 12, children = {
          Text { "#" .. i, style = TextStyle { fontWeight = FontWeight.w600 } },
          Expanded { child = Text {
            local_state.taps == 0 and "点一下（本地状态）" or ("本地点击 " .. local_state.taps .. " 次"),
          } },
          IconButton {
            icon = Icon { favorite and Icons.favorite or Icons.favorite_border, color = Colors.pink },
            onPressed = function() props.store.favorites[i] = not favorite end,
          },
        } },
      },
    }
  end
end)

local function count(t)
  local n = 0
  for _, v in ui.pairs(t) do if v then n = n + 1 end end
  return n
end

return App {
  store = { favorites = {} },
  view = function(store)
    return Scaffold {
      appBar = AppBar { title = Text { "Core 组件" } },
      body = Column { children = {
        Padding {
          padding = EdgeInsets.all(12),
          child = Row { spacing = 12, children = {
            Container {
              width = 120, height = 72,
              alignment = Alignment.center,
              decoration = BoxDecoration {
                borderRadius = BorderRadius.circular(12),
                gradient = LinearGradient { colors = { Color(0xFF3F51B5), Color(0xFF00BCD4) } },
                boxShadow = { BoxShadow { blurRadius = 6, offset = Offset(0, 3), color = Color(0x40000000) } },
              },
              child = Text { "渐变 + 阴影", style = TextStyle { color = Colors.white } },
            },
            Stack { children = {
              Container { width = 72, height = 72, color = Colors.amber[200] },
              Positioned { right = 4, bottom = 4, child = Icon { Icons.star, color = Colors.deepOrange } },
            } },
            Opacity { opacity = 0.5, child = ClipRRect {
              borderRadius = BorderRadius.circular(36),
              child = Container { width = 72, height = 72, color = Colors.teal },
            } },
            Expanded { child = Wrap { spacing = 6, runSpacing = 6, children = {
              Text { "Wrap" }, Text { "会" }, Text { "自动" }, Text { "换行" },
              Text { "收藏 " .. count(store.favorites) .. " 项", style = TextStyle { color = Colors.pink } },
            } } },
          } },
        },
        Expanded { child = ListView.builder {
          itemCount = 1000,
          itemExtent = 56,
          itemBuilder = function(context, index)
            return Item { key = index, index = index + 1, store = store }
          end,
        } },
      } },
    }
  end,
}
