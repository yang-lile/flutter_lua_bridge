# Developing this repository

Rules for changing the code (source ownership, generated files, commits) are
in [`AGENTS.md`](../AGENTS.md); what each test tier covers is in
[`testing-matrix.md`](testing-matrix.md).

## Checks

```sh
dart pub get
./tool/ci_light.sh      # the pull request gate
./tool/ci.sh            # the release gate: light, native, versions, example
```

`ci_light.sh` runs the analyzer, the builders with a drift check on every
generated file, the generator tests, the example's Lua entries and its game
tests. `ci.sh` adds the native shim tests with ASan/UBSan on every bundled Lua
(`python3 packages/flutter_lua_bridge/tool/test_native.py`), the runtime and
generator tests on every bundled Lua release, and the example's Flutter
tests. Both scripts honour `DART_CMD` and `FLUTTER_CMD`, for example
`DART_CMD="fvm dart" FLUTTER_CMD="fvm flutter"`.

The generator's Teal worker tests run in a process of their own,
`dart test -P teal-worker`; see `packages/flutter_lua_bridge_codegen/dart_test.yaml`.

## Running the workflows locally

`actionlint` validates the workflow files. Full workflow emulation with `act`
needs a Docker-compatible daemon; with Podman, `tool/ci_podman.sh` wraps the
options:

```sh
./tool/ci_podman.sh dry-run       # parse the workflow and list its jobs
./tool/ci_podman.sh light         # run the daily lightweight workflow
./tool/ci_podman.sh release       # run the release integration workflow
```

The release workflow uses a temporary x64 Flutter configuration in the local
Podman wrapper because Flutter 3.38.10 does not publish a Linux arm64 archive.
On Apple Silicon, the native ASan test may still fail under amd64 emulation;
use `./tool/ci.sh` on the host or the GitHub release workflow for the
authoritative native check.

## VS Code

Open the repository root. `.vscode/launch.json` (Run and Debug, F5) has:

| Configuration | What it starts |
| --- | --- |
| Example app | `examples/flutter_lua_bridge_example` on the device picked in the status bar, after regenerating its Lua with `tool/generate_example.sh` |
| Example app (profile, for the benchmark) | The same in profile mode, for meaningful numbers on the safety level page |
| Lua Canvas Studio (macOS) | `examples/lua_canvas_host`, after syncing its asset list from `assets/lua/manifest.txt` |
| Lua Canvas Studio (macOS, flutter_driver) | The same with `lib/driver_main.dart` |
| Lua: run current file | The open `.tl`/`.lua` entry without an app |

`.vscode/settings.json` points the Dart extension at fvm's global Flutter
(`~/fvm/default`); change it if your SDK lives elsewhere. If the debugger
cannot attach to Lua Canvas Studio, the task "canvas: build and open
(tools/dev.sh)" builds it with Xcode and opens it. The other tasks
(Terminal > Run Task) run the Lua entries and both end-to-end tests; see
[`examples/flutter_lua_bridge_example/lua/README.md`](../examples/flutter_lua_bridge_example/lua/README.md).

## Publishing

[Melos](https://melos.invertase.dev) (a dev dependency of the workspace,
configured under `melos:` in the root `pubspec.yaml`) publishes the three
packages in dependency order: `flutter_lua_bridge_codegen_annotation`,
`flutter_lua_bridge`, then `flutter_lua_bridge_codegen`. The examples are
`publish_to: none` and skipped.

```sh
dart run melos run publish:check            # dry run of every package
dart run melos publish --no-dry-run -t      # publish what pub.dev lacks, tag each release
```

`-t` creates one git tag per package (`<package>-v<version>`); push them
with `git push origin --tags`. Before publishing, raise `version:` in the
packages, their `^` constraints on each other, and the CHANGELOGs. The
other scripts (`dart run melos run ci:light`, `ci`, `generate`) wrap the
`tool/` scripts.
