# Cyan Lua project

`src/` contains editable Teal modules and the generated `.d.tl` declarations
used by those modules. `build/` contains the Lua files produced by Cyan for
the bundled Lua 5.4 runtime (Cyan's portable 5.3 target is compatible with
Lua 5.4).
The Dart generator writes the bridge companion into `src/`; it is also embedded
in the generated Dart library so the runtime can load it without reading a
second asset.

Install the Teal toolchain once with LuaRocks:

```sh
luarocks --lua-version=5.4 install tl 0.24.8-1
luarocks --lua-version=5.4 install cyan 0.4.1-1
```

Build all Teal modules from this directory:

```sh
cyan build
```

The Flutter example packages compiled modules such as `build/basic.lua` and
`build/battle.lua` as assets. Generated bridge Dart code then loads those
modules through `LuaRuntime`.
