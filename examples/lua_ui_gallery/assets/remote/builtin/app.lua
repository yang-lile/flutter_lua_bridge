-- The built-in bundle: shown when the server and the cache both fail.
return App {
  view = function()
    return Center { child = Column {
      mainAxisSize = MainAxisSize.min,
      spacing = 8,
      children = {
        Icon { Icons.home, size = 40, color = Colors.grey },
        Text { "内置版本 0.9.0", style = TextStyle { fontSize = 20 } },
        Text { "服务器和缓存都不可用时显示", style = TextStyle { color = Colors.grey } },
      },
    } }
  end,
}
