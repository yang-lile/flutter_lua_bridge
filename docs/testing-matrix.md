# Project architecture and testing matrix

## Project structure

The repository is a Dart workspace with seven packages and three examples:

| Area | Responsibility |
| --- | --- |
| `packages/flutter_lua_bridge` | `LuaRuntime`, the `flb` shim and its bindings, codecs, result envelopes, native asset hook, and the bundled Lua releases. |
| `packages/flutter_lua_bridge_codegen_annotation` | Dependency-free annotations that describe APIs, Lua names and the optimization level. |
| `packages/flutter_lua_bridge_codegen` | `build_runner` builders: contract reader, model, Dart/Lua/Teal emitters, and the Teal compiler (`tl.lua`) with its worker process. |
| `packages/flutter_lua_bridge_ui` | Widget trees from Lua: `LuaView`, the `flb.ui` Lua module, the core widget registry and `LuaStore`. |
| `packages/flutter_lua_bridge_ui_material` | The Material widget registry and the `flb.ui.material` Lua module. |
| `packages/flutter_lua_bridge_ui_cupertino` | The Cupertino widget registry and the `flb.ui.cupertino` Lua module. |
| `packages/flutter_lua_bridge_remote` | Lua bundles over the network: `LuaBundleLoader` and `RemoteLuaView`. |
| `examples/flutter_lua_bridge_example/lib/bridge` | Application contracts and their generated `.g.dart` parts. |
| `examples/flutter_lua_bridge_example/lua/src` | Editable Teal and Lua business logic. |
| `examples/flutter_lua_bridge_example/lua/types` | Generated Teal declarations. |
| `examples/flutter_lua_bridge_example/assets/lua` | Builder output consumed by Flutter as Lua assets. |
| `examples/flutter_lua_bridge_example/lib` and `examples/flutter_lua_bridge_example/test` | Example application logic, bridge scenarios, and widget/domain tests. |
| `examples/lua_ui_gallery` | A macOS app whose screens are Lua scripts: the widget packages, Lua routes and remote bundles, driven by widget tests. |
| `examples/lua_canvas_host` | Lua output as `rfw` remote widgets and canvas drawings, with the `LuaView` and `rfw` benchmarks. |
| `tool` | Generation with drift check, light CI, full release CI, multi-version tests, the widget packages' Teal sample check and Lua module embedding, the Lua runner for editors, pana scoring, and Podman/act helpers. |
| `.github/workflows` | A light PR/main workflow and a release-only integration workflow (Ubuntu stages plus macOS/Windows smoke tests). |

Generated files remain derived artifacts. Contracts and Teal sources are edited
by hand; generated Dart/Lua/Teal files are refreshed by `build_runner`
(`tool/generate_example.sh`).

## Module test list

### Annotation package

- Annotation constructors retain module names, Lua names and optimization
  defaults.
- Explicit optimization values are preserved.
- The package remains dependency-free at runtime.

Implemented in `packages/flutter_lua_bridge_codegen_annotation/test/annotations_test.dart`.

### Runtime package

- Primitive codecs accept declared values and reject wrong types with paths.
- Nullable codecs preserve null and delegate non-null values.
- Lists require dense integer keys; maps require string keys.
- Field decoding requires a `BridgeTable`.
- Success, typed failure, malformed, and missing result envelopes classify
  errors correctly.
- `LuaRuntime` covers execution, values and handles, errors with tracebacks,
  host functions, modules, memory limit and interrupt.
- Native sanitizer coverage validates the shim on every bundled Lua release.
- The build hook selects the bundled release, a local tree or a verified
  archive URL, and builds the native library.

Fast codec checks are in `packages/flutter_lua_bridge/test/codecs_test.dart`,
the runtime checks in `test/lua_runtime_test.dart`, `LuaWorker` (plain
data both ways, errors, timeout and interrupt of endless loops, ordering,
close, memory limit, setup) in `test/worker_test.dart`, the hook's source
selection in `test/lua_source_test.dart` and the hook build in
`test/hook_build_test.dart`. The multi-version and sanitizer checks remain in
the release gate.

### Code generator package

- The model renders nested nullable Dart types correctly, and O1/O2/O3 policy
  flags remain explicit (`test/model_test.dart`).
- The reader accepts resolved contracts, including types from other libraries,
  and rejects unsupported types, names and contract shapes; emitters produce
  deterministic Dart, Lua and Teal; builder options are validated
  (`test/generator_test.dart`).
- O1 contains validators and `pcall`; O2 keeps error envelopes without
  validators; O3 keeps the direct call path. Each level has a successful call
  and an error path against a real runtime (`test/levels_test.dart`).
- Generated clients and host registration cover DTOs, int64, enums, nested
  collections, callbacks, re-entry, unregistering, stack restoration and
  independent runtimes (`test/runtime_test.dart`).
- The Teal worker compiles modules, resolves `require` among sources and
  declarations, and reports type errors, syntax errors and missing modules
  (`test/teal_test.dart`, run on its own with `dart test -P teal-worker`:
  the worker's `dart run` rewrites the copied native library in place, which
  crashes a Linux test process that has already loaded it).
- The Lua runner behind `flutter_lua_bridge_codegen:run` resolves `require`
  through `tlconfig.lua`, type checks Teal entries and modules, stubs missing
  `*_bridge` modules, and reports failed assertions, type errors and
  unstubbed host calls (`test/lua_runner_test.dart`).

The fixtures under `test/fixtures` are generated by the package's own builders
and checked for drift.

### Widget packages

- Each package's Dart registry, Lua module and Teal declarations name the
  same widgets, and the embedded Lua modules match `lua/`
  (`test/catalog_test.dart`).
- `flutter_lua_bridge_ui`: `LuaView` renders, rebuilds only the components
  that read a changed `LuaStore` key, syncs the store both ways, decodes
  Flutter-style values and callbacks, builds `ListView.builder` lazily, and
  shows the fallback on Lua errors (`test/lua_view_test.dart`); Lua calls
  Dart functions, waits for Futures and pushes Lua routes through
  `Navigator` (`test/host_functions_test.dart`).
- The Material and Cupertino controls send their values to Lua
  (`test/material_test.dart`, `test/cupertino_test.dart`).
- `lua/test/*_test.tl` type check and run; `lua/test_fail/*_test.tl` are
  rejected by Teal with their `-- expect:` message (`tool/check_teal_ui.sh`).

### Remote package

- `LuaBundleLoader` downloads, verifies and caches versions, falls back to the
  last good one offline, skips versions marked bad or needing a missing
  library, and rejects manifests pointing outside the bundle
  (`test/loader_test.dart`).
- `RemoteLuaView` shows a bundle, marks it good after the first frame, and
  shows the fallback without one (`test/remote_view_test.dart`).

### Example

- The card game (`test/game`) loads its typed card catalog, passives and
  skill effects from Lua, and checks that the same seeded battle gives the
  same events with the Dart reference formulas and with the Lua formulas at
  O1, O2 and O3. A deliberately faulty script shows how each level reports a
  wrong result type and a runtime error, and the benchmark runs for every
  backend. Widget tests drive the game page, the arena and the safety level
  page.
- The Lua side runs alone through `flutter_lua_bridge_codegen:run`: the
  formulas, the card catalog and passives, and a module calling a stubbed
  Dart host (`lua/test`). The light gate runs it on the default Lua; the
  version stage runs it, and the basic bridge test, on every other release.
- macOS and Windows run the basic bridge and battle simulator smoke tests.
- The release gate runs the full scenario matrix: pure Lua, compiled Teal,
  dynamic Lua, and Dart-host implementations.

### Lua UI gallery

- Widget tests drive every screen: Lua routes in separate instances, the
  Material and Cupertino widgets, the lazy core list, and remote bundles
  (download, bad version, offline, built-in) (`test/gallery_test.dart`).

## Execution tiers

| Tier | Trigger | Checks |
| --- | --- | --- |
| Light | Pull requests and pushes to `main` | `tool/ci.sh light`: analyzer, builders with generated artifact drift, all generator tests (including Teal on the default Lua), the runtime tests, the example's Lua entries and game tests, the Teal samples and tests of the widget and remote packages, the widget package layering check, and the gallery tests. |
| Release integration | Published GitHub Release or manual dispatch | Full `tool/ci.sh` as parallel jobs: native sanitizer on every bundled Lua release; runtime, generator, example Lua, widget and remote package tests on the other releases; the example's bridge, scenario and widget tests; plus macOS/Windows smoke tests. |
| Local | Developer choice | `./tool/ci_light.sh` for fast feedback, `./tool/ci.sh` before a release, or `./tool/ci_podman.sh` for workflow emulation. The example's `integration_test` (the whole app on macOS) runs only here, by hand. |

Two independent test implementations were compared before consolidating this
matrix. The final suite keeps the annotation test in the annotation package,
adopts the stronger malformed-envelope and schema parsing cases, and keeps the
runtime codec checks separate from Lua VM integration tests.
