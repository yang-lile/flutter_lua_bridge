-- Teal settings for editors that open this package folder, and for
-- `dart run flutter_lua_bridge_codegen:run lua/test` (see tool/ci_light.sh).
-- Applications add lua/types of this package to their own include_dir to
-- type check require("flb.ui") and require("flb.ui.prelude").
return {
  include_dir = { "lua/types", "lua" },
  gen_compat = "off",
}
