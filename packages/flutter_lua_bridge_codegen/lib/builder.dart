/// build_runner entry points; see `build.yaml`.
library;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/builders/bridge_generator.dart';
import 'src/builders/options.dart';
import 'src/builders/teal_builder.dart';
import 'src/builders/teal_types_builder.dart';

/// Generates the Dart side of a contract into the library's `.g.dart` part.
Builder bridgeBuilder(BuilderOptions options) => SharedPartBuilder([
  BridgeGenerator(BridgeOptions.parse(options.config)),
], 'flutter_lua_bridge');

/// Generates the Teal declarations of a contract.
Builder tealTypesBuilder(BuilderOptions options) =>
    TealTypesBuilder(BridgeOptions.parse(options.config));

/// Type-checks Teal sources and compiles them to Lua; copies Lua sources.
Builder tealBuilder(BuilderOptions options) =>
    TealBuilder(BridgeOptions.parse(options.config));
