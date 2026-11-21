import 'dart:io';

import 'package:flutter_lua_bridge_ui/flutter_lua_bridge_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The core widget names must agree in the Dart registry, the Lua
/// constructors of `flb.ui` and the Teal declarations.
void main() {
  final dart = coreLibrary().widgets.keys.toSet();

  test('flb.ui has a constructor for every core widget', () {
    final list = RegExp(r'M\.core = M\.library\("core", \{([^}]*)\}\)')
        .firstMatch(uiLuaSource)!
        .group(1)!;
    final lua = RegExp(r'"(\w+)"').allMatches(list).map((m) => m[1]!).toSet();
    expect(lua, dart);
  });

  test('ui.d.tl declares every core widget', () {
    final teal = File('lua/types/flb/ui.d.tl').readAsStringSync();
    final declared = RegExp(
      r'^  (\w+): Constructor$',
      multiLine: true,
    ).allMatches(teal).map((m) => m[1]!).toSet();
    expect(declared, dart);
  });
}
