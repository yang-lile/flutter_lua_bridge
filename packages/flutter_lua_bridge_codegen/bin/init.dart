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
-- For editor tooling only (for example the Teal language server).
-- `dart run build_runner build` compiles the sources with the Teal compiler
-- bundled in flutter_lua_bridge_codegen and does not read this file.
return {
  source_dir = "src",
  include_dir = { "src", "types" },
  gen_compat = "off",
}
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
  _write('lua/tlconfig.lua', _tlconfig);

  final manual = <String>[];
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
  lua/types/*.d.tl     generated Teal declarations
  assets/lua/*.lua     generated Lua to ship

Generate everything with:
  dart run build_runner build''');
  if (manual.isNotEmpty) {
    stdout.writeln('\nLeft for you:');
    for (final step in manual) {
      stdout.writeln('- ${step.replaceAll('\n', '\n  ')}');
    }
  }
}
