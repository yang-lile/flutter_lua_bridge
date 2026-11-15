import '../generator/model.dart';

/// Options shared by the builders. Every builder accepts the same keys in
/// `build.yaml`, so one YAML anchor can configure all three.
class BridgeOptions {
  const BridgeOptions({
    this.contracts = 'lib/bridge',
    this.types = 'lua/types',
    this.sources = 'lua/src',
    this.output = 'assets/lua',
    this.optimization = BridgeOptimization.o1,
  });

  factory BridgeOptions.parse(Map<String, Object?> config) {
    const known = {'contracts', 'types', 'sources', 'output', 'optimization'};
    for (final key in config.keys) {
      if (!known.contains(key)) {
        throw ArgumentError('Unknown flutter_lua_bridge_codegen option: $key');
      }
    }
    String directory(String key, String fallback) {
      final value = config[key] ?? fallback;
      if (value is! String ||
          value.isEmpty ||
          value.startsWith('/') ||
          value.split('/').any((part) => part.isEmpty || part == '..')) {
        throw ArgumentError.value(
          value,
          key,
          'must be a directory relative to the package root',
        );
      }
      return value;
    }

    const defaults = BridgeOptions();
    final optimization = config['optimization'];
    return BridgeOptions(
      contracts: directory('contracts', defaults.contracts),
      types: directory('types', defaults.types),
      sources: directory('sources', defaults.sources),
      output: directory('output', defaults.output),
      optimization: optimization == null
          ? defaults.optimization
          : parseBridgeOptimization('$optimization'),
    );
  }

  /// Directory of the hand-written Dart contracts.
  final String contracts;

  /// Directory receiving the generated Teal declarations.
  final String types;

  /// Directory of the hand-written Teal and Lua sources.
  final String sources;

  /// Directory receiving the Lua files to ship.
  final String output;

  /// Safety level of `@LuaApi` interfaces that do not choose their own.
  final BridgeOptimization optimization;

  /// The contract name of a Dart library: its path below [contracts] with
  /// dots for directories, or just the file name when it lives elsewhere.
  String contractName(String path) {
    final withoutExtension = path.substring(0, path.length - '.dart'.length);
    if (withoutExtension.startsWith('$contracts/')) {
      return withoutExtension
          .substring(contracts.length + 1)
          .replaceAll('/', '.');
    }
    return withoutExtension.split('/').last;
  }
}
