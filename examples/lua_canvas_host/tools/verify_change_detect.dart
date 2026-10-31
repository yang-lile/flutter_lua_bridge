// tools/verify_change_detect.dart
//
// 验证「内容变了没有」的判断是对的。
//
// ## 为什么单独一个工具
//
// 判断错的后果是**静默漏更新**：画面停住不刷新，界面上没有任何报错。
// 这类 bug 靠"跑一遍看看对不对"发现不了 —— 它在绝大多数时候都对。
//
// ## 验的是两件事
//
// 1. **结构相同 -> 不重建**（否则白重建，白掉帧）
// 2. **任何一处不同 -> 一定重建**（否则漏更新）
//
// 第 2 条里的"任何一处"是重点：遍历每一个可选字段逐一改动，确认都能被发现。
// 早期的内容指纹就漏过字段 —— 而单测全绿。
//
// ## 为什么能在纯 Dart 里跑
//
// 比较发生在**原始 JSON** 上（见 `lib/deep_equality.dart` 的说明）：
// `DisplayList` 里的 DrawOp 用 `dart:ui`，纯 Dart VM 跑不起来，
// 但原始 JSON 是纯 Dart 的。所以这里测的是**生产用的同一份比较函数**，
// 而不是它的副本。
//
// 运行：dart run tools/verify_change_detect.dart

import 'dart:convert';
import 'dart:io';

import 'package:lua_canvas_host/deep_equality.dart';
import 'package:lua_canvas_host/lua_modules.dart';
import 'package:lua_canvas_host/sandbox.dart';
import 'package:lua_canvas_host/ui_tree.dart';

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

/// 跑一段画布代码，返回它的**内容部分**（剥掉派生字段）。
///
/// 用的是生产代码里的同一个 [contentOf]，规则不会两边跑偏。
Map<String, dynamic> canvasJson(String root, String body) {
  final r = LuaSandbox().run(body, libraryPath: root);
  if (r.error != null) throw StateError(r.error!);
  return contentOf(jsonDecode(r.displayListJson!) as Map<String, dynamic>);
}

/// 跑一段画布代码，返回未经处理的原始 JSON（含 fingerprint）。
Map<String, dynamic> canvasJsonRaw(String root, String body) {
  final r = LuaSandbox().run(body, libraryPath: root);
  if (r.error != null) throw StateError(r.error!);
  return jsonDecode(r.displayListJson!) as Map<String, dynamic>;
}

/// 跑一段 UI 代码，返回它的原始 JSON。
Map<String, dynamic> uiJsonOf(String root, String body) {
  final r = LuaSandbox().runUi(body, libraryPath: root);
  if (r.error != null) throw StateError(r.error!);
  return jsonDecode(r.uiTreeJson!) as Map<String, dynamic>;
}

/// 画布判定的快路径：指纹相同就直接认为相同。
///
/// 与 `DisplayList.sameAs` 的第一步一致。
bool canvasFastPath(Map<String, dynamic> a, Map<String, dynamic> b) {
  final fa = a['fingerprint'];
  final fb = b['fingerprint'];
  return fa != null && fb != null && fa == fb;
}

void main() {
  final root = loadLuaModulesFromDisk().root;

  // ================================================================
  stderr.writeln('=== 1. 画布：逐字段改动都必须被发现 ===');
  // ================================================================
  String canvasWith({
    int w = 300,
    int h = 200,
    String bg = '#101010',
    String ops = 'c:circle(10,10,5,{fill="#fff"})',
  }) =>
      '''
local c = canvas.new({ width = $w, height = $h, background = "$bg" })
$ops
return json.encode(c:build())
''';

  final cBaseRaw = canvasJsonRaw(root, canvasWith());
  final cBase = contentOf(cBaseRaw);

  check('自比较 -> 相同', deepEquals(cBase, cBase));
  check('null -> 不同', !deepEquals(cBase, null));

  final cMutations = <String, Map<String, dynamic>>{
    '宽度': canvasJson(root, canvasWith(w: 301)),
    '高度': canvasJson(root, canvasWith(h: 201)),
    '背景': canvasJson(root, canvasWith(bg: '#101011')),
    '圆心 x': canvasJson(root, canvasWith(ops: 'c:circle(11,10,5,{fill="#fff"})')),
    '半径': canvasJson(root, canvasWith(ops: 'c:circle(10,10,6,{fill="#fff"})')),
    '填充色': canvasJson(root, canvasWith(ops: 'c:circle(10,10,5,{fill="#eee"})')),
    '描边色': canvasJson(root, canvasWith(ops: 'c:circle(10,10,5,{fill="#fff",stroke="#f00"})')),
    '线宽': canvasJson(root,
        canvasWith(ops: 'c:circle(10,10,5,{fill="#fff",stroke="#f00",stroke_width=2})')),
    '圆角': canvasJson(root, canvasWith(ops: 'c:rect(1,1,5,5,{fill="#fff",radius=3})')),
    '矩形宽': canvasJson(root, canvasWith(ops: 'c:rect(1,1,6,5,{fill="#fff",radius=3})')),
    '文本内容': canvasJson(root, canvasWith(ops: 'c:text(1,1,"a",{fill="#fff"})')),
    '文本对齐': canvasJson(root,
        canvasWith(ops: 'c:text(1,1,"a",{fill="#fff",align="center"})')),
    '字号': canvasJson(root, canvasWith(ops: 'c:text(1,1,"a",{fill="#fff",size=20})')),
    '线的端点': canvasJson(root, canvasWith(ops: 'c:line(0,0,11,10,{stroke="#fff"})')),
    '多边形顶点': canvasJson(root,
        canvasWith(ops: 'c:polygon({{x=0,y=0},{x=9,y=0},{x=0,y=9}},{fill="#fff"})')),
    '图元数量': canvasJson(root, canvasWith(
        ops: 'c:circle(10,10,5,{fill="#fff"}) c:circle(20,20,5,{fill="#fff"})')),
    '图元顺序': canvasJson(root, canvasWith(
        ops: 'c:circle(20,20,5,{fill="#fff"}) c:circle(10,10,5,{fill="#fff"})')),
  };

  cMutations.forEach((what, other) {
    check('改动「$what」-> 判定为不同', !deepEquals(cBase, other));
    check('改动「$what」-> 反向也判定为不同', !deepEquals(other, cBase));
  });

  // 同样的内容跑两遍 -> 必须完全相同（指纹与结构都一样）
  check('同样内容跑两遍 -> 相同', deepEquals(cBase, canvasJson(root, canvasWith())));
  check('同样内容跑两遍 -> 指纹也相同',
      cBaseRaw['fingerprint'] == canvasJsonRaw(root, canvasWith())['fingerprint']);

  // ================================================================
  stderr.writeln('\n=== 2. 快路径与权威判断的分工 ===');
  // ================================================================
  // 内容相同、只有指纹不同 —— 纯指纹方案在这里会白白重建
  // 内容一样、指纹换成别的值
  final withFingerprint = <String, dynamic>{
    ...cBaseRaw,
    'fingerprint': 'ffffffffffffffff',
  };
  final sameContentNewFingerprint = contentOf(withFingerprint);
  check('内容相同 + 指纹不同 -> 仍然判定为相同',
      deepEquals(cBase, sameContentNewFingerprint),
      '纯指纹方案在这里会白白重建');
  check('内容相同 + 指纹不同 -> 快路径不放行，交给结构比较裁决',
      !canvasFastPath(cBaseRaw, withFingerprint));
  check('内容不同 -> 快路径也会放行（所以权威判断不能省）',
      !deepEquals(cBase, cMutations['宽度']!));

  final noFingerprint = cBaseRaw.containsKey('fingerprint')
      ? (Map<String, dynamic>.from(cBaseRaw)..remove('fingerprint'))
      : cBaseRaw;
  check('缺指纹时靠结构比较仍能认出相同',
      deepEquals(cBase, contentOf(noFingerprint)));
  check('缺指纹时快路径不放行（交给结构比较）',
      !canvasFastPath(cBaseRaw, noFingerprint));

  // ================================================================
  stderr.writeln('\n=== 3. 组件树：逐字段改动都必须被发现 ===');
  // ================================================================
  String uiWith({
    String text = 'hi',
    String style = 'body',
    String color = '#ffffff',
    String align = 'left',
    int gap = 4,
    String event = 'go',
    int? argIndex,
    String variant = 'elevated',
    bool toggle = true,
    double? sliderMax,
    int title = 0,
  }) {
    final stylePart = 'style = "$style"';
    return '''
local app = ui.app({
  title = "T$title",
  state = {},
  handlers = { go = function() end, stop = function() end },
  view = function(b, s)
    b:column({ gap = $gap }, function(b)
      b:text("$text", { $stylePart, color = "$color", align = "$align" })
      b:button("B", { on_tap = "$event"${argIndex != null ? ', arg = { index = $argIndex }' : ''}, variant = "$variant" })
      b:toggle({ value = $toggle, on_change = "go" })${sliderMax != null ? '''
      b:slider({ value = 1, min = 0, max = $sliderMax, on_change = "go" })''' : ''}
    end)
  end,
})
return json.encode(app:build())
''';
  }

  final uBase = uiJsonOf(root, uiWith());
  final uBaseTree = UiTree.parse(jsonEncode(uBase));

  final uMutations = <String, Map<String, dynamic>>{
    '标题': uiJsonOf(root, uiWith(title: 1)),
    '文本内容': uiJsonOf(root, uiWith(text: 'bye')),
    '样式预设': uiJsonOf(root, uiWith(style: 'title')),
    '颜色': uiJsonOf(root, uiWith(color: '#eeeeee')),
    '对齐': uiJsonOf(root, uiWith(align: 'center')),
    'gap': uiJsonOf(root, uiWith(gap: 9)),
    '事件名': uiJsonOf(root, uiWith(event: 'stop')),
    '事件参数': uiJsonOf(root, uiWith(argIndex: 7)),
    '按钮变体': uiJsonOf(root, uiWith(variant: 'outlined')),
    '开关值': uiJsonOf(root, uiWith(toggle: false)),
    '滑条上限': uiJsonOf(root, uiWith(sliderMax: 99)),
  };

  uMutations.forEach((what, other) {
    check('改动「$what」-> 判定为不同', !uiTreeEquals(uBaseTree, UiTree.parse(jsonEncode(other))));
    if (what == '标题') {
      // 标题在信封顶层：树本身没变，但整体内容变了。
      // uiTreeEquals 把 title 算进判断，所以照样能发现。
      check('改动「标题」-> 树没变但整体判定为不同',
          deepEquals(uBase['tree'], other['tree']) &&
              !uiTreeEquals(uBaseTree, UiTree.parse(jsonEncode(other))));
    } else {
      check('改动「$what」-> 树也判定为不同',
          !deepEquals(uBase['tree'], other['tree']));
    }
  });

  check('同样内容跑两遍 -> 相同', uiTreeEquals(uBaseTree, UiTree.parse(jsonEncode(uiJsonOf(root, uiWith())))));

  // state 不参与比较：只改 state 不该触发重建
  final onlyState = uiJsonOf(root, '''
local app = ui.app({
  title = "T0",
  state = { n = ${DateTime.now().microsecondsSinceEpoch} },
  handlers = { go = function() end },
  view = function(b, s)
    b:column({ gap = 4 }, function(b)
      b:text("hi", { style = "body", color = "#ffffff", align = "left" })
      b:button("B", { on_tap = "go", variant = "elevated" })
      b:toggle({ value = true, on_change = "go" })
    end)
  end,
})
return json.encode(app:build())
''');
  check('只改 state（树不变）-> 不重建', uiTreeEquals(uBaseTree, UiTree.parse(jsonEncode(onlyState))),
      'state 变了但界面没变是正常的');

  // ================================================================
  stderr.writeln('\n=== 4. 数值类型必须区分 ===');
  // ================================================================
  check('int 1 与 double 1.0 判为不同', !deepEquals({'v': 1}, {'v': 1.0}),
      'rfw 的 v<int> 与 v<double> 是两套解码');
  check('int 1 与 int 1 判为相同', deepEquals({'v': 1}, {'v': 1}));
  check('double 1.0 与 double 1.0 判为相同', deepEquals({'v': 1.0}, {'v': 1.0}));

  // ================================================================
  stderr.writeln('\n=== 5. 差异定位（诊断用）===');
  // ================================================================
  {
    final out = <String>[];
    final changed = canvasJson(root, canvasWith(ops: 'c:circle(11,10,5,{fill="#fff"})'));
    findFirstDifference(cBase, changed, 'dl', out);
    check('能指出具体位置', out.isNotEmpty && out.first.contains('ops'),
        out.isEmpty ? '没有差异' : out.first);
  }

  stderr.writeln('\n$_pass passed, $_fail failed');
  exit(_fail == 0 ? 0 : 1);
}
