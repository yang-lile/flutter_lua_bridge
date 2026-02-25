import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
    if (input.config.buildCodeAssets) {
      final builder = CBuilder.library(
        name: packageName,
        assetName: 'src/gen/$packageName.g.dart',
        sources: [
          "src/lua/src/lapi.c",
          "src/lua/src/lauxlib.c",
          "src/lua/src/lbaselib.c",
          "src/lua/src/lcode.c",
          "src/lua/src/lcorolib.c",
          "src/lua/src/lctype.c",
          "src/lua/src/ldblib.c",
          "src/lua/src/ldebug.c",
          "src/lua/src/ldo.c",
          "src/lua/src/ldump.c",
          "src/lua/src/lfunc.c",
          "src/lua/src/lgc.c",
          "src/lua/src/linit.c",
          "src/lua/src/liolib.c",
          "src/lua/src/llex.c",
          "src/lua/src/lmathlib.c",
          "src/lua/src/lmem.c",
          "src/lua/src/loadlib.c",
          "src/lua/src/lobject.c",
          "src/lua/src/lopcodes.c",
          "src/lua/src/loslib.c",
          "src/lua/src/lparser.c",
          "src/lua/src/lstate.c",
          "src/lua/src/lstring.c",
          "src/lua/src/lstrlib.c",
          "src/lua/src/ltable.c",
          "src/lua/src/ltablib.c",
          "src/lua/src/ltm.c",
          "src/lua/src/lua.c",
          "src/lua/src/lundump.c",
          "src/lua/src/lutf8lib.c",
          "src/lua/src/lvm.c",
          "src/lua/src/lzio.c",
        ],
      );
      await builder.run(input: input, output: output);
    }
  });
}
