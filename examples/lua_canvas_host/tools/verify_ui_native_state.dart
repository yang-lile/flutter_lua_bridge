// tools/verify_ui_native_state.dart
//
// 验证「交互不回 Lua」这条路真的接通了。
//
// ## 为什么它成立
//
// rfw 有两种 handler，代价差一个数量级（见 bench_rebuild）：
//
//   SetStateHandler  rfw 客户端自己改状态，**不产生事件**、不回宿主
//   EventHandler     上报给宿主，由宿主决定怎么处理
//
// 所以「瞬时 UI 状态」必须编译成 SetStateHandler，「业务事件」才用
// EventHandler。这份验证盯的就是**这个分流对不对**——
// 分错了，功能看着都能用，但交互每一下都要重跑整棵树。
//
// 运行：dart run tools/verify_ui_native_state.dart

import 'dart:io';

import 'package:lua_canvas_host/lua_modules.dart';
import 'package:lua_canvas_host/sandbox.dart';
import 'package:lua_canvas_host/ui_rfw_ast.dart';
import 'package:lua_canvas_host/ui_tree.dart';
import 'package:rfw/formats.dart';

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

/// 带本地状态的组件 + 业务事件的混合应用。
const String app = r'''
ui.component("RowItem", {
  state = { open = false, count = 0 },
  view = function(b, state)
    b:card(function(b)
      b:column(function(b)
        -- 瞬时：本地状态，不回 Lua
        b:button("展开", { on_tap = b:set_state("open", not state.open) })
        b:button("+1", { on_tap = b:set_state("count", state.count + 1) })
        -- 关键：状态必须以**引用**留在树里。写 "x" .. state.count
        -- 会被 Lua 算成字面量烤进去，rfw 重渲染多少次都不变。
        b:text(b:sref("count"))
        -- 业务：回 Lua
        b:button("删除", { on_tap = "remove", arg = { id = 1 } })
        if state.open then b:text("展开了", { style = "caption" }) end
      end)
    end)
  end,
})

local app = ui.app({
  state = {},
  handlers = { remove = function(s, ev) s.last = ev.id end },
  view = function(b)
    b:column(function(b)
      b:RowItem()
      b:RowItem()
      b:button("全删", { on_tap = "remove", arg = { id = 0 } })
    end)
  end,
})
return json.encode(app:build())
''';

/// 遍历库，统计两类 handler。
class _Tally {
  int setStates = 0;
  int events = 0;
  int stateRefs = 0;
  final List<String> eventNames = <String>[];

  void walk(Object? n) {
    if (n is List) {
      n.forEach(walk);
      return;
    }
    if (n is SetStateHandler) {
      setStates++;
      return;
    }
    if (n is StateReference) {
      stateRefs++;
      return;
    }
    if (n is EventHandler) {
      events++;
      eventNames.add(n.eventName);
      return;
    }
    if (n is ConstructorCall) {
      walk(n.arguments.values.toList());
      return;
    }
    if (n is Map) {
      n.values.forEach(walk);
    }
  }
}

void main() {
  final root = loadLuaModulesFromDisk().root;

  stderr.writeln('=== 交互分层：本地状态 vs 业务事件 ===\n');

  final r = LuaSandbox().runUi(app, libraryPath: root);
  if (r.error != null) {
    stderr.writeln('Lua 执行失败：${r.error}');
    exit(1);
  }
  final tree = UiTree.parse(r.uiTreeJson!);

  stderr.writeln('契约层面：');
  check('组件声明进了信封', tree.declarations.length == 1,
      tree.declarations.map((d) => d.name).join(','));
  check('组件带初始状态',
      tree.declarations.first.state?['open'] == false);
  check('契约里有本地状态写入',
      tree.declarations.first.root.stateWrites.length == 2);
  // 这条是原生状态能不能生效的**前提**：树里必须有状态引用，
  // rfw 状态变化时只会重新解析引用，没法凭空加节点。
  check('契约里有状态引用（否则 rfw 改不动）',
      tree.stateReads.isNotEmpty,
      tree.stateReads.join(','));
  check('契约里有业务事件',
      tree.declarations.first.root.events.length == 1);
  check('组件被引用了两次', () {
    var refs = 0;
    for (final n in tree.root.walk()) {
      if (n.widget == 'RowItem') refs++;
    }
    return refs == 2;
  }());

  stderr.writeln('\nrfw 层面（这才是关键）：');
  final lib = buildUiLibrary(tree);
  check('编出两个声明（组件 + root）', lib.widgets.length == 2,
      lib.widgets.map((w) => w.name).join(','));
  check('组件声明带 initialState', lib.widgets.first.initialState != null,
      '${lib.widgets.first.initialState}');
  check('root 声明没有状态', lib.widgets.last.initialState == null);

  final tally = _Tally();
  for (final w in lib.widgets) {
    tally.walk(w.root);
  }
  check('状态引用编成了 StateReference', tally.stateRefs >= 1,
      '${tally.stateRefs} 个');
  check('两个本地状态 -> SetStateHandler', tally.setStates == 2,
      '${tally.setStates} 个');
  // 组件里一个「删除」+ root 里一个「全删」，都是业务事件。
  check('两个业务事件 -> EventHandler', tally.events == 2,
      '${tally.events} 个: ${tally.eventNames.join(",")}');
  check('两者互不串味', tally.setStates == 2 && tally.events == 2,
      '分流错了的话，交互每一下都要重跑整棵树');

  // 组件名是本树自己声明的，不该被报成「rfw 不认识的 widget」。
  // 这条是真机上点出来的：组件越多，噪音越大，最后真的拼写错误
  // 就被淹没在里面了。
  final unknown = collectWidgetNames(tree)
      .where((w) => !kBuiltinWidgets.contains(w))
      .toList();
  check('组件名不会被当成未知 widget', unknown.isEmpty,
      unknown.isEmpty ? '组件 ${tree.declarations.map((d) => d.name).join(",")} 已排除'
                      : '仍被报成未知: ${unknown.join(",")}');

  final bytes = encodeLibraryBlob(lib);
  check('能编成二进制库', bytes.isNotEmpty, '${bytes.length} 字节');

  stderr.writeln('\n  为什么这个分流重要（bench_rebuild 实测，扣掉 vsync 地板）：');
  stderr.writeln('    换库（= 走 EventHandler 回 Lua）500 项  72.80 ms');
  stderr.writeln('    改 data/state（= SetStateHandler）500 项  <0.01 ms');

  stderr.writeln('\n$_pass passed, $_fail failed');
  exit(_fail == 0 ? 0 : 1);
}
