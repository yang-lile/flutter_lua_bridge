import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

/// 基础 FFI 调用示例函数，作为 lua_CFunction 注册到 Lua 中
int safeLoader(Pointer<lua_State> l) {
  FlutterLuaBridge.auxApi.luaL_openlibs(l);
  final luaVersion = FlutterLuaBridge.cApi.lua_version(l);

  String code = '''
function functionalRandom()
    local seed = tonumber(tostring(os.time()):reverse():sub(1,6))
    return function(low, up)
        math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)) )
        seed = math.random(low, up)
        return seed
    end
end
r = functionalRandom()
      a = r(1, 1024)
      b = r(1, 1024)
      print(a,b)
      ''';

  // 执行 Lua 代码
  final result = FlutterLuaBridge.auxApi.luaL_dostring(l, code.toNativeUtf8().cast<Char>());
  if (LuaStatusCode(result).isError) {
    final error = FlutterLuaBridge.auxApi.luaL_tolstring(l, -1, nullptr);
    FlutterLuaBridge.cApi.lua_pop(l, 1);
    debugPrint('Lua error: $error');
    return result;
  }

  FlutterLuaBridge.cApi.lua_pushnumber(l, luaVersion);

  // 获取全局变量
  final ptrA = 'a'.toNativeUtf8().cast<Char>();
  try {
    FlutterLuaBridge.cApi.lua_getglobal(l, ptrA);
    final luaResult = FlutterLuaBridge.auxApi.luaL_optinteger(l, -1, -1);
    FlutterLuaBridge.cApi.lua_pop(l, 1);
    FlutterLuaBridge.cApi.lua_pushinteger(l, luaResult);
  } finally {
    calloc.free(ptrA);
  }

  final ptrB = 'b'.toNativeUtf8().cast<Char>();
  try {
    FlutterLuaBridge.cApi.lua_getglobal(l, ptrB);
    final luaResultb = FlutterLuaBridge.auxApi.luaL_optinteger(l, -1, -1);
    FlutterLuaBridge.cApi.lua_pop(l, 1);
    FlutterLuaBridge.cApi.lua_pushinteger(l, luaResultb);
  } finally {
    calloc.free(ptrB);
  }

  return 3;
}

/// Bridge 基础演示结果
class BridgeDemoResult {
  final num luaVersion;
  final int a;
  final int b;

  const BridgeDemoResult({
    required this.luaVersion,
    required this.a,
    required this.b,
  });
}

/// Bridge 基础演示
class BasicBridgeDemo {
  /// 运行基础 FFI 调用示例
  static BridgeDemoResult run() {
    final l = FlutterLuaBridge.auxApi.luaL_newstate();
    try {
      final dartFunction = Pointer.fromFunction<lua_CFunctionFunction>(safeLoader, 0);
      FlutterLuaBridge.cApi.lua_pushcclosure(l, dartFunction, 0);

      final stateCode = FlutterLuaBridge.cApi.lua_pcallk(l, 0, 3, 0, 0, nullptr);
      if (LuaStatusCode(stateCode).isError) {
        final error = FlutterLuaBridge.auxApi.luaL_tolstring(l, -1, nullptr);
        FlutterLuaBridge.cApi.lua_pop(l, 1);
        debugPrint('Error: $error');
        throw Exception('Lua error: $error');
      }

      final bValue = FlutterLuaBridge.cApi.lua_isinteger(l, -3 + 2) != 0
          ? FlutterLuaBridge.cApi.lua_tointegerx(l, -3 + 2, nullptr)
          : 0;
      final aValue = FlutterLuaBridge.cApi.lua_isinteger(l, -3 + 1) != 0
          ? FlutterLuaBridge.cApi.lua_tointegerx(l, -3 + 1, nullptr)
          : 0;
      final version = FlutterLuaBridge.cApi.lua_isnumber(l, -3 + 0) != 0
          ? FlutterLuaBridge.cApi.lua_tonumberx(l, -3 + 0, nullptr)
          : 0;

      return BridgeDemoResult(luaVersion: version, a: aValue, b: bValue);
    } finally {
      FlutterLuaBridge.cApi.lua_close(l);
    }
  }
}
