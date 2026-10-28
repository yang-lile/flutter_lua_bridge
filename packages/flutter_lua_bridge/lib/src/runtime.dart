import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'codecs.dart';
import 'errors.dart';
import 'native.dart';

/// Owns one Lua 5.4 state, its modules and generated host bindings.
///
/// Calls are synchronous and confined to the creating Dart isolate. Re-entering
/// the runtime from a host callback is rejected. Always close it in a finally
/// block; this also releases host implementation references.
class LuaRuntime {
  LuaRuntime._();

  static LuaRuntime create({bool openLibraries = true}) {
    final runtime = LuaRuntime._();
    runtime._callback = NativeCallable<NativeCallback>.isolateLocal(
      runtime._dispatch,
    );
    runtime._handle = flb_create(
      runtime._callback.nativeFunction,
      openLibraries ? 1 : 0,
    );
    if (runtime._handle == nullptr) {
      runtime._callback.close();
      throw LuaBridgeException('Could not create Lua 5.4 runtime');
    }
    return runtime;
  }

  late final NativeCallable<NativeCallback> _callback;
  late final Pointer<NativeRuntime> _handle;
  final _handlers = <int, BridgeHostMethod>{};
  final _modules = <String, Map<String, int>>{};
  final _contracts = <String, String>{};
  final _loadedSources = <String, String>{};
  int _nextId = 1;
  bool _closed = false;
  bool _busy = false;
  bool get isClosed => _closed;

  T _run<T>(T Function() action) {
    if (_closed) throw StateError('LuaRuntime is closed');
    if (_busy) {
      throw StateError('LuaRuntime cannot be re-entered from a Dart callback');
    }
    _busy = true;
    try {
      return action();
    } finally {
      _busy = false;
    }
  }

  /// Executes a text chunk that returns a module table. The table is available
  /// to generated APIs and require(). Bytecode is deliberately unsupported.
  void loadModule(String module, {required String source}) => _run(() {
    _name(module);
    using((arena) {
      final bytes = utf8.encode(source);
      final native = arena<Uint8>(bytes.length + 1);
      native.asTypedList(bytes.length).setAll(0, bytes);
      _consume(
        flb_load(
          _handle,
          module.toNativeUtf8(allocator: arena).cast(),
          native.cast(),
          bytes.length,
        ),
      );
      _loadedSources[module] = source;
    });
  });

  /// Loads generated protocol glue once per runtime. Generated API helpers use
  /// this method so applications only need to provide their business module.
  void ensureModule(String module, {required String source}) => _run(() {
    if (_loadedSources[module] == source) return;
    _name(module);
    using((arena) {
      final bytes = utf8.encode(source);
      final native = arena<Uint8>(bytes.length + 1);
      native.asTypedList(bytes.length).setAll(0, bytes);
      _consume(
        flb_load(
          _handle,
          module.toNativeUtf8(allocator: arena).cast(),
          native.cast(),
          bytes.length,
        ),
      );
    });
    _loadedSources[module] = source;
  });

  /// Generator support; application code uses the generated API constructor.
  LuaBinding bindLua({
    required String module,
    required String contract,
    required List<String> methods,
  }) => _run(() {
    _name(module);
    using((arena) {
      final value = _encode(_array(methods));
      try {
        _consume(
          flb_bind(
            _handle,
            module.toNativeUtf8(allocator: arena).cast(),
            contract.toNativeUtf8(allocator: arena).cast(),
            value,
          ),
        );
      } finally {
        flb_value_free(value);
      }
    });
    return LuaBinding._(this, module, contract);
  });

  /// Generator support; passing null unregisters an interface.
  void registerDart({
    required String module,
    required String contract,
    required Map<String, BridgeHostMethod>? methods,
  }) => _run(() {
    _name(module);
    if (_contracts[module] != null && _contracts[module] != contract) {
      throw LuaBridgeException(
        'Dart module $module is already registered with another contract; unregister it first',
      );
    }
    final ids = <String, int>{};
    final handlers = <int, BridgeHostMethod>{};
    final entries = <Object, Object?>{};
    if (methods != null) {
      for (final e in methods.entries) {
        final id = _modules[module]?[e.key] ?? _nextId++;
        ids[e.key] = id;
        entries[e.key] = id;
        handlers[id] = e.value;
      }
    }
    using((arena) {
      final value = _encode(methods == null ? null : BridgeTable(entries));
      try {
        _consume(
          flb_register(
            _handle,
            module.toNativeUtf8(allocator: arena).cast(),
            contract.toNativeUtf8(allocator: arena).cast(),
            value,
          ),
        );
      } finally {
        flb_value_free(value);
      }
    });
    for (final id in _modules[module]?.values ?? <int>[]) {
      _handlers.remove(id);
    }
    _handlers.addAll(handlers);
    if (methods == null) {
      _modules.remove(module);
      _contracts.remove(module);
    } else {
      _modules[module] = ids;
      _contracts[module] = contract;
    }
  });

  Object? _call(
    String module,
    String contract,
    String method,
    List<Object?> arguments,
    bool isVoid,
  ) => _run(
    () => using((arena) {
      final value = _encode(_array(arguments));
      try {
        return _consume(
          flb_call(
            _handle,
            module.toNativeUtf8(allocator: arena).cast(),
            contract.toNativeUtf8(allocator: arena).cast(),
            method.toNativeUtf8(allocator: arena).cast(),
            value,
            isVoid ? 1 : 0,
          ),
        );
      } finally {
        flb_value_free(value);
      }
    }),
  );

  Pointer<NativeResult> _dispatch(int id, Pointer<NativeValue> arguments) {
    final result = flb_result_new();
    if (result == nullptr) return nullptr;
    try {
      final handler = _handlers[id];
      if (_closed || handler == null) {
        throw StateError('Dart API has been unregistered');
      }
      final args = bridgeList(
        BridgeCodec<Object?>((v, _) => v, (v, _) => v),
      ).decode(_decode(arguments.ref), 'arguments');
      final value = handler.invoke(args);
      result.ref.is_void = handler.isVoid ? 1 : 0;
      flb_value_move(flb_result_value(result), _encode(value));
    } catch (error) {
      result.ref.failed = 1;
      try {
        flb_value_move(flb_result_value(result), _encode(error.toString()));
      } catch (_) {
        flb_result_free(result);
        return nullptr;
      }
    }
    return result;
  }

  Object? _consume(Pointer<NativeResult> result) {
    if (result == nullptr) {
      throw LuaBridgeException('Native bridge ran out of memory');
    }
    try {
      final value = _decode(result.ref.value);
      if (result.ref.failed != 0) {
        throw LuaBridgeException(value?.toString() ?? 'Native bridge failed');
      }
      return value;
    } finally {
      flb_result_free(result);
    }
  }

  /// Idempotent. Generated proxies fail with StateError after closing.
  void close() {
    if (_closed) return;
    if (_busy) throw StateError('Cannot close LuaRuntime during a callback');
    _closed = true;
    try {
      flb_close(_handle);
    } finally {
      _callback.close();
      _handlers.clear();
      _modules.clear();
      _contracts.clear();
      _loadedSources.clear();
    }
  }
}

class LuaBinding {
  LuaBinding._(this._runtime, this._module, this._contract);
  final LuaRuntime _runtime;
  final String _module, _contract;
  Object? call(String method, List<Object?> arguments, {bool isVoid = false}) =>
      _runtime._call(_module, _contract, method, arguments, isVoid);
}

class BridgeHostMethod {
  const BridgeHostMethod(this.invoke, {this.isVoid = false});
  final Object? Function(List<Object?> arguments) invoke;
  final bool isVoid;
}

void _name(String name) {
  if (name.isEmpty || name.contains('\u0000')) {
    throw ArgumentError.value(
      name,
      'module',
      'must be a nonempty name without NUL',
    );
  }
}

BridgeTable _array(List<Object?> values) =>
    BridgeTable({for (var i = 0; i < values.length; i++) i + 1: values[i]});

Pointer<NativeValue> _encode(
  Object? value, [
  int depth = 0,
  List<int>? budget,
]) {
  budget ??= [0];
  if (depth >= 64 || ++budget[0] > 100000) {
    throw LuaBridgeException('Bridge value exceeds nesting/size limit');
  }
  final kind = switch (value) {
    null => 0,
    bool() => 1,
    int() => 2,
    double() => 3,
    String() => 4,
    BridgeTable() => 5,
    _ => throw LuaTypeException('value', 'generated bridge value', value),
  };
  final bytes = value is String ? utf8.encode(value) : null;
  final pointer = flb_value_new(
    kind,
    bytes?.length ?? (value is BridgeTable ? value.entries.length : 0),
  );
  if (pointer == nullptr) {
    throw LuaBridgeException('Native bridge ran out of memory');
  }
  try {
    if (value is bool) pointer.ref.integer = value ? 1 : 0;
    if (value is int) pointer.ref.integer = value;
    if (value is double) pointer.ref.number = value;
    if (bytes != null) {
      pointer.ref.bytes
          .cast<Uint8>()
          .asTypedList(bytes.length)
          .setAll(0, bytes);
    }
    if (value is BridgeTable) {
      var i = 0;
      for (final entry in value.entries.entries) {
        flb_value_move(
          pointer.ref.children + i++,
          _encode(entry.key, depth + 1, budget),
        );
        flb_value_move(
          pointer.ref.children + i++,
          _encode(entry.value, depth + 1, budget),
        );
      }
    }
    return pointer;
  } catch (_) {
    flb_value_free(pointer);
    rethrow;
  }
}

Object? _decode(NativeValue value) => switch (value.kind) {
  0 => null,
  1 => value.integer != 0,
  2 => value.integer,
  3 => value.number,
  4 => _decodeString(value),
  5 => BridgeTable({
    for (var i = 0; i < value.length; i++)
      _decode((value.children + i * 2).ref)!: _decode(
        (value.children + i * 2 + 1).ref,
      ),
  }),
  _ => throw LuaBridgeException(
    'Invalid native bridge value kind ${value.kind}',
  ),
};
String _decodeString(NativeValue value) {
  try {
    return utf8.decode(value.bytes.cast<Uint8>().asTypedList(value.length));
  } on FormatException {
    throw LuaBridgeException('Lua string is not valid UTF-8');
  }
}
