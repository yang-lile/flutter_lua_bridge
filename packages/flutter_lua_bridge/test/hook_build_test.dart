import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:test/test.dart';

import '../hook/build.dart' as lua_hook;

void main() {
  test('build hook accepts a configured Lua source path', () async {
    final packageRoot = Directory.current.absolute;
    final luaRoot = Directory.fromUri(packageRoot.uri.resolve('lua_src/'));

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
