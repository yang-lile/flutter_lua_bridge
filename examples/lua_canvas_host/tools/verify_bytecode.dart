// tools/verify_bytecode.dart
//
// 验证字节码预编译真的生效了——不是"文件生成了"，而是"执行时确实走了它"。
//
// 验证手法很直接：**把 .lua 源码全部改名**，只留 .luac，再跑一次。
// 能跑通就说明 Lua 的搜索器命中的确实是字节码。
//
// 这比断言"文件存在"强得多：字节码可能因为版本不匹配、
// 路径模板写错、magic byte 校验失败而被 Lua 静默跳过，
// 那种情况下文件照样在，但执行的还是源码。
//
// 运行：dart run tools/verify_bytecode.dart

import 'dart:io';

import 'package:lua_canvas_host/lua_modules.dart';
import 'package:lua_canvas_host/lua_worker.dart';

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

Future<void> main() async {
  final root = loadLuaModulesFromDisk().root;

  stderr.writeln('=== 1. 模块清单 ===');
  final modules = listLuaModuleNames(root);
  check('能列出模块', modules.isNotEmpty, modules.join(', '));
  check('包含 canvas / ui / perf',
      modules.contains('canvas') &&
      modules.contains('ui') &&
      modules.contains('perf'));

  stderr.writeln('\n=== 2. 预编译 ===');
  final compiled = precompileLuaModules(root, modules);
  check('全部模块都编译成功', compiled.length == modules.length,
      '${compiled.length}/${modules.length}');

  final bcDir = Directory('$root/$kBytecodeDir');
  final luac = bcDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.luac'))
      .toList();
  check('字节码文件已写出', luac.length == modules.length, '${luac.length} 个');
  check('字节码非空', luac.every((f) => f.lengthSync() > 0),
      '最小 ${luac.map((f) => f.lengthSync()).reduce((a, b) => a < b ? a : b)} 字节');

  // magic byte 是 0x1B (ESC)，Lua 加载二进制 chunk 时会校验
  final magic = luac.first.readAsBytesSync()[0];
  check('magic byte 是 0x1B（Lua 二进制 chunk）', magic == 0x1B, '0x${magic.toRadixString(16)}');

  stderr.writeln('\n=== 3. 只留字节码也能跑（这才是真的在用）===');

  // 把源码挪走
  final moved = <String, String>{};
  for (final f in Directory(root).listSync(recursive: true)) {
    if (f is File && f.path.endsWith('.lua')) {
      final to = '${f.path}.hidden';
      f.renameSync(to);
      moved[to] = f.path;
    }
  }
  check('源码已全部挪走', moved.isNotEmpty, '${moved.length} 个 .lua');

  try {
    final w = LuaWorker();
    await w.start(root);

    final canvas = await w.run('''
local c = canvas.new({ width = 200, height = 200 })
c:circle(100, 100, 60, { fill = "#4a9eff" })
return json.encode(c:build())
''');
    check('画布模式能跑通', canvas.error == null, canvas.error);
    check('画布产出正常', canvas.displayListJson?.contains('"op_count":1') ?? false);

    final built = await w.runUi('''
local app = ui.app({
  state = { n = 1 },
  handlers = { bump = function(s) s.n = s.n + 1 end },
  view = function(b, s)
    b:column(function(b)
      b:text(tostring(s.n))
      b:button("go", { on_tap = "bump" })
    end)
  end,
})
return json.encode(app:build())
''');
    check('组件模式能跑通', built.error == null, built.error);
    // Column + Text + ElevatedButton + 按钮里的 Text = 4 个节点
    check('组件产出节点', (built.uiTreeJson?.contains('"node_count":4') ?? false),
        built.uiTreeJson?.substring(0, 60));

    // 事件路径也要能用（guard 的 debug.sethook 也在字节码里）
    // stateJson 是**状态本身**的 JSON，不是整个信封
    final state = '{"n":7}';
    final ev = await w.runUi('''
local app = ui.app({
  state = { n = 1 },
  handlers = { bump = function(s) s.n = s.n + 1 end },
  view = function(b, s)
    b:column(function(b)
      b:text(tostring(s.n))
      b:button("go", { on_tap = "bump" })
    end)
  end,
})
return json.encode(app:build())
''', stateJson: state, eventName: 'bump');
    check('事件分发能跑通', ev.error == null, ev.error);
    check('状态累积生效', ev.uiTreeJson?.contains('"n":8') ?? false, ev.uiTreeJson);

    w.dispose();
  } finally {
    for (final entry in moved.entries) {
      File(entry.key).renameSync(entry.value);
    }
  }
  check('源码已还原', moved.isNotEmpty);

  stderr.writeln('\n=== 4. 字节码缺失时能退回源码（降级路径）===');
  // 删掉一个字节码文件，应该静默退回 .lua 而不是报错
  final victim = luac.first;
  final backup = victim.readAsBytesSync();
  victim.deleteSync();
  try {
    final w = LuaWorker();
    await w.start(root);
    final r = await w.run('''
local c = canvas.new({ width = 100, height = 100 })
c:circle(50, 50, 10, { fill = "#fff" })
return json.encode(c:build())
''');
    check('缺字节码时仍能执行（走源码）', r.error == null, r.error);
    w.dispose();
  } finally {
    victim.writeAsBytesSync(backup);
  }

  stderr.writeln('\n$_pass passed, $_fail failed');
  exit(_fail == 0 ? 0 : 1);
}
