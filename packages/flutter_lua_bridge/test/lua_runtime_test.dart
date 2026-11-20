// The general-purpose side of LuaRuntime. tool/test_lua_versions.sh runs this
// file against every bundled Lua release and sets FLB_EXPECT_LUA_VERSION so a
// build of the wrong release cannot pass unnoticed.
import 'dart:async';
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

  group('asynchronous Dart functions', () {
    LuaFunction function(String code) => lua.eval(code)! as LuaFunction;

    test('read as plain calls in Lua that Dart runs asynchronously', () async {
      final requests = <String>[];
      lua['fetch'] = lua.function((a) {
        final url = a.single! as String;
        requests.add(url);
        return Future.delayed(
          const Duration(milliseconds: 5),
          () => url == '/user' ? 'ana' : 42,
        );
      });
      final results = await function('''return function()
          local user = fetch("/user")
          local ok, score = pcall(fetch, "/score/" .. user)
          return user .. ":" .. score
        end''').callAsync();
      expect(results, ['ana:42']);
      expect(requests, ['/user', '/score/ana']);
    });

    test(
      'several values, and the runtime stays usable while it waits',
      () async {
        final gate = Completer<Object?>();
        lua['pair'] = lua.function(
          (_) => Future.value(const LuaValues([1, 2])),
        );
        lua['wait'] = lua.function((_) => gate.future);
        final a = function(
          'return function() local x, y = pair() return x + y end',
        ).callAsync();
        final b = function('return function() return wait() .. "!" end')
            .callAsync();
        await Future<void>.delayed(Duration.zero);
        expect(lua.eval('return 6 * 7'), 42); // not blocked by the waiting call
        gate.complete('done');
        expect(await Future.wait([a, b]), [
          [3],
          ['done!'],
        ]);
      },
    );

    test(
      'a failed future raises in Lua, with the Dart error as cause',
      () async {
        final error = StateError('offline');
        lua['fetch'] = lua.function((_) => Future<Object?>.error(error));
        expect(
          await function(
            'return function() local ok, e = pcall(fetch) return ok, e end',
          ).callAsync(),
          [false, error.toString()],
        );
        await expectLater(
          function('return function() return fetch() end').callAsync(),
          throwsA(
            isA<LuaBridgeException>()
                .having((e) => e.status, 'status', LuaStatus.host)
                .having((e) => e.cause, 'cause', same(error)),
          ),
        );
      },
    );

    test('Lua that Dart runs synchronously cannot wait', () async {
      lua['fetch'] = lua.function((_) => Future.value(1));
      final notAsync = isA<LuaBridgeException>().having(
        (e) => e.message,
        'message',
        contains('runs synchronously'),
      );
      expect(() => lua.eval('return fetch()'), throwsA(notAsync));
      final thread = function('return function() return fetch() end')
          .coroutine();
      expect(() => thread.resume(), throwsA(notAsync));
      // Nor Lua reached through another Dart function, nor a coroutine that
      // Lua resumes itself: only the code Dart runs asynchronously waits.
      lua['through'] = lua.function((a) => (a.single! as LuaFunction).call());
      await expectLater(
        function(
          'return function() return through(function() return fetch() end) end',
        ).callAsync(),
        throwsA(notAsync),
      );
      await expectLater(
        function(
          'return function() return coroutine.wrap(function() return fetch() end)() end',
        ).callAsync(),
        throwsA(notAsync),
      );
    });

    test('resumeAsync returns what the coroutine yields by itself', () async {
      lua['fetch'] = lua.function((a) => Future.value((a.single! as int) * 2));
      final thread = function(
        'return function(x) local y = coroutine.yield(fetch(x)) return fetch(y) end',
      ).coroutine();
      expect(await thread.resumeAsync([3]), [6]);
      expect(thread.isDead, isFalse);
      expect(await thread.resumeAsync([10]), [20]);
      expect(thread.isDead, isTrue);
    });

    test('callAsync refuses a function that yields by itself', () async {
      await expectLater(
        function('return function() coroutine.yield(1) end').callAsync(),
        throwsA(isA<StateError>()),
      );
    });

    test('closing the runtime while a call waits', () async {
      final gate = Completer<Object?>();
      lua['wait'] = lua.function((_) => gate.future);
      final call = function('return function() return wait() end').callAsync();
      await Future<void>.delayed(Duration.zero);
      lua.close();
      gate.complete(1);
      await expectLater(call, throwsA(isA<StateError>()));
    });
  });

  group('streams', () {
    LuaFunction function(String code) => lua.eval(code)! as LuaFunction;

    test('a Lua generator is a Dart stream', () async {
      final countdown = function(
        'return function(n) for i = n, 1, -1 do coroutine.yield(i) end end',
      );
      expect(await countdown.stream([3]).toList(), [3, 2, 1]);
    });

    test('Lua produces only what the listener takes', () async {
      var produced = 0;
      lua['produced'] = lua.function((_) => ++produced);
      final naturals = function(
        'return function() local i = 0 while true do i = produced() coroutine.yield(i) end end',
      );
      expect(await naturals.stream().take(3).toList(), [1, 2, 3]);
      await Future<void>.delayed(Duration.zero);
      expect(produced, 3);
    });

    test('a generator may wait for Dart between items', () async {
      lua['later'] = lua.function(
        (a) => Future.delayed(const Duration(milliseconds: 2), () => a.single),
      );
      final generator = function(
        'return function() for i = 1, 3 do coroutine.yield(later(i * 10)) end end',
      );
      expect(await generator.stream().toList(), [10, 20, 30]);
    });

    test('a Lua error is an error event after the items before it', () async {
      final failing = function(
        'return function() coroutine.yield(1) error("broken", 0) end',
      );
      final events = <Object?>[];
      await expectLater(
        failing.stream().forEach(events.add),
        throwsA(
          isA<LuaBridgeException>().having(
            (e) => e.message,
            'message',
            'broken',
          ),
        ),
      );
      expect(events, [1]);
    });

    test('a Dart stream is a Lua iterator', () async {
      lua['events'] = lua.function(
        (_) => Stream.fromIterable([1, 2, 3]).asyncMap(
          (v) => Future.delayed(const Duration(milliseconds: 1), () => v),
        ),
      );
      final sum = function(
        'return function() local s = 0 for v in events() do s = s + v end return s end',
      );
      expect(await sum.callAsync(), [6]);
    });

    test('a Dart error event raises in the Lua loop', () async {
      lua['events'] = lua.function(
        (_) => Stream<int>.multi((c) {
          c.add(1);
          c.addError(StateError('feed lost'));
        }),
      );
      final reader = function('''return function()
          local seen = 0
          local ok, e = pcall(function() for v in events() do seen = seen + v end end)
          return seen, tostring(e)
        end''');
      final results = await reader.callAsync();
      expect(results.first, 1);
      expect(results.last, contains('feed lost'));
    });

    test('an iterator needs Lua that Dart runs asynchronously', () {
      lua['events'] = lua.function((_) => Stream.value(1));
      expect(
        () => lua.eval('for v in events() do end'),
        throwsA(
          isA<LuaBridgeException>().having(
            (e) => e.message,
            'message',
            contains('runs synchronously'),
          ),
        ),
      );
    });

    test('leaving the loop early cancels the subscription', () async {
      var cancelled = false;
      final controller = StreamController<int>(
        onListen: () {},
        onCancel: () => cancelled = true,
      );
      lua['events'] = lua.function((_) => controller.stream);
      final firstOnly = function(
        'return function() for v in events() do return v end end',
      );
      final call = firstOnly.callAsync();
      await Future<void>.delayed(Duration.zero);
      controller.add(7);
      expect(await call, [7]);
      lua.collectGarbage();
      await Future<void>.delayed(Duration.zero);
      expect(cancelled, isTrue);
    });

    test('closing the runtime cancels the subscriptions', () async {
      var cancelled = false;
      final controller = StreamController<int>(
        onCancel: () => cancelled = true,
      );
      final iterator = lua.iterate(controller.stream);
      final waiting = expectLater(
        (lua.eval('return function(it) return it() end')! as LuaFunction)
            .callAsync([iterator]),
        throwsA(isA<StateError>()), // the runtime is closed
      );
      await Future<void>.delayed(Duration.zero);
      lua.close();
      await waiting;
      expect(cancelled, isTrue);
    });
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
