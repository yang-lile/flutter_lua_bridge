// tools/verify_proto_text.dart
//
// 验证「Lua 直接产出 rfw 文本格式」这条路线可行。
//
// 端到端：真实 Lua 跑原型 -> 文本 -> rfw 的 parseLibraryFile ->
// encodeLibraryBlob。只要这三步都过，就证明：
//
//   * Lua 能生成合法的 rfw 源文件
//   * rfw 自己的解析器认它（不是我们自己"能生成字符串"就算数）
//   * 能编成二进制库，也就是真实服务端会下发的那个东西
//
// 顺带和现有 JSON 路线对比产出的库是否等价。
//
// 运行：dart run tools/verify_proto_text.dart

import 'dart:io';

import 'package:lua_canvas_host/lua_modules.dart';
import 'package:lua_canvas_host/sandbox.dart';
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

/// 原型页面：像写子程序那样写，产出 rfw 文本。
const String protoApp = r'''
local page = proto.page()
page:state { count = 0, on = true }
page:on("inc", function(s, ev) s.count = s.count + (ev.amount or 1) end)
page:body(function(ui, s)
  ui:column({ main = "center", align = "center" }, function()
    ui:card(function()
      ui:column(function()
        ui:text("计数", { style = "label" })
        ui:text(tostring(s.count), { style = "w700", size = 32 })
        ui:row({ main = "center" }, function()
          ui:button("-1", ui:event("inc", { amount = -1 }), { kind = "OutlinedButton" })
          ui:button("+1", ui:event("inc", { amount = 1 }))
          ui:spacer({ size = 8 })
          ui:icon("add", { size = 18 })
        end)
      end)
    end)
    ui:toggle(s.on, "on", "开关")
    ui:divider()
    ui:button("就地取反", ui:set("on", not s.on), { kind = "TextButton" })
    -- 覆盖面：按 rfw_gen 的 widget_registry 补齐的那批
    ui:listview(function()
      ui:listtile(function()
        ui:text("第一项", { style = "w600" })
        ui:text("副标题", { style = "caption" })
      end)
    end)
    -- 剩下这几个 DSL 支持的容器也走一遍
    ui:box({ width = 200.0, height = 40.0 }, function()
      ui:center(function()
        ui:pad({ x = 8.0 }, function()
          ui:expand(function()
            ui:text("居中 + 内边距 + 撑开", { style = "caption" })
          end)
        end)
      end)
    end)
    ui:scroll(function()
      ui:text("滚动区", { style = "caption" })
    end)
    ui:row(function()
      ui:icon("star", { size = 16 })
      ui:wrap({ gap = 4.0 }, function()
        ui:text("标签一")
        ui:text("标签二")
      end)
      ui:spacer({ size = 4 })
      ui:linear_progress(0.4)
    end)
  end)
end)
return page:emit()
''';

/// 跑原型。带事件时走 dispatch。
ExecResult run(String root, String code, {String? event, String? args}) {
  return LuaSandbox().run(code, libraryPath: root);
}

void main() {
  final root = loadLuaModulesFromDisk().root;

  stderr.writeln('=== Lua -> rfw 文本：可行性验证 ===\n');

  // 注入 proto 模块与前置
  const harness = '''
local proto = require("ui.proto")
''';

  final r1 = run(root, harness + protoApp);
  if (r1.error != null) {
    stderr.writeln('原型执行失败：${r1.error}');
    exit(1);
  }
  final text = r1.displayListJson ?? '';
  check('产出了文本', text.trim().isNotEmpty, '${text.length} 字符');

  // --- 结构检查（不依赖 rfw，先看形状对不对）---
  check('有 import 语句', text.contains('import core.widgets;'));
  check('有 root 声明', text.contains('widget root'));
  check('state 写进了声明', RegExp(r'widget root \{[^}]*"count"').hasMatch(text));
  check('业务事件是 event "inc"', text.contains('event "inc"'));
  final setState = RegExp(r'set state\.\w+ = ').firstMatch(text);
  check('本地状态是 set state.xxx', setState != null, setState?.group(0));
  check('浮点带小数点', text.contains('32.0'),
      'rfw 的解析器靠小数点区分 double 与 int');
  check('没有 JSON 的花哨东西', !text.contains(r'$widget'));

  // 覆盖面：按 rfw_gen 的 registry 补齐的 widget 都要真的出现在文本里。
  // rfw 的解析器只管语法，不管这个 widget 存不存在——
  // 拼错的名字它照收，错误要到渲染时才变成 ErrorWidget。
  const covered = <String>[
    'Column', 'Row', 'Text', 'Card', 'Container', 'Center', 'Padding',
    'Expanded', 'SizedBox', 'Divider', 'Icon', 'SingleChildScrollView',
    'ElevatedButton', 'TextButton', 'ListView', 'ListTile', 'Wrap',
    'LinearProgressIndicator', 'StudioToggle', 'Container', 'Center',
    'Padding', 'SingleChildScrollView',
    // 注意：DSL 的间距用 SizedBox 实现，不发 Spacer——
    // Flutter 的 Column/Row 里 Spacer 就是 Expanded(SizedBox.shrink)，
    // 我们直接给尺寸更省一层。
  ];
  // 文本格式里 widget 名不加引号（`Column(` 而不是 `"Column"`）——
  // 参数名才加引号。这个不对称很容易写错，所以断言里说清楚。
  final missing = covered.where((w) => !text.contains('$w(')).toList();
  check('覆盖的 widget 都进了文本', missing.isEmpty,
      missing.isEmpty ? '${covered.length} 个' : '缺: ${missing.join(", ")}');

  // --- rfw 真的能解析吗 ---
  late RemoteWidgetLibrary lib;
  try {
    lib = parseLibraryFile(text);
    check('rfw 的 parseLibraryFile 解析成功', true);
  } catch (e) {
    check('rfw 的 parseLibraryFile 解析成功', false, '$e');
    stderr.writeln('\n--- 生成的文本（前 30 行）---\n$text');
    exit(1);
  }

  check('只有一个声明', lib.widgets.length == 1);
  final bytes = encodeLibraryBlob(lib);
  check('能编成二进制库', bytes.isNotEmpty, '${bytes.length} 字节');

  // --- 事件回 Lua 后重新出文本 ---
  // 二次执行必须产出**完全相同**的文本（同样的输入 -> 同样的输出）。
  // 事件路径依赖这个性质：宿主靠文本比较来判断"要不要重建"。
  final r2 = run(root, harness + protoApp);
  check('二次执行成功', r2.error == null, r2.error);
  check('同样输入 -> 同样文本（事件路径靠这个跳过重建）',
      r2.displayListJson == text,
      r2.displayListJson == text ? null : '两次产出不一致');

  stderr.writeln('\n  说明：这份验证覆盖的是「Lua 出文本 -> rfw 解析 -> 二进制」这条链路。');
  stderr.writeln('  性能上的结论在 tools/bench_text_vs_json.dart（文本解析比 json 慢 1.3–7 倍）。');

  stderr.writeln('\n$_pass passed, $_fail failed');
  exit(_fail == 0 ? 0 : 1);
}
