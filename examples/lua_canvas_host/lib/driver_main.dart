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
// flutter drive -t lib/driver_main.dart --driver test_driver/studio_test.dart -d macos
// ```
// 连上之后就能用真实点击驱动界面：
// `flutter_driver` / MCP 的 `flutter_driver_command`。
//
// 框架错误（FlutterError，含布局溢出）和未捕获的异步错误会被记录下来，
// 驱动端用 `requestData('errors')` 取回（JSON 数组），
// `requestData('clear_errors')` 清空。Lua 脚本自身的报错显示在错误卡片里，
// 属于正常产出，不计入。

import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'main.dart' show StudioApp;

final _errors = <String>[];

void main() {
  enableFlutterDriverExtension(
    handler: (message) async {
      switch (message) {
        case 'errors':
          return jsonEncode(_errors);
        case 'clear_errors':
          _errors.clear();
          return '[]';
      }
      return '';
    },
  );

  final present = FlutterError.onError;
  FlutterError.onError = (details) {
    _errors.add(details.toString());
    present?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    _errors.add('$error\n$stack');
    return false; // 仍按默认方式打印
  };

  runApp(const StudioApp());
}
