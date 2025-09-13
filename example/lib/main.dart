import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'package:flutter/material.dart';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart' as flb;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// 读版本
///
/// 读 code 读 a 和 b
int safeLoader(Pointer<flb.lua_State> l) {
  flb.bindings.luaL_openlibs(l);
  final luaVersion = flb.bindings.lua_version(l);

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
  var pointer = code.toPointChar();
  var luaCallState = flb.bindings.luaL_dostring(l, pointer);
  debugPrint('luaCallState: $luaCallState');
  if (luaCallState != 0) {
    debugPrint('dostring error: ${flb.bindings.lua_tostring(l, -1)}');
    flb.bindings.lua_pop(l, -1);
    return luaCallState;
  }
  flb.bindings.lua_pushnumber(l, luaVersion);

  flb.bindings.lua_getglobal(l, 'a'.toPointChar());
  final luaResult = flb.bindings.luaL_optinteger(l, 1, -1);
  flb.bindings.lua_pop(l, 1);
  flb.bindings.lua_pushinteger(l, luaResult);

  flb.bindings.lua_getglobal(l, 'b'.toNativeUtf8().cast<Char>());
  final luaResultb = flb.bindings.luaL_optinteger(l, 1, -1);
  flb.bindings.lua_pop(l, 1);
  flb.bindings.lua_pushinteger(l, luaResultb);

  return 3;
}

class _MyAppState extends State<MyApp> {
  num? luaVersion;
  int? fetchAValue;
  int? bValue;
  Duration? stopwatchDuration;

  void onPressed() {
    final l = flb.bindings.luaL_newstate();

    var dartFunction = Pointer.fromFunction<flb.lua_CFunctionFunction>(
      safeLoader,
      0,
    );
    flb.bindings.lua_pushcfunction(l, dartFunction);
    if (flb.bindings.lua_pcall(l, 0, 3, 0) case final stateCode
        when stateCode != 0) {
      debugPrint('dostring error: ${flb.bindings.lua_tostring(l, -1)}');
      flb.bindings.lua_pop(l, -1);
      return;
    }
    final luaResultb = flb.bindings.lua_isinteger(l, -3 + 2) != 0
        ? flb.bindings.lua_tointegerx(l, -3 + 2, nullptr)
        : 0;
    final luaResult = flb.bindings.lua_isinteger(l, -3 + 1) != 0
        ? flb.bindings.lua_tointegerx(l, -3 + 1, nullptr)
        : 0;
    final v = flb.bindings.lua_isnumber(l, -3 + 0) != 0
        ? flb.bindings.lua_tonumberx(l, -3 + 0, nullptr)
        : 0;

    setState(() {
      luaVersion = v;
      fetchAValue = luaResult;
      bValue = luaResultb;
    });
    flb.bindings.lua_close(l);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Native Packages')),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              spacing: 10,
              children: [
                const Text(
                  'This calls a native function through FFI that is shipped as source in the package. '
                  'The native code is built as part of the Flutter Runner build.',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'lua version = $luaVersion',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'fetch a value: $fetchAValue',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'fetch b value: $bValue',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'fetch duration: $stopwatchDuration',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(onPressed: onPressed),
      ),
    );
  }
}
