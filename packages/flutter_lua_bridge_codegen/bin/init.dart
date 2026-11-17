// Sets up the conventional layout in the current package:
//
//     dart run flutter_lua_bridge_codegen:init
//
// Existing files are never overwritten.
import 'dart:io';

const _buildYaml = r'''
# build_runner reads only the directories listed under `sources`. This is its
# default list plus `lua/**`, where the Teal and Lua sources live.
targets:
  $default:
    sources:
      - $package$
      - pubspec.yaml
      - pubspec.lock
      - lib/**
      - lua/**
      - assets/**
      - bin/**
      - test/**
      - integration_test/**
      - tool/**
      - web/**
      - example/**
      - benchmark/**
''';

const _tlconfig = '''
-- Teal project settings for tools, read from the package root:
-- - the Teal language server (VS Code and other editors) reads tlconfig.lua
--   only from the folder that is opened, so it sits here, not in lua/;
-- - `dart run flutter_lua_bridge_codegen:run` uses include_dir and
--   source_dir to resolve require() for the entries in lua/test.
-- `dart run build_runner build` does not read it.
return {
  source_dir = "lua/src",
  include_dir = { "lua/src", "lua/types", "lua/test" },
  gen_compat = "off",
}
''';

const _main = '''
-- A scratch entry for trying the Lua side without the app:
--   dart run flutter_lua_bridge_codegen:run lua/test/main.tl -- some args
-- Add test entries next to it as *_test.tl or *_test.lua and run them all
-- with `dart run flutter_lua_bridge_codegen:run`. An entry passes when it
-- returns without raising an error.
--
-- require() finds this directory, lua/src and lua/types. A generated
-- <contract>_bridge module is stubbed here: bindXxx(t) returns t unchanged,
-- and getXxx() returns a table you fill with stand-ins for the Dart side.
print("Hello from " .. _VERSION, ...)
''';

void _write(String path, String content) {
  final file = File(path);
  if (file.existsSync()) {
    stdout.writeln('  kept     $path');
    return;
  }
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content.trimLeft());
  stdout.writeln('  created  $path');
}

void _directory(String path) {
  final directory = Directory(path);
  if (directory.existsSync()) {
    stdout.writeln('  kept     $path/');
    return;
  }
  directory.createSync(recursive: true);
  stdout.writeln('  created  $path/');
}

void main() {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln(
      'Run this command in a package directory (no pubspec.yaml).',
    );
    exitCode = 64;
    return;
  }
  _directory('lib/bridge');
  _directory('lua/src');
  _directory('lua/types');
  _directory('assets/lua');
  _write('tlconfig.lua', _tlconfig);
  _write('lua/test/main.tl', _main);

  final manual = <String>[];
  if (File('lua/tlconfig.lua').existsSync()) {
    manual.add(
      'Delete lua/tlconfig.lua: editors read tlconfig.lua only from the '
      'opened folder, which is now covered by ./tlconfig.lua.',
    );
  }
  if (File('build.yaml').existsSync()) {
    stdout.writeln('  kept     build.yaml');
    if (!File('build.yaml').readAsStringSync().contains('lua/**')) {
      manual.add(
        'Add `lua/**` to targets.\$default.sources in build.yaml, together '
        'with the directories you already build:\n$_buildYaml',
      );
    }
  } else {
    _write('build.yaml', _buildYaml);
  }

  final pubspec = File('pubspec.yaml').readAsStringSync();
  if (!pubspec.contains('assets/lua/')) {
    manual.add(
      'For a Flutter app, ship the compiled Lua by adding it to pubspec.yaml:\n'
      '\n'
      'flutter:\n'
      '  assets:\n'
      '    - assets/lua/\n',
    );
  }
  for (final dependency in const ['build_runner', 'flutter_lua_bridge']) {
    if (!RegExp('^  $dependency:', multiLine: true).hasMatch(pubspec)) {
      manual.add('Add `$dependency` to pubspec.yaml.');
    }
  }

  stdout.writeln('''

Layout:
  lib/bridge/*.dart    contracts you write (@LuaApi / @DartApi)
  lua/src/*.tl|*.lua   Teal or Lua implementations you write
  lua/test/*.tl|*.lua  entries to run the Lua side without the app
  lua/types/*.d.tl     generated Teal declarations
  assets/lua/*.lua     generated Lua to ship
  tlconfig.lua         editor settings for Teal

Generate everything with:
  dart run build_runner build

Run the entries in lua/test with:
  dart run flutter_lua_bridge_codegen:run [--watch] [file or directory]''');
  if (manual.isNotEmpty) {
    stdout.writeln('\nLeft for you:');
    for (final step in manual) {
      stdout.writeln('- ${step.replaceAll('\n', '\n  ')}');
    }
  }
}
