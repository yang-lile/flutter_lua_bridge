#!/usr/bin/env dart
// MCP 客户端脚本 - 用于与 Dart/Flutter MCP 服务器交互
// 用法: dart agents/scripts/mcp_client.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() async {
  final projectRoot = '/Users/lilua/workspace/gitss/flutter_lua_bridge';

  print('🔌 正在启动 Dart MCP 服务器...');

  // 启动 MCP 服务器
  final process = await Process.start('dart', [
    'mcp-server',
  ], workingDirectory: projectRoot);

  // 处理服务器输出
  process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(
    (line) {
      if (line.trim().isNotEmpty) {
        try {
          final response = jsonDecode(line);
          _handleResponse(response);
        } catch (e) {
          print('📤 服务器: $line');
        }
      }
    },
  );

  process.stderr.transform(utf8.decoder).listen((err) {
    if (err.trim().isNotEmpty) print('⚠️  错误: $err');
  });

  // 等待服务器启动
  await Future.delayed(Duration(milliseconds: 500));

  // 发送初始化请求
  print('\n📡 正在初始化 MCP 连接...');
  _sendRequest(process, 1, 'initialize', {
    'protocolVersion': '2024-11-05',
    'capabilities': {'tools': {}, 'resources': {}},
    'clientInfo': {'name': 'flutter_lua_bridge_mcp_client', 'version': '1.0'},
  });

  await Future.delayed(Duration(milliseconds: 500));

  // 获取工具列表
  print('\n🛠️  获取可用工具列表...');
  _sendRequest(process, 2, 'tools/list', {});

  await Future.delayed(Duration(milliseconds: 500));

  // 分析项目
  print('\n🔍 分析项目...');
  _sendRequest(process, 3, 'tools/call', {
    'name': 'dart_analyze',
    'arguments': {},
  });

  await Future.delayed(Duration(seconds: 2));

  // 获取项目信息
  print('\n📊 获取项目信息...');
  _sendRequest(process, 4, 'tools/call', {
    'name': 'dart_get_project_info',
    'arguments': {},
  });

  // 等待结果
  await Future.delayed(Duration(seconds: 3));

  print('\n👋 关闭连接...');
  process.kill();

  exit(0);
}

void _sendRequest(
  Process process,
  int id,
  String method,
  Map<String, dynamic> params,
) {
  final request = {
    'jsonrpc': '2.0',
    'id': id,
    'method': method,
    'params': params,
  };
  final jsonStr = jsonEncode(request);
  print('📤 发送: $jsonStr');
  process.stdin.writeln(jsonStr);
  process.stdin.flush();
}

void _handleResponse(Map<String, dynamic> response) {
  if (response.containsKey('result')) {
    final result = response['result'];
    if (result is Map && result.containsKey('tools')) {
      print('\n✅ 可用工具:');
      final tools = result['tools'] as List;
      for (final tool in tools) {
        print('   • ${tool['name']}: ${tool['description']}');
      }
    } else if (result is Map && result.containsKey('content')) {
      final content = result['content'] as List;
      for (final item in content) {
        if (item['type'] == 'text') {
          print('\n📄 结果:\n${item['text']}');
        }
      }
    } else {
      final jsonStr = jsonEncode(result);
      final displayStr = jsonStr.length > 200
          ? '${jsonStr.substring(0, 200)}...'
          : jsonStr;
      print('✅ 响应 [${response['id']}]: $displayStr');
    }
  } else if (response.containsKey('error')) {
    print('❌ 错误 [${response['id']}]: ${response['error']}');
  }
}
