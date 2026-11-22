-- Version 1.0.0: a counter.
local greeting = require("greeting")

return App {
  store = { taps = 0 },
  view = function(store)
    return Center { child = Column {
      mainAxisSize = MainAxisSize.min,
      spacing = 12,
      children = {
        Text { greeting.text("v1", store.taps), style = TextStyle { fontSize = 22 } },
        FilledButton {
          onPressed = function() store.taps = store.taps + 1 end,
          child = Text { "点我" },
        },
      },
    } }
  end,
}
