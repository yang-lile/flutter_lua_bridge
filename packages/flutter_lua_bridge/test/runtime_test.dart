import 'dart:io';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:test/test.dart';
import 'fixtures/values.g.dart';
import 'fixtures/battle.g.dart' as battle;

class TestCallbacks implements CallbacksApi {
  final messages = <String>[];
  Payload Function(Payload)? onEcho;
  void Function()? onNotify;
  @override
  Payload echo(Payload value) => onEcho?.call(value) ?? value;
  @override
  void notify(String message) {
    onNotify?.call();
    messages.add(message);
  }
}

const payload = Payload(
  count: 9223372036854775807,
  ratio: 2.5,
  enabled: true,
  text: 'Lua\u0000中文🙂',
  note: null,
  mode: Mode.easy,
  items: [1, -9223372036854775808],
  scores: {'中文\u0000key': 9007199254740993},
);

String script({
  String echo = 'return value',
  String team = 'return values',
  String scores = 'return values',
  String text = 'return value',
  String add = 'return a + b',
  String notify = 'callbacks.notify(message)',
}) =>
    '''
local bridge = require("values_bridge")
local callbacks = bridge.getCallbacksApi()
return bridge.bindValuesApi({
  echo = function(value) $echo end,
  team = function(values) $team end,
  scores = function(values) $scores end,
  text = function(value) $text end,
  add = function(a, b) $add end,
  notify = function(message) $notify end,
})
''';

void checkPayload(Payload result) {
  expect(result.count, payload.count);
  expect(result.ratio, payload.ratio);
  expect(result.enabled, payload.enabled);
  expect(result.text, payload.text);
  expect(result.note, isNull);
  expect(result.mode, Mode.easy);
  expect(result.items, payload.items);
  expect(result.scores, payload.scores);
}

void main() {
  late LuaRuntime lua;
  late TestCallbacks callbacks;
  late ValuesApi api;
  void load(String source) {
    lua.loadModule('values', source: source);
    api = ValuesApi(runtime: lua);
  }

  setUp(() {
    lua = LuaRuntime.create();
    callbacks = TestCallbacks();
    CallbacksApi.setUp(callbacks, runtime: lua);
    lua.loadModule('values_bridge', source: bridgeLuaSource);
    load(script());
  });
  tearDown(() => lua.close());

  test('copies typed DTOs with exact int64, enums, null and NUL UTF-8', () {
    checkPayload(api.echo(payload));
    expect(api.text(null), isNull);
    expect(api.text(payload.text), payload.text);
    expect(api.add(10, b: 20), 30);
  });
  test('copies nested collections, including empty arrays and maps', () {
    checkPayload(api.team([payload]).single);
    expect(api.team([]), isEmpty);
    expect(
      api.scores({
        'a': [1, 2],
        'empty': [],
      }),
      {
        'a': [1, 2],
        'empty': [],
      },
    );
    expect(api.scores({}), isEmpty);
  });
  test('calls Dart synchronously with DTOs and void results', () {
    load(script(echo: 'return callbacks.echo(value)'));
    checkPayload(api.echo(payload));
    api.notify(payload.text);
    expect(callbacks.messages, [payload.text]);
  });
  test('validates Lua arguments before entering a Dart implementation', () {
    load(script(notify: 'callbacks.notify(42)'));
    expect(
      () => api.notify('test'),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.message,
          'path',
          contains('CallbacksApi.notify.message'),
        ),
      ),
    );
    expect(callbacks.messages, isEmpty);
  });
  test('validates callback argument count', () {
    load(script(notify: 'callbacks.notify(message, "extra")'));
    expect(
      () => api.notify('test'),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.message,
          'message',
          contains('expected 1 arguments, got 2'),
        ),
      ),
    );
  });
  test('Dart exceptions become Lua errors after the callback returns', () {
    callbacks.onNotify = () => throw StateError('host failed');
    expect(
      () => api.notify('test'),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.message,
          'message',
          contains('host failed'),
        ),
      ),
    );
    callbacks.onNotify = null;
    api.notify('recovered');
    expect(callbacks.messages, ['recovered']);
  });
  test('Lua can catch host exceptions with pcall', () {
    callbacks.onNotify = () => throw StateError('host failed');
    load(
      script(
        text:
            'local ok, err = pcall(callbacks.notify, value); return ok and "ok" or err',
      ),
    );
    expect(api.text('test'), contains('host failed'));
    expect(api.add(1, b: 2), 3);
  });
  test('rejects re-entry and close during host callbacks', () {
    callbacks.onNotify = () => api.add(1, b: 2);
    expect(
      () => api.notify('test'),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.message,
          'message',
          contains('re-entered'),
        ),
      ),
    );
    callbacks.onNotify = lua.close;
    expect(
      () => api.notify('test'),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.message,
          'message',
          contains('Cannot close'),
        ),
      ),
    );
    expect(lua.isClosed, isFalse);
  });
  test('unregister invalidates cached Lua host references safely', () {
    CallbacksApi.setUp(null, runtime: lua);
    expect(
      () => api.notify('test'),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.message,
          'message',
          contains('unregistered'),
        ),
      ),
    );
    expect(api.add(1, b: 2), 3);
  });
  test('replacing a host implementation updates cached Lua references', () {
    final replacement = TestCallbacks();
    CallbacksApi.setUp(replacement, runtime: lua);
    api.notify('replacement');
    expect(replacement.messages, ['replacement']);
    expect(callbacks.messages, isEmpty);
  });
  test('rejects coercion of float and numeric string to integer', () {
    for (final invalid in ['1.0', '"1"']) {
      load(script(echo: 'value.total = $invalid; return value'));
      expect(
        () => api.echo(payload),
        throwsA(
          isA<LuaTypeException>().having(
            (e) => e.message,
            'path',
            contains('ValuesApi.echo.result.total'),
          ),
        ),
      );
    }
  });
  test('checks required fields and enum values', () {
    load(script(echo: 'value.total = nil; return value'));
    expect(() => api.echo(payload), throwsA(isA<LuaTypeException>()));
    load(script(echo: 'value.mode = "unknown"; return value'));
    expect(
      () => api.echo(payload),
      throwsA(
        isA<LuaTypeException>().having(
          (e) => e.message,
          'path',
          contains('.mode'),
        ),
      ),
    );
  });
  test('rejects sparse arrays and non-string maps', () {
    load(script(team: 'return { [1] = values[1], [3] = values[1] }'));
    expect(() => api.team([payload]), throwsA(isA<LuaTypeException>()));
    load(script(scores: 'return { [1] = { 2 } }'));
    expect(() => api.scores({}), throwsA(isA<LuaTypeException>()));
  });
  test('rejects cyclic tables, functions and invalid UTF-8', () {
    load(script(echo: 'value.cycle = value; return value'));
    expect(
      () => api.echo(payload),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.message,
          'message',
          contains('cyclic'),
        ),
      ),
    );
    load(script(text: 'return function() end'));
    expect(() => api.text('a'), throwsA(isA<LuaBridgeException>()));
    load(script(text: 'return string.char(255)'));
    expect(
      () => api.text('a'),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.message,
          'message',
          contains('UTF-8'),
        ),
      ),
    );
  });
  test('enforces exactly one result, or zero for void', () {
    load(script(add: 'return a, b'));
    expect(
      () => api.add(1, b: 2),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.message,
          'message',
          contains('exactly 1'),
        ),
      ),
    );
    load(script(notify: 'return 1'));
    expect(
      () => api.notify('a'),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.message,
          'message',
          contains('exactly 0'),
        ),
      ),
    );
  });
  test('restores the Lua stack after syntax/runtime/conversion failures', () {
    expect(
      () => lua.loadModule('invalid', source: 'this is invalid'),
      throwsA(isA<LuaBridgeException>()),
    );
    load(script(add: 'error("script failed")'));
    expect(
      () => api.add(1, b: 2),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.message,
          'traceback',
          contains('stack traceback'),
        ),
      ),
    );
    load(script());
    for (var i = 0; i < 1000; i++) {
      expect(api.add(i, b: 1), i + 1);
    }
  });
  test('checks contract fingerprints and required methods when binding', () {
    lua.loadModule('values', source: 'return {}');
    expect(
      () => ValuesApi(runtime: lua),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.message,
          'message',
          contains('contract mismatch'),
        ),
      ),
    );
    load(script());
    lua.loadModule(
      'values',
      source:
          'local b = require("values_bridge"); local m = require("values"); m.add = nil; return m',
    );
    expect(
      () => ValuesApi(runtime: lua),
      throwsA(
        isA<LuaBridgeException>().having(
          (e) => e.message,
          'message',
          contains('missing'),
        ),
      ),
    );
  });
  test('requires a module table and rejects bytecode', () {
    expect(
      () => lua.loadModule('invalid', source: 'return 42'),
      throwsA(isA<LuaBridgeException>()),
    );
    expect(
      () => lua.loadModule('invalid', source: '\u001bLua'),
      throwsA(isA<LuaBridgeException>()),
    );
  });
  test('close is idempotent and invalidates all proxies', () {
    lua.close();
    lua.close();
    expect(() => api.add(1, b: 2), throwsStateError);
    expect(() => CallbacksApi.setUp(callbacks, runtime: lua), throwsStateError);
    expect(() => lua.loadModule('x', source: 'return {}'), throwsStateError);
  });
  test('keeps independent runtimes and host registrations isolated', () {
    final other = LuaRuntime.create();
    try {
      final host = TestCallbacks();
      CallbacksApi.setUp(host, runtime: other);
      other.loadModule('values_bridge', source: bridgeLuaSource);
      other.loadModule('values', source: script());
      ValuesApi(runtime: other).notify('other');
      expect(host.messages, ['other']);
      expect(callbacks.messages, isEmpty);
    } finally {
      other.close();
    }
  });
  test('executes the documented BattleApi/HostApi example', () {
    final host = _BattleHost();
    battle.HostApi.setUp(host, runtime: lua);
    lua.loadModule('battle_bridge', source: battle.bridgeLuaSource);
    lua.loadModule(
      'battle',
      source: File('../../examples/flutter_lua_bridge_example/lua/build/battle.lua').readAsStringSync(),
    );
    final result = battle.BattleApi(runtime: lua).calculateDamage(
      const battle.Fighter(attack: 100, defense: 20),
      const battle.Fighter(attack: 80, defense: 30),
    );
    expect(result.damage, 75);
    expect(result.critical, isFalse);
    expect(host.messages, ['calculated damage 70']);
  });
}

class _BattleHost implements battle.HostApi {
  final messages = <String>[];
  @override
  void log(String message) => messages.add(message);
  @override
  int bonus(int damage) => damage + 5;
}
