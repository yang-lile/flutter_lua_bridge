-- Cyan project for the Lua modules shipped with the Flutter example.
-- Teal sources live in src/ and compiled Lua is written to build/.
return {
  source_dir = "src",
  build_dir = "build",
  include = { "**/*.tl" },
  -- Cyan's portable target is 5.3; the generated Lua runs on our 5.4 VM.
  gen_target = "5.3",
  gen_compat = "off",
}
