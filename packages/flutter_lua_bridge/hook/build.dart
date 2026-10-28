import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
    if (input.config.buildCodeAssets) {
      final sources = [
        "lua_src/src/lapi.c",
        "lua_src/src/lauxlib.c",
        "lua_src/src/lbaselib.c",
        "lua_src/src/lcode.c",
        "lua_src/src/lcorolib.c",
        "lua_src/src/lctype.c",
        "lua_src/src/ldblib.c",
        "lua_src/src/ldebug.c",
        "lua_src/src/ldo.c",
        "lua_src/src/ldump.c",
        "lua_src/src/lfunc.c",
        "lua_src/src/lgc.c",
        "lua_src/src/linit.c",
        "lua_src/src/liolib.c",
        "lua_src/src/llex.c",
        "lua_src/src/lmathlib.c",
        "lua_src/src/lmem.c",
        "lua_src/src/loadlib.c",
        "lua_src/src/lobject.c",
        "lua_src/src/lopcodes.c",
        "lua_src/src/loslib.c",
        "lua_src/src/lparser.c",
        "lua_src/src/lstate.c",
        "lua_src/src/lstring.c",
        "lua_src/src/lstrlib.c",
        "lua_src/src/ltable.c",
        "lua_src/src/ltablib.c",
        "lua_src/src/ltm.c",
        "lua_src/src/lundump.c",
        "lua_src/src/lutf8lib.c",
        "lua_src/src/lvm.c",
        "lua_src/src/lzio.c",
        "native/bridge.c",
      ];

      // assetName 必须与 FFI 代码中的 @DefaultAsset 注解匹配
      // FFI 注解: @DefaultAsset('package:flutter_lua_bridge/flutter_lua_bridge.dart')
      final builder = CBuilder.library(
        name: packageName,
        assetName: '$packageName.dart',
        sources: sources,
        includes: ['lua_src/src', 'native'],
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
    }
  });
}
