import 'package:build/build.dart';
import 'package:glob/glob.dart';

import 'options.dart';
import 'teal_worker_client.dart';

/// Compiles `<sources>/**.tl` to `<output>/**.lua` after type-checking it
/// against the other sources and the generated declarations, and copies
/// hand-written `<sources>/**.lua` unchanged.
class TealBuilder implements Builder {
  TealBuilder(this.options);
  final BridgeOptions options;

  @override
  late final Map<String, List<String>> buildExtensions = {
    '^${options.sources}/{{}}.tl': ['${options.output}/{{}}.lua'],
    '^${options.sources}/{{}}.lua': ['${options.output}/{{}}.lua'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final input = buildStep.inputId;
    final relative = input.path.substring(options.sources.length + 1);
    if (relative.endsWith('.d.tl')) return; // declarations produce no Lua
    final output = AssetId(
      input.package,
      '${options.output}/${relative.replaceFirst(RegExp(r'\.(tl|lua)$'), '')}.lua',
    );
    final source = await buildStep.readAsString(input);
    if (relative.endsWith('.lua')) {
      await buildStep.writeAsString(output, source);
      return;
    }
    // Everything a Teal source can require; reading it also makes this step
    // rerun when a declaration or sibling module changes.
    final modules = <String, Map<String, Map<String, String>>>{};
    for (final root in {options.sources, options.types}) {
      await for (final asset in buildStep.findAssets(Glob('$root/**'))) {
        if (asset == input) continue;
        final path = asset.path.substring(root.length + 1);
        final kind = const [
          '.d.tl',
          '.tl',
          '.lua',
        ].where(path.endsWith).firstOrNull;
        if (kind == null) continue;
        final module = path
            .substring(0, path.length - kind.length)
            .replaceAll('/', '.');
        (modules[module] ??= {})[kind.substring(1)] = {
          'path': asset.path,
          'source': await buildStep.readAsString(asset),
        };
      }
    }
    final worker = await buildStep.fetchResource(tealWorker);
    final result = await worker.compile(
      path: input.path,
      source: source,
      modules: modules,
    );
    if (result.errors.isNotEmpty) {
      // Severe messages fail the build; no Lua is written for this source.
      log.severe('Teal errors:\n${result.errors.join('\n')}');
      return;
    }
    await buildStep.writeAsString(output, result.lua!);
  }
}
