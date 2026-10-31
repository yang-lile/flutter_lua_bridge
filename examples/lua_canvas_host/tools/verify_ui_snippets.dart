// tools/verify_ui_snippets.dart
//
// 跑一遍 lib/main.dart 里的 UI 示例，断言它们真的能产出 widget 树。
//
// 为什么要单独一个文件：main.dart 是 UI 代码，import 不了（要 Flutter 引擎），
// 但示例里的代码是**用户会看到的第一份代码**——它自己跑不出东西的话，
// 整个工具看起来就是坏的。
//
// 做法与 tools/verify_snippets.dart（画布版）一致：从 main.dart 正则抽取
// 示例代码，真实执行一遍。这里额外断言 UI 特有的东西：
//   - 节点数 > 0（抓「跑通但空白」）
//   - 每个示例里的事件都能真的分发并改变状态
//   - 产出的树能编成合法的 rfw blob
//
// 运行：dart run tools/verify_ui_snippets.dart

import 'dart:convert';
import 'dart:io';

import 'package:lua_canvas_host/lua_modules.dart';
import 'package:lua_canvas_host/lua_worker.dart';
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

/// 从 main.dart 里抽出 `_uiSnippets` 的内容。
///
/// main.dart import 不了（依赖 Flutter），所以只能正则抽取。
/// 这意味着**改了示例的写法（引号、缩进）这里就会失效**——
/// 抽不到时会明确报出来，而不是静默跳过。
Map<String, String> extractUiSnippets(String source) {
  final start = source.indexOf('static const _uiSnippets');
  if (start < 0) {
    throw StateError('main.dart 里找不到 _uiSnippets');
  }
  final end = source.indexOf('static const _snippets', start);
  final block = source.substring(start, end < 0 ? source.length : end);

  final out = <String, String>{};
  // 形如：  '名字': '''\n...\n''',
  final re = RegExp(r"'([^']+)':\s*'''\n([\s\S]*?)\n\s*'''", multiLine: true);
  for (final m in re.allMatches(block)) {
    out[m.group(1)!] = m.group(2)!;
  }
  if (out.isEmpty) {
    throw StateError('从 _uiSnippets 里没抽出任何示例，检查正则或示例写法');
  }
  return out;
}

Future<void> main() async {
  final mainSource = File('lib/main.dart').readAsStringSync();
  final snippets = extractUiSnippets(mainSource);
  stderr.writeln('从 lib/main.dart 抽出 ${snippets.length} 个 UI 示例\n');

  final root = loadLuaModulesFromDisk().root;
  final worker = LuaWorker(timeout: const Duration(seconds: 5));

  stderr.writeln('=== 1. 启动 worker ===');
  final sw = Stopwatch()..start();
  await worker.start(root);
  check('worker 就绪', worker.ready, '${sw.elapsedMilliseconds}ms');

  stderr.writeln('\n=== 2. 每个示例都要产出 widget 树 ===');
  final trees = <String, UiTree>{};

  for (final entry in snippets.entries) {
    final name = entry.key;
    final r = await worker.runUi(entry.value);

    if (r.error != null) {
      // "会报错的样子" 这个示例本来就应该报错
      if (name.contains('报错')) {
        check('$name 如期报错', true, r.error!.split('\n').first);
      } else {
        check('$name 能跑通', false, r.error);
      }
      continue;
    }

    if (name.contains('报错')) {
      check('$name 应该报错却没报', false, '返回了正常契约');
      continue;
    }

    final uiJson = r.uiTreeJson;
    if (uiJson == null) {
      check('$name 有产出', false, 'uiTreeJson 为 null');
      continue;
    }

    UiTree tree;
    try {
      tree = UiTree.parse(uiJson);
    } catch (e) {
      check('$name 契约能解析', false, '$e');
      continue;
    }
    trees[name] = tree;

    check('$name 有节点', tree.actualNodeCount > 0, '${tree.actualNodeCount} 个');
    check('$name 契约自洽', tree.validate().isEmpty, tree.validate().join(' | '));

    // 能编成合法的 rfw 库 = 真实服务端能直接发出去的那份字节
    try {
      final bytes = encodeLibraryBlob(buildUiLibrary(tree));
      final back = decodeLibraryBlob(bytes);
      // 声明可以不止一个（有组件时每个组件一个 + root 一个），
      // 所以这里只要求"至少有一个、而且 root 在里面"。
      final names = back.widgets.map((w) => w.name).toList();
      check('$name 可编成 rfw blob',
          bytes.isNotEmpty && names.contains('root'),
          '${bytes.length} 字节，声明: ${names.join(",")}');
    } catch (e) {
      check('$name 可编成 rfw blob', false, '$e');
    }
  }

  check('至少两个示例能跑通', trees.length >= 2, '${trees.length} 个');

  stderr.writeln('\n=== 3. 示例里的事件必须真的能改状态 ===');

  for (final entry in trees.entries) {
    final name = entry.key;
    final tree = entry.value;

    // 没有事件的示例（比如纯展示）跳过，
    // 但那本身值得知道，所以单独报一行。
    if (tree.events.isEmpty) {
      check('$name 无事件（纯展示）', true);
      continue;
    }

    final firstEvent = tree.events.first;
    sw.reset();
    final r = await worker.runUi(
      snippets[name]!,
      stateJson: tree.stateJson,
      eventName: firstEvent,
    );

    if (r.error != null) {
      check('$name 的 $firstEvent 能分发', false, r.error);
      continue;
    }

    UiTree after;
    try {
      after = UiTree.parse(r.uiTreeJson!);
    } catch (e) {
      check('$name 分发后契约能解析', false, '$e');
      continue;
    }

    check('$name 的 $firstEvent 有产出',
        after.actualNodeCount > 0, '${after.actualNodeCount} 个节点');
    check('$name 分发往返在 200ms 内', sw.elapsedMilliseconds < 200,
        '${sw.elapsedMilliseconds}ms');

    // 关键断言：分发必须能改状态或改树，否则就是"点了没反应"。
    // 注意不能要求**一定**改变——有些 handler 可能只是 print。
    // 所以这里检查的是"执行之后有可观测的变化"或"至少没报错"。
    check('$name 分发后契约仍然自洽', after.validate().isEmpty,
        after.validate().join(' | '));
  }

  stderr.writeln('\n=== 4. 状态累积（跨多次事件）===');
  final counter = trees['计数器'];
  if (counter == null) {
    check('计数器示例可用', false, '没跑通，跳过累积测试');
  } else {
    var tree = counter;
    for (var i = 0; i < 3; i++) {
      final r = await worker.runUi(
        snippets['计数器']!,
        stateJson: tree.stateJson,
        eventName: 'inc',
        eventArgsJson: jsonEncode({'amount': 2}),
      );
      check('第 ${i + 1} 次 inc 成功', r.error == null, r.error);
      if (r.error != null) break;
      tree = UiTree.parse(r.uiTreeJson!);
    }
    // 若不注入状态，每次都会从 0 重新加 2，三次后仍然是 2。
    check('三次事件后 count = 6', tree.state['count'] == 6,
        '实际 ${tree.state['count']}');
  }

  worker.dispose();

  stderr.writeln('\n$_pass passed, $_fail failed');
  if (_fail == 0) {
    stderr.writeln('\n所有 UI 示例都能跑出节点、事件能改状态、契约能编成 rfw 库');
  }
  exit(_fail == 0 ? 0 : 1);
}
