import 'dart:io';

import 'package:flutter_lua_bridge_ui/flutter_lua_bridge_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The core widget names must agree in the Dart registry, the
/// `CORE` list of `lua/flb/ui.lua` and the Teal declarations, and the
/// embedded Lua modules must match `lua/`.
void main() {
  final dart = coreLibrary().widgets.keys.toSet();

  test('the Lua module has a constructor for every widget', () {
    final source = File('lua/flb/ui.lua').readAsStringSync();
    final list = RegExp(r'local CORE = \{([^}]*)\}')
        .firstMatch(source)!
        .group(1)!;
    final lua = RegExp(r'"([\w.]+)"')
        .allMatches(list)
        .map((m) => m[1]!)
        .toSet();
    expect(lua, dart);
  });

  test('the Teal declarations declare every widget', () {
    expect(
      declaredWidgets(
        File('lua/types/flb/ui/prelude.d.tl').readAsStringSync(),
        File('lua/types/flb/ui.d.tl').readAsStringSync(),
      ),
      dart,
    );
  });

  test('the Lua module and Teal declare every host function', () {
    final source = File('lua/flb/ui.lua').readAsStringSync();
    final list = RegExp(
      r'local CORE_FUNCTIONS = \{([^}]*)\}',
    ).firstMatch(source)!.group(1)!;
    final functions = coreLibrary().functions.keys.toSet();
    expect(
      RegExp(r'"([\w.]+)"').allMatches(list).map((m) => m[1]!).toSet(),
      functions,
    );
    final navigator = RegExp(
      r'record NavigatorType\n(.*?)\n  end',
      dotAll: true,
    ).firstMatch(File('lua/types/flb/ui.d.tl').readAsStringSync())!;
    expect(
      RegExp(r'^    (\w+): function', multiLine: true)
          .allMatches(navigator.group(1)!)
          .map((m) => 'Navigator.${m[1]}')
          .toSet(),
      functions,
    );
  });

  test('the embedded Lua modules match lua/', () {
    expect(
      uiLuaModules,
      luaFiles(),
      reason: 'run: dart run tool/embed_lua.dart packages/flutter_lua_bridge_ui uiLuaModules',
    );
  });
}

/// The widgets that [prelude] declares as globals, with the named
/// constructors of their `<Widget>Constructor` records in [module].
Set<String> declaredWidgets(String prelude, String module) {
  final declared = <String>{};
  final global = RegExp(
    r'^global (\w+): (?:\w+\.(\w+)Constructor|function\(args: \w+\.\w+Args\))',
    multiLine: true,
  );
  for (final match in global.allMatches(prelude)) {
    final name = match[1]!;
    declared.add(name);
    if (match[2] == null) continue;
    final constructor = RegExp(
      'record ${name}Constructor\\n(.*?)\\n  end',
      dotAll: true,
    ).firstMatch(module)!;
    for (final named in RegExp(
      r'^    (\w+): function',
      multiLine: true,
    ).allMatches(constructor.group(1)!)) {
      declared.add('$name.${named[1]}');
    }
  }
  return declared;
}

/// `lua/**/*.lua` outside `lua/test*`, by module name.
Map<String, String> luaFiles() => {
  for (final file in Directory(
    'lua',
  ).listSync(recursive: true).whereType<File>())
    if (file.path.endsWith('.lua') && !file.path.startsWith('lua/test'))
      file.path.substring(4, file.path.length - 4).replaceAll('/', '.'): file
          .readAsStringSync(),
};
