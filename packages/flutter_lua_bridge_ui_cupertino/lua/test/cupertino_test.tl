-- Type checks a Cupertino view and checks the nodes it builds.
-- Run: tool/check_teal_ui.sh packages/flutter_lua_bridge_ui_cupertino
local ui = require("flb.ui.cupertino.prelude")

local record Store
  wifi: boolean
  mode: string
end

local store: Store = { wifi = true, mode = "day" }
local app = App {
  store = store,
  view = function(s: Store, _: ui.Props): ui.Node
    return CupertinoPageScaffold {
      navigationBar = CupertinoNavigationBar { middle = Text { "Settings" } },
      child = CupertinoListSection.insetGrouped {
        header = Text { "Network" },
        children = {
          CupertinoListTile {
            title = Text { "Wi-Fi" },
            trailing = CupertinoSwitch {
              value = s.wifi,
              activeTrackColor = CupertinoColors.systemGreen,
              onChanged = function(value: boolean) s.wifi = value end,
            },
          },
          CupertinoSegmentedControl {
            groupValue = s.mode,
            children = {
              { value = "day", child = Text { "Day" } },
              { value = "night", child = Text { "Night" } },
            },
            onValueChanged = function(value: any) s.mode = value as string end,
          },
          CupertinoButton.filled { onPressed = function() end, child = Text { "Save" } },
          CupertinoTextField { placeholder = "Name", onChanged = function(_: string) end },
        },
      },
    }
  end,
}

local result = app.render() as {string: any}
local scaffold = (result.root as {string: any}).n as ui.Node
assert(scaffold.t == "cupertino.CupertinoPageScaffold", tostring(scaffold.t))
local section = (scaffold.a as {string: any}).child as ui.Node
assert(section.t == "cupertino.CupertinoListSection.insetGrouped", tostring(section.t))
local tile = ((section.a as {string: any}).children as {ui.Node})[1]
local switch = (tile.a as {string: any}).trailing as ui.Node
assert((switch.a as {string: any}).activeTrackColor == 0xFF34C759, "CupertinoColors.systemGreen")
print("flb.ui.cupertino: ok")
