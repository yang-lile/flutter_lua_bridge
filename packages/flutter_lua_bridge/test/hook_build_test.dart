import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:test/test.dart';

import '../hook/build.dart' as lua_hook;

void main() {
  final packageRoot = Directory.current.absolute;

  for (final release in ['5.3.6', '5.4.9', '5.5.0']) {
    test('build hook compiles a configured Lua $release source path', () async {
      final luaRoot = Directory.fromUri(
        packageRoot.uri.resolve('third_party/lua-$release/'),
      );

      await testCodeBuildHook(
        mainMethod: lua_hook.main,
        userDefines: PackageUserDefines(
          workspacePubspec: PackageUserDefinesSource(
            defines: {'lua_source': luaRoot.path},
            basePath: packageRoot.uri,
          ),
        ),
        check: (_, _) {},
      );
    });
  }

  for (final line in ['5.3', '5.4', '5.5']) {
    test('build hook compiles the bundled Lua $line line', () async {
      await testCodeBuildHook(
        mainMethod: lua_hook.main,
        userDefines: PackageUserDefines(
          workspacePubspec: PackageUserDefinesSource(
            defines: {'lua_version': line},
            basePath: packageRoot.uri,
          ),
        ),
        check: (_, _) {},
      );
    });
  }
}
