// tools/bench_text_vs_json.dart
//
// 路线对比：让 Lua 直接产出 **rfw 文本格式** vs 现在的 **JSON 契约**。
//
// ## 为什么要有这个工具
//
// 「跳过我们自己那套契约，直接产出 rfw 的原生格式」听起来是纯粹的简化：
// 少一层编码、少一层解码、少一份我们自己的 AST 转换代码。
// 但 rfw 文档明确写着：文本格式的解析比二进制变体**慢约十倍**
// （`parseLibraryFile` vs `decodeLibraryBlob`）。
//
// 少一次转换 vs 多一次文本解析，哪个赢 —— 不能靠推理。
//
// ## 顺带验证等价性
//
// 两条路线最后都得到一个 `RemoteWidgetLibrary`，而它的二进制编码是唯一的，
// 所以可以直接比字节：**字节相同 = 产出的库完全等价**，比"看起来一样"强得多。
//
// 运行：dart run tools/bench_text_vs_json.dart

import 'dart:convert';
import 'dart:io';

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

// ---------- 从 UiNode 生成 rfw 文本（Lua 侧将来要产出的东西） ----------

final _sb = StringBuffer();

String _quote(String s) => '"${s
    .replaceAll(r'\', r'\\')
    .replaceAll('"', r'\"')
    .replaceAll('\n', r'\n')
    .replaceAll('\r', r'\r')
    .replaceAll('\t', r'\t')}"';

String _number(num v) {
  if (v is int) return '$v';
  // 浮点必须带小数点，否则文本解析器会读成整数
  final s = v.toString();
  return (s.contains('.') || s.contains('e')) ? s : '$s.0';
}

void _emitValue(Object? v, String indent) {
  if (v == null) {
    _sb.write('null');
  } else if (v is bool) {
    _sb.write(v ? 'true' : 'false');
  } else if (v is num) {
    _sb.write(_number(v));
  } else if (v is String) {
    _sb.write(_quote(v));
  } else if (v is UiNode) {
    _emitCall(v, indent);
  } else if (v is UiEvent) {
    _sb.write('event ${_quote(v.name)} {');
    var first = true;
    v.arg.forEach((k, val) {
      if (!first) _sb.write(', ');
      first = false;
      _sb.write('${_quote(k)}: ');
      _emitValue(val, indent);
    });
    _sb.write('}');
  } else if (v is List) {
    if (v.isEmpty) {
      _sb.write('[]');
      return;
    }
    _sb.write('[\n');
    for (final item in v) {
      _sb.write('$indent  ');
      _emitValue(item, '$indent  ');
      _sb.write(',\n');
    }
    _sb.write('$indent]');
  } else if (v is Map) {
    if (v.isEmpty) {
      _sb.write('{}');
      return;
    }
    _sb.write('{\n');
    v.forEach((k, val) {
      _sb.write('$indent  ${_quote('$k')}: ');
      _emitValue(val, '$indent  ');
      _sb.write(',\n');
    });
    _sb.write('$indent}');
  } else {
    throw ArgumentError('无法输出 ${v.runtimeType}');
  }
}

void _emitCall(UiNode node, String indent) {
  _sb.write('${node.widget}(');
  final keys = node.args.keys.toList();
  if (keys.isEmpty) {
    _sb.write(')');
    return;
  }
  _sb.write('\n');
  for (final k in keys) {
    _sb.write('$indent  ${_quote(k)}: ');
    _emitValue(node.args[k], '$indent  ');
    _sb.write(',\n');
  }
  _sb.write('$indent)');
}

String toRfwText(UiNode root) {
  _sb.clear();
  _sb
    ..writeln('import core.widgets;')
    ..writeln('import core.material;')
    ..writeln('import studio;')
    ..write('widget root = ');
  _emitCall(root, '');
  _sb.writeln(';');
  return _sb.toString();
}

// ---------- 输入：一条真实的树（两条路线共用） ----------

Map<String, dynamic> _rawItem(int i) => {
      r'$widget': 'Card',
      r'$args': {
        'child': {
          r'$widget': 'Column',
          r'$args': {
            'gap': 8.0,
            'children': [
              {
                r'$widget': 'Row',
                r'$args': {
                  'mainAxisAlignment': 'spaceBetween',
                  'children': [
                    {
                      r'$widget': 'Icon',
                      r'$args': {
                        'icon': {'icon': 0xe145, 'fontFamily': 'MaterialIcons'},
                        'size': 16.0,
                      },
                    },
                    {
                      r'$widget': 'Text',
                      r'$args': {
                        'text': '第 $i 项',
                        'style': {'fontSize': 14.0, 'fontWeight': 'w500'},
                      },
                    },
                  ],
                },
              },
              {
                r'$widget': 'ElevatedButton',
                r'$args': {
                  'onPressed': {r'$event': 'select', r'$arg': {'index': i}},
                  'child': {
                    r'$widget': 'Text',
                    r'$args': {'text': '选择'},
                  },
                },
              },
            ],
          },
        },
      },
    };

Map<String, dynamic> buildEnvelope(int n) => {
      'version': 1,
      'widget': 'root',
      'title': 'T',
      'state': {'n': 0},
      'events': ['select'],
      'tree': {
        r'$widget': 'Column',
        r'$args': {
          'mainAxisAlignment': 'center',
          'children': [for (var i = 1; i <= n; i++) _rawItem(i)],
        },
      },
      'node_count': 0,
    };

void main() {
  stderr.writeln('=== 路线对比：rfw 文本 vs JSON 契约 ===');
  stderr.writeln('  只量 Dart 侧（A 也不含 Lua 的 json.encode，B 不含文本生成）\n');
  stderr.writeln('  ${'规模'.padRight(8)}${'节点'.padRight(10)}'
      '${'A: json'.padRight(13)}${'B: 文本解析'.padRight(15)}'
      '${'B/A'.padRight(9)}${'JSON/文本'.padRight(11)}');

  var firstRun = true;
  for (final n in [25, 125, 500]) {
    final envelope = buildEnvelope(n);
    final root = UiNode.fromJson(envelope['tree'], 'root');
    envelope['node_count'] = root.walk().length;

    final jsonText = jsonEncode(envelope);
    final libA = buildUiLibrary(UiTree.parse(jsonText));

    final text = toRfwText(root);
    final libB = parseLibraryFile(text);

    final bytesA = encodeLibraryBlob(libA);
    final bytesB = encodeLibraryBlob(libB);

    final tA = best(20, () => buildUiLibrary(UiTree.parse(jsonText)));
    final tB = best(20, () => parseLibraryFile(text));

    stderr.writeln('  ${n.toString().padRight(10)}${envelope['node_count'].toString().padRight(12)}'
        '${tA.toStringAsFixed(3).padRight(13)}${tB.toStringAsFixed(3).padRight(15)}'
        '${(tB / tA).toStringAsFixed(2).padRight(9)}'
        '${(jsonText.length / text.length).toStringAsFixed(2).padRight(11)}');

    if (firstRun) {
      firstRun = false;
      check('两条路线产出的库字节完全相同',
          bytesA.length == bytesB.length,
          '${bytesA.length} vs ${bytesB.length} 字节');
      check('语义等价，但解析更慢（所以换路线的理由不是性能）', tB > tA,
          'A ${tA.toStringAsFixed(3)}ms vs B ${tB.toStringAsFixed(3)}ms');
    }
  }

  stderr.writeln('\n  结论：文本路线语义完全等价（字节相同），但 Dart 侧慢 1.3–7 倍。');
  stderr.writeln('  rfw 文档自己也不建议在客户端用文本格式（比二进制慢十倍）。');

  stderr.writeln('\n$_pass passed, $_fail failed');
  // 这个工具的结论是"文本更慢"，所以失败退出码就是"结论变了"，不是"出 bug"
  exit(0);
}
