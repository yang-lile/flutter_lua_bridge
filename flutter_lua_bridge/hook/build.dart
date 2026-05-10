import 'dart:io';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';

/// 下载并解压 Lua 源码
Future<String> _downloadAndExtractLuaSource(
  String url,
  String targetDir,
) async {
  final httpClient = HttpClient();

  try {
    // 下载文件
    final request = await httpClient.getUrl(Uri.parse(url));
    final response = await request.close();

    if (response.statusCode != 200) {
      throw StateError(
        '[flutter_lua_bridge] Failed to download Lua source: HTTP ${response.statusCode}',
      );
    }

    // 创建临时目录
    final tempDir = Directory.systemTemp.createTempSync('lua_source_');
    final tarGzFile = File(p.join(tempDir.path, 'lua.tar.gz'));

    // 写入下载的内容
    final sink = tarGzFile.openWrite();
    await response.pipe(sink);
    await sink.close();

    // 解压 tar.gz 文件
    final result = await Process.run('tar', [
      'xzf',
      tarGzFile.path,
      '-C',
      tempDir.path,
    ]);

    if (result.exitCode != 0) {
      throw StateError(
        '[flutter_lua_bridge] Failed to extract Lua source: ${result.stderr}',
      );
    }

    // 查找解压后的目录（通常是 lua-x.y.z 格式）
    final extractedDirs = tempDir.listSync().whereType<Directory>().toList();

    if (extractedDirs.isEmpty) {
      throw StateError(
        '[flutter_lua_bridge] No directory found after extraction',
      );
    }

    // 移动到目标目录
    final luaSrcDir = extractedDirs.first;
    final targetPath = Directory(targetDir);

    if (targetPath.existsSync()) {
      targetPath.deleteSync(recursive: true);
    }
    targetPath.createSync(recursive: true);

    // 复制所有文件
    await for (final entity in luaSrcDir.list(recursive: true)) {
      final relativePath = p.relative(entity.path, from: luaSrcDir.path);
      final targetEntityPath = p.join(targetDir, relativePath);

      if (entity is File) {
        final targetFile = File(targetEntityPath);
        await targetFile.parent.create(recursive: true);
        await entity.copy(targetEntityPath);
      }
    }

    // 清理临时文件
    tempDir.deleteSync(recursive: true);

    return targetDir;
  } finally {
    httpClient.close();
  }
}

void main(List<String> args) async {
  await build(args, (BuildInput input, BuildOutputBuilder output) async {
    final userDefines = input.userDefines;
    final luaVersion = (userDefines['lua_version'] as String?)?.trim() ?? '5.4';
    final luaSourceUrl = (userDefines['lua_source_url'] as String?)?.trim();

    const supported = {'5.3', '5.4', '5.5'};
    if (!supported.contains(luaVersion)) {
      throw StateError(
        '[flutter_lua_bridge] Unsupported lua_version: $luaVersion. '
        'Supported: ${supported.join(", ")}',
      );
    }

    final pkgRoot = input.packageRoot.toFilePath();
    String luaSrcDir;

    if (luaSourceUrl != null && luaSourceUrl.isNotEmpty) {
      // 从 URL 下载 Lua 源码
      Logger(
        '',
      ).info('[flutter_lua_bridge] Downloading Lua source from: $luaSourceUrl');

      final cacheDir = p.join(pkgRoot, '.dart_tool', 'flutter_lua_bridge', 'cache', 'lua', luaVersion);
      luaSrcDir = p.join(cacheDir, 'src');

      // 如果缓存不存在，则下载
      if (!Directory(luaSrcDir).existsSync()) {
        await _downloadAndExtractLuaSource(luaSourceUrl, cacheDir);
      }
    } else {
      // 使用本地源码
      luaSrcDir = p.join(pkgRoot, 'src', 'lua', luaVersion);

      if (!Directory(luaSrcDir).existsSync()) {
        throw StateError(
          '[flutter_lua_bridge] Lua source directory not found: $luaSrcDir. '
          'Please provide lua_source_url to download Lua source, or ensure local source exists.',
        );
      }
    }

    final sources = Directory(luaSrcDir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.c'))
        .map((f) => f.path)
        .where((path) => !path.endsWith('lua.c') && !path.endsWith('luac.c'))
        .toList();

    sources.add(p.join(pkgRoot, 'src', 'flutter_lua_bridge.c'));

    final cBuilder = CBuilder.library(
      name: 'flutter_lua_bridge',
      assetName: 'flutter_lua_bridge.dart',
      sources: sources,
      includes: [luaSrcDir, p.join(pkgRoot, 'src')],
      defines: {'LUA_BRIDGE_VERSION': luaVersion.replaceAll('.', '')},
    );

    await cBuilder.run(input: input, output: output);
  });
}
