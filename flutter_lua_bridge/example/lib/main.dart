import 'package:flutter/material.dart';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late int versionNumber;

  @override
  void initState() {
    super.initState();
    versionNumber = kLuaVersionReleaseNum;
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Flutter Lua Bridge')),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Text(
                  'Flutter Lua Bridge - FFI bindings for Lua C API',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                Text(
                  'Lua Version: $versionNumber',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                const Text(
                  'Type Enums:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                ...FlbType.values.map((type) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${type.name}: ${type.value}'),
                )),
                spacerSmall,
                const Text(
                  'Status Enums:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                ...FlbStatus.values.map((status) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${status.name}: ${status.value}'),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
