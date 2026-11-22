-- Version 2.0.0: a downloaded script can call the host functions too. It
-- pushes a route of the app and waits for a Dart Future.
local greeting = require("greeting")

return App {
  store = { taps = 0, quote = "" },
  view = function(store)
    return Center { child = Column {
      mainAxisSize = MainAxisSize.min,
      spacing = 12,
      children = {
        Text { greeting.text("v2", store.taps), style = TextStyle { fontSize = 22, color = Colors.indigo } },
        Row {
          mainAxisSize = MainAxisSize.min,
          spacing = 8,
          children = {
            FilledButton {
              onPressed = function() store.taps = store.taps + 1 end,
              child = Text { "点我" },
            },
            OutlinedButton {
              onPressed = function() Navigator.pushNamed("/routes", { arguments = { depth = 1, from = "远程 v2" } }) end,
              child = Text { "打开路由案例" },
            },
            TextButton {
              onPressed = function()
                store.quote = "加载中…"
                store.quote = Gallery.fetchQuote(store.taps)
              end,
              child = Text { "异步取一句话" },
            },
          },
        },
        Text { store.quote },
      },
    } }
  end,
}
