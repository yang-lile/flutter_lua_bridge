// The general-purpose side of LuaRuntime. tool/test_lua_versions.sh runs this
// file against every bundled Lua release and sets FLB_EXPECT_LUA_VERSION so a
// build of the wrong release cannot pass unnoticed.
import 'dart:io';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:test/test.dart';

void main() {
  late LuaRuntime lua;
  setUp(() => lua = LuaRuntime.create());
  tearDown(() => lua.close());

  test('reports the Lua release the hook was asked to build', () {
    final version = LuaRuntime.luaVersion;
    expect(version, anyOf(503, 504, 505));
    expect(LuaRuntime.luaRelease, startsWith('Lua 5.${version % 100}.'));
    final expected = Platform.environment['FLB_EXPECT_LUA_VERSION'];
    if (expected != null && expected.isNotEmpty) {
      expect(LuaRuntime.luaRelease, startsWith('Lua $expected'));
    }
    expect(lua.eval('return _VERSION'), 'Lua 5.${version % 100}');
  });

  test('keeps integers, floats, strings and nil apart', () {
    final values = lua.run("return 1, 1.5, 'Lua 中文', true, nil, 2^53");
    expect(values, [1, 1.5, 'Lua 中文', true, null, 9007199254740992.0]);
    expect(values[0], isA<int>());
    expect(values[5], isA<double>());
  });

  test('reads and writes globals', () {
    lua['answer'] = 42;
    lua['config'] = {
      'name': 'demo',
      'tags': ['a', 'b'],
    };
    expect(lua['answer'], 42);
    expect(lua.eval('return config.name .. #config.tags'), 'demo2');
    expect(lua['missing'], isNull);
    expect(lua.globals['answer'], 42);
  });

  test('tables are handles with table semantics', () {
    final table = lua.eval('return {10, 20, 30, name = "t"}')! as LuaTable;
    expect(table.length, 3);
    expect(table[2], 20);
    expect(table['name'], 't');
    table['name'] = 'renamed';
    table[4] = 40;
    expect(table.sequence, [10, 20, 30, 40]);
    expect(table.entries, {1: 10, 2: 20, 3: 30, 4: 40, 'name': 'renamed'});
    lua['t'] = table;
    expect(lua.eval('return t.name'), 'renamed');
    expect(table.sameAs(lua['t']! as LuaTable), isTrue);

    final made = lua.table({'x': 1});
    made.metatable = lua.table({
      '__index': lua.eval('return function(_, k) return k .. "!" end'),
    });
    expect(made['x'], 1);
    expect(made['y'], 'y!');
    expect(made.get('y', raw: true), isNull);
  });

  test('copies a table to plain Dart data', () {
    final table =
        lua.eval(
              'return {id = "a", stats = {hp = 10, rate = 0.5}, '
              'tags = {"x", "y"}, empty = {}}',
            )!
            as LuaTable;
    expect(table.toDart(), {
      'id': 'a',
      'stats': {'hp': 10, 'rate': 0.5},
      'tags': ['x', 'y'],
      'empty': <Object, Object?>{},
    });
    final cyclic = lua.eval('local t = {} t.t = t return t')! as LuaTable;
    expect(
      cyclic.toDart,
      throwsA(
        isA<LuaBridgeException>()
            .having((e) => e.status, 'status', LuaStatus.argument)
            .having((e) => e.message, 'message', contains('cyclic')),
      ),
    );
  });

  test('calls Lua functions with every result', () {
    final divmod =
        lua.eval('return function(a, b) return a // b, a % b end')!
            as LuaFunction;
    expect(divmod.call([17, 5]), [3, 2]);
    final object =
        lua.eval(
              'return {n = 1, add = function(self, d) return self.n + d end,'
              ' twice = function(x) return x * 2 end}',
            )!
            as LuaTable;
    expect(object.callMethod('add', [4]), [5]);
    expect(object.call('twice', [4]), [8]);
  });

  test('reports syntax and runtime errors with a traceback', () {
    expect(
      () => lua.run('return +', name: '=broken'),
      throwsA(
        isA<LuaBridgeException>()
            .having((e) => e.status, 'status', LuaStatus.syntax)
            .having((e) => e.message, 'message', contains('broken:1:')),
      ),
    );
    expect(
      () => lua.run("local function f() error('boom') end f()"),
      throwsA(
        isA<LuaBridgeException>()
            .having((e) => e.status, 'status', LuaStatus.runtime)
            .having((e) => e.message, 'message', contains('boom'))
            .having((e) => e.traceback, 'traceback', contains('traceback')),
      ),
    );
    expect(lua.eval('return 1'), 1);
  });

  test('Lua calls Dart functions, including re-entrant ones', () {
    lua['add'] = lua.function((args) => (args[0]! as int) + (args[1]! as int));
    lua['split'] = lua.function(
      (args) => LuaValues((args[0]! as String).split(',')),
    );
    lua['twice'] = lua.function((args) => lua.eval('return ${args[0]} * 2'));
    lua['apply'] = lua.function(
      (args) => (args[0]! as LuaFunction).call([args[1]]).first,
    );
    expect(
      lua.run("local a, b, c = split('x,y,z') return add(20, 22), a, b, c"),
      [42, 'x', 'y', 'z'],
    );
    expect(lua.eval('return twice(21)'), 42);
    expect(lua.eval('return apply(function(n) return n + 1 end, 1)'), 2);
  });

  test('a Dart exception is a Lua error and comes back as the cause', () {
    final failure = StateError('from dart');
    lua['fail'] = lua.function((_) => throw failure);
    expect(lua.run('local ok, e = pcall(fail) return ok, type(e), e'), [
      false,
      'string',
      contains('from dart'),
    ]);
    expect(
      () => lua.run('fail()'),
      throwsA(
        isA<LuaBridgeException>()
            .having((e) => e.status, 'status', LuaStatus.host)
            .having((e) => e.cause, 'cause', same(failure))
            .having((e) => e.message, 'message', contains('from dart')),
      ),
    );
  });

  test('Dart objects travel through Lua as userdata', () {
    final type = lua.createClass('Counter');
    type['__index'] = lua.table({
      'value': lua.function(
        (args) => ((args[0]! as LuaUserdata).object! as List<int>).length,
      ),
    });
    final counter = <int>[1, 2, 3];
    lua['counter'] = lua.wrap(counter, type);
    expect(lua.eval('return counter:value()'), 3);
    expect((lua['counter']! as LuaUserdata).object, same(counter));
    expect(lua.eval('return tostring(counter)'), startsWith('Counter'));
  });

  test('host functions that Lua drops are forgotten', () {
    var calls = 0;
    lua['temporary'] = lua.function((_) => calls++);
    lua.run('temporary() temporary = nil');
    lua.collectGarbage();
    lua.collectGarbage();
    expect(calls, 1);
    expect(lua.eval('return temporary'), isNull);
  });

  test('modules: setModule, preload and searchers', () {
    lua.setModule('host.config', {'level': 3});
    expect(lua.eval("return require('host.config').level"), 3);
    lua.preload('lazy', lua.function((args) => lua.table({'name': args[0]})));
    expect(lua.eval("return require('lazy').name"), 'lazy');
    lua.addSearcher(
      lua.function(
        (args) => args[0] == 'found'
            ? lua.function((_) => 'by searcher')
            : '\n\tnot provided by the host',
      ),
    );
    expect(lua.eval("return (require('found'))"), 'by searcher');
    expect(
      () => lua.run("require('absent')"),
      throwsA(isA<LuaBridgeException>()),
    );
    expect(lua.module('host.config'), isA<LuaTable>());
    lua.setModule('host.config', null);
    expect(lua.module('host.config'), isNull);
  });

  test('chunks: environments and binary round trip', () {
    final environment = lua.table({'x': 5});
    expect(lua.load('return x', environment: environment).call(), [5]);
    final bytes = (lua.load('return ... + 1')).dump();
    expect(() => lua.load(bytes), throwsA(isA<LuaBridgeException>()));
    expect(lua.load(bytes, allowBinary: true).call([41]), [42]);
  });

  test('coroutines', () {
    final thread =
        (lua.eval(
                  'return function(a) local b = coroutine.yield(a + 1) '
                  'return a + b end',
                )!
                as LuaFunction)
            .coroutine();
    expect(thread.resume([10]), [11]);
    expect(thread.status, LuaThreadStatus.suspended);
    expect(thread.resume([5]), [15]);
    expect(thread.isDead, isTrue);
  });

  test('sandbox, memory limit and interruption', () {
    expect(lua.run('return io, os, debug, dofile, loadfile'), [
      null,
      null,
      null,
      null,
      null,
    ]);
    final full = LuaRuntime.create(libraries: LuaLibrary.all);
    try {
      expect(full.eval('return type(os.time())'), 'number');
    } finally {
      full.close();
    }

    lua.memoryLimit = lua.memoryUsed + 256 * 1024;
    expect(
      () => lua.run(
        "local t = {} for i = 1, 1e7 do t[i] = ('x'):rep(100) .. i end",
      ),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.status,
          'status',
          LuaStatus.memory,
        ),
      ),
    );
    lua.memoryLimit = 0;

    lua['stop'] = lua.function((_) {
      lua.interrupt();
      return null;
    });
    expect(
      () => lua.run('stop() while true do pcall(function() end) end'),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.status,
          'status',
          LuaStatus.interrupted,
        ),
      ),
    );
    expect(lua.eval('return 2'), 2);
  });

  group('an interruption cannot be swallowed', () {
    late LuaFunction stop;
    setUp(() {
      stop = lua.function((_) {
        lua.interrupt();
        return null;
      });
      lua['stop'] = stop;
    });

    Matcher interrupted() => throwsA(
      isA<LuaBridgeException>().having(
        (e) => e.status,
        'status',
        LuaStatus.interrupted,
      ),
    );

    test('by returning a caught interruption at once', () {
      expect(
        () => lua.run('stop() return pcall(function() while true do end end)'),
        interrupted(),
      );
      expect(
        () => lua.run(
          'stop() local ok = coroutine.resume(coroutine.create('
          'function() while true do end end)) return ok',
        ),
        interrupted(),
      );
      final function = lua.eval(
        'return function() stop() return pcall(function() while true do end end) end',
      ) as LuaFunction;
      expect(() => function.call(), interrupted());
      function.release();
      expect(lua.eval('return 1'), 1);
    });

    test('by a coroutine that catches it and yields', () {
      final body = lua.eval(
        'return function() stop() '
        'coroutine.yield(pcall(function() while true do end end)) end',
      ) as LuaFunction;
      final thread = body.coroutine();
      expect(() => thread.resume(), interrupted());
      body.release();
      thread.release();
      final returning = lua.eval(
        'return function() stop() '
        'return pcall(function() while true do end end) end',
      ) as LuaFunction;
      final other = returning.coroutine();
      expect(() => other.resume(), interrupted());
      returning.release();
      other.release();
      expect(lua.eval('return 2'), 2);
    });

    test('but stops nothing when no Lua code runs', () {
      lua.interrupt();
      expect(lua.eval('return 1'), 1);
      lua.interrupt();
      expect(
        lua.eval('local n = 0 for i = 1, 100000 do n = n + i end return n'),
        5000050000,
      );
      final table = lua.table({'a': 1});
      lua.interrupt();
      expect(table['a'], 1);
      table.release();
    });
  });

  test('closing invalidates the runtime and its handles', () {
    final other = LuaRuntime.create();
    final table = other.table({'a': 1});
    final released = other.table();
    released.release();
    expect(() => released['a'], throwsStateError);
    other.close();
    other.close();
    expect(other.isClosed, isTrue);
    expect(() => other.run('return 1'), throwsStateError);
    expect(() => table['a'], throwsStateError);
    expect(() => lua['foreign'] = table, throwsArgumentError);
  });
}
