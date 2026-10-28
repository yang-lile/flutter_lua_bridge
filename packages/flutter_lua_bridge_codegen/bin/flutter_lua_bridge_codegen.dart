import 'dart:io';
import 'package:flutter_lua_bridge_codegen/flutter_lua_bridge_codegen.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('--help')) {
    stdout.writeln(
      'Usage: dart run flutter_lua_bridge_codegen --input bridge/api.dart [-O1|-O2|-O3] [--check]',
    );
    if (args.isEmpty) exitCode = 64;
    return;
  }
  try {
    final options = <String, String>{};
    var check = false;
    BridgeOptimization? optimization;
    for (var i = 0; i < args.length; i++) {
      if (args[i] == '--check') {
        check = true;
        continue;
      }
      if (args[i] == '-O1' || args[i] == '-O2' || args[i] == '-O3') {
        if (optimization != null) {
          throw FormatException('Duplicate optimization option');
        }
        optimization = parseBridgeOptimization(args[i].substring(1));
        continue;
      }
      if (args[i] == '--opt-level') {
        if (i + 1 >= args.length || optimization != null) {
          throw FormatException('Unknown or incomplete option: --opt-level');
        }
        optimization = parseBridgeOptimization(args[++i]);
        continue;
      }
      if (![
            '--input',
            '--dart-out',
            '--lua-out',
            '--teal-out',
          ].contains(args[i]) ||
          i + 1 >= args.length) {
        throw FormatException('Unknown or incomplete option: ${args[i]}');
      }
      final option = args[i];
      if (options.containsKey(option)) {
        throw FormatException('Duplicate option $option');
      }
      options[option] = args[++i];
    }
    final input = options['--input'];
    if (input == null) throw FormatException('--input is required');
    var schema = parseBridgeSchema(await File(input).readAsString());
    if (optimization != null) schema = schema.withOptimization(optimization);
    final outputs = <String, String>{};
    for (final item in [
      ('dartOut', '--dart-out', emitDart(schema)),
      ('luaOut', '--lua-out', emitLua(schema)),
      ('tealOut', '--teal-out', emitTeal(schema)),
    ]) {
      final path = options[item.$2] ?? schema.outputs[item.$1];
      if (path == null || path.isEmpty) {
        throw FormatException(
          'Specify ${item.$2} or @ConfigureLuaBridge(${item.$1}: ...)',
        );
      }
      final absolute = File.fromUri(
        File(path).absolute.uri.normalizePath(),
      ).path;
      if (absolute ==
              File.fromUri(File(input).absolute.uri.normalizePath()).path ||
          outputs.containsKey(absolute)) {
        throw FormatException(
          'Output paths must be distinct and different from the input',
        );
      }
      outputs[absolute] = item.$3;
    }
    // Complete parsing/validation/emission before writing any artifacts.
    for (final entry in outputs.entries) {
      final file = File(entry.key);
      if (check) {
        if (!await file.exists() || await file.readAsString() != entry.value) {
          throw FormatException('Generated artifact is stale: ${file.path}');
        }
      } else {
        await file.parent.create(recursive: true);
        await file.writeAsString(entry.value);
        stdout.writeln('Generated ${file.path}');
      }
    }
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
