// tools/verify_worker.dart
//
// 验证 LuaWorker 的实际行为。这是纯 Dart 入口，不依赖 GUI，
// 所以能在无 Flutter 引擎的环境里跑（flutter test 在受限环境下不可用）。
//
// 运行：dart run tools/verify_worker.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:lua_canvas_host/lua_modules.dart';
import 'package:lua_canvas_host/lua_worker.dart';

int _pass = 0;
int _fail = 0;

void check(String name, bool ok, [String? detail]) {
  if (ok) {
    _pass++;
    stderr.writeln('  PASS  $name${detail != null ? "  ($detail)" : ""}');
  } else {
    _fail++;
    stderr.writeln('  FAIL  $name${detail != null ? "  -> $detail" : ""}');
  }
}

Future<void> main() async {
  final root = loadLuaModulesFromDisk().root;
  final worker = LuaWorker(timeout: const Duration(seconds: 2));

  stderr.writeln('=== 1. 启动 ===');
  final sw = Stopwatch()..start();
  await worker.start(root);
  check('worker 就绪', worker.ready, '${sw.elapsedMilliseconds}ms');
  check('启动后不忙', !worker.busy);

  stderr.writeln('\n=== 2. 正常执行 ===');
  const good = '''
local c = canvas.new({ width = 200, height = 200, background = "#0f1116" })
c:circle(100, 100, 60, { fill = "#4a9eff" })
c:text(20, 180, "worker", { size = 14, color = "#ffffff" })
return json.encode(c:build())
''';
  sw.reset();
  var r = await worker.run(good);
  check('无错误', r.error == null, r.error);
  check('有结果', r.displayListJson != null);

  final list = jsonDecode(r.displayListJson!) as Map<String, dynamic>;
  check('图元数为 2', list['op_count'] == 2, '${list['op_count']}');
  check('尺寸正确', list['width'] == 200 && list['height'] == 200);
  check('Lua 耗时已上报', r.elapsedMicros > 0, '${r.elapsedMicros}us');
  stderr.writeln('    往返 ${sw.elapsedMilliseconds}ms');

  stderr.writeln('\n=== 3. 复用：连续执行不应变慢 ===');
  final times = <int>[];
  for (var i = 1; i <= 5; i++) {
    final t0 = sw.elapsedMilliseconds;
    final res = await worker.run(good.replaceAll('#4a9eff', '#${i}0a9ff'));
    times.add(sw.elapsedMilliseconds - t0);
    if (res.error != null) {
      check('第$i次执行', false, res.error);
    }
  }
  check('5 次全部成功', !worker.busy);
  check('第 5 次仍在 50ms 内', times.last < 50, '${times.last}ms');
  stderr.writeln('    逐次往返: ${times.join(', ')} ms');

  stderr.writeln('\n=== 4. 日志回传 ===');
  r = await worker.run('''
print("第一条", 42)
print("第二条")
local c = canvas.new({ width = 100, height = 100 })
c:circle(50, 50, 20, { fill = "#30a46c" })
return json.encode(c:build())
''');
  check('日志 2 条', r.logs.length == 2, '${r.logs}');
  if (r.logs.length >= 2) {
    check('第 1 条正确', r.logs[0] == '第一条 42', r.logs[0]);
    check('第 2 条正确', r.logs[1] == '第二条', r.logs[1]);
  }

  stderr.writeln('\n=== 5. Lua 报错回传 ===');
  r = await worker.run('''
local c = canvas.new({ width = 100, height = 100 })
c:circle(100, 100, "不是数字", { fill = "#4a9eff" })
return json.encode(c:build())
''');
  check('捕获到错误', r.error != null);
  check('错误信息含类型提示',
      r.error?.contains('must be a number') ?? false, r.error);
  check('出错时无结果', r.displayListJson == null);

  stderr.writeln('\n=== 6. 死循环 -> 超时，UI 不受影响 ===');
  // 看门狗：主 isolate 必须能按时跑自己的定时器。
  // 如果 Lua 跑在主 isolate 上，这 300ms 的定时器会被拖到 2 秒以后。
  var watchdogFired = false;
  var watchdogDelayMs = -1;
  final watchdogStart = DateTime.now();
  Timer(const Duration(milliseconds: 300), () {
    watchdogFired = true;
    watchdogDelayMs = DateTime.now().difference(watchdogStart).inMilliseconds;
  });

  sw.reset();
  r = await worker.run('local x = 0 while true do x = x + 1 end');
  final waited = sw.elapsedMilliseconds;
  // 等看门狗有机会触发
  await Future<void>.delayed(const Duration(milliseconds: 400));

  // 两��超时都可能赢，取决于机器负载：
  //
  //   a) Lua 的 guard 先到（正常情况）——1500ms 的预算，
  //      错误信息是「预算 1500ms」，worker **不用**重建
  //   b) 宿主超时先到（机器很忙时）——guard 用的是 os.clock()，
  //      那是 **CPU 时间**；负载高时 1500ms CPU 要拖很久才攒够，
  //      可能超过宿主那 4ms 墙钟超时，于是 worker 被丢弃重建
  //
  // (b) 不是 bug，是"进程被抢占了"的正确反应。所以断言要覆盖两条路，
  // 而不是假设 (a) 一定赢——那样在负载高的开发机上就会随机红。
  final guardWon = (r.error ?? '').contains('预算');
  stderr.writeln('  → 走的是 ${guardWon ? "Lua guard" : "宿主超时"}'
      '（${waited}ms）  错误原文: ${r.error ?? "(无)"}');

  check('返回超时错误', r.error?.contains('超时') ?? false, r.error);
  check('超时发生在预期窗口内', waited < 3500, '${waited}ms');
  check('主 isolate 定时器准时触发', watchdogFired,
      watchdogFired ? '实际延迟 ${watchdogDelayMs}ms' : '300ms 定时器从未触发');
  check('定时器未被拖到超时之后', watchdogFired && watchdogDelayMs < 1000,
      '$watchdogDelayMs');

  stderr.writeln('\n=== 7. 超时之后 worker 仍然健康 ===');
  // 关键不是"就绪"这个布尔值——guard 赢的时候一直是 true，
  // 宿主超时赢的时候会被丢弃重建、变 false。两条路都要能恢复。
  //
  // 值得肯定的是 (a)：guard 在 Lua 内部把死循环打断后，
  // isolate 本身是干净的，不需要 kill 一个卡在 FFI 里的 isolate。
  check('没有残留的挂起请求', !worker.busy);

  r = await worker.run(good);
  check('下一次执行正常', r.error == null, r.error);
  check('结果正确',
      (jsonDecode(r.displayListJson!) as Map)['op_count'] == 2);

  stderr.writeln('\n=== 8. 慢执行不阻塞后续编辑 ===');
  // guard 保证单次执行不超过 budgetMs。这里用较慢的正常代码
  // （而非死循环）验证：用户在它执行完之前又改了一版，
  // 后一版应该能立刻接管，前一版被标记为取代。
  final slowCode = '''
local c = canvas.new({ width = 300, height = 300 })
for i = 1, 400000 do c:circle(i % 300, 150, 1, { fill = "#4a9eff" }) end
return json.encode(c:build())
''';
  final slow = worker.run(slowCode);
  await Future<void>.delayed(const Duration(milliseconds: 20));

  sw.reset();
  final quick = await worker.run(good);
  check('后发请求正常完成', quick.error == null, quick.error);
  check('后发请求未等前一个跑完', sw.elapsedMilliseconds < 1000,
      '${sw.elapsedMilliseconds}ms');
  check('后发请求结果正确',
      (jsonDecode(quick.displayListJson!) as Map)['op_count'] == 2);

  final slowRes = await slow;
  check('前一个被标记为取代', slowRes.error?.contains('取代') ?? false,
      slowRes.error);
  check('取代后 worker 仍健康', worker.ready);

  stderr.writeln('\n=== 9. dispose 后不再接受请求 ===');
  worker.dispose();
  r = await worker.run(good);
  check('返回释放错误', r.error?.contains('释放') ?? false, r.error);

  stderr.writeln('\n$_pass passed, $_fail failed');
  if (_fail > 0) exit(1);
}
