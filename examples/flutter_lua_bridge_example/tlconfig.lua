-- Teal project settings for tools, read from the package root:
-- - the Teal language server (VS Code and other editors) reads tlconfig.lua
--   only from the folder that is opened, so it sits here, not in lua/;
-- - `dart run flutter_lua_bridge_codegen:run` uses include_dir and
--   source_dir to resolve require() for the entries in lua/test.
-- `dart run build_runner build` does not read it.
return {
  source_dir = "lua/src",
  include_dir = { "lua/src", "lua/types", "lua/test" },
  gen_compat = "off",
}
