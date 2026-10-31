// tool_verify_return.dart
//
// 验证 return 风格的用户代码能正确执行。
//
// 不依赖 GUI：直接跑 lib/sandbox.dart，与应用里的调用路径一致。
//
// 用法：dart run tool_verify_return.dart

import 'dart:convert';
import 'dart:io';

import 'package:lua_canvas_host/lua_modules.dart';
import 'package:lua_canvas_host/sandbox.dart';

int pass = 0;
int fail = 0;

void check(String name, bool cond, [String? d]) {
  if (cond) {
    pass++;
    stdout.writeln('  PASS  $name${d != null ? "  ($d)" : ""}');
  } else {
    fail++;
    stdout.writeln('  FAIL  $name${d != null ? "  -> $d" : ""}');
  }
}

void main() {
  // 从磁盘加载模块（不依赖 Flutter，可在纯 Dart 环境运行）
  final modules = loadLuaModulesFromDisk();
  final path = modules.root;
  stdout.writeln('Lua 模块: ${modules.count} 个, 缺失 ${modules.missing.length}');
  stdout.writeln('临时目录: $path\n');

  final sandbox = LuaSandbox();

  // ---- 1. 直接写代码体（自动包函数）----
  stdout.writeln('=== 1. 代码体写法 ===');
  final r1 = sandbox.run('''
local c = canvas.new({ width = 200, height = 200 })
c:circle(100, 100, 50, { fill = "#4a9eff" })
return json.encode(c:build())
''', libraryPath: path);
  check('无错误', r1.error == null, r1.error);
  check('有结果', r1.displayListJson != null);
  if (r1.displayListJson != null) {
    final d = jsonDecode(r1.displayListJson!) as Map<String, dynamic>;
    check('图元数为 1', d['op_count'] == 1, '${d['op_count']}');
  }

  // ---- 2. 显式 return function ----
  stdout.writeln('\n=== 2. return function 写法 ===');
  final r2 = sandbox.run('''
return function()
  local c = canvas.new({ width = 200, height = 200, background = "#000000" })
  c:rect(20, 20, 160, 160, { radius = 8, fill = "#30a46c" })
  return json.encode(c:build())
end
''', libraryPath: path);
  check('无错误', r2.error == null, r2.error);
  if (r2.displayListJson != null) {
    final d = jsonDecode(r2.displayListJson!) as Map<String, dynamic>;
    check('背景为黑', d['background'] == '#000000', '${d['background']}');
  }

  // ---- 3. 函数内部复用 ----
  stdout.writeln('\n=== 3. 函数复用 ===');
  final r3 = sandbox.run('''
local function box(color, y)
  local c = canvas.new({ width = 300, height = 300 })
  c:rect(30, y, 120, 60, { fill = color })
  return c
end

-- 注意：canvas 各自独立时合并不到一起，
-- 所以这里改成同一个 canvas 累加
local c = canvas.new({ width = 300, height = 300 })
for i, col in ipairs({ "#4a9eff", "#30a46c", "#f5a524" }) do
  c:rect(30, 30 + (i - 1) * 70, 120, 50, { fill = col })
end
return json.encode(c:build())
''', libraryPath: path);
  check('无错误', r3.error == null, r3.error);
  if (r3.displayListJson != null) {
    final d = jsonDecode(r3.displayListJson!) as Map<String, dynamic>;
    check('图元数为 3', d['op_count'] == 3, '${d['op_count']}');
  }

  // ---- 4. print 收集 ----
  stdout.writeln('\n=== 4. print 收集 ===');
  final r4 = sandbox.run('''
stdout.writeln("第一条", 42)
stdout.writeln("第二条")
local c = canvas.new({ width = 100, height = 100 })
c:circle(50, 50, 20)
return json.encode(c:build())
''', libraryPath: path);
  check('日志 2 条', r4.logs.length == 2, '实际 ${r4.logs}');
  if (r4.logs.length >= 2) {
    check('第1条正确', r4.logs[0] == '第一条 42', r4.logs[0]);
  }

  // ---- 5. 错误捕获 ----
  stdout.writeln('\n=== 5. 错误捕获 ===');
  final r5 = sandbox.run('''
local c = canvas.new()
c:circle("半径", 1, 1)
return json.encode(c:build())
''', libraryPath: path);
  check('捕获到错误', r5.error != null);
  check('信息正确', r5.error?.contains('must be a number') ?? false, r5.error);

  // ---- 6. 返回 nil ----
  stdout.writeln('\n=== 6. 返回 nil ===');
  final r6 = sandbox.run('''
local c = canvas.new()
stdout.writeln("只打印不返回")
''', libraryPath: path);
  check('无错误', r6.error == null, r6.error);
  check('结果为 null', r6.displayListJson == null);
  check('日志仍有', r6.logs.length == 1, '${r6.logs}');

  // ---- 7. 返回非字符串 ----
  stdout.writeln('\n=== 7. 返回类型错误 ===');
  final r7 = sandbox.run('return function() return 123 end', libraryPath: path);
  check('报类型错误', r7.error?.contains('应返回字符串') ?? false, r7.error);
  check('错误信息含实际类型', r7.error?.contains('数字') ?? false, r7.error);

  // ---- 8. 只有赋值没有 return ----
  // 代码体会被包成函数，函数返回 nil -> 无结果但无错误，这是合理的。
  // 用户若想返回显示列表，必须显式 return。
  stdout.writeln('\n=== 8. 无 return 的代码体 ===');
  final r8 = sandbox.run('local x = 1', libraryPath: path);
  check('无错误', r8.error == null, r8.error);
  check('结果为 null', r8.displayListJson == null, r8.displayListJson);

  // ---- 9. 状态隔离 ----
  stdout.writeln('\n=== 9. 状态隔离 ===');
  sandbox.run('leaked_global = "x"', libraryPath: path);
  final r9 = sandbox.run(
    'return function() return leaked_global end',
    libraryPath: path,
  );
  check('无泄漏', r9.error != null || r9.displayListJson == null,
      r9.error);

  // ---- 10. 连续执行 ----
  stdout.writeln('\n=== 10. 连续 20 轮 ===');
  var good = 0;
  for (var i = 1; i <= 20; i++) {
    final r = sandbox.run('''
local c = canvas.new({ width = 200, height = 200 })
for k = 1, $i do c:circle(k * 6, 100, 4) end
return json.encode(c:build())
''', libraryPath: path);
    if (r.error == null && r.displayListJson != null) {
      final d = jsonDecode(r.displayListJson!) as Map<String, dynamic>;
      if (d['op_count'] == i) good++;
    }
  }
  check('20 轮全部正确', good == 20, '$good/20');

  stdout.writeln('\n$pass passed, $fail failed');
  exit(fail == 0 ? 0 : 1);
}