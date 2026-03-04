import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'package:flutter/material.dart';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart' as flb;
import 'game/game_demo_page.dart';

void main() {
  runApp(const MyApp());
}

/// 基础 FFI 调用示例
int safeLoader(Pointer<flb.lua_State> l) {
  flb.luaL_openlibs(l);
  final luaVersion = flb.lua_version(l);

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

  // 使用新的 LuaStateX 扩展方法
  final result = l.doString(code);
  if (result != flb.LuaStatus.OK) {
    final error = l.toLuaString(-1);
    l.pop(1);
    debugPrint('Lua error: $error');
    return result;
  }

  flb.lua_pushnumber(l, luaVersion);

  // 获取全局变量
  final ptrA = 'a'.toPointerChar();
  try {
    flb.lua_getglobal(l, ptrA);
    final luaResult = flb.luaL_optinteger(l, -1, -1);
    l.pop(1);
    flb.lua_pushinteger(l, luaResult);
  } finally {
    calloc.free(ptrA);
  }

  final ptrB = 'b'.toPointerChar();
  try {
    flb.lua_getglobal(l, ptrB);
    final luaResultb = flb.luaL_optinteger(l, -1, -1);
    l.pop(1);
    flb.lua_pushinteger(l, luaResultb);
  } finally {
    calloc.free(ptrB);
  }

  return 3;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  num? luaVersion;
  int? fetchAValue;
  int? bValue;

  void onPressed() {
    final l = flb.luaL_newstate();

    var dartFunction = Pointer.fromFunction<flb.lua_CFunctionFunction>(safeLoader, 0);
    flb.lua_pushcclosure(l, dartFunction, 0);

    final stateCode = flb.lua_pcallk(l, 0, 3, 0, 0, nullptr);
    if (stateCode != flb.LuaStatus.OK) {
      final error = l.toLuaString(-1);
      l.pop(1);
      debugPrint('Error: $error');
      return;
    }

    final luaResultb = flb.lua_isinteger(l, -3 + 2) != 0 ? flb.lua_tointegerx(l, -3 + 2, nullptr) : 0;
    final luaResult = flb.lua_isinteger(l, -3 + 1) != 0 ? flb.lua_tointegerx(l, -3 + 1, nullptr) : 0;
    final v = flb.lua_isnumber(l, -3 + 0) != 0 ? flb.lua_tonumberx(l, -3 + 0, nullptr) : 0;

    setState(() {
      luaVersion = v;
      fetchAValue = luaResult;
      bValue = luaResultb;
    });
    flb.lua_close(l);
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Lua Bridge Demo'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GameDemoPage()));
            },
            child: const Text('游戏Demo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            spacing: 10,
            children: [
              const Text('Flutter Lua Bridge - FFI Example', style: textStyle, textAlign: TextAlign.center),
              const Text(
                'This example demonstrates FFI integration with Lua',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const Divider(),
              Text('Lua version = $luaVersion', style: textStyle, textAlign: TextAlign.center),
              Text('Random value A: $fetchAValue', style: textStyle, textAlign: TextAlign.center),
              Text('Random value B: $bValue', style: textStyle, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GameDemoPage()));
                },
                icon: const Icon(Icons.gamepad),
                label: const Text('打开抽卡战斗游戏 Demo'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: onPressed, child: const Icon(Icons.play_arrow)),
    );
  }
}
