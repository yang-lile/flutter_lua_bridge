import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

part 'basic_api.g.dart';

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

@LuaApi(module: 'basic')
abstract class BasicApi {
  RandomResult run();
}
