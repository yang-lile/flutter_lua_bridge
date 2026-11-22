-- A route that returns a value: Navigator.pop(result) completes the
-- Future that Navigator.pushNamed returned in the caller's instance.
local choices = {
  { name = "红", color = Colors.red },
  { name = "绿", color = Colors.green },
  { name = "蓝", color = Colors.blue },
  { name = "琥珀", color = Colors.amber },
}

return App {
  view = function(store, props)
    local current = (props.arguments or {}).current
    local tiles = {}
    for _, choice in ipairs(choices) do
      tiles[#tiles + 1] = ListTile {
        key = choice.name,
        leading = Container {
          width = 32, height = 32,
          decoration = BoxDecoration { color = choice.color, shape = BoxShape.circle },
        },
        title = Text { choice.name },
        trailing = current == choice.name and Icon { Icons.check } or nil,
        onTap = function()
          Navigator.pop({ name = choice.name, value = choice.color.value })
        end,
      }
    end
    tiles[#tiles + 1] = ListTile {
      key = "cancel",
      title = Text { "取消（返回 nil）" },
      onTap = function() Navigator.pop() end,
    }
    return Scaffold {
      appBar = AppBar { title = Text { "选一个颜色" } },
      body = ListView { children = tiles },
    }
  end,
}
