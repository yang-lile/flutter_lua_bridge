// lib/driver_main.dart
//
// 带 flutter_driver 扩展的入口，供交互测试与 MCP 驱动使用。
//
// 单独一个入口而不是在 main.dart 里用开关：driver_extension 属于
// 交互测试设施，不该出现在正式入口的 import 里（flutter_driver 也不是
// 运行时依赖）。
//
// ```sh
// flutter run -t lib/driver_main.dart
// ```
// 连上之后就能用真实点击驱动界面：
// `flutter_driver` / MCP 的 `flutter_driver_command`。

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'main.dart' show StudioApp;

void main() {
  enableFlutterDriverExtension();
  runApp(const StudioApp());
}
