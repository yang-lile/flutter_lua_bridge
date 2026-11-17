import 'dart:io';

import 'package:flutter_lua_bridge_codegen/lua_runner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory project;
  late List<String> printed;
  late LuaRunner runner;

  void write(String path, String content) {
    final file = File(p.join(project.path, path));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  String path(String relative) => p.join(project.path, relative);

  setUp(() {
    project = Directory.systemTemp.createTempSync('lua_runner_test_');
    printed = [];
    runner = LuaRunner(output: printed.add);
    write('tlconfig.lua', '''
return {
  source_dir = "lua/src",
  include_dir = { "lua/src", "lua/types" },
}
''');
    write('lua/types/demo_bridge.d.tl', '''
local record Demo
  record CounterApi
    next: function(integer): integer
  end
  bindCounterApi: function(CounterApi): CounterApi
  record HostApi
    label: function(string): string
  end
  getHostApi: function(): HostApi
end
return Demo
''');
    write('lua/src/counter.tl', '''
local bridge = require("demo_bridge")
return bridge.bindCounterApi({
  next = function(n: integer): integer return n + 1 end,
})
''');
    write('lua/src/labels.tl', '''
local bridge = require("demo_bridge")
local host = bridge.getHostApi()
return { describe = function(n: integer): string return host.label(tostring(n)) end }
''');
  });

  tearDown(() => project.deleteSync(recursive: true));

  test('runs a Teal entry with the project modules and stubbed bind', () async {
    write('lua/test/counter_test.tl', '''
local counter = require("counter")
local helper = require("helper")
assert(counter.next(helper.start) == 42)
print("args", ...)
''');
    // Next to the entry, so it is found before the configured directories.
    write('lua/test/helper.tl', 'return { start = 41 }');
    final result = await runner.run(
      path('lua/test/counter_test.tl'),
      arguments: ['a', 'b'],
    );
    expect(result.error, isNull);
    expect(result.passed, isTrue);
    expect(printed, ['args\ta\tb']);
  });

  test('a failed assertion fails the entry with its location', () async {
    write('lua/test/bad_test.lua', '''
local counter = require("counter")
assert(counter.next(1) == 3, "off by one")
''');
    final result = await runner.run(path('lua/test/bad_test.lua'));
    expect(result.passed, isFalse);
    expect(result.error, contains('bad_test.lua:2: off by one'));
    expect(result.error, isNot(contains('xpcall')));
    expect(result.error, isNot(contains('flb_run:')));
  });

  test('Teal type errors fail the entry before it runs', () async {
    write('lua/test/typed_test.tl', '''
local counter = require("counter")
print("ran")
local s: string = counter.next(1)
''');
    final result = await runner.run(path('lua/test/typed_test.tl'));
    expect(result.passed, isFalse);
    expect(result.error, contains('typed_test.tl:3:'));
    expect(printed, isEmpty);
  });

  test('type errors in a required module are reported', () async {
    write('lua/src/broken.tl', 'local n: integer = "x"\nreturn n\n');
    write('lua/test/broken_test.tl', 'require("broken")\n');
    final result = await runner.run(path('lua/test/broken_test.tl'));
    expect(result.passed, isFalse);
    expect(result.error, contains('broken.tl:1:'));
  });

  test('Dart host functions are stubbed by the entry', () async {
    write('lua/test/host_test.tl', '''
local bridge = require("demo_bridge")
local host = bridge.getHostApi()
host.label = function(s: string): string return "#" .. s end
assert(require("labels").describe(7) == "#7")
''');
    expect((await runner.run(path('lua/test/host_test.tl'))).passed, isTrue);

    write('lua/test/unstubbed_test.lua', 'require("labels").describe(7)\n');
    final result = await runner.run(path('lua/test/unstubbed_test.lua'));
    expect(result.passed, isFalse);
    expect(result.error, contains('demo_bridge: HostApi.label is not stubbed'));
  });

  test('only *_bridge modules are stubbed', () async {
    write('lua/test/missing_test.lua', 'require("nowhere")\n');
    final result = await runner.run(path('lua/test/missing_test.lua'));
    expect(result.passed, isFalse);
    expect(result.error, contains("module 'nowhere' not found"));
  });

  test('directories expand to main and *_test entries', () {
    write('lua/test/a_test.tl', '');
    write('lua/test/nested/main.lua', '');
    write('lua/test/helper.tl', '');
    write('lua/test/types_test.d.tl', '');
    final entries = LuaRunner.entries([path('lua/test')]);
    expect(entries.map((e) => p.relative(e, from: project.path)), [
      p.join('lua', 'test', 'a_test.tl'),
      p.join('lua', 'test', 'nested', 'main.lua'),
    ]);
    expect(
      () => LuaRunner.entries([path('missing')]),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('the nearest tlconfig.lua sets the search directories', () {
    final found = LuaRunner.project(path('lua/test/x_test.tl'));
    expect(found.config, path('tlconfig.lua'));
    expect(found.searchDirs, [
      path('lua/test'),
      path('lua/src'),
      path('lua/types'),
    ]);

    File(path('tlconfig.lua')).deleteSync();
    final bare = LuaRunner.project(path('lua/test/x_test.tl'));
    expect(bare.config, isNull);
    expect(bare.searchDirs, [path('lua/test')]);
  });
}
