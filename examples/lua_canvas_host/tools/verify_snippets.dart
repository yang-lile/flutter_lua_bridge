// tools/verify_snippets.dart
//
// 验证编辑器里的每个预设示例都能真实执行并产出显示列表。
//
// 这个检查很有必要：示例是写给用户看的"第一份代码"，
// 如果它自己画不出东西（画布用错、变量遮蔽之类），用户第一眼就会
// 觉得整个工具是坏的。
//
// 运行：dart run tools/verify_snippets.dart

import 'dart:convert';
import 'dart:io';

import 'package:lua_canvas_host/lua_modules.dart';
import 'package:lua_canvas_host/sandbox.dart';

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

/// 示例直接从 lib/main.dart 里抽，避免两份定义漂移。
Map<String, String> loadSnippets() {
  final src = File('lib/main.dart').readAsStringSync();

  final start = src.indexOf('static const _snippets');
  if (start == -1) throw StateError('未找到 _snippets');

  // 必须在 _uiSnippets 之前截断。main.dart 里现在有两张示例表，
  // 不截断的话会连 UI 示例一起抽进来——它们要的是 ui 全局，
  // 在画布沙箱里跑必然报 "attempt to index a nil value (global 'ui')"。
  final uiStart = src.indexOf('static const _uiSnippets', start);
  final body = src.substring(start, uiStart == -1 ? src.length : uiStart);
  final out = <String, String>{};

  // 匹配 '名称': '''...''' 形式
  final re = RegExp("'([^']+)': '''([\\s\\S]*?)'''", multiLine: true);
  for (final m in re.allMatches(body)) {
    out[m.group(1)!] = m.group(2)!;
  }
  return out;
}

void main() {
  final root = loadLuaModulesFromDisk().root;
  final snippets = loadSnippets();

  stderr.writeln('=== 1. 抽取到 ${snippets.length} 个示例 ===');
  for (final k in snippets.keys) {
    stderr.writeln('  - $k');
  }
  check('示例数量为 6', snippets.length == 6, '${snippets.length}');

  stderr.writeln('\n=== 2. 逐个执行 ===');
  for (final entry in snippets.entries) {
    final name = entry.key;
    final code = entry.value;

    final r = LuaSandbox().run(code, libraryPath: root, budgetMs: 3000);

    if (r.error != null) {
      // 「会报错的样子」是故意出错的，跳过成功断言
      if (name == '会报错的样子') {
        check('$name（预期报错）', r.displayListJson == null,
            r.error!.split('\n').first);
      } else {
        check(name, false, r.error!.split('\n').first);
      }
      continue;
    }

    if (r.displayListJson == null) {
      check(name, false, '没有产出显示列表');
      continue;
    }

    final d = jsonDecode(r.displayListJson!) as Map<String, dynamic>;
    final opCount = (d['op_count'] as int?) ?? 0;

    // 关键断言：图元数必须 > 0。
    // 「运行成功但画面空白」就是 canvas.new 用错导致的。
    check(name, opCount > 0, '$opCount 个图元, ${d['width']}x${d['height']}');

    if (opCount > 0) {
      final ops = d['ops'] as List;
      final kinds = <String, int>{};
      for (final raw in ops) {
        final k = (raw as Map)['op'] as String;
        kinds[k] = (kinds[k] ?? 0) + 1;
      }
      final desc = kinds.entries.map((e) => '${e.key}=${e.value}').join(' ');
      stderr.writeln('         $desc');
    }
  }

  stderr.writeln('\n=== 3. 画布尺寸必须为正 ===');
  for (final entry in snippets.entries) {
    if (entry.key == '会报错的样子') continue;
    final r = LuaSandbox().run(entry.value, libraryPath: root, budgetMs: 3000);
    if (r.displayListJson == null) continue;
    final d = jsonDecode(r.displayListJson!) as Map<String, dynamic>;
    final w = (d['width'] as num).toDouble();
    final h = (d['height'] as num).toDouble();
    check('${entry.key} 尺寸有效', w > 0 && h > 0, '${w.toInt()}x${h.toInt()}');
  }

  stderr.writeln('\n=== 4. 指纹必须存在（宿主靠它重绘）===');
  for (final entry in snippets.entries) {
    if (entry.key == '会报错的样子') continue;
    final r = LuaSandbox().run(entry.value, libraryPath: root, budgetMs: 3000);
    if (r.displayListJson == null) continue;
    final d = jsonDecode(r.displayListJson!) as Map<String, dynamic>;
    final fp = d['fingerprint'] as String?;
    check('${entry.key} 有指纹', fp != null && fp.isNotEmpty, fp);
  }

  stderr.writeln('\n$_pass passed, $_fail failed');
  if (_fail > 0) exit(1);
}
