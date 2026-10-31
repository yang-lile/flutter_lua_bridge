import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

import 'lua_source.dart';

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
    if (input.config.buildCodeAssets) {
      String? readStringDefine(String key) {
        final value = input.userDefines[key];
        if (value != null && value is! String) {
          throw FormatException('$key must be a string.');
        }
        return value as String?;
      }

      final configuredSource = readStringDefine(luaSourceUserDefine);
      final luaSource = await resolveLuaSource(
        packageRoot: input.packageRoot,
        configuredRoot: input.userDefines.path(luaSourceUserDefine),
        configuredSource: configuredSource,
        version: readStringDefine(luaVersionUserDefine),
        sha256: readStringDefine(luaSha256UserDefine),
        outputDirectoryShared: input.outputDirectoryShared,
      );
      final sources = [
        ...luaSource.sourceFiles.map((file) => file.toFilePath()),
        "native/bridge.c",
      ];

      // assetName 必须与 FFI 代码中的 @DefaultAsset 注解匹配
      // FFI 注解: @DefaultAsset('package:flutter_lua_bridge/flutter_lua_bridge.dart')
      final builder = CBuilder.library(
        name: packageName,
        assetName: '$packageName.dart',
        sources: sources,
        includes: [luaSource.sourceDirectory.toFilePath(), 'native'],
        libraries: switch (input.config.code.targetOS) {
          OS.linux || OS.android => ['m', 'dl'],
          OS.macOS || OS.iOS => ['m'],
          _ => [],
        },
        defines: switch (input.config.code.targetOS) {
          OS.windows => {'LUA_BUILD_AS_DLL': null},
          OS.macOS => {'LUA_USE_MACOSX': null},
          OS.iOS => {'LUA_USE_IOS': null},
          OS.linux || OS.android => {'LUA_USE_LINUX': null},
          _ => {},
        },
      );
      await builder.run(input: input, output: output);
      // Track the configured tree itself so additions/removals invalidate the
      // hook, in addition to the individual files reported by CBuilder.
      output.dependencies.add(luaSource.sourceDirectory);
    }
  });
}
