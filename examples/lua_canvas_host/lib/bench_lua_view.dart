// lib/bench_lua_view.dart
//
// 量 flutter_lua_bridge_ui（Lua 节点直接建 widget，不经过 rfw Runtime）
// 一次交互后的重建成本，和 lib/bench_rebuild.dart 的 rfw 数据对照。
//
// ```sh
// fvm flutter build macos --profile -t lib/bench_lua_view.dart
// build/macos/Build/Products/Profile/lua_canvas_studio.app/Contents/MacOS/lua_canvas_studio
// ```
//
// 每个列表项和 bench_rebuild.dart 一样是 6 个节点：
// Column(Row(Icon, Text), GestureDetector(Text))。
//
// 四种交互：
// - 无组件·全量：列表项不是组件，任何改动都让 Lua 交出整棵树；
// - 组件·改1项：每项是一个读 store.items[i] 的组件，只改 1 项；
// - 组件·全改：所有项都改，每个组件都重渲染（看响应式代理的额外开销）；
// - 组件·父级：只改根组件读的标题，子组件 props 没变，只发引用。
//
// 每档记录（都在 UI 线程上）：
// - 调用：controller.call 本身，即 Lua 执行和渲染、把更新复制到 Dart、
//   把节点转成 widget；它发生在帧外，FrameTiming 统计不到；
// - build：FrameTiming.buildDuration，随后这一帧的 build + layout + paint；
// - 总计：调用 + build，即一次交互在 UI 线程上的全部开销；
// - Lua：只调用 Lua 方法并复制更新的时间（调用的一部分）。
//
// 和 bench_rebuild.dart 一样还记了“净耗时”（等这一帧结束的时间减去空帧
// 地板），只为和 rfw 横向对照；开销能在一帧内消化时它显示为 0。

import 'dart:async';
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge_ui/flutter_lua_bridge_ui.dart';

void _out(String s) => debugPrint('[luaviewbench] $s');

const String _source = r'''
local ui = require("flb.ui")

local function body(item, on_tap)
  return ui.Column {
    crossAxisAlignment = "start",
    ui.Row { ui.Icon { icon = "add", size = 16 }, ui.Text { "值 " .. item.value } },
    ui.GestureDetector { onTap = on_tap, child = ui.Text { "GO" } },
  }
end

local Item = ui.component(function()
  return function(props)
    return body(props.item, function() props.item.value = props.item.value + 1 end)
  end
end)

return ui.app {
  store = { title = "t", items = {} },
  methods = {
    setSize = function(s, n)
      local items = {}
      for i = 1, n do items[i] = { value = 0 } end
      s.items = items
    end,
    bumpOne = function(s) s.items[1].value = s.items[1].value + 1 end,
    bumpAll = function(s)
      for i, item in ipairs(s.items) do item.value = item.value + 1 end
    end,
    retitle = function(s) s.title = s.title .. "!" end,
  },
  view = function(s)
    local children = { ui.Text { s.title } }
    for i, item in ipairs(s.items) do
      if COMPONENTS then
        children[i + 1] = Item { key = i, item = item }
      else
        children[i + 1] = body(item, function() item.value = item.value + 1 end)
      end
    end
    return ui.SingleChildScrollView { child = ui.Column { children = children } }
  end,
}
''';

String _sourceFor(bool components) =>
    'local COMPONENTS = $components\n$_source';

const _icons = <String, IconData>{
  'add': IconData(0xe047, fontFamily: 'MaterialIcons'),
};

final _libraries = [coreLibrary(icons: _icons)];

final List<FrameTiming> _timings = [];

Future<double> _frame(void Function() mutate) async {
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

/// Median net time, build duration of the frames after [op], and the
/// time of [op] itself.
Future<(double, double, double)> _measure(void Function() op) async {
  final floor = <double>[];
  for (var i = 0; i < 10; i++) {
    floor.add(await _frame(() {}));
  }
  // FrameTiming arrives in batches; let the floor frames flush first.
  await Future<void>.delayed(const Duration(milliseconds: 200));
  _timings.clear();
  final samples = <double>[];
  final calls = <double>[];
  for (var i = 0; i < 10; i++) {
    samples.add(
      await _frame(() {
        final sw = Stopwatch()..start();
        op();
        calls.add(sw.elapsedMicroseconds / 1000);
      }),
    );
  }
  await Future<void>.delayed(const Duration(milliseconds: 300));
  final builds = [
    for (final t in _timings) t.buildDuration.inMicroseconds / 1000,
  ];
  final net = _median(samples) - _median(floor);
  return (
    net < 0 ? 0.0 : net,
    builds.isEmpty ? double.nan : _median(builds),
    _median(calls),
  );
}

/// Lua time of [op]: the method call and copying the update into Dart.
double _luaOnly(int n, {required bool components, required String op}) {
  final lua = LuaRuntime.create();
  try {
    lua.ensureModule(uiLuaModule, source: uiLuaSource);
    final app = lua.run(_sourceFor(components)).first as LuaTable;
    final call = app['call'] as LuaFunction;
    final render = app['render'] as LuaFunction;
    Object? copy(List<Object?> r) {
      final t = r.first as LuaTable;
      final d = t.toDart();
      t.release();
      return d;
    }

    copy(render.call([const <String, Object?>{}]));
    copy(call.call(['setSize', n]));
    final samples = <double>[];
    for (var i = 0; i < 20; i++) {
      final sw = Stopwatch()..start();
      copy(call.call([op]));
      samples.add(sw.elapsedMicroseconds / 1000);
    }
    return _median(samples);
  } finally {
    lua.close();
  }
}

const _cases = <(String, bool, String)>[
  ('无组件·全量', false, 'bumpAll'),
  ('组件·改1项', true, 'bumpOne'),
  ('组件·全改', true, 'bumpAll'),
  ('组件·父级', true, 'retitle'),
];

Future<void> _run(LuaRuntime lua, void Function(Widget) show) async {
  _out('');
  _out('=== flutter_lua_bridge_ui 交互重建成本（单位 ms，每项取中位数）===');
  _out('每格：总计 = 调用 + build（Lua）；净耗时单列在下方表');
  final header = StringBuffer('规模      ');
  for (final c in _cases) {
    header.write(c.$1.padRight(26));
  }
  _out(header.toString());
  final nets = <String>[];
  for (final n in const [50, 200, 500, 1000]) {
    final row = StringBuffer(n.toString().padRight(10));
    final netRow = StringBuffer(n.toString().padRight(10));
    for (final (_, components, op) in _cases) {
      final controller = LuaViewController();
      show(
        Directionality(
          key: UniqueKey(),
          textDirection: TextDirection.ltr,
          child: LuaView(
            runtime: lua,
            source: _sourceFor(components),
            libraries: _libraries,
            controller: controller,
          ),
        ),
      );
      await _frame(() {});
      controller.call('setSize', n);
      await _frame(() {});
      await _frame(() {});
      final (net, build, call) = await _measure(() => controller.call(op));
      final luaTime = _luaOnly(n, components: components, op: op);
      String f(double v) => v.toStringAsFixed(2);
      row.write(
        '${f(call + build)} = ${f(call)} + ${f(build)} (${f(luaTime)})'
            .padRight(30),
      );
      netRow.write(f(net).padRight(14));
    }
    _out(row.toString());
    nets.add(netRow.toString());
  }
  _out('');
  _out('净耗时（与 bench_rebuild.dart 同口径）：');
  nets.forEach(_out);
  _out('');
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final lua = LuaRuntime.create();
  final page = ValueNotifier<Widget>(const SizedBox());
  SchedulerBinding.instance.addTimingsCallback(_timings.addAll);
  runApp(
    ValueListenableBuilder<Widget>(
      valueListenable: page,
      builder: (context, child, _) => child,
    ),
  );
  SchedulerBinding.instance.addPostFrameCallback((_) {
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 500), () async {
        await _run(lua, (w) => page.value = w);
        exit(0);
      }),
    );
  });
}
