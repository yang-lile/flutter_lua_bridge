import 'package:flutter_lua_bridge_codegen_annotation/flutter_lua_bridge_codegen_annotation.dart';

class RandomResult {
  const RandomResult({
    required this.luaVersion,
    required this.a,
    required this.b,
  });
  final int luaVersion;
  final int a;
  final int b;
}

@ConfigureLuaBridge(
  dartOut: 'lib/bridge/basic_api.g.dart',
  luaOut: 'lua/src/basic_bridge.lua',
  tealOut: 'lua/src/basic_bridge.d.tl',
)
@LuaApi(module: 'basic')
abstract class BasicApi {
  RandomResult run();
}
