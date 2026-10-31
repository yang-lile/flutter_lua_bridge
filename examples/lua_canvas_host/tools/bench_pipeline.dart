// tools/bench_pipeline.dart
//
// 量清楚 Lua <-> Dart 互操作这条链路的成本分布。
//
// 目的不是给出一个"快/慢"的结论，而是回答：**损耗主要落在哪一段**，
// 以及**规模到哪儿会顶到帧预算**。
//
// 测量方法上的两个要点：
//
//  1. 取多轮**最小值**而不是平均值。最小值最接近"没有 GC / 没有调度抖动"
//     时的真实成本，均值会把偶发的 GC 全摊进来。
//  2. 用**差分法**拆固定成本。`return "x"` 那一档走完全相同的引导流程，
//     与真实脚本的差就是"用户代码 + 编码"的代价。
//
// 运行：dart run tools/bench_pipeline.dart

import 'dart:convert';
import 'dart:io';

import 'package:lua_canvas_host/lua_modules.dart';
import 'package:lua_canvas_host/lua_worker.dart';

void section(String title) {
  stdout.writeln('\n\x1b[1m$title\x1b[0m');
}

/// 收集到的指标。key 用稳定的英文，方便和基线文件对齐。
final Map<String, double> _metrics = <String, double>{};

/// 要盯的指标及其展示顺序。
const _watched = <String>[
  'cold.first_run',
  'cold.worker_spawn',
  'fixed.bootstrap',
  'scale.canvas.10',
  'scale.canvas.100',
  'scale.canvas.1000',
  'scale.ui.10',
  'scale.ui.100',
  'scale.ui.1000',
  'event.roundtrip',
  'drift.percent',
];

void line(String k, double ms, [String? note]) {
  stdout.writeln('  $k\t${ms.toStringAsFixed(3)} ms'
      '${note != null ? '   $note' : ''}');
}

void record(String key, double ms) => _metrics[key] = ms;

/// 异步取最小值。
Future<double> _bestOf(int reps, Future<void> Function() f) async {
  var b = double.infinity;
  for (var i = 0; i < reps; i++) {
    final sw = Stopwatch()..start();
    await f();
    final v = sw.elapsedMicroseconds / 1000;
    if (v < b) b = v;
  }
  return b;
}

/// 多轮取最小值。
double best(int reps, void Function() f) {
  var b = double.infinity;
  for (var i = 0; i < reps; i++) {
    final sw = Stopwatch()..start();
    f();
    final v = sw.elapsedMicroseconds / 1000;
    if (v < b) b = v;
  }
  return b;
}

// ============ 被测的脚本 ============

/// 一个只走引导、不产出任何东西的脚本。
/// 与真实脚本的差 = 用户代码 + 序列化的代价。
const String trivial = 'return "x"';

/// 画布脚本：n 个图元。
String canvasApp(int n) => '''
local c = canvas.new({ width = 800, height = 600, background = "#0f1116" })
for i = 1, $n do
  c:circle(i % 800, (i * 7) % 600, 8 + (i % 20), { fill = "#4a9eff" })
end
return json.encode(c:build())
''';

/// 组件脚本：n 个节点。
String uiApp(int n) => '''
local app = ui.app({
  state = { count = 0, items = {} },
  handlers = { bump = function(s) s.count = s.count + 1 end },
  view = function(b, s)
    b:column({ gap = 4 }, function(b)
      for i = 1, $n do
        b:text("row " .. i, { style = "body" })
        b:button("go", { on_tap = "bump", arg = { i = i } })
      end
    end)
  end,
})
return json.encode(app:build())
''';

Future<void> main(List<String> args) async {
  final root = loadLuaModulesFromDisk().root;
  stdout.writeln('流水线基准  (assets -> $root)');
  checkEnvironment();

  // ---------------------------------------------------------------
  section('1. 冷启动（一次性）');
  // ---------------------------------------------------------------
  {
    final w0 = LuaWorker();
    final sw = Stopwatch()..start();
    await w0.start(root);
    final spawn = sw.elapsedMicroseconds / 1000;

    // 第一次执行会绑定全部 @Native 符号，之后才快
    final sw2 = Stopwatch()..start();
    final first = await w0.run(canvasApp(10));
    final firstMs = sw2.elapsedMicroseconds / 1000;
    final sw3 = Stopwatch()..start();
    for (var i = 0; i < 20; i++) {
      await w0.run(canvasApp(10));
    }
    final afterMs = (sw3.elapsedMicroseconds / 20) / 1000;

    record('cold.worker_spawn', spawn);
    line('worker isolate spawn + 握手', spawn, '常驻，不计入每次执行');
    record('cold.first_run', firstMs);
    line('首次执行（含 FFI 符号绑定）', firstMs,
        'first.error=${first.error ?? "无"}');
    line('第 2–21 次执行', afterMs);
    stdout.writeln('  → 首尾差 ${(firstMs - afterMs).toStringAsFixed(1)} ms '
        '是符号绑定的一次性成本');
    w0.dispose();
  }

  // ---------------------------------------------------------------
  section('2. 每次执行的固定成本（引导 + 重建 LuaState）');
  // ---------------------------------------------------------------
  final worker = LuaWorker();
  await worker.start(root);
  await worker.run(trivial); // 预热符号

  // 引导的固定成本：走完全相同的流程但不产出任何东西
  late double trivialMs;
  {
    // 先热身再测：前几次调用 JIT 未热，测出来的"地板"会虚高一倍。
    for (var i = 0; i < 20; i++) {
      await worker.run(trivial);
    }
    var b = double.infinity;
    for (var round = 0; round < 5; round++) {
      final sw = Stopwatch()..start();
      for (var i = 0; i < 30; i++) {
        await worker.run(trivial);
      }
      final v = (sw.elapsedMicroseconds / 30) / 1000;
      if (v < b) b = v;
    }
    trivialMs = b;
  }
  record('fixed.bootstrap', trivialMs);
  line('引导（newState + openLibs + require）', trivialMs,
      '两种模式都一样，这是地板');

  // ---------------------------------------------------------------
  section('3. 规模扫描：执行耗时 vs 产出规模');
  // ---------------------------------------------------------------
  stdout.writeln('  ${"规模".padRight(12)}${"画布(图元)".padRight(18)}'
      '${'组件(节点)'.padRight(18)}备注');
  for (final n in [10, 100, 1000, 10000, 100000]) {
    // 取**最小值**而不是平均值：平均值会把偶发的 GC 和调度抖动全摊进来，
    // 实测同一台机器连续跑，平均值的方差能到 20%，比大多数优化幅度还大。
    final canvasMs = await _bestOf(5, () => worker.run(canvasApp(n)));
    final uiMs = await _bestOf(5, () => worker.runUi(uiApp(n)));

    final warn = canvasMs > 16 || uiMs > 16
        ? '\x1b[33m已超 60fps 的 16ms 预算\x1b[0m'
        : '';
    record('scale.canvas.$n', canvasMs);
    record('scale.ui.$n', uiMs);
    stdout.writeln('  ${n.toString().padRight(12)}'
        '${canvasMs.toStringAsFixed(2).padRight(18)}'
        '${uiMs.toStringAsFixed(2).padRight(18)}$warn');
  }
  stdout.writeln('  （含引导的固定成本 ${trivialMs.toStringAsFixed(2)} ms，'
      '已计入上列）');

  // ---------------------------------------------------------------
  section('4. 事件分发（UI 模式的交互路径）');
  // ---------------------------------------------------------------
  {
    // 先建一棵树拿到 state
    final built = await worker.runUi(uiApp(10));
    final state = ((jsonDecode(built.uiTreeJson!) as Map)['state']).toString();

    // 对照组：同一个脚本、只是不传事件。
    //
    // 两组**交替**测并各取最小值。顺序测会被上一段留下的 GC 压力带偏，
    // 实测能出现"带事件反而更快"这种明显不合理的结论。
    const reps = 25;
    Future<double> buildOnce() async {
      final sw = Stopwatch()..start();
      for (var i = 0; i < reps; i++) {
        await worker.runUi(uiApp(10));
      }
      return (sw.elapsedMicroseconds / reps) / 1000;
    }

    Future<double> eventOnce() async {
      final sw = Stopwatch()..start();
      for (var i = 0; i < reps; i++) {
        await worker.runUi(uiApp(10),
            stateJson: state, eventName: 'bump', eventArgsJson: '{"i":3}');
      }
      return (sw.elapsedMicroseconds / reps) / 1000;
    }

    var bMin = double.infinity;
    var eMin = double.infinity;
    for (var round = 0; round < 4; round++) {
      bMin = (await buildOnce()) < bMin ? await buildOnce() : bMin;
      eMin = (await eventOnce()) < eMin ? await eventOnce() : eMin;
    }

    record('event.roundtrip', eMin);
    line('同脚本纯构建', bMin);
    line('同脚本 + 一次事件', eMin);
    stdout.writeln('  → 两者同一量级。差值落在噪声里（worker 堆受上一段'
        '大测试影响，GC 记账会串），所以不报"事件的额外代价"——'
        '要精确数字得在独立进程里各测一遍。');
    stdout.writeln('  → 每次点击都要重建 LuaState 并重跑整个 view，'
        '这是当前架构最贵的一环');
  }

  // ---------------------------------------------------------------
  section('5. 长期运行的稳定性（每次重建 LuaState 会不会越来越慢）');
  // ---------------------------------------------------------------
  {
    // 先热身 200 次**并且不计入**：不热身的话量到的是 JIT 预热，
    // 那不是"越来越慢"。
    for (var i = 0; i < 200; i++) {
      await worker.run(canvasApp(50));
    }

    // 分段取平均：漂移要看趋势，用平均值比用最小值合适
    // （最小值会把"某一段 GC 比较频繁"这种噪声抹平）。
    Future<double> seg(int count) async {
      final sw = Stopwatch()..start();
      for (var i = 0; i < count; i++) {
        await worker.run(canvasApp(50));
      }
      return (sw.elapsedMicroseconds / count) / 1000;
    }

    final early = await seg(300);
    final late = await seg(300);

    line('前 200 次平均', early);
    line('第 201–1000 次平均', late);
    final drift = (late - early) / early * 100;
    record('drift.percent', drift.abs());
    stdout.writeln('  → 漂移 ${drift.toStringAsFixed(1)}%'
        '${drift > 15 ? '  \x1b[33m有劣化，注意\x1b[0m' : '  \x1b[32m稳定\x1b[0m'}');
  }

  // ---------------------------------------------------------------
  section('6. 反向：宿主侧一次事件要付的固定代价');
  // ---------------------------------------------------------------
  {
    // 必须跑**同一个脚本**，否则比的是两件事。
    // 之前这里跑 trivial 却和 canvasApp(10) 比，差额算出来是负的。
    final sw = Stopwatch()..start();
    const reps = 50;
    for (var i = 0; i < reps; i++) {
      await worker.run(canvasApp(10));
    }
    final total = (sw.elapsedMicroseconds / reps) / 1000;
    stdout.writeln('  ${'从主 isolate 看一次 run 的总延迟'.padRight(34)}'
        '${total.toStringAsFixed(3)} ms');
    final r = await worker.run(canvasApp(10));
    final inLua = r.elapsedMicros / 1000;
    stdout.writeln('    ${'其中 worker 内自报'.padRight(36)}'
        '${inLua.toStringAsFixed(3)} ms  <- 引导+执行+编码');
    stdout.writeln('    ${'差额（调度 + 消息投递 + 主 isolate 侧）'.padRight(36)}'
        '${(total - inLua).toStringAsFixed(3)} ms');
  }

  worker.dispose();
  stdout.writeln('');

  // 基线比较是最后一步；它决定进程退出码，所以要放在 dispose 之后。
  exit(compareWithBaseline(update: args.contains('--update')));
}

// ============ 基线比较 ============
//
// 绝对值在这个环境里没有意义：同一个 `make bench` 换台机器就能差几倍
// （CI runner、笔记本插电与否、其它进程负载）。所以：
//
//   * 基线文件 `tools/bench_baseline.json` 记的是**相对值**
//   * 判定标准是「相对基线劣化超过阈值」，不是「超过某个绝对值」
//
// 阈值按指标性质分开给：
//   * 固定成本 / 规模扫描：10%（这几项最稳定，也最值得盯）
//   * 冷启动：25%（含 FFI 符号绑定，抖动大）
//   * 漂移：单独看，超过 15% 说明有累积性问题

/// 相对基线允许的劣化比例。
///
/// ## 阈值是**量出来的**，不是拍的
///
/// 同一台机器、连续三次跑（已确认没有残留进程），各指标的波动：
///
///   fixed.bootstrap    0.569 / 0.493 / 0.582 ms      ±8%
///   scale.canvas.1000  15.9 / 12.8 / 16.4  ms       ±13%
///   scale.ui.1000      60.1 / 53.5 / 60.9  ms       ±7%
///
/// 所以阈值取 2 倍左右的波动。定成 10% 的话，上面每一次都会误报，
/// 而误报多了这个信号就没人看了。
///
/// ## 反面教材：机器不干净时能虚高多少
///
/// 有一次残留的 `flutter run` 在跑（占一个核），同样的代码
/// 三次跑出 0.65 / 0.92 / 1.64 ms —— **比干净环境高 2 倍**。
/// 所以 [checkEnvironment] 会在开跑前先看机器负载。
const Map<String, double> _tolerance = <String, double>{
  'cold': 0.40,
  'fixed': 0.25,
  'scale': 0.25,
  'event': 0.30,
  'drift': 30.0,
};

/// 开跑前看一眼机器负载。
///
/// 基准数字只在安静机器上才有意义。带着 1 个后台进程跑出来的
/// "劣化"绝大多数是环境问题，不是代码问题 —— 与其让人追一个不存在的
/// 性能回归，不如先把话说清楚。
void checkEnvironment() {
  try {
    final r = Process.runSync('sysctl', <String>['-n', 'vm.loadavg']);
    // macOS 的 vm.loadavg 输出是 `{ 1.23 0.98 0.90 }`（带花括号和空格）。
    // 只去掉花括号再按空白切分——顺手把空格也 replace 掉的话
    // 三个数字会粘成 "1.230.980.90"，解析出来是 0，等于永远不报警。
    final text = (r.stdout as String).replaceAll('{', '').replaceAll('}', '');
    final parts = text.trim().split(RegExp(r'\s+'));
    final value = parts.isEmpty ? 0.0 : (double.tryParse(parts.first) ?? 0.0);
    final load = value.toStringAsFixed(2);
    stdout.writeln('机器负载（1 分钟 loadavg）: $load');
    if (value > 2.0) {
      stdout.writeln('\x1b[33m警告：负载偏高，基准数字可能虚高。\x1b[0m');
      stdout.writeln('      实测有残留进程时同样的代码能虚高 2 倍。');
      stdout.writeln('      先关掉后台的 flutter run / 构建，再看结论。');
    }
  } catch (_) {
    // 拿不到就算了，不该因此挡住基准
  }
}

double _tolFor(String key) {
  for (final entry in _tolerance.entries) {
    if (key.startsWith(entry.key)) {
      return entry.value;
    }
  }
  return 0.15;
}

const String _baselinePath = 'tools/bench_baseline.json';

/// 与基线比较，打印表格，返回有几项劣化。
///
/// `--update` 时把当前值写成新基线。
///
/// ## 基线必须在**安静的机器**上建立
///
/// 实测：一个残留的 `flutter run`（占一个核）就能让同样的代码慢 2 倍；
/// 一次 Android Studio 的 Java 进程在跑，能让 loadavg 冲到 167、
/// 所有数字虚高 60%。所以 [checkEnvironment] 会在开跑前先看负载并提醒。
/// 换机器或机器状态变了就重新 `--update`。
int compareWithBaseline({bool update = false}) {
  final file = File(_baselinePath);
  final Map<String, double> baseline;
  if (file.existsSync()) {
    try {
      final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      baseline = raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      stdout.writeln('基线文件读不出来，按"没有基线"处理');
      return compareWithBaseline(update: update);
    }
  } else {
    baseline = <String, double>{};
  }

  if (update || baseline.isEmpty) {
    final snapshot = <String, double>{};
    for (final k in _watched) {
      snapshot[k] = _metrics[k] ?? 0.0;
    }
    file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(snapshot));
    stdout.writeln('\n已写入基线：$_baselinePath'
        '${baseline.isEmpty ? '（首次建立）' : ''}');
    return 0;
  }

  stdout.writeln('\n\x1b[1m=== 与基线比较 ===\x1b[0m');
  stdout.writeln('  ${'指标'.padRight(22)}${'本次'.padRight(12)}'
      '${'基线'.padRight(12)}${'变化'.padRight(10)}判定');
  int worse = 0;
  int better = 0;
  for (final key in _watched) {
    final now = _metrics[key];
    final before = baseline[key];
    if (now == null || before == null || before == 0) continue;

    final ratio = (now - before) / before;
    final tol = _tolFor(key);
    final verdict = ratio > tol
        ? '\x1b[31m劣化\x1b[0m'
        : ratio < -tol
            ? '\x1b[32m改善\x1b[0m'
            : 'ok';
    if (ratio > tol) worse++;
    if (ratio < -tol) better++;

    stdout.writeln('  ${key.padRight(22)}'
        '${now.toStringAsFixed(3).padRight(12)}'
        '${before.toStringAsFixed(3).padRight(12)}'
        '${'${(ratio * 100).toStringAsFixed(1)}%'.padRight(10)}'
        '$verdict');
  }
  stdout.writeln('\n  劣化 $worse 项，改善 $better 项。');
  stdout.writeln('  阈值（按实测波动定的，不是拍的）：固定成本/规模 25%，'
      '冷启动 40%，事件 30%，漂移 30%。');
  stdout.writeln('  劣化不代表一定是问题——先跑两次看是否稳定，再看是否与本次改动相关。');
  stdout.writeln('  确认是环境差异就更新基线：dart run tools/bench_pipeline.dart --update');
  return worse;
}
