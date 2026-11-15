import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../generator/emitter.dart';
import '../generator/reader.dart';
import 'options.dart';

/// Emits codecs, Lua clients and Dart host registration for the `@LuaApi`
/// and `@DartApi` interfaces of a library.
class BridgeGenerator extends Generator {
  const BridgeGenerator(this.options);
  final BridgeOptions options;

  @override
  String? generate(LibraryReader library, BuildStep buildStep) {
    final schema = readBridgeSchema(
      library.element,
      name: options.contractName(buildStep.inputId.path),
      optimization: options.optimization,
    );
    return schema == null ? null : emitDart(schema);
  }
}
