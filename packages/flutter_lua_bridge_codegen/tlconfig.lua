-- Teal project settings for the editor when this package is opened, so the
-- generator fixtures resolve their declarations. The build does not read it.
return {
  source_dir = "test/fixtures/lua/src",
  include_dir = { "test/fixtures/lua/src", "test/fixtures/lua/types" },
  gen_compat = "off",
}
