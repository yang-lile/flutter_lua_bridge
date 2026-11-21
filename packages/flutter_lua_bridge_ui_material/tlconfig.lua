-- Teal settings for editors that open this package folder, and for
-- `dart run flutter_lua_bridge_codegen:run lua/test` (tool/check_teal_ui.sh).
-- Applications add lua/types of this package and of flutter_lua_bridge_ui to
-- their own include_dir.
return {
  include_dir = {
    "lua/types", "lua",
    "../flutter_lua_bridge_ui/lua/types", "../flutter_lua_bridge_ui/lua",
  },
  gen_compat = "off",
}
