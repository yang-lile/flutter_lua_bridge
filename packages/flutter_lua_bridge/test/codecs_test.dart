import 'package:flutter_lua_bridge/generated.dart';
import 'package:test/test.dart';

void main() {
  group('primitive codecs', () {
    test('decode supported primitive values', () {
      expect(bridgeInt.decode(7, 'value'), 7);
      expect(bridgeDouble.decode(7, 'value'), 7.0);
      expect(bridgeDouble.decode(7.5, 'value'), 7.5);
      expect(bridgeBool.decode(true, 'value'), isTrue);
      expect(bridgeString.decode('lua', 'value'), 'lua');
    });

    test('reject values with the wrong type and path', () {
      expect(
        () => bridgeInt.decode(7.5, 'result.count'),
        throwsA(
          isA<LuaTypeException>().having(
            (error) => error.message,
            'message',
            contains('result.count'),
          ),
        ),
      );
      expect(
        () => bridgeBool.decode('true', 'result.enabled'),
        throwsA(isA<LuaTypeException>()),
      );
      expect(
        () => bridgeString.decode(null, 'result.label'),
        throwsA(isA<LuaTypeException>()),
      );
    });
  });

  group('collection codecs', () {
    test('round trips nullable lists and string maps', () {
      final list = bridgeNullable(bridgeList(bridgeInt));
      final map = bridgeMap(bridgeString);

      expect(list.decode(list.encode([1, 2], 'items'), 'items'), [1, 2]);
      expect(list.decode(null, 'items'), isNull);
      expect(
        map.decode(map.encode({'name': 'Lua'}, 'labels'), 'labels'),
        {'name': 'Lua'},
      );
    });

    test('nullable codecs preserve null and delegate non-null values', () {
      final codec = bridgeNullable(bridgeInt);

      expect(codec.decode(null, 'value'), isNull);
      expect(codec.decode(9, 'value'), 9);
      expect(codec.encode(null, 'value'), isNull);
      expect(codec.encode(9, 'value'), 9);
    });

    test('rejects sparse arrays and non-string map keys', () {
      final list = bridgeList(bridgeInt);
      final map = bridgeMap(bridgeString);

      expect(
        () => list.decode(BridgeTable({1: 1, 3: 3}), 'items'),
        throwsA(isA<LuaTypeException>()),
      );
      expect(
        () => map.decode(BridgeTable({1: 'Lua'}), 'labels'),
        throwsA(isA<LuaTypeException>()),
      );
    });

    test('requires a BridgeTable when decoding fields', () {
      expect(
        () => bridgeFields({'value': 1}, 'value'),
        throwsA(isA<LuaTypeException>()),
      );
    });
  });

  group('result envelopes', () {
    test('decodes successful and typed failure results', () {
      final success = decodeLuaResult<int>(
        BridgeTable({'status': 'ok', 'value': 42}),
        'call',
        bridgeInt.decode,
      );
      final failure = decodeLuaResult<int>(
        BridgeTable({
          'status': 'error',
          'kind': 'runtime',
          'message': 'boom',
        }),
        'call',
        bridgeInt.decode,
      );

      expect(success, isA<LuaSuccess<int>>());
      expect((success as LuaSuccess<int>).value, 42);
      expect(failure, isA<LuaFailure<int>>());
      final typedFailure = failure as LuaFailure<int>;
      expect(typedFailure.kind, LuaErrorKind.runtime);
      expect(typedFailure.message, 'boom');
    });

    test('turns malformed envelopes into protocol failures', () {
      final result = decodeLuaResult<int>(
        BridgeTable({'status': 'unknown', 'value': 42}),
        'call',
        bridgeInt.decode,
      );

      expect(result, isA<LuaFailure<int>>());
      expect((result as LuaFailure<int>).kind, LuaErrorKind.protocol);

      final missing = decodeLuaResult<int>(null, 'call', bridgeInt.decode);
      expect(missing, isA<LuaFailure<int>>());
      expect((missing as LuaFailure<int>).kind, LuaErrorKind.type);
    });
  });
}
