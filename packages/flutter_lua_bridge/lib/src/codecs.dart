import 'errors.dart';

/// Internal representation of a copied Lua table. No Lua pointer escapes.
class BridgeTable {
  BridgeTable(this.entries);
  final Map<Object, Object?> entries;
}

/// Generator support. This protocol can change between releases.
class BridgeCodec<T> {
  const BridgeCodec(this.encode, this.decode);
  final Object? Function(T value, String path) encode;
  final T Function(Object? value, String path) decode;
}

final bridgeInt = BridgeCodec<int>((v, _) => v, (v, p) {
  if (v is int) return v;
  throw LuaTypeException(p, 'Lua integer', v);
});
final bridgeDouble = BridgeCodec<double>((v, _) => v, (v, p) {
  if (v is num) return v.toDouble();
  throw LuaTypeException(p, 'Lua number', v);
});
final bridgeBool = BridgeCodec<bool>((v, _) => v, (v, p) {
  if (v is bool) return v;
  throw LuaTypeException(p, 'boolean', v);
});
final bridgeString = BridgeCodec<String>((v, _) => v, (v, p) {
  if (v is String) return v;
  throw LuaTypeException(p, 'UTF-8 string', v);
});
BridgeCodec<T?> bridgeNullable<T>(BridgeCodec<T> inner) => BridgeCodec(
  (v, p) => v == null ? null : inner.encode(v, p),
  (v, p) => v == null ? null : inner.decode(v, p),
);
Map<Object, Object?> bridgeFields(Object? value, String path) {
  if (value is BridgeTable) return value.entries;
  throw LuaTypeException(path, 'table', value);
}

BridgeCodec<List<T>> bridgeList<T>(BridgeCodec<T> inner) => BridgeCodec(
  (v, p) => BridgeTable({
    for (var i = 0; i < v.length; i++) i + 1: inner.encode(v[i], '$p[$i]'),
  }),
  (v, p) {
    final fields = bridgeFields(v, p);
    for (final key in fields.keys) {
      if (key is! int || key < 1 || key > fields.length) {
        throw LuaTypeException(
          p,
          'dense array with keys 1..${fields.length}',
          key,
        );
      }
    }
    return [
      for (var i = 1; i <= fields.length; i++)
        inner.decode(fields[i], '$p[${i - 1}]'),
    ];
  },
);
BridgeCodec<Map<String, T>> bridgeMap<T>(BridgeCodec<T> inner) => BridgeCodec(
  (v, p) => BridgeTable({
    for (final e in v.entries) e.key: inner.encode(e.value, '$p.${e.key}'),
  }),
  (v, p) {
    final fields = bridgeFields(v, p);
    return {
      for (final e in fields.entries)
        bridgeString.decode(e.key, '$p.<key>'): inner.decode(
          e.value,
          '$p.${e.key}',
        ),
    };
  },
);
void bridgeArgumentCount(List<Object?> values, int expected, String path) {
  if (values.length != expected) {
    throw LuaBridgeException(
      '$path: expected $expected arguments, got ${values.length}',
    );
  }
}

LuaErrorKind _luaErrorKind(Object? value) => switch (value) {
  'type' => LuaErrorKind.type,
  'runtime' => LuaErrorKind.runtime,
  _ => LuaErrorKind.protocol,
};

/// Decodes the result envelope emitted by generated O1/O2 Lua bindings.
LuaCallResult<T> decodeLuaResult<T>(
  Object? value,
  String path,
  T Function(Object? value, String path)? decode,
) {
  try {
    final fields = bridgeFields(value, path);
    final status = bridgeString.decode(
      fields['status'] ?? fields['__flb_result'],
      '$path.status',
    );
    if (status == 'error') {
      return LuaFailure<T>(
        kind: _luaErrorKind(fields['kind']),
        message: bridgeString.decode(fields['message'], '$path.message'),
      );
    }
    if (status != 'ok') {
      return LuaFailure<T>(
        kind: LuaErrorKind.protocol,
        message: '$path: unknown result status $status',
      );
    }
    final decoded = decode == null
        ? valueOrNull<T>(fields['value'])
        : decode(fields['value'], '$path.value');
    return LuaSuccess<T>(decoded);
  } on LuaTypeException catch (error) {
    return LuaFailure<T>(kind: LuaErrorKind.type, message: error.message);
  } on LuaBridgeException catch (error) {
    return LuaFailure<T>(kind: LuaErrorKind.protocol, message: error.message);
  } on Object catch (error) {
    return LuaFailure<T>(kind: LuaErrorKind.protocol, message: '$error');
  }
}

T valueOrNull<T>(Object? value) => value as T;
