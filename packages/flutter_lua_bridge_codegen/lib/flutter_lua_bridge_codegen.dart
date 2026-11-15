/// The contract model and emitters behind the flutter_lua_bridge builders.
///
/// Applications do not import this library: they run `build_runner`, which
/// loads the builders from `builder.dart`.
library;

export 'src/generator/emitter.dart' show emitDart, emitLua, emitTeal;
export 'src/generator/model.dart';
export 'src/generator/reader.dart' show readBridgeSchema;
