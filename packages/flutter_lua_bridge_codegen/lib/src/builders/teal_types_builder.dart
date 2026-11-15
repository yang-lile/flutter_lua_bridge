import 'package:build/build.dart';

import '../generator/emitter.dart';
import '../generator/reader.dart';
import 'options.dart';

/// Writes `<types>/<contract>_bridge.d.tl` for every contract library below
/// the contracts directory.
class TealTypesBuilder implements Builder {
  TealTypesBuilder(this.options);
  final BridgeOptions options;

  @override
  late final Map<String, List<String>> buildExtensions = {
    '^${options.contracts}/{{}}.dart': ['${options.types}/{{}}_bridge.d.tl'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final input = buildStep.inputId;
    if (input.path.endsWith('.g.dart') ||
        !await buildStep.resolver.isLibrary(input)) {
      return;
    }
    final name = options.contractName(input.path);
    final schema = readBridgeSchema(
      await buildStep.inputLibrary,
      name: name,
      optimization: options.optimization,
    );
    if (schema == null) return;
    await buildStep.writeAsString(
      AssetId(
        input.package,
        '${options.types}/${name.replaceAll('.', '/')}_bridge.d.tl',
      ),
      emitTeal(schema),
    );
  }
}
