-- Globals that LuaView installs from flb.ui.cupertino, after those of flb.ui.
-- Teal code requires "flb.ui.cupertino.prelude" to see these declarations.
local type UI = require("flb.ui")
local type M = require("flb.ui.cupertino")
local ui = require("flb.ui.prelude")

global CupertinoActivityIndicator: function(args: M.CupertinoActivityIndicatorArgs): UI.Node
global CupertinoButton: M.CupertinoButtonConstructor
global CupertinoListSection: M.CupertinoListSectionConstructor
global CupertinoListTile: function(args: M.CupertinoListTileArgs): UI.Node
global CupertinoNavigationBar: function(args: M.CupertinoNavigationBarArgs): UI.Node
global CupertinoPageScaffold: function(args: M.CupertinoPageScaffoldArgs): UI.Node
global CupertinoSegmentedControl: function(args: M.CupertinoSegmentedControlArgs): UI.Node
global CupertinoSlider: function(args: M.CupertinoSliderArgs): UI.Node
global CupertinoSwitch: function(args: M.CupertinoSwitchArgs): UI.Node
global CupertinoTextField: function(args: M.CupertinoTextFieldArgs): UI.Node

global CupertinoColors: M.CupertinoColorsType

return ui
