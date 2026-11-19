# Choosing the Lua source

`flutter_lua_bridge` builds Lua from source with a Dart build hook, for the
target platform, together with the `flb` C shim (`native/flb.h`). Lua 5.3.6,
5.4.9 and 5.5.0 are bundled under `packages/flutter_lua_bridge/third_party/`;
without any setting the hook builds 5.4.

The application selects another source in its workspace root `pubspec.yaml`
(the hook reads these settings from nowhere else):

```yaml
hooks:
  user_defines:
    flutter_lua_bridge:
      # One of the bundled release lines: 5.3, 5.4 (default) or 5.5.
      lua_version: "5.5"
      # Or a local source tree, relative to the workspace root:
      # lua_source: third_party/lua-5.4
      # Or an immutable archive URL, with a fixed version label:
      # lua_source: https://example.com/lua-5.5.tar.gz
      # lua_version: 5.5.0
      # Optional: lua_sha256: <64-character SHA-256 digest>
```

- A source tree must contain `src/lua.h` and the Lua library sources. The hook
  checks them against a fixed manifest; the standalone `lua.c` and `luac.c`
  programs are never compiled.
- A URL source needs a fixed `lua_version` label. With `lua_sha256` the
  downloaded archive is verified and cached under the hook's shared output
  directory. Without a digest the URL and the label form the cache key, so
  change `lua_version` when the remote content changes.
- Differences between Lua releases are handled inside `native/flb.c`, so the
  Dart bindings are identical for every release and the hook does not impose
  a version.

`LuaRuntime.luaVersion` reports the release the application runs on (for
example `504`).
