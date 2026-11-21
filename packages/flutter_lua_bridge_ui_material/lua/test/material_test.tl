-- Type checks a Material view and checks the nodes it builds.
-- Run: tool/check_teal_ui.sh packages/flutter_lua_bridge_ui_material
local ui = require("flb.ui.material.prelude")

local record Store
  count: integer
  draft: string
  dark: boolean
end

local store: Store = { count = 0, draft = "", dark = false }
local app = App {
  store = store,
  view = function(s: Store, _: ui.Props): ui.Node
    return Scaffold {
      appBar = AppBar {
        title = Text { "Inbox" },
        backgroundColor = Colors.indigo,
        actions = { IconButton { icon = Icon { Icons.search }, onPressed = function() end } },
      },
      body = ListView { children = {
        ListTile { title = Text { "count " .. s.count }, trailing = Switch {
          value = s.dark,
          onChanged = function(value: boolean) s.dark = value end,
        } },
        TextField {
          text = s.draft,
          keyboardType = TextInputType.emailAddress,
          decoration = InputDecoration {
            labelText = "Email",
            border = OutlineInputBorder { borderRadius = BorderRadius.circular(8) },
          },
          onChanged = function(value: string) s.draft = value end,
        },
        Card { color = Colors.red.shade100, child = Text { "card" } },
        Divider { color = Colors.grey[300] },
        ElevatedButton.icon { onPressed = function() end, icon = Icon { Icons.send }, label = Text { "Send" } },
        FilledButton.tonal { onPressed = function() end, child = Text { "Tonal" } },
      } },
      floatingActionButton = FloatingActionButton.extended {
        onPressed = function() s.count = s.count + 1 end,
        icon = Icon { Icons.add },
        label = Text { "Add" },
      },
    }
  end,
}

local result = app.render() as {string: any}
local scaffold = (result.root as {string: any}).n as ui.Node
assert(scaffold.t == "material.Scaffold", tostring(scaffold.t))
local args = scaffold.a as {string: any}
local bar = (args.appBar as ui.Node).a as {string: any}
assert((bar.backgroundColor as {string: integer}).value == 0xFF3F51B5, "Colors.indigo")
local fab = args.floatingActionButton as ui.Node
assert(fab.t == "material.FloatingActionButton.extended", tostring(fab.t))
local children = ((args.body as ui.Node).a as {string: any}).children as {ui.Node}
local field = children[2].a as {string: any}
assert(field.keyboardType == "emailAddress", "TextInputType")
local border = (field.decoration as {string: any}).border as {string: any}
assert(border.type == "outline" and border.borderRadius == 8, "OutlineInputBorder")
assert((children[3].a as {string: any}).color == 0xFFFFCDD2, "Colors.red.shade100")
assert((children[4].a as {string: any}).color == 0xFFE0E0E0, "Colors.grey[300]")
print("flb.ui.material: ok")
