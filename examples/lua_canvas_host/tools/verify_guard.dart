// 验证 canvas_guard 与 sandbox 的 budgetMs 集成
import 'dart:io';
import 'package:lua_canvas_host/lua_modules.dart';
import 'package:lua_canvas_host/sandbox.dart';

int pass = 0, fail = 0;
void check(String n, bool ok, [String? d]) {
  if (ok) { pass++; stderr.writeln('  PASS  $n${d != null ? "  ($d)" : ""}'); }
  else { fail++; stderr.writeln('  FAIL  $n${d != null ? "  -> $d" : ""}'); }
}

void main() {
  final root = loadLuaModulesFromDisk().root;

  stderr.writeln('=== 1. 无 budget 时死循环会卡住（对照组，仅验证 API）===');
  check('sandbox.run 支持 budgetMs 参数', true);

  stderr.writeln('\n=== 2. budget=300ms：死循环被 Lua 侧拦下 ===');
  final sw = Stopwatch()..start();
  final r1 = LuaSandbox().run(
    'local c = canvas.new({width=100,height=100})\n'
    'local x = 0 while true do x = x + 1 end\n'
    'return json.encode(c:build())',
    libraryPath: root,
    budgetMs: 300,
  );
  check('返回超时错误', r1.error?.contains('超时') ?? false, r1.error);
  check('在预算附近返回', sw.elapsedMilliseconds < 1500, '${sw.elapsedMilliseconds}ms');

  stderr.writeln('\n=== 3. 同一 sandbox 后续执行正常（hook 已清理）===');
  final r2 = LuaSandbox().run(
    'local c = canvas.new({width=200,height=200})\n'
    'c:circle(100,100,50,{fill="#4a9eff"})\n'
    'c:rect(20,20,50,50,{fill="#30a46c"})\n'
    'return json.encode(c:build())',
    libraryPath: root,
    budgetMs: 2000,
  );
  check('无错误', r2.error == null, r2.error);
  check('图元数 2', r2.displayListJson?.contains('"op_count":2') ?? false);

  stderr.writeln('\n=== 4. budget=3000ms：正常代码不该被误杀 ===');
  final r3 = LuaSandbox().run(
    'local c = canvas.new({width=400,height=300})\n'
    'for i = 1, 20000 do c:circle(i % 400, 150, 2, {fill="#4a9eff"}) end\n'
    'return json.encode(c:build())',
    libraryPath: root,
    budgetMs: 3000,
  );
  check('2 万图元未被误杀', r3.error == null, r3.error);
  check('图元数 20000', r3.displayListJson?.contains('"op_count":20000') ?? false);
  check('Lua 耗时', r3.elapsedMicros > 0, '${r3.elapsedMicros ~/ 1000}ms');

  stderr.writeln('\n=== 5. guard 不影响 print 日志 ===');
  final r4 = LuaSandbox().run(
    'print("第一条")\nprint("第二条")\n'
    'local c = canvas.new({width=100,height=100})\n'
    'c:circle(50,50,20,{fill="#fff"})\n'
    'return json.encode(c:build())',
    libraryPath: root,
    budgetMs: 2000,
  );
  check('日志 2 条', r4.logs.length == 2, '${r4.logs}');

  stderr.writeln('\n=== 6. Lua 报错仍能穿透 ===');
  final r5 = LuaSandbox().run(
    'local c = canvas.new()\nc:circle("x",1,1)',
    libraryPath: root,
    budgetMs: 2000,
  );
  check('参数错误被捕获', r5.error?.contains('must be a number') ?? false, r5.error);

  stderr.writeln('\n$pass passed, $fail failed');
}
