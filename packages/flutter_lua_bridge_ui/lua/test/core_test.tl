-- Type checks a view written against the core declarations and checks the
-- nodes flb.ui builds. Run: dart run flutter_lua_bridge_codegen:run lua/test
local ui = require("flb.ui.prelude")

local function eq(actual: any, expected: any, what: string)
  if actual ~= expected then
    error(what .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

local Item = ui.component(function(_: ui.Props): ui.Render
  local state = ui.state({ open = false })
  return function(props: ui.Props): ui.Node
    return GestureDetector {
      onTap = function() state.open = not state.open end,
      behavior = HitTestBehavior.opaque,
      child = Padding {
        padding = EdgeInsets.symmetric { horizontal = 16, vertical = 8 },
        child = Text { (props.title as string) .. (state.open and " -" or " +"), style = TextStyle { fontWeight = FontWeight.w600 } },
      },
    }
  end
end)

local record Store
  items: {string}
end

local store: Store = { items = { "a", "b" } }
local app = App {
  store = store,
  view = function(s: Store, _: ui.Props): ui.Node
    local items = s.items
    return Column {
      mainAxisAlignment = MainAxisAlignment.center,
      crossAxisAlignment = CrossAxisAlignment["end"],
      spacing = 4,
      children = {
        Container {
          key = "header",
          margin = EdgeInsets.fromLTRB(1, 2, 3, 4),
          alignment = Alignment(0.5, -1),
          decoration = BoxDecoration {
            color = Color(0xFF2196F3),
            borderRadius = BorderRadius.only { topLeft = Radius.circular(4) },
            border = Border.all { color = "#ccc", width = 1 },
            boxShadow = { BoxShadow { blurRadius = 2, offset = Offset(0, 1) } },
            gradient = LinearGradient { colors = { Color.fromARGB(255, 0, 0, 0), 0xFFFFFFFF } },
          },
          child = Row { children = { Icon { Icons.add, size = 16 }, Text { "header" } } },
        },
        Image.network { "https://example.com/a.png", fit = BoxFit.cover },
        SizedBox { height = 40, child = ListView.builder {
          itemCount = #items,
          itemBuilder = function(_: any, index: integer): ui.Node
            return Item { key = index, title = items[index + 1] }
          end,
        } },
        Expanded { child = SizedBox.expand {} },
      },
    }
  end,
}

local result = app.render() as {string: any}
local root = (result.root as {string: any}).n as ui.Node
eq(root.t, "core.Column", "root type")
local args = root.a as {string: any}
eq(args.mainAxisAlignment, "center", "enum value")
eq(args.crossAxisAlignment, "end", "keyword enum value")
local children = args.children as {ui.Node}
local header = children[1]
eq(header.k, "header", "widget key")
local box = header.a as {string: any}
eq((box.margin as {string: number}).bottom, 4, "EdgeInsets.fromLTRB")
eq((box.alignment as {string: number}).y, -1, "Alignment(x, y)")
local deco = box.decoration as {string: any}
eq(deco.color, 0xFF2196F3, "Color")
eq((deco.gradient as {string: {integer}}).colors[1], 0xFF000000, "Color.fromARGB")
local row = (box.child as ui.Node).a as {string: any}
local icon = (row.children as {ui.Node})[1]
eq((icon.a as {string: any}).icon, "add", "Icon positional")
eq(children[2].t, "core.Image.network", "named constructor")
eq((children[2].a as {string: any}).src, "https://example.com/a.png", "Image.network positional")
local list = (children[3].a as {string: any}).child as ui.Node
local builder = (list.a as {string: any}).itemBuilder as {string: integer}
assert(builder["$b"] ~= nil, "itemBuilder is a builder reference")

-- Running the builder renders an item component of its own.
local built = app.build(builder["$b"], { nil, 1 }, 2) as {string: any}
local item = built.node as {string: any}
eq(item.c, "root/$b" .. tostring(builder["$b"]) .. "/1", "item instance id")
-- The item is the Item component, keyed by index inside the builder output.
local component = item.n as {string: any}
eq(component.c, (item.c as string) .. "/1", "Item instance id")
local detector = component.n as ui.Node
local tap = (detector.a as {string: any}).onTap as {string: integer}
assert(tap["$h"] ~= nil, "onTap is a handler reference")

-- A tap re-renders only that Item.
local update = app.dispatch(tap["$h"], {}, 0) as {string: any}
local patches = update.patches as {{string: any}}
eq(#patches, 1, "one patch")
eq(patches[1].id, component.c, "the patched Item")

-- Releasing the item unmounts it.
local released = app.release(item.c as string) as {string: {string}}
eq(#released.removed, 2, "released item and its Item")

-- Misuse is reported clearly.
local ok, message = pcall(function(): any return ui.core.Column({ Text { "x" } } as ui.ColumnArgs) end)
assert(not ok and tostring(message):find("children = {", 1, true), tostring(message))
local ok2, message2 = pcall(function(): any return (MainAxisAlignment as {string: string}).centre end)
assert(not ok2 and tostring(message2):find("no member centre", 1, true), tostring(message2))
-- Host functions: a fake host answers Navigator.pushNamed with a Future
-- (token 7), which the test completes through resume.
local calls: {string} = {}
ui.set_host(function(name: string, n: integer): {string: any}
  calls[#calls + 1] = name .. "/" .. tostring(n)
  if name == "core.Navigator.pushNamed" then return { p = 7 } end
  return { v = true }
end)
local record PickStore
  picked: string
end
local pick_store: PickStore = { picked = "none" }
local nav = App {
  store = pick_store,
  view = function(s: PickStore, _: ui.Props): ui.Node
    return GestureDetector {
      onTap = function()
        if Navigator.canPop() then
          s.picked = Navigator.pushNamed("/pick", { arguments = { from = "home" } }) as string
        end
      end,
      child = Text { s.picked },
    }
  end,
}
local nav_root = ((nav.render() as {string: any}).root as {string: any}).n as ui.Node
local nav_tap = (nav_root.a as {string: any}).onTap as {string: integer}
local waiting = nav.dispatch(nav_tap["$h"], {}, 0) as {string: any}
eq(#(waiting.patches as {any}), 0, "no patch while waiting")
eq(calls[1], "core.Navigator.canPop/0", "a host call that returns at once")
eq(calls[2], "core.Navigator.pushNamed/2", "a host call that returns a Future")
local done = nav.resume(7, true, "red") as {string: any}
local tree = ((done.patches as {{string: any}})[1].tree) as ui.Node
local label = (tree.a as {string: any}).child as ui.Node
eq((label.a as {string: any}).data, "red", "the handler continues with the result")

print("flb.ui core: ok")
