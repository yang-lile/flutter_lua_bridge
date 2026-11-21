-- Globals that LuaView installs from flb.ui.material, after those of flb.ui.
-- Teal code requires "flb.ui.material.prelude" to see these declarations.
local type UI = require("flb.ui")
local type M = require("flb.ui.material")
local ui = require("flb.ui.prelude")

global AppBar: function(args: M.AppBarArgs): UI.Node
global Card: function(args: M.CardArgs): UI.Node
global Checkbox: function(args: M.CheckboxArgs): UI.Node
global Chip: function(args: M.ChipArgs): UI.Node
global CircularProgressIndicator: function(args: M.CircularProgressIndicatorArgs): UI.Node
global Divider: function(args: M.DividerArgs): UI.Node
global ElevatedButton: M.ElevatedButtonConstructor
global FilledButton: M.FilledButtonConstructor
global FloatingActionButton: M.FloatingActionButtonConstructor
global IconButton: M.IconButtonConstructor
global InkWell: function(args: M.InkWellArgs): UI.Node
global LinearProgressIndicator: function(args: M.LinearProgressIndicatorArgs): UI.Node
global ListTile: function(args: M.ListTileArgs): UI.Node
global Material: function(args: M.MaterialArgs): UI.Node
global OutlinedButton: M.OutlinedButtonConstructor
global Scaffold: function(args: M.ScaffoldArgs): UI.Node
global Slider: function(args: M.SliderArgs): UI.Node
global Switch: function(args: M.SwitchArgs): UI.Node
global TextButton: M.TextButtonConstructor
global TextField: function(args: M.TextFieldArgs): UI.Node

global Colors: M.ColorsType
global InputDecoration: function(args: M.InputDecorationValue): M.InputDecorationValue
global OutlineInputBorder: function(args?: M.OutlineInputBorderArgs): M.InputBorderValue
global UnderlineInputBorder: function(): M.InputBorderValue
global InputBorder: M.InputBorderType
global TextInputType: M.TextInputTypeType

return ui
