-- For editor tooling only (for example the Teal language server).
-- `dart run build_runner build` compiles the sources with the Teal compiler
-- bundled in flutter_lua_bridge_codegen and does not read this file.
return {
  source_dir = "src",
  include_dir = { "src", "types" },
  gen_compat = "off",
}
