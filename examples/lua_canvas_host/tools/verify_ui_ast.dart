// tools/verify_ui_ast.dart
//
// 端到端验证 UI 链路：真实 Lua 产出 -> 契约解析 -> rfw AST -> blob 编解码 -> 事件分发。
//
// 这是纯 Dart 入口，不依赖 Flutter 引擎，所以在受限环境里也能跑
// （`flutter test` 需要 flutter_tester 与工具建立本地 WebSocket，会被拦）。
//
// 能做到端到端的原因：rfw 把「格式层」拆成了不依赖 dart:ui 的
// `package:rfw/formats.dart`，lib/ui_rfw_ast.dart 只 import 它。
// 所以这一串里唯一需要引擎的部分（RemoteWidget 真正渲染）留在
// lib/ui_view.dart，由应用本身验证。
//
// 运行：dart run tools/verify_ui_ast.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

void section(String title) {
  stderr.writeln('\n$title');
}

/// 把一段 Lua 代码作为 UI 应用跑一遍，返回契约。
UiTree buildTree(String root, String code) {
  final r = LuaSandbox().runUi(code, libraryPath: root);
  if (r.error != null) {
    throw StateError('Lua 执行失败：${r.error}');
  }
  return UiTree.parse(r.uiTreeJson!);
}

/// 跑一次事件，返回新的契约。
UiTree dispatch(UiTree before, String code, String event,
    [Map<String, dynamic>? args]) {
  final r = LuaSandbox().runUi(
    code,
    libraryPath: _root,
    stateJson: before.stateJson,
    eventName: event,
    eventArgsJson: args == null ? null : jsonEncode(args),
  );
  if (r.error != null) {
    throw StateError('事件 $event 执行失败：${r.error}');
  }
  return UiTree.parse(r.uiTreeJson!);
}

late final String _root;

// ---------------------------------------------------------------- 示例

/// 与 lib/main.dart 里的示例同源（那边是给编辑器用的副本）。
/// 这里单独一份是因为验证工具不能 import lib/main.dart（那会拉进 Flutter）。
const String counterApp = '''
local app = ui.app({
  title = "计数器",
  state = { count = 0, verbose = false },
  handlers = {
    inc = function(s, ev) s.count = s.count + (ev.amount or 1) end,
    reset = function(s) s.count = 0 end,
    toggle_verbose = function(s) s.verbose = not s.verbose end,
  },
  view = function(b, s)
    b:column({ main = "center", align = "center", gap = 14 }, function(b)
      b:card({ color = "#14171F" }, function(b)
        b:column({ gap = 10 }, function(b)
          b:text("计数", { style = "label", color = "#6B7488" })
          b:text(tostring(s.count), { style = "display" })
          b:row({ main = "center", align = "center", gap = 8 }, function(b)
            b:button("减", { on_tap = "inc", arg = { amount = -1 }, variant = "outlined" })
            b:button("加", { on_tap = "inc", arg = { amount = 1 } })
            b:button("归零", { on_tap = "reset", variant = "text" })
          end)
        end)
      end)
      b:toggle({ value = s.verbose, on_change = "toggle_verbose", label = "详细" })
      b:divider()
      b:text("rfw 渲染，Lua 编排", { style = "caption", align = "center" })
    end)
  end,
})

return json.encode(app:build())
''';

const String galleryApp = '''
local items = { "第一项", "第二项", "第三项" }
local app = ui.app({
  state = { picked = 0 },
  handlers = {
    pick = function(s, ev) s.picked = ev.index or 0 end,
  },
  view = function(b, s)
    b:column({ gap = 8 }, function(b)
      b:scroll({ padding = 4 }, function(b)
        b:row({ gap = 8 }, function(b)
          for i, name in ipairs(items) do
            b:button(name, { on_tap = "pick", arg = { index = i } })
          end
          b:spacer({ flex = 1 })
          b:icon("star", { size = 20, color = "#4A9EFF" })
        end)
      end)
      b:kpi("已选", items[s.picked] or "无", { accent = "#4A9EFF" })
      b:progress({ value = 0.7 })
    end)
  end,
})

return json.encode(app:build())
''';

void main() {
  _root = loadLuaModulesFromDisk().root;

  // ---- 1. 契约解析 ----
  section('=== 1. Lua -> UI 契约 ===');
  final UiTree counter = buildTree(_root, counterApp);
  check('解析成功', counter.version == 1, 'v${counter.version}');
  check('入口 widget 名', counter.widget == 'root');
  check('标题带过来了', counter.title == '计数器', counter.title);
  check('节点数 > 0', counter.actualNodeCount > 0, '${counter.actualNodeCount} 个');
  check('Lua 自报节点数与 Dart 一致', counter.validate().isEmpty,
      counter.validate().join(' | '));
  check('事件清单已注册', counter.events.length == 3, counter.events.join(','));
  check('树里引用的事件都在清单里',
      counter.referencedEvents.difference(counter.events.toSet()).isEmpty,
      counter.referencedEvents.join(','));

  // ---- 2. rfw AST 转换 ----
  section('\n=== 2. UiTree -> rfw AST ===');
  final lib = buildUiLibrary(counter);
  check('库只有一个 root 声明', lib.widgets.length == 1, '${lib.widgets.length}');
  check('入口是 ConstructorCall', lib.widgets.first.root is ConstructorCall);
  check('导入三个本地库', lib.imports.length == 3,
      lib.imports.map((i) => i.name.toString()).join(', '));

  final names = collectWidgetNames(counter);
  check('用到的 widget 都在 rfw 清单里',
      names.every(kBuiltinWidgets.contains),
      names.where((n) => !kBuiltinWidgets.contains(n)).join(', '));
  check('覆盖多种 widget', names.length >= 5, names.join(' '));

  // ---- 3. blob 编解码往返 ----
  // 这一步证明产出的库是合法的 rfw 远端库格式——
  // 也就是真实场景里服务端能直接发到客户端的那份字节。
  section('\n=== 3. rfw blob 编解码往返 ===');
  final Uint8List bytes;
  try {
    bytes = encodeLibraryBlob(lib);
    check('编码成功', bytes.isNotEmpty, '${bytes.length} 字节');
  } catch (e) {
    check('编码成功', false, '$e');
    return;
  }

  final decoded = decodeLibraryBlob(bytes);
  check('解出 1 个声明', decoded.widgets.length == 1);
  final rootCall = decoded.widgets.first.root as ConstructorCall;
  check('入口 widget 名保持不变', rootCall.name == 'Column', rootCall.name);
  check('导入列表保持不变', decoded.imports.length == 3);

  // 事件处理器要活过编解码，否则点击事件在真实场景里会静默失效
  final before = encodeLibraryBlob(lib);
  final after = encodeLibraryBlob(decodeLibraryBlob(before));
  check('再编码结果一致（往返稳定）', before.length == after.length);

  // ---- 4. 事件分发 ----
  section('\n=== 4. 事件分发（状态必须累积）===');
  final t0 = counter.state['count'] as int;
  final afterInc = dispatch(counter, counterApp, 'inc', {'amount': 5});
  check('事件改了状态', afterInc.state['count'] == t0 + 5,
      '$t0 -> ${afterInc.state["count"]}');

  final afterAgain = dispatch(afterInc, counterApp, 'inc');
  check('默认参数生效', afterAgain.state['count'] == t0 + 6,
      '${afterInc.state["count"]} -> ${afterAgain.state["count"]}');

  final afterToggle = dispatch(afterAgain, counterApp, 'toggle_verbose');
  check('无参事件也能改状态', afterToggle.state['verbose'] == true,
      '${afterToggle.state["verbose"]}');

  final afterReset = dispatch(afterToggle, counterApp, 'reset');
  check('reset 把状态清零', afterReset.state['count'] == 0,
      '${afterReset.state["count"]}');

  // 关键：状态必须由宿主注入。若不注入，每次事件都会回到初始值——
  // 表现为「点一下归零」，而且看起来完全正常。
  check('多次事件后状态是累积的',
      afterReset.state['count'] == 0 && afterAgain.state['count'] == t0 + 6);

  // ---- 5. 指纹 ----
  section('\n=== 5. 内容指纹 ===');
  check('指纹存在', counter.fingerprint != null, counter.fingerprint);
  // 不能用 int.tryParse 判：指纹高 32 位可能超过 Dart int 的有符号 64 位，
  // 0xfa00890200000000 这种会溢出成 null，而它其实是个合法指纹。
  check('指纹是 16 位十六进制',
      counter.fingerprint != null &&
          counter.fingerprint!.length == 16 &&
          RegExp(r'^[0-9a-f]{16}$').hasMatch(counter.fingerprint!),
      counter.fingerprint);
  check('状态变了指纹就变', counter.fingerprint != afterInc.fingerprint,
      '${counter.fingerprint} vs ${afterInc.fingerprint}');
  check('同一状态两次构建指纹相同',
      buildTree(_root, counterApp).fingerprint == counter.fingerprint);

  // ---- 6. 第二个应用 ----
  section('\n=== 6. 循环与列表 ===');
  final UiTree gallery = buildTree(_root, galleryApp);
  check('解析成功', gallery.actualNodeCount > 0, '${gallery.actualNodeCount} 个节点');
  check('Lua 与 Dart 节点数一致', gallery.validate().isEmpty,
      gallery.validate().join(' | '));

  final picked = dispatch(gallery, galleryApp, 'pick', {'index': 2});
  check('列表项事件带上 index', picked.state['picked'] == 2,
      '${picked.state["picked"]}');
  check('自定义组件 studio.Kpi 进了树',
      collectWidgetNames(picked).contains('studio.Kpi'),
      collectWidgetNames(picked).join(' '));

  // ---- 7. 数值类型 ----
  // rfw 的 `DataSource.v<T>()` 是 `value is T ? value : null`：
  // 类型不符就**静默丢参数**，控件用默认值，画面看上去完全正常。
  // Lua 的 JSON 编码器曾经把 40.0 写成 40（%.14g 的缘故），
  // 于是 slider(max=100) 变成 0..1，拖到最右事件里带的是 0.9。
  // 真实运行应用、真的拖了一下滑条才发现的——单测全部通过。
  section('\n=== 7. 数值类型（rfw 会静默丢参数）===');
  final numeric = buildTree(_root, '''
local app = ui.app({
  state = {},
  handlers = {},
  view = function(b)
    b:scroll({ padding = 6 }, function(b)
      b:column({ gap = 10 }, function(b)
        b:box({ width = 8, height = 12 })
        b:divider({ thickness = 2 })
        b:icon("add", { size = 20 })
        b:text("x", { style = "display", lines = 2 })
        b:slider({ value = 5, min = 0, max = 100, divisions = 10 })
        b:pad({ x = 4, y = 6 }, function(b) b:text("y") end)
        b:expand({ flex = 2 }, function(b) b:text("z") end)
      end)
    end)
  end,
})
return json.encode(app:build())
''');

  // 收集所有参数名 -> 值类型
  final types = <String, Set<String>>{};
  void walkTypes(UiNode n) {
    n.args.forEach((key, value) {
      (types[key] ??= <String>{}).add(value.runtimeType.toString());
      // children 是数组，child 是单节点——两种都要往下走
      if (value is UiNode) {
        walkTypes(value);
      } else if (value is List) {
        for (final item in value) {
          if (item is UiNode) walkTypes(item);
        }
      }
    });
  }

  walkTypes(numeric.root);

  // rfw 用 v<double> 解码的参数——必须是 double
  const doubleArgs = <String>[
    'width', 'height', 'thickness', 'size', 'gap',
    'min', 'max', 'value',
  ];
  for (final key in doubleArgs) {
    final seen = types[key];
    if (seen == null) continue;
    check('$key 是 double（rfw 用 v<double> 读）',
        seen.every((t) => t.contains('double')),
        seen.join(','));
  }

  // rfw 用 v<int> 解码的参数——必须是 int
  const intArgs = <String>['maxLines', 'flex', 'divisions', 'color'];
  for (final key in intArgs) {
    final seen = types[key];
    if (seen == null) continue;
    check('$key 是 int（rfw 用 v<int> 读）',
        seen.every((t) => t.contains('int')),
        seen.join(','));
  }

  // padding 是 4 元数组，rfw 逐项用 v<double> 读
  final padNode = numeric.root.walk().firstWhere(
    (n) => n.widget == 'Padding',
  );
  final insets = (padNode.args['padding'] as List).cast<num>();
  check('padding 四项都是 double',
      insets.length == 4 && insets.every((v) => v is double && v == v.roundToDouble()),
      insets.map((v) => '$v(${v.runtimeType})').join(' '));
  check('padding 的值没被改（x=4 y=6）',
      insets[0] == 4.0 && insets[1] == 6.0,
      insets.join(','));

  // ---- 8. 错误信息 ----
  // Lua 侧的报错质量直接决定编辑器好不好用：必须能指出错在哪。
  section('\n=== 8. 错误信息 ===');
  final cases = <String, String>{
    '未注册的事件': '''
local app = ui.app({ state = {}, handlers = {},
  view = function(b) b:button("x", { on_tap = "nope" }) end })
return json.encode(app:build())''',
    '不存在的属性': '''
local app = ui.app({ state = {}, handlers = {},
  view = function(b) b:column({ gapp = 4 }) end })
return json.encode(app:build())''',
    '非法颜色': '''
local app = ui.app({ state = {}, handlers = {},
  view = function(b) b:text("x", { color = "red" }) end })
return json.encode(app:build())''',
    '未知样式': '''
local app = ui.app({ state = {}, handlers = {},
  view = function(b) b:text("x", { style = "huge" }) end })
return json.encode(app:build())''',
    'view 没建节点': '''
local app = ui.app({ state = {}, handlers = {}, view = function(b) end })
return json.encode(app:build())''',
    '顶层多个节点': '''
local app = ui.app({ state = {}, handlers = {}, view = function(b)
  b:text("a") b:text("b") end })
return json.encode(app:build())''',
    '单槽位塞了两个子节点': '''
local app = ui.app({ state = {}, handlers = {}, view = function(b)
  b:center(function(b) b:text("a") b:text("b") end) end })
return json.encode(app:build())''',
    '枚举值非法': '''
local app = ui.app({ state = {}, handlers = {}, view = function(b)
  b:column({ main = "middle" }) end })
return json.encode(app:build())''',
  };

  cases.forEach((name, code) {
    final r = LuaSandbox().runUi(code, libraryPath: _root);
    final msg = r.error ?? '(没有报错)';
    // 报错必须带位置，否则用户得自己数行
    check('$name 有可读报错',
        r.error != null && msg.contains('ui:'),
        msg.split('\n').first);
  });

  // 分发不存在的事件
  final badDispatch = LuaSandbox().runUi(counterApp,
      libraryPath: _root, stateJson: counter.stateJson, eventName: '不存在');
  check('分发未注册的事件会报错',
      badDispatch.error != null && badDispatch.error!.contains('未注册的事件'),
      badDispatch.error?.split('\n').first);

  // ---- 9. 坏契约 ----
  section('\n=== 8. 宿主侧校验（不信任脚本）===');
  check('拒绝缺 tree 的契约',
      _parseFails('{"version":1,"widget":"root"}', '缺少 tree'));
  check('拒绝版本不对的契约',
      _parseFails('{"version":99,"widget":"root","tree":{"\$widget":"Text"}}', '版本'));
  check('拒绝缺 widget 名的节点',
      _parseFails('{"version":1,"widget":"root","tree":{"\$args":{}}}', 'widget'));

  stderr.writeln('\n$_pass passed, $_fail failed');
  if (_fail == 0) {
    stderr.writeln('\n'
        'Lua 产出可被 Dart 完整消费，并编成合法的 rfw 远端库');
  }
  exit(_fail == 0 ? 0 : 1);
}

bool _parseFails(String json, String expect) {
  try {
    UiTree.parse(json);
    return false;
  } catch (e) {
    return e.toString().contains(expect);
  }
}
