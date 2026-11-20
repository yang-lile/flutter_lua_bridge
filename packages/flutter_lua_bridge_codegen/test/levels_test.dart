import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:test/test.dart';

import 'fixtures/levels.dart';

/// One Lua implementation serves all three interfaces, so the tests compare
/// the safety levels and nothing else.
String implementation(String bind) =>
    '''
local bridge = require("levels_bridge")
return bridge.$bind({
  half = function(value)
    if value < 0 then error("negative input", 0) end
    if value == 1 then return "not a number" end
    return value // 2
  end,
  move = function(point, by) return { x = point.x + by, y = point.y + by } end,
  ping = function() end,
  -- Waits for the asynchronous ClockApi, written as plain calls.
  halfLater = function(value)
    local clock = bridge.getClockApi()
    local later = clock.later(value)
    clock.tick()
    if later < 0 then error("negative input", 0) end
    if later == 1 then return "not a number" end
    return later // 2
  end,
  syncWait = function(value) return bridge.getClockApi().later(value) end,
})
''';

/// Answers after a real wait; 99 fails.
class Clock implements ClockApi {
  int ticks = 0;

  @override
  Future<int> later(int value) => Future.delayed(
    const Duration(milliseconds: 1),
    () => value == 99 ? throw StateError('clock broke') : value,
  );

  @override
  Future<void> tick() async => ticks++;
}

void main() {
  late LuaRuntime lua;
  late Clock clock;
  setUp(() {
    lua = LuaRuntime.create();
    clock = Clock();
    registerClockApi(clock, runtime: lua);
  });
  tearDown(() => lua.close());

  /// The message Lua gets when it calls ClockApi from a synchronous method.
  final notAsync = contains('runs synchronously');

  test('O1 returns results and reports runtime and type errors', () {
    final api = CheckedApiClient.load(
      runtime: lua,
      source: implementation('bindCheckedApi'),
    );
    expect(
      api.half(10),
      isA<LuaSuccess<int>>().having((r) => r.value, 'value', 5),
    );
    expect(
      api.move(const Point(1, 2), 3),
      isA<LuaSuccess<Point>>()
          .having((r) => r.value.x, 'x', 4)
          .having((r) => r.value.y, 'y', 5),
    );
    expect(api.ping().isOk, isTrue);
    expect(
      api.half(-1),
      isA<LuaFailure<int>>()
          .having((r) => r.kind, 'kind', LuaErrorKind.runtime)
          .having((r) => r.message, 'message', 'negative input'),
    );
    // The Lua validator rejects the wrong result type and names the path.
    expect(
      api.half(1),
      isA<LuaFailure<int>>()
          .having((r) => r.kind, 'kind', LuaErrorKind.type)
          .having(
            (r) => r.message,
            'message',
            'CheckedApi.half.result: expected integer',
          ),
    );
  });

  test(
    'O1 asynchronous methods wait for Dart and report every error',
    () async {
      final api = CheckedApiClient.load(
        runtime: lua,
        source: implementation('bindCheckedApi'),
      );
      expect(
        await api.halfLater(10),
        isA<LuaSuccess<int>>().having((r) => r.value, 'value', 5),
      );
      expect(clock.ticks, 1);
      expect(
        await api.halfLater(-1),
        isA<LuaFailure<int>>()
            .having((r) => r.kind, 'kind', LuaErrorKind.runtime)
            .having((r) => r.message, 'message', 'negative input'),
      );
      expect(
        await api.halfLater(1),
        isA<LuaFailure<int>>()
            .having((r) => r.kind, 'kind', LuaErrorKind.type)
            .having(
              (r) => r.message,
              'message',
              'CheckedApi.halfLater.result: expected integer',
            ),
      );
      // A failed Dart future is an error at the Lua call.
      expect(
        await api.halfLater(99),
        isA<LuaFailure<int>>()
            .having((r) => r.kind, 'kind', LuaErrorKind.runtime)
            .having((r) => r.message, 'message', contains('clock broke')),
      );
      expect(
        api.syncWait(4),
        isA<LuaFailure<int>>()
            .having((r) => r.kind, 'kind', LuaErrorKind.runtime)
            .having((r) => r.message, 'message', notAsync),
      );
    },
  );

  test('O2 returns results and reports runtime errors without Lua checks', () {
    final api = GuardedApiClient.load(
      runtime: lua,
      source: implementation('bindGuardedApi'),
    );
    expect(
      api.half(10),
      isA<LuaSuccess<int>>().having((r) => r.value, 'value', 5),
    );
    expect(
      api.move(const Point(1, 2), 3),
      isA<LuaSuccess<Point>>().having((r) => r.value.x, 'x', 4),
    );
    expect(api.ping().isOk, isTrue);
    expect(
      api.half(-1),
      isA<LuaFailure<int>>()
          .having((r) => r.kind, 'kind', LuaErrorKind.runtime)
          .having((r) => r.message, 'message', 'negative input'),
    );
    // No Lua validator: the wrong type is caught when Dart decodes it.
    expect(
      api.half(1),
      isA<LuaFailure<int>>()
          .having((r) => r.kind, 'kind', LuaErrorKind.type)
          .having(
            (r) => r.message,
            'message',
            contains('GuardedApi.half.result'),
          ),
    );
  });

  test('O2 asynchronous methods wait for Dart and report errors', () async {
    final api = GuardedApiClient.load(
      runtime: lua,
      source: implementation('bindGuardedApi'),
    );
    expect(
      await api.halfLater(10),
      isA<LuaSuccess<int>>().having((r) => r.value, 'value', 5),
    );
    expect(
      await api.halfLater(-1),
      isA<LuaFailure<int>>().having(
        (r) => r.message,
        'message',
        'negative input',
      ),
    );
    expect(
      await api.halfLater(1),
      isA<LuaFailure<int>>()
          .having((r) => r.kind, 'kind', LuaErrorKind.type)
          .having(
            (r) => r.message,
            'message',
            contains('GuardedApi.halfLater.result'),
          ),
    );
    expect(
      await api.halfLater(99),
      isA<LuaFailure<int>>().having(
        (r) => r.message,
        'message',
        contains('clock broke'),
      ),
    );
    expect(
      api.syncWait(4),
      isA<LuaFailure<int>>().having((r) => r.message, 'message', notAsync),
    );
  });

  test('O3 implements the interface and throws on failure', () {
    // The O3 client implements the API and the interface it inherits from.
    final Halver api = DirectApiClient.load(
      runtime: lua,
      source: implementation('bindDirectApi'),
    );
    expect(api.half(10), 5);
    expect(api.move(const Point(1, 2), 3).y, 5);
    api.ping();
    expect(
      () => api.half(-1),
      throwsA(
        isA<LuaBridgeException>()
            .having((e) => e.message, 'message', 'negative input')
            .having((e) => e.status, 'status', LuaStatus.runtime),
      ),
    );
    expect(() => api.half(1), throwsA(isA<LuaTypeException>()));
  });

  test('O3 asynchronous methods return futures that throw', () async {
    final Halver api = DirectApiClient.load(
      runtime: lua,
      source: implementation('bindDirectApi'),
    );
    expect(await api.halfLater(10), 5);
    await expectLater(
      api.halfLater(-1),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.message,
          'message',
          'negative input',
        ),
      ),
    );
    await expectLater(api.halfLater(1), throwsA(isA<LuaTypeException>()));
    // The Dart error itself is the cause.
    await expectLater(
      api.halfLater(99),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.cause,
          'cause',
          isA<StateError>(),
        ),
      ),
    );
    expect(
      () => api.syncWait(4),
      throwsA(
        isA<LuaBridgeException>().having((e) => e.message, 'message', notAsync),
      ),
    );
  });

  test('one table cannot be bound to APIs of different levels', () {
    // The O1 wrappers replace the functions of the table in place, so
    // binding the same table again as O3 must fail instead of handing O3
    // the O1 result envelopes.
    lua.loadModule(
      'shared',
      source: '''
return {
  half = function(value) return value // 2 end,
  move = function(point, by) return point end,
  ping = function() end,
  halfLater = function(value) return value // 2 end,
  syncWait = function(value) return value end,
}
''',
    );
    expect(
      () => CheckedApiClient.load(
        runtime: lua,
        source:
            'return require("levels_bridge").bindCheckedApi(require("shared"))',
      ),
      returnsNormally,
    );
    expect(
      () => DirectApiClient.load(
        runtime: lua,
        source:
            'return require("levels_bridge").bindDirectApi(require("shared"))',
      ),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.message,
          'message',
          contains('already bound as CheckedApi'),
        ),
      ),
    );
    // Binding the same table to the same API again is harmless.
    expect(
      CheckedApiClient.load(
        runtime: lua,
        source:
            'return require("levels_bridge").bindCheckedApi(require("shared"))',
      ).half(8),
      isA<LuaSuccess<int>>().having((r) => r.value, 'value', 4),
    );
  });
}
