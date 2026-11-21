-- flb.ui.material: Lua constructors for the `material` library of
-- flutter_lua_bridge_ui_material. LuaView installs the table this module
-- returns as globals, so scripts write `ElevatedButton { ... }` and
-- `Colors.blue`. This file is the source of lib/src/lua_modules.dart: after
-- editing it, run `dart run tool/embed_lua.dart
-- packages/flutter_lua_bridge_ui_material materialLuaModules` at the
-- repository root.
local ui = require("flb.ui")

-- Keep in step with materialLibrary() in Dart and material.d.tl.
local MATERIAL = {
  "AppBar", "Card", "Checkbox", "Chip", "CircularProgressIndicator",
  "Divider", "ElevatedButton", "ElevatedButton.icon", "FilledButton",
  "FilledButton.icon", "FilledButton.tonal", "FloatingActionButton",
  "FloatingActionButton.extended", "IconButton", "IconButton.filled",
  "InkWell", "LinearProgressIndicator", "ListTile", "Material",
  "OutlinedButton", "OutlinedButton.icon", "Scaffold", "Slider", "Switch",
  "TextButton", "TextButton.icon", "TextField",
}

local M = ui.library("material", MATERIAL)

-- A swatch is its primary color (`Colors.red`) with shades
-- (`Colors.red.shade100`, `Colors.red[100]`).
local function swatch(value, shades)
  local t = { value = value }
  for shade, color in pairs(shades) do
    t[shade] = color
    t["shade" .. shade] = color
  end
  return t
end

M.Colors = {
  transparent = 0x00000000,
  black = 0xFF000000,
  black87 = 0xDD000000,
  black54 = 0x8A000000,
  black45 = 0x73000000,
  black38 = 0x61000000,
  black26 = 0x42000000,
  black12 = 0x1F000000,
  white = 0xFFFFFFFF,
  white70 = 0xB3FFFFFF,
  white60 = 0x99FFFFFF,
  white54 = 0x8AFFFFFF,
  white38 = 0x62FFFFFF,
  white30 = 0x4DFFFFFF,
  white24 = 0x3DFFFFFF,
  white12 = 0x1FFFFFFF,
  white10 = 0x1AFFFFFF,
  red = swatch(0xFFF44336, { [50] = 0xFFFFEBEE, [100] = 0xFFFFCDD2, [200] = 0xFFEF9A9A, [300] = 0xFFE57373, [400] = 0xFFEF5350, [500] = 0xFFF44336, [600] = 0xFFE53935, [700] = 0xFFD32F2F, [800] = 0xFFC62828, [900] = 0xFFB71C1C }),
  redAccent = swatch(0xFFFF5252, { [100] = 0xFFFF8A80, [200] = 0xFFFF5252, [400] = 0xFFFF1744, [700] = 0xFFD50000 }),
  pink = swatch(0xFFE91E63, { [50] = 0xFFFCE4EC, [100] = 0xFFF8BBD0, [200] = 0xFFF48FB1, [300] = 0xFFF06292, [400] = 0xFFEC407A, [500] = 0xFFE91E63, [600] = 0xFFD81B60, [700] = 0xFFC2185B, [800] = 0xFFAD1457, [900] = 0xFF880E4F }),
  pinkAccent = swatch(0xFFFF4081, { [100] = 0xFFFF80AB, [200] = 0xFFFF4081, [400] = 0xFFF50057, [700] = 0xFFC51162 }),
  purple = swatch(0xFF9C27B0, { [50] = 0xFFF3E5F5, [100] = 0xFFE1BEE7, [200] = 0xFFCE93D8, [300] = 0xFFBA68C8, [400] = 0xFFAB47BC, [500] = 0xFF9C27B0, [600] = 0xFF8E24AA, [700] = 0xFF7B1FA2, [800] = 0xFF6A1B9A, [900] = 0xFF4A148C }),
  purpleAccent = swatch(0xFFE040FB, { [100] = 0xFFEA80FC, [200] = 0xFFE040FB, [400] = 0xFFD500F9, [700] = 0xFFAA00FF }),
  deepPurple = swatch(0xFF673AB7, { [50] = 0xFFEDE7F6, [100] = 0xFFD1C4E9, [200] = 0xFFB39DDB, [300] = 0xFF9575CD, [400] = 0xFF7E57C2, [500] = 0xFF673AB7, [600] = 0xFF5E35B1, [700] = 0xFF512DA8, [800] = 0xFF4527A0, [900] = 0xFF311B92 }),
  deepPurpleAccent = swatch(0xFF7C4DFF, { [100] = 0xFFB388FF, [200] = 0xFF7C4DFF, [400] = 0xFF651FFF, [700] = 0xFF6200EA }),
  indigo = swatch(0xFF3F51B5, { [50] = 0xFFE8EAF6, [100] = 0xFFC5CAE9, [200] = 0xFF9FA8DA, [300] = 0xFF7986CB, [400] = 0xFF5C6BC0, [500] = 0xFF3F51B5, [600] = 0xFF3949AB, [700] = 0xFF303F9F, [800] = 0xFF283593, [900] = 0xFF1A237E }),
  indigoAccent = swatch(0xFF536DFE, { [100] = 0xFF8C9EFF, [200] = 0xFF536DFE, [400] = 0xFF3D5AFE, [700] = 0xFF304FFE }),
  blue = swatch(0xFF2196F3, { [50] = 0xFFE3F2FD, [100] = 0xFFBBDEFB, [200] = 0xFF90CAF9, [300] = 0xFF64B5F6, [400] = 0xFF42A5F5, [500] = 0xFF2196F3, [600] = 0xFF1E88E5, [700] = 0xFF1976D2, [800] = 0xFF1565C0, [900] = 0xFF0D47A1 }),
  blueAccent = swatch(0xFF448AFF, { [100] = 0xFF82B1FF, [200] = 0xFF448AFF, [400] = 0xFF2979FF, [700] = 0xFF2962FF }),
  lightBlue = swatch(0xFF03A9F4, { [50] = 0xFFE1F5FE, [100] = 0xFFB3E5FC, [200] = 0xFF81D4FA, [300] = 0xFF4FC3F7, [400] = 0xFF29B6F6, [500] = 0xFF03A9F4, [600] = 0xFF039BE5, [700] = 0xFF0288D1, [800] = 0xFF0277BD, [900] = 0xFF01579B }),
  lightBlueAccent = swatch(0xFF40C4FF, { [100] = 0xFF80D8FF, [200] = 0xFF40C4FF, [400] = 0xFF00B0FF, [700] = 0xFF0091EA }),
  cyan = swatch(0xFF00BCD4, { [50] = 0xFFE0F7FA, [100] = 0xFFB2EBF2, [200] = 0xFF80DEEA, [300] = 0xFF4DD0E1, [400] = 0xFF26C6DA, [500] = 0xFF00BCD4, [600] = 0xFF00ACC1, [700] = 0xFF0097A7, [800] = 0xFF00838F, [900] = 0xFF006064 }),
  cyanAccent = swatch(0xFF18FFFF, { [100] = 0xFF84FFFF, [200] = 0xFF18FFFF, [400] = 0xFF00E5FF, [700] = 0xFF00B8D4 }),
  teal = swatch(0xFF009688, { [50] = 0xFFE0F2F1, [100] = 0xFFB2DFDB, [200] = 0xFF80CBC4, [300] = 0xFF4DB6AC, [400] = 0xFF26A69A, [500] = 0xFF009688, [600] = 0xFF00897B, [700] = 0xFF00796B, [800] = 0xFF00695C, [900] = 0xFF004D40 }),
  tealAccent = swatch(0xFF64FFDA, { [100] = 0xFFA7FFEB, [200] = 0xFF64FFDA, [400] = 0xFF1DE9B6, [700] = 0xFF00BFA5 }),
  green = swatch(0xFF4CAF50, { [50] = 0xFFE8F5E9, [100] = 0xFFC8E6C9, [200] = 0xFFA5D6A7, [300] = 0xFF81C784, [400] = 0xFF66BB6A, [500] = 0xFF4CAF50, [600] = 0xFF43A047, [700] = 0xFF388E3C, [800] = 0xFF2E7D32, [900] = 0xFF1B5E20 }),
  greenAccent = swatch(0xFF69F0AE, { [100] = 0xFFB9F6CA, [200] = 0xFF69F0AE, [400] = 0xFF00E676, [700] = 0xFF00C853 }),
  lightGreen = swatch(0xFF8BC34A, { [50] = 0xFFF1F8E9, [100] = 0xFFDCEDC8, [200] = 0xFFC5E1A5, [300] = 0xFFAED581, [400] = 0xFF9CCC65, [500] = 0xFF8BC34A, [600] = 0xFF7CB342, [700] = 0xFF689F38, [800] = 0xFF558B2F, [900] = 0xFF33691E }),
  lightGreenAccent = swatch(0xFFB2FF59, { [100] = 0xFFCCFF90, [200] = 0xFFB2FF59, [400] = 0xFF76FF03, [700] = 0xFF64DD17 }),
  lime = swatch(0xFFCDDC39, { [50] = 0xFFF9FBE7, [100] = 0xFFF0F4C3, [200] = 0xFFE6EE9C, [300] = 0xFFDCE775, [400] = 0xFFD4E157, [500] = 0xFFCDDC39, [600] = 0xFFC0CA33, [700] = 0xFFAFB42B, [800] = 0xFF9E9D24, [900] = 0xFF827717 }),
  limeAccent = swatch(0xFFEEFF41, { [100] = 0xFFF4FF81, [200] = 0xFFEEFF41, [400] = 0xFFC6FF00, [700] = 0xFFAEEA00 }),
  yellow = swatch(0xFFFFEB3B, { [50] = 0xFFFFFDE7, [100] = 0xFFFFF9C4, [200] = 0xFFFFF59D, [300] = 0xFFFFF176, [400] = 0xFFFFEE58, [500] = 0xFFFFEB3B, [600] = 0xFFFDD835, [700] = 0xFFFBC02D, [800] = 0xFFF9A825, [900] = 0xFFF57F17 }),
  yellowAccent = swatch(0xFFFFFF00, { [100] = 0xFFFFFF8D, [200] = 0xFFFFFF00, [400] = 0xFFFFEA00, [700] = 0xFFFFD600 }),
  amber = swatch(0xFFFFC107, { [50] = 0xFFFFF8E1, [100] = 0xFFFFECB3, [200] = 0xFFFFE082, [300] = 0xFFFFD54F, [400] = 0xFFFFCA28, [500] = 0xFFFFC107, [600] = 0xFFFFB300, [700] = 0xFFFFA000, [800] = 0xFFFF8F00, [900] = 0xFFFF6F00 }),
  amberAccent = swatch(0xFFFFD740, { [100] = 0xFFFFE57F, [200] = 0xFFFFD740, [400] = 0xFFFFC400, [700] = 0xFFFFAB00 }),
  orange = swatch(0xFFFF9800, { [50] = 0xFFFFF3E0, [100] = 0xFFFFE0B2, [200] = 0xFFFFCC80, [300] = 0xFFFFB74D, [400] = 0xFFFFA726, [500] = 0xFFFF9800, [600] = 0xFFFB8C00, [700] = 0xFFF57C00, [800] = 0xFFEF6C00, [900] = 0xFFE65100 }),
  orangeAccent = swatch(0xFFFFAB40, { [100] = 0xFFFFD180, [200] = 0xFFFFAB40, [400] = 0xFFFF9100, [700] = 0xFFFF6D00 }),
  deepOrange = swatch(0xFFFF5722, { [50] = 0xFFFBE9E7, [100] = 0xFFFFCCBC, [200] = 0xFFFFAB91, [300] = 0xFFFF8A65, [400] = 0xFFFF7043, [500] = 0xFFFF5722, [600] = 0xFFF4511E, [700] = 0xFFE64A19, [800] = 0xFFD84315, [900] = 0xFFBF360C }),
  deepOrangeAccent = swatch(0xFFFF6E40, { [100] = 0xFFFF9E80, [200] = 0xFFFF6E40, [400] = 0xFFFF3D00, [700] = 0xFFDD2C00 }),
  brown = swatch(0xFF795548, { [50] = 0xFFEFEBE9, [100] = 0xFFD7CCC8, [200] = 0xFFBCAAA4, [300] = 0xFFA1887F, [400] = 0xFF8D6E63, [500] = 0xFF795548, [600] = 0xFF6D4C41, [700] = 0xFF5D4037, [800] = 0xFF4E342E, [900] = 0xFF3E2723 }),
  grey = swatch(0xFF9E9E9E, { [50] = 0xFFFAFAFA, [100] = 0xFFF5F5F5, [200] = 0xFFEEEEEE, [300] = 0xFFE0E0E0, [350] = 0xFFD6D6D6, [400] = 0xFFBDBDBD, [500] = 0xFF9E9E9E, [600] = 0xFF757575, [700] = 0xFF616161, [800] = 0xFF424242, [850] = 0xFF303030, [900] = 0xFF212121 }),
  blueGrey = swatch(0xFF607D8B, { [50] = 0xFFECEFF1, [100] = 0xFFCFD8DC, [200] = 0xFFB0BEC5, [300] = 0xFF90A4AE, [400] = 0xFF78909C, [500] = 0xFF607D8B, [600] = 0xFF546E7A, [700] = 0xFF455A64, [800] = 0xFF37474F, [900] = 0xFF263238 }),
}

-- InputDecoration { border = OutlineInputBorder { borderRadius = ... } }.
M.InputDecoration = function(t) return t end
M.OutlineInputBorder = function(t)
  t = t or {}
  return { type = "outline", borderRadius = t.borderRadius }
end
M.UnderlineInputBorder = function() return { type = "underline" } end
M.InputBorder = { none = { type = "none" } }
M.TextInputType = ui.enum("TextInputType", {
  "text", "multiline", "number", "phone", "datetime", "emailAddress", "url",
  "visiblePassword", "name",
})

return M
