import 'package:flutter/material.dart';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'bridge/basic_bridge_demo.dart';
import 'game/game_demo_page.dart';

void main() {
  runApp(const MyApp());
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
    try {
      final result = BasicBridgeDemo.run();
      setState(() {
        luaVersion = result.luaVersion;
        fetchAValue = result.a;
        bValue = result.b;
      });
    } catch (e) {
      debugPrint('Bridge demo error: $e');
    }
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
                const Text('Flutter Lua Bridge - 测试列表', style: textStyle, textAlign: TextAlign.center),
                const Text(
                  '点击下方列表项运行对应测试',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const Divider(),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.code, color: Colors.blue),
                    title: const Text('Bridge 基础测试'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lua version = $luaVersion'),
                        Text('Random value A: $fetchAValue'),
                        Text('Random value B: $bValue'),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.green),
                      onPressed: onPressed,
                      tooltip: '运行 Bridge 测试',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.gamepad, color: Colors.orange),
                    title: const Text('抽卡战斗游戏测试'),
                    subtitle: const Text('加载 Lua 卡牌配置并运行战斗模拟'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GameDemoPage()));
                    },
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}
