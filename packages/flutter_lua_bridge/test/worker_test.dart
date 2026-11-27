import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
// ignore: implementation_imports
import 'package:flutter_lua_bridge/src/worker.dart' show debugOpenLuaWorkers;
import 'package:test/test.dart';

void _rules(LuaRuntime lua) {
  lua.loadModule(
    'rules',
    source: '''
      local rules = {}
      function rules.score(board) return board.a * 10 + board.b, #board.moves end
      function rules.spin() while true do end end
      function rules.shape() return { name = "x", list = { 1, 2, 3 } } end
      function rules.handle() return function() end end
      function rules.fail() error("bad move") end
      function rules.dart(n) return double(n) end
      return rules
    ''',
  );
  lua.run('rules = require("rules")');
  lua['double'] = lua.function((arguments) {
    final n = arguments.first! as int;
    if (n < 0) throw ArgumentError('negative');
    return n * 2;
  });
}

Future<void> _asyncSetup(LuaRuntime lua) async {
  await Future<void>.delayed(const Duration(milliseconds: 1));
  lua['ready'] = true;
}

void _failingSetup(LuaRuntime lua) => lua.run('error("no rules")');

/// Allocates until the collector has run the finalizers that [done] waits
/// for, or fails after a while.
Future<void> _collectUntil(bool Function() done) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) fail('not collected');
    var garbage = <List<int>>[];
    for (var i = 0; i < 200; i++) {
      garbage.add(List<int>.filled(100000, i));
    }
    garbage = [];
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

Future<void> _spawnAndDrop() async {
  final worker = await LuaWorker.spawn();
  expect(await worker.run('return 1'), [1]);
}

void main() {
  late LuaWorker worker;
  setUp(() async => worker = await LuaWorker.spawn(setup: _rules));
  tearDown(() => worker.close());

  test('runs code and returns plain data', () async {
    expect(await worker.run('return 1, 1.5, "中文", true, nil'), [
      1,
      1.5,
      '中文',
      true,
      null,
    ]);
    expect(await worker.run('return 6 * 7'), [42]);
    expect(await worker.call('rules.shape', []), [
      {
        'name': 'x',
        'list': [1, 2, 3],
      },
    ]);
  });

  test('passes Dart data in and calls Dart functions of the setup', () async {
    final results = await worker.call('rules.score', [
      {
        'a': 4,
        'b': 2,
        'moves': ['e4', 'e5'],
      },
    ]);
    expect(results, [42, 2]);
    expect(await worker.call('rules.dart', [21]), [42]);
    expect(
      await worker.call('string.len', [
        Uint8List.fromList([1, 2, 3]),
      ]),
      [3],
    );
  });

  test('reports Lua and Dart errors as LuaBridgeException', () async {
    await expectLater(
      worker.call('rules.fail', []),
      throwsA(
        isA<LuaBridgeException>()
            .having((e) => e.status, 'status', LuaStatus.runtime)
            .having((e) => e.message, 'message', contains('bad move'))
            .having((e) => e.traceback, 'traceback', contains('traceback')),
      ),
    );
    await expectLater(
      worker.call('rules.dart', [-1]),
      throwsA(
        isA<LuaBridgeException>()
            .having((e) => e.status, 'status', LuaStatus.host)
            .having((e) => e.cause, 'cause', contains('negative')),
      ),
    );
    await expectLater(
      worker.run('return ('),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.status,
          'status',
          LuaStatus.syntax,
        ),
      ),
    );
    await expectLater(
      worker.call('rules.missing', []),
      throwsA(isA<LuaBridgeException>()),
    );
    await expectLater(
      worker.call('rules.handle', []),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.message,
          'message',
          contains('cannot leave the LuaWorker'),
        ),
      ),
    );
    // The worker is still usable.
    expect(await worker.run('return 1'), [1]);
  });

  test('a timeout stops an endless loop and the worker goes on', () async {
    final watch = Stopwatch()..start();
    await expectLater(
      worker.call('rules.spin', [], timeout: const Duration(milliseconds: 50)),
      throwsA(
        isA<LuaBridgeException>()
            .having((e) => e.status, 'status', LuaStatus.interrupted)
            .having((e) => e.message, 'message', contains('timed out')),
      ),
    );
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    expect(await worker.run('return 2'), [2]);
    // pcall cannot catch the interruption.
    await expectLater(
      worker.run(
        'local ok = pcall(function() while true do end end) return ok',
        timeout: const Duration(milliseconds: 20),
      ),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.status,
          'status',
          LuaStatus.interrupted,
        ),
      ),
    );
  });

  test('a timeout that fires before the call starts still stops it', () async {
    for (var i = 0; i < 50; i++) {
      await expectLater(
        worker.call('rules.spin', [], timeout: Duration.zero),
        throwsA(
          isA<LuaBridgeException>().having(
            (e) => e.status,
            'status',
            LuaStatus.interrupted,
          ),
        ),
      );
    }
    expect(await worker.run('return 3'), [3]);
  });

  test('interrupt stops the running call only', () async {
    final spinning = worker.call('rules.spin', []);
    final waiting = worker.run('return "after"');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    worker.interrupt();
    await expectLater(
      spinning,
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.status,
          'status',
          LuaStatus.interrupted,
        ),
      ),
    );
    expect(await waiting, ['after']);
  });

  test('a late interrupt does not leak into the next call', () async {
    for (var i = 0; i < 20; i++) {
      final call = worker.run('return $i');
      worker.interrupt();
      try {
        await call;
      } on LuaBridgeException catch (e) {
        expect(e.status, LuaStatus.interrupted);
      }
      expect(await worker.run('return "ok"'), ['ok']);
    }
  });

  test('runs calls in order', () async {
    final results = await Future.wait([
      for (var i = 0; i < 10; i++) worker.run('n = (n or 0) + 1; return n'),
    ]);
    expect(results, [
      for (var i = 1; i <= 10; i++) [i],
    ]);
  });

  test('close stops a running call and fails the waiting ones', () async {
    final spinning = expectLater(
      worker.call('rules.spin', []),
      throwsA(anything),
    );
    final waiting = expectLater(worker.run('return 1'), throwsStateError);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await worker.close();
    await spinning;
    await waiting;
    expect(worker.isClosed, isTrue);
    await expectLater(worker.run('return 1'), throwsStateError);
    await worker.close();
  });

  test('keeps the memory limit', () async {
    final small = await LuaWorker.spawn(memoryLimit: 1 << 20);
    addTearDown(small.close);
    await expectLater(
      small.run('local t = {} for i = 1, 1e7 do t[i] = i end'),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.status,
          'status',
          LuaStatus.memory,
        ),
      ),
    );
    expect(await small.run('return 1'), [1]);
  });

  test('waits for an asynchronous setup', () async {
    final other = await LuaWorker.spawn(setup: _asyncSetup);
    addTearDown(other.close);
    expect(await other.run('return ready'), [isTrue]);
  });

  test('fails to spawn when the setup fails', () async {
    await expectLater(
      LuaWorker.spawn(setup: _failingSetup),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.message,
          'message',
          contains('no rules'),
        ),
      ),
    );
  });

  group('without close', () {
    for (final (mode, output) in [
      ('idle', '[1]'),
      ('pending', '[4500001500000]'),
      ('close', 'closed'),
    ]) {
      test('the program exits ($mode)', () async {
        final result = await Process.run(Platform.resolvedExecutable, [
          'run',
          'test/fixtures/worker_exit.dart',
          mode,
        ]).timeout(const Duration(seconds: 90));
        expect(result.exitCode, 0, reason: '${result.stderr}');
        expect(result.stdout, contains(output));
      }, timeout: const Timeout(Duration(minutes: 2)));
    }

    test('a worker nobody references is closed when collected', () async {
      final before = debugOpenLuaWorkers;
      await _spawnAndDrop();
      expect(debugOpenLuaWorkers, before + 1);
      await _collectUntil(() => debugOpenLuaWorkers == before);
    });

    test('a worker with a call in flight is not collected', () async {
      final before = debugOpenLuaWorkers;
      Future<List<Object?>> start() async {
        final worker = await LuaWorker.spawn(setup: _rules);
        return worker.call(
          'rules.spin',
          [],
          timeout: const Duration(milliseconds: 300),
        );
      }

      final call = start();
      // Collect while the call runs; it must still complete.
      final collecting = _collectUntil(() => debugOpenLuaWorkers == before);
      await expectLater(
        call,
        throwsA(
          isA<LuaBridgeException>().having(
            (e) => e.status,
            'status',
            LuaStatus.interrupted,
          ),
        ),
      );
      // Idle afterwards, so collected after all.
      await collecting;
    });
  });
}
