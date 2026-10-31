// lib/bench_rebuild.dart
//
// 一次性实验：量 rfw 在不同架构下的重建成本。
//
// ```sh
// flutter run -t lib/bench_rebuild.dart
// ```
//
// ## 为什么要分这么多档
//
// rfw 有两条改变界面的路径，代价差一个数量级：
//
// A. `runtime.update(新库)` —— 换掉整个远端库。
//    内部走 `_clearCache()`：清空 `_cachedConstructors` 与 `_widgets`
//    （所有 `_CurriedWidget` 缓存），再 `notifyListeners()`，
//    RemoteWidget 收到通知后 setState → **整棵子树重建**。
//    这是我们现在的做法（每次事件都换库）。
//
// B. 改 data 或改 widget 的 state ——
//    `DynamicContent.update(key, value)` → 通知**订阅了该 key** 的
//    `_Subscription` → 只有读了这个 key 的 `_WidgetState.updateData`
//    → 只重建这些 `_Widget`。**按 key 粒度。**
//
// 树本身又有两种组织方式：平铺（每个节点都写全）和组件化
// （声明一次、引用 N 次）。所以要量的是 2 × 2 的矩阵，
// 才能判断「组件化」和「原生状态」各自贡献了多少。
//
// ## 为什么用 data 变更代理 state 变更
//
// 两者最终都落到 `_WidgetState.updateData(Set<_Key>)` → `setState`，
// 是同一套按 key 订阅的机制。区别只在于状态存在 `_stateStore`
// 还是 `DynamicContent` 里。
//
// 不直接触发 state 写入是因为它只能由交互控件（GestureDetector 的
// onTapDown 等）在 build 期间调用 `source.voidHandler` 触发，
// 而这里没有 flutter_test 的 TestGesture 可用。
//
// ## 为什么必须扣掉 vsync 地板
//
// 60Hz 意味着 `endOfFrame` 至少要等 16.67ms。不扣掉这一项，
// 所有数字都会显示成 "~16ms"，看起来"改 data 永远要 16ms"——
// 那是量错了，不是真的慢。所以每档都先测一个什么都不改的基线。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:rfw/rfw.dart';

/// 内部输出。macOS 应用里 `stdout.writeln` 不一定穿透到启动它的终端，
/// `debugPrint` 是实测能穿透的。
void _out(String s) => debugPrint('[rfwbench] $s');

final Runtime _runtime = Runtime();
final DynamicContent _data = DynamicContent();

/// data 的取值必须**每次不同**。
///
/// `_data.update('k', 同一个值)` 不会触发订阅通知（值没变），
/// 于是测出来的是"什么都没发生"，不是重建成本。
int _tick = 0;

const LibraryName _main = LibraryName(<String>['lua']);

// ---------- 树的形状 ----------

/// 一个"列表项"的内容：图标行 + 按钮。刻意做得比裸 Text 复杂，
/// 免得测出来的数字只对最简单的控件成立。
ConstructorCall _rowItemBody({String? readDataKey, String? readStateKey}) {
  final textArgs = <String, dynamic>{'text': '静态'};
  if (readDataKey != null) {
    textArgs['text'] = <Object?>['值 ', DataReference(<String>[readDataKey])];
  }
  if (readStateKey != null) {
    textArgs['text'] = <Object?>['值 ', StateReference(<String>[readStateKey])];
  }

  return ConstructorCall('Column', <String, dynamic>{
    'crossAxisAlignment': 'start',
    'children': <Object?>[
      ConstructorCall('Row', <String, dynamic>{
        'children': <Object?>[
          ConstructorCall('Icon', <String, dynamic>{
            'icon': <String, dynamic>{'icon': 0xe145, 'fontFamily': 'MaterialIcons'},
            'size': 16.0,
          }),
          ConstructorCall('Text', textArgs),
        ],
      }),
      ConstructorCall('ElevatedButton', <String, dynamic>{
        'onPressed': const EventHandler('go', <String, dynamic>{}),
        'child': ConstructorCall('Text', <String, dynamic>{'text': 'GO'}),
      }),
    ],
  });
}

/// **平铺**：root 里直接写 N 份完整子树。
///
/// 这是我们现在的产出方式 —— Lua 每建一个节点就往树里塞一份完整结构。
RemoteWidgetLibrary _flatLibrary(int n, {int revision = 0, int readers = 0}) {
  final children = <Object?>[];
  for (var i = 0; i < n; i++) {
    final body = _rowItemBody(
      readDataKey: i < readers ? 'k' : null,
    );
    // revision 每次不同：确保换库一定被判为"变了"，走完整的重建路径
    if (revision != 0) {
      children.add(ConstructorCall('Text', <String, dynamic>{
        'text': 'r$revision',
      }));
    }
    children.add(body);
  }
  return RemoteWidgetLibrary(
    <Import>[const Import(_coreWidgets), const Import(_coreMaterial)],
    <WidgetDeclaration>[
      WidgetDeclaration('root', null, ConstructorCall('Column', <String, dynamic>{
        'children': children,
      })),
    ],
  );
}

/// **组件化**：body 声明一次，root 里放 N 个引用。
///
/// 这是 rfw 的 `WidgetDeclaration` + `ConstructorCall` 组合，
/// 也是我们准备给 Lua 加的组件能力对应的结构。
RemoteWidgetLibrary _componentLibrary(
  int n, {
  int revision = 0,
  int readers = 0,
  bool withState = false,
}) {
  // 组件本体只写一次
  final item = WidgetDeclaration(
    'RowItem',
    withState ? <String, dynamic>{'tick': 0} : null,
    _rowItemBody(
      readDataKey: readers > 0 ? 'k' : null,
      readStateKey: withState ? 'tick' : null,
    ),
  );

  final refs = <Object?>[];
  for (var i = 0; i < n; i++) {
    if (revision != 0) {
      refs.add(ConstructorCall('Text', <String, dynamic>{'text': 'r$revision'}));
    }
    refs.add(ConstructorCall('RowItem', <String, dynamic>{'index': i}));
  }

  return RemoteWidgetLibrary(
    <Import>[const Import(_coreWidgets), const Import(_coreMaterial)],
    <WidgetDeclaration>[
      item,
      WidgetDeclaration('root', null, ConstructorCall('Column', <String, dynamic>{
        'children': refs,
      })),
    ],
  );
}

const LibraryName _coreWidgets = LibraryName(<String>['core', 'widgets']);
const LibraryName _coreMaterial = LibraryName(<String>['core', 'material']);

// ---------- 测量 ----------

/// 改一次，等这一帧画完，返回耗时。
///
/// **必须显式 `scheduleFrame()`。** `endOfFrame` 的 future 只在有帧被
/// 调度时才会完成——而"改了一个没人订阅的 data key"恰恰不产生帧，
/// 于是 await 永远挂住，整个基准静默卡死（第一次写就踩了）。
Future<double> frameTime(void Function() mutate) async {
  final sw = Stopwatch()..start();
  mutate();
  SchedulerBinding.instance.scheduleFrame();
  await SchedulerBinding.instance.endOfFrame;
  return sw.elapsedMicroseconds / 1000;
}

double _median(List<double> xs) {
  final s = List<double>.of(xs)..sort();
  return s[s.length ~/ 2];
}

/// 一组测量：地板 + 各种操作，各自取中位数。
class Row2 {
  Row2(this.floor, this.ops);
  final double floor;
  final Map<String, double> ops;

  double net(String k) {
    final v = (ops[k] ?? 0) - floor;
    return v < 0 ? 0 : v;
  }
}

Future<Row2> measure(Map<String, void Function()> ops) async {
  // 地板：什么都不改，只等一帧
  final floorSamples = <double>[];
  for (var i = 0; i < 10; i++) {
    floorSamples.add(await frameTime(() {}));
  }
  final floor = _median(floorSamples);

  final out = <String, double>{};
  for (final op in ops.entries) {
    final samples = <double>[];
    for (var i = 0; i < 10; i++) {
      samples.add(await frameTime(op.value));
    }
    out[op.key] = _median(samples);
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
  return Row2(floor, out);
}

Future<void> runBench() async {
  _out('');
  _out('=== rfw 重建成本（已扣掉 vsync 地板）===');
  _out('每项 10 次取中位数。地板 = 什么都不改、只等一帧（60Hz 约 16.7ms）。');

  const sizes = <int>[50, 200, 500, 1000];

  _out('');
  _out('  ┌ 换库 runtime.update（O(树大小)）');
  _out('  │   平铺          = 我们现在的做法');
  _out('  │   组件化        = 只声明一次，N 个引用');
  _out('  └ 改 data（按 key 订阅）');
  _out('      平铺/全读     = 所有节点都是订阅者');
  _out('      组件化/1 个读  = 只有 1 个组件订阅 -> 理想情况');
  _out('');

  final header = StringBuffer('  ${'规模'.padRight(8)}');
  for (final c in <String>[
    '地板',
    '换库·平铺',
    '换库·组件化',
    '改data·全读',
    '改data·1读',
  ]) {
    header.write(c.padRight(14));
  }
  _out(header.toString());

  for (final n in sizes) {
    // ---- 换库 · 平铺 ----
    _runtime.update(_main, _flatLibrary(n, revision: 1));
    await frameTime(() {});
    final flat = await measure(<String, void Function()>{
      '换库·平铺': () => _runtime.update(_main, _flatLibrary(n, revision: 2)),
    });

    // ---- 换库 · 组件化 ----
    _runtime.update(_main, _componentLibrary(n, revision: 1));
    await frameTime(() {});
    final comp = await measure(<String, void Function()>{
      '换库·组件化': () =>
          _runtime.update(_main, _componentLibrary(n, revision: 2)),
    });

    // ---- 改 data · 全读（平铺，所有节点都订阅 k）----
    _runtime.update(_main, _flatLibrary(n, readers: n));
    await frameTime(() {});
    final allRead = await measure(<String, void Function()>{
      '改data·全读': () => _data.update('k', _tick++),
    });

    // ---- 改 data · 只有 1 个组件订阅 ----
    _runtime.update(_main, _componentLibrary(n, readers: 1));
    await frameTime(() {});
    final oneRead = await measure(<String, void Function()>{
      '改data·1读': () => _data.update('k', _tick++),
    });

    String f(double v) => v.toStringAsFixed(2);
    _out('  ${n.toString().padRight(10)}'
        '${f(flat.floor).padRight(14)}'
        '${f(flat.net('换库·平铺')).padRight(14)}'
        '${f(comp.net('换库·组件化')).padRight(14)}'
        '${f(allRead.net('改data·全读')).padRight(14)}'
        '${f(oneRead.net('改data·1读')).padRight(14)}');

    await Future<void>.delayed(const Duration(milliseconds: 60));
  }

  _out('');
  _out('  怎么读这张表：');
  _out('   · 「地板」是等一帧的固定开销，不是重建的代价，看趋势不看绝对值');
  _out('   · 「换库·平铺」= 现状：每次点击都要付这一列');
  _out('   · 「换库·组件化」= 只做了组件化，仍是每次换整棵树');
  _out('   · 「改data·1读」= 组件化 + 原生状态，理想路径');
  _out('   · 「改data·全读」= 用了原生状态但所有节点都订阅，订阅粒度失效');
  _out('');
  _out('=== 结束 ===');
}

class BenchPage extends StatefulWidget {
  const BenchPage({super.key});

  @override
  State<BenchPage> createState() => _BenchPageState();
}

class _BenchPageState extends State<BenchPage> {
  @override
  void initState() {
    super.initState();
    _runtime.update(_coreWidgets, createCoreWidgets());
    _runtime.update(_coreMaterial, createMaterialWidgets());
    _runtime.update(_main, _flatLibrary(20));
    _data.updateAll(<String, Object>{'k': 0});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 700,
            height: 500,
            child: RemoteWidget(
              runtime: _runtime,
              data: _data,
              widget: const FullyQualifiedWidgetName(_main, 'root'),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const BenchPage());
  // 等首帧之后再开始量
  SchedulerBinding.instance.addPostFrameCallback((_) {
    unawaited(
        Future<void>.delayed(const Duration(milliseconds: 500), runBench));
  });
}
