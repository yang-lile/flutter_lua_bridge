-- flb.ui.cupertino: Lua constructors for the `cupertino` library of
-- flutter_lua_bridge_ui_cupertino. LuaView installs the table this module
-- returns as globals, so scripts write `CupertinoButton { ... }` and
-- `CupertinoColors.systemBlue`. This file is the source of
-- lib/src/lua_modules.dart: after editing it, run `dart run
-- tool/embed_lua.dart packages/flutter_lua_bridge_ui_cupertino
-- cupertinoLuaModules` at the repository root.
local ui = require("flb.ui")

-- Keep in step with cupertinoLibrary() in Dart and cupertino.d.tl.
local CUPERTINO = {
  "CupertinoActivityIndicator", "CupertinoButton", "CupertinoButton.filled",
  "CupertinoListSection", "CupertinoListSection.insetGrouped",
  "CupertinoListTile", "CupertinoNavigationBar", "CupertinoPageScaffold",
  "CupertinoSegmentedControl", "CupertinoSlider", "CupertinoSwitch",
  "CupertinoTextField",
}

local M = ui.library("cupertino", CUPERTINO)

-- The light variant of each color: Lua has no BuildContext to resolve the
-- dark or high-contrast variants of a CupertinoDynamicColor.
M.CupertinoColors = {
  activeBlue = 0xFF007AFF,
  activeGreen = 0xFF34C759,
  activeOrange = 0xFFFF9500,
  white = 0xFFFFFFFF,
  black = 0xFF000000,
  transparent = 0x00000000,
  lightBackgroundGray = 0xFFE5E5EA,
  extraLightBackgroundGray = 0xFFEFEFF4,
  darkBackgroundGray = 0xFF171717,
  inactiveGray = 0xFF999999,
  destructiveRed = 0xFFFF3B30,
  systemBlue = 0xFF007AFF,
  systemGreen = 0xFF34C759,
  systemMint = 0xFF00C7BE,
  systemIndigo = 0xFF5856D6,
  systemOrange = 0xFFFF9500,
  systemPink = 0xFFFF2D55,
  systemBrown = 0xFFA2845E,
  systemPurple = 0xFFAF52DE,
  systemRed = 0xFFFF3B30,
  systemTeal = 0xFF5AC8FA,
  systemCyan = 0xFF32ADE6,
  systemYellow = 0xFFFFCC00,
  systemGrey = 0xFF8E8E93,
  systemGrey2 = 0xFFAEAEB2,
  systemGrey3 = 0xFFC7C7CC,
  systemGrey4 = 0xFFD1D1D6,
  systemGrey5 = 0xFFE5E5EA,
  systemGrey6 = 0xFFF2F2F7,
  label = 0xFF000000,
  secondaryLabel = 0x993C3C43,
  tertiaryLabel = 0x4C3C3C43,
  quaternaryLabel = 0x2D3C3C43,
  systemFill = 0x33787880,
  secondarySystemFill = 0x28787880,
  tertiarySystemFill = 0x1E767680,
  quaternarySystemFill = 0x14747480,
  placeholderText = 0x4C3C3C43,
  systemBackground = 0xFFFFFFFF,
  secondarySystemBackground = 0xFFF2F2F7,
  tertiarySystemBackground = 0xFFFFFFFF,
  systemGroupedBackground = 0xFFF2F2F7,
  secondarySystemGroupedBackground = 0xFFFFFFFF,
  tertiarySystemGroupedBackground = 0xFFF2F2F7,
  separator = 0x493C3C43,
  opaqueSeparator = 0xFFC6C6C8,
  link = 0xFF007AFF,
}

return M
