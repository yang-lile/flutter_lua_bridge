import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter/services.dart';
import 'basic_api.g.dart';

typedef BridgeDemoResult = RandomResult;

/// Runs the generated typed API used by the Flutter home screen.
class BasicBridgeDemo {
  static Future<LuaCallResult<BridgeDemoResult>> run() async {
    final source = await rootBundle.loadString('lua/build/basic.lua');
    final lua = LuaRuntime.create();
    try {
      return BasicApi.load(runtime: lua, source: source).run();
    } finally {
      lua.close();
    }
  }
}
