import 'dart:ffi';

import 'package:flutter/material.dart';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart'
    as flutter_lua_bridge;
import 'package:flutter_lua_bridge/flutter_lua_bridge_bindings_generated.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Pointer<lua_State> lNewstate;
  late double luaVersion;

  @override
  void initState() {
    super.initState();
    lNewstate = flutter_lua_bridge.bindings.luaL_newstate();
    luaVersion = flutter_lua_bridge.bindings.lua_version(lNewstate);
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Native Packages')),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Text(
                  'This calls a native function through FFI that is shipped as source in the package. '
                  'The native code is built as part of the Flutter Runner build.',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                Text(
                  'lua version = $luaVersion',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
