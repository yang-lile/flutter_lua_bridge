-- The entry module of the example bundle. Pack it with
--   dart run flutter_lua_bridge_remote:pack example/bundle --name hello --version 1.0.0
local greeting = require("greeting")

return App {
  store = { taps = 0 },
  view = function(store)
    return Center {
      child = GestureDetector {
        onTap = function() store.taps = store.taps + 1 end,
        child = Text { greeting.text(store.taps), style = TextStyle { fontSize = 24 } },
      },
    }
  end,
}
