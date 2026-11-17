// Runs Lua and Teal entry files on LuaRuntime, outside the app:
//
//     dart run flutter_lua_bridge_codegen:run                  # lua/test
//     dart run flutter_lua_bridge_codegen:run lua/test/cards_test.tl
//     dart run flutter_lua_bridge_codegen:run lua/sandbox -- a b   # args
//     dart run flutter_lua_bridge_codegen:run --watch
//
// It generates nothing; the builders stay the only generator.
import 'dart:async';
import 'dart:io';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge_codegen/lua_runner.dart';
import 'package:path/path.dart' as p;

const _usage = '''
Usage: dart run flutter_lua_bridge_codegen:run [options] [target ...] [-- args]

Runs each target in a fresh Lua state. A target is a .tl or .lua file, or a
directory searched recursively for main.tl|lua and *_test.tl|lua. Without a
target, lua/test is run. An entry passes when it returns without raising an
error.

require() searches the entry's directory, then the include_dir and source_dir
of the nearest tlconfig.lua. Teal is type checked like in the build. A
<contract>_bridge module that has no file is stubbed: bindXxx(t) returns t,
and getXxx() returns a table to fill with stand-ins for the Dart functions.

Options:
  -w, --watch   Run again whenever a .tl or .lua file changes.
  -h, --help    Show this help.''';

Future<void> main(List<String> argv) async {
  final separator = argv.indexOf('--');
  final options = separator < 0 ? argv : argv.sublist(0, separator);
  final arguments = separator < 0
      ? const <String>[]
      : argv.sublist(separator + 1);
  var watch = false;
  final targets = <String>[];
  for (final option in options) {
    switch (option) {
      case '-h' || '--help':
        stdout.writeln(_usage);
        return;
      case '-w' || '--watch':
        watch = true;
      default:
        if (option.startsWith('-')) {
          stderr.writeln('Unknown option $option\n\n$_usage');
          exitCode = 64;
          return;
        }
        targets.add(option);
    }
  }
  if (targets.isEmpty) targets.add(p.join('lua', 'test'));

  final runner = LuaRunner();
  Future<bool> runAll() async {
    final List<String> entries;
    try {
      entries = LuaRunner.entries(targets);
    } on ArgumentError catch (error) {
      stderr.writeln('${error.invalidValue}: ${error.message}');
      return false;
    }
    if (entries.isEmpty) {
      stderr.writeln(
        'No main.tl|lua or *_test.tl|lua under ${targets.join(' ')}',
      );
      return false;
    }
    // `dart run` may leave its "Running build hooks..." line open.
    stdout.writeln('\n${LuaRuntime.luaRelease}');
    var failed = 0;
    for (final entry in entries) {
      final name = p.relative(entry);
      stdout.writeln('--- $name');
      final result = await runner.run(entry, arguments: arguments);
      final ms = result.elapsed.inMicroseconds / 1000;
      if (result.passed) {
        stdout.writeln('PASS $name (${ms.toStringAsFixed(1)} ms)');
      } else {
        failed++;
        stdout.writeln('FAIL $name\n${result.error}');
      }
    }
    stdout.writeln(
      failed == 0
          ? 'All ${entries.length} passed.'
          : '$failed of ${entries.length} failed.',
    );
    return failed == 0;
  }

  final passed = await runAll();
  if (!watch) {
    exitCode = passed ? 0 : 1;
    return;
  }

  // Re-run on changes below the targets' project roots, debounced.
  final roots = <String>{
    for (final target in targets)
      LuaRunner.project(
        FileSystemEntity.isDirectorySync(target)
            ? p.join(target, 'main.tl')
            : target,
      ).root,
  };
  stdout.writeln(
    'Watching ${roots.map(p.relative).join(', ')} (Ctrl-C to stop)',
  );
  Timer? pending;
  var running = false;
  for (final root in roots) {
    Directory(root).watch(recursive: true).listen((event) {
      if (!event.path.endsWith('.tl') && !event.path.endsWith('.lua')) return;
      pending?.cancel();
      pending = Timer(const Duration(milliseconds: 200), () async {
        if (running) return;
        running = true;
        stdout.writeln('\n=== ${p.relative(event.path)} changed');
        await runAll();
        running = false;
      });
    });
  }
}
