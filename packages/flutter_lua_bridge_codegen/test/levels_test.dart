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
})
''';

void main() {
  late LuaRuntime lua;
  setUp(() => lua = LuaRuntime.create());
  tearDown(() => lua.close());

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
