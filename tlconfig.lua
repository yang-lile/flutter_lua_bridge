-- Teal project settings for the editor when the repository root is opened.
-- The Teal language server reads tlconfig.lua only from the opened folder,
-- so this one points at the example app. Open a package folder to use that
-- package's own tlconfig.lua instead. The build does not read it.
local example = "examples/flutter_lua_bridge_example/lua/"
return {
  source_dir = example .. "src",
  include_dir = { example .. "src", example .. "types", example .. "test" },
  gen_compat = "off",
}
