// Flutter Lua Bridge - 简化版 API 使用示例
//
// 运行方式：dart run example/simple_example.dart

import 'package:flutter_lua_bridge/lua_simple_api.dart';

void main() {
  print('=== Flutter Lua Bridge - Simple API Demo ===\n');

  // 1. 基本表达式求值
  print('1. 基本表达式求值:');
  print('  1 + 1 = ${lua.eval('1 + 1')}');
  print('  10 * 5 = ${lua.eval('10 * 5')}');
  print('  2 ^ 10 = ${lua.eval('2 ^ 10')}');
  print('');

  // 2. 字符串操作
  print('2. 字符串操作:');
  print('  "Hello" = ${lua.eval('"Hello"')}');
  print('  concat = ${lua.eval('"Hello" .. " " .. "World"')}');
  print('');

  // 3. 设置和获取变量
  print('3. 变量操作:');
  lua.set('name', 'John');
  lua.set('age', 30);
  print('  name = ${lua.get('name')}');
  print('  age = ${lua.get('age')}');
  print('  has("name") = ${lua.has('name')}');
  print('  has("nonexistent") = ${lua.has('nonexistent')}');
  print('');

  // 4. 执行多行代码
  print('4. 执行多行代码:');
  lua.exec('''
    function factorial(n)
      if n <= 1 then
        return 1
      else
        return n * factorial(n - 1)
      end
    end
  ''');
  print('  factorial(5) = ${lua.call('factorial', [5])}');
  print('  factorial(10) = ${lua.call('factorial', [10])}');
  print('');

  // 5. 函数调用
  print('5. 函数调用:');
  lua.exec('function add(a, b) return a + b end');
  lua.exec('function greet(name) return "Hello, " .. name end');
  print('  add(10, 20) = ${lua.call('add', [10, 20])}');
  print('  greet("Lua") = ${lua.call('greet', ['Lua'])}');
  print('');

  // 6. 多返回值
  print('6. 多返回值:');
  lua.exec('function multi() return 1, 2, 3 end');
  final results = lua.callMulti('multi', [], 3);
  print('  multi() = $results');
  print('');

  // 7. 表操作
  print('7. 表操作:');
  lua.exec('config = {host = "localhost", port = 8080, debug = true}');
  final config = lua.getTable('config');
  print('  config.host = ${config['host']}');
  print('  config.port = ${config['port']}');
  print('  config.debug = ${config['debug']}');
  config.dispose();
  print('');

  // 8. 创建 Dart 表并传递给 Lua
  print('8. Dart 表操作:');
  final person = lua.createTable({
    'name': 'Alice',
    'age': 25,
    'city': 'New York',
  });
  print('  person.name = ${person['name']}');
  print('  person.age = ${person['age']}');
  person['email'] = 'alice@example.com';
  print('  person.email (added) = ${person['email']}');
  print('  All keys: ${person.keys}');
  print('  To Map: ${person.toMap()}');
  person.dispose();
  print('');

  // 9. 斐波那契数列
  print('9. 斐波那契数列:');
  lua.exec('''
    function fib(n)
      if n <= 1 then return n end
      return fib(n - 1) + fib(n - 2)
    end
  ''');
  print('  fib(0) = ${lua.call('fib', [0])}');
  print('  fib(1) = ${lua.call('fib', [1])}');
  print('  fib(10) = ${lua.call('fib', [10])}');
  print('  fib(20) = ${lua.call('fib', [20])}');
  print('');

  // 10. 闭包
  print('10. 闭包 (Counter):');
  lua.exec('''
    function makeCounter()
      local count = 0
      return function()
        count = count + 1
        return count
      end
    end
    counter = makeCounter()
  ''');
  print('  counter() = ${lua.call('counter', [])}');
  print('  counter() = ${lua.call('counter', [])}');
  print('  counter() = ${lua.call('counter', [])}');
  print('');

  // 11. 错误处理
  print('11. 错误处理:');
  try {
    lua.eval('error("This is a test error")');
  } catch (e) {
    print('  Caught error: $e');
  }
  print('');

  // 12. 版本信息
  print('12. 版本信息:');
  print('  Lua version: ${lua.version}');
  print('');

  print('=== Demo completed successfully! ===');

  // 清理资源
  lua.dispose();
}
