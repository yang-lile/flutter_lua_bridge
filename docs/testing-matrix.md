# Project architecture and testing matrix

## Project structure

The repository is a Dart workspace with three packages and one executable
example:

| Area | Responsibility |
| --- | --- |
| `packages/flutter_lua_bridge` | Runtime API, Lua 5.4 bindings, codecs, result envelopes, native asset hook, and the bundled Lua C source. |
| `packages/flutter_lua_bridge_codegen_annotation` | Dependency-free annotations that describe APIs, names, output paths, and optimization levels. |
| `packages/flutter_lua_bridge_codegen` | Dart AST parser, contract model, fingerprinting, and Dart/Lua/Teal emitters plus the generator executable. |
| `examples/flutter_lua_bridge_example/bridge` | Application contracts. These files are the source of generated Dart, Lua protocol, and Teal declarations. |
| `examples/flutter_lua_bridge_example/lua/src` | Editable Teal business logic. |
| `examples/flutter_lua_bridge_example/lua/build` | Cyan output consumed by Flutter as Lua assets. |
| `examples/flutter_lua_bridge_example/lib` and `examples/flutter_lua_bridge_example/test` | Example application logic, generated clients, bridge scenarios, and widget/domain tests. |
| `tool` | Generation, playground, light CI, full release CI, and Podman/act helpers. |
| `.github/workflows` | A light PR/main workflow and a release-only Ubuntu integration workflow. |

Generated files remain derived artifacts. Contracts and Teal sources are edited
by hand; generated Dart/Lua/Teal files are refreshed by the generator or Cyan.

## Module test list

### Annotation package

- Annotation constructors retain module names, Lua names, output paths, and
  optimization defaults.
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
- Full runtime behavior covers Lua execution, stack restoration, callbacks,
  host registration, re-entry guards, and independent runtimes.
- Native sanitizer coverage validates the C ABI and bundled Lua boundary.

Fast codec checks are in `packages/flutter_lua_bridge/test/codecs_test.dart`.
The Lua VM, native hook integration, and sanitizer checks remain in the release
gate.

### Code generator package

- The model renders nested nullable Dart types correctly.
- O1/O2/O3 policy flags and parsing remain explicit.
- Annotation options map into the shared schema model.
- Parser validation rejects unsupported types, names, and contract shapes.
- Emitters produce deterministic Dart, Lua, and Teal artifacts.
- O1 contains validators and `pcall`; O2 keeps error envelopes without
  validators; O3 keeps the direct call path.
- Fingerprints change when the protocol contract changes.

Model checks are in `packages/flutter_lua_bridge_codegen/test/model_test.dart`.
The existing generator suite covers invalid contracts, emitters, fingerprints,
and generated artifact drift.

### Example and Teal/Cyan

- Card and skill parsing, defaults, numeric coercion, copying, and domain
  values are covered by `examples/flutter_lua_bridge_example/test/game/card_loader_test.dart`.
- macOS and Windows run the basic bridge and card-loader smoke tests.
- The release gate runs the full scenario matrix: pure Lua, compiled Teal,
  dynamic Lua, and Dart-host implementations.
- The release gate builds bundled Lua 5.4 and runs Cyan against all Teal
  sources.

## Execution tiers

| Tier | Trigger | Checks |
| --- | --- | --- |
| Light | Pull requests and pushes to `main` | Analyzer, codegen unit tests, generated contract checks, example domain unit test, macOS/Windows smoke tests. |
| Release integration | Published GitHub Release only | Full `tool/ci.sh`, native sanitizer, Lua/Cyan build, runtime tests, and Flutter scenario/integration tests. |
| Local | Developer choice | `./tool/ci_light.sh` for fast feedback, `./tool/ci.sh` before a release, or `./tool/ci_podman.sh` for workflow emulation. |

Two independent test implementations were compared before consolidating this
matrix. The final suite keeps the annotation test in the annotation package,
adopts the stronger malformed-envelope and schema parsing cases, and keeps the
runtime codec checks separate from Lua VM integration tests.
