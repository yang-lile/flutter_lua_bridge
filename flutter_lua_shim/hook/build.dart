import 'dart:io';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  await build(args, (BuildInput input, BuildOutputBuilder output) async {
    final userDefines = input.userDefines;
    final luaVersion = (userDefines['lua_version'] as String?)?.trim() ?? '5.4';

    const supported = {'5.3', '5.4'};
    if (!supported.contains(luaVersion)) {
      throw StateError(
        '[flutter_lua_shim] Unsupported lua_version: $luaVersion. '
        'Supported: ${supported.join(", ")}',
      );
    }

    final pkgRoot = input.packageRoot.toFilePath();
    final luaSrcDir = p.join(pkgRoot, 'src', 'lua', luaVersion);

    if (!Directory(luaSrcDir).existsSync()) {
      throw StateError('Lua $luaVersion source not found at $luaSrcDir');
    }

    final sources = Directory(luaSrcDir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.c'))
        .map((f) => f.path)
        .where((path) => !path.endsWith('lua.c') && !path.endsWith('luac.c'))
        .toList();

    sources.add(p.join(pkgRoot, 'src', 'lua_api_shim.c'));

    final cBuilder = CBuilder.library(
      name: 'flutter_lua_shim',
      assetName: 'flutter_lua_shim.dart',
      sources: sources,
      includes: [luaSrcDir, p.join(pkgRoot, 'src')],
      defines: {'LUA_SHIM_VERSION': luaVersion.replaceAll('.', '')},
    );

    await cBuilder.run(input: input, output: output);
  });
}
