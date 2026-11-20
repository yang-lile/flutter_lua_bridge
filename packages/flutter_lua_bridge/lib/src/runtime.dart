import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'codecs.dart';
import 'errors.dart';
import 'flb.g.dart';

/// Standard library selection for [LuaRuntime.create]. Combine with `|`.
abstract final class LuaLibrary {
  static const int base = FLB_LIB_BASE;
  static const int coroutine = FLB_LIB_COROUTINE;
  static const int table = FLB_LIB_TABLE;
  static const int string = FLB_LIB_STRING;
  static const int math = FLB_LIB_MATH;
  static const int utf8 = FLB_LIB_UTF8;

  /// `require`, limited to modules provided by the host.
  static const int require = FLB_LIB_REQUIRE;
  static const int io = FLB_LIB_IO;
  static const int os = FLB_LIB_OS;
  static const int debug = FLB_LIB_DEBUG;

  /// The unrestricted `package` library (files and native libraries).
  static const int package = FLB_LIB_PACKAGE;

  /// Everything that cannot reach files, processes or native code.
  static const int safe = FLB_LIBS_SAFE;
  static const int all = FLB_LIBS_ALL;
  static const int none = 0;
}

/// Several values returned from a Dart function to Lua.
final class LuaValues {
  const LuaValues(this.values);
  final List<Object?> values;
}

/// Returned from a [LuaCallback] to suspend the coroutine that called it,
/// yielding [values] to whoever resumes it: [LuaThread.resume] returns them.
/// The values of the next resume become the callback's results in Lua, and
/// [LuaThread.resumeWithError] makes the call raise instead.
///
/// The coroutine is suspended after the callback has returned. Lua code not
/// running in a coroutine, or reached through another Dart callback, cannot
/// be suspended: the call then raises a Lua error.
final class LuaYield {
  const LuaYield([this.values = const []]);
  final List<Object?> values;
}

enum LuaThreadStatus { suspended, running, normal, dead }

/// A Dart function callable from Lua. Return a [LuaValues] for several
/// results, a [LuaYield] to suspend the calling coroutine, or a [Future] to
/// suspend it until the future completes (see [LuaThread.resumeAsync]); any
/// other value is the single result.
typedef LuaCallback = Object? Function(List<Object?> arguments);

/// A future a Dart function returned to Lua, which suspended the coroutine.
final class _Pending {
  _Pending(this.future, {required this.isVoid});
  final Future<Object?> future;
  final bool isVoid;
}

final _runtimes = <int, WeakReference<LuaRuntime>>{};
final _hostCall = NativeCallable<flb_host_callFunction>.isolateLocal(
  _onHostCall,
)..keepIsolateAlive = false;
final _hostRelease = NativeCallable<flb_host_releaseFunction>.isolateLocal(
  _onHostRelease,
)..keepIsolateAlive = false;
final _stateFinalizer = NativeFinalizer(
  Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
    flb_state_release,
  ),
);
final _tokenFinalizer = NativeFinalizer(
  Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
    flb_token_release,
  ),
);
final _scratchFinalizer = NativeFinalizer(calloc.nativeFree);

void _onHostCall(
  Pointer<flb_state> state,
  int id,
  Pointer<flb_value> arguments,
  int count,
) {
  final runtime = _runtimes[state.address]?.target;
  if (runtime == null) {
    using((arena) {
      final message = 'the Dart runtime is gone'.toNativeUtf8(allocator: arena);
      flb_fail(state, 0, message.cast(), message.length);
    });
    return;
  }
  runtime._dispatch(id, arguments, count);
}

void _onHostRelease(Pointer<flb_state> state, int id, int isObject) {
  _runtimes[state.address]?.target?._released(id, isObject != 0);
}

class _HostFunction {
  _HostFunction(
    this.invoke, {
    this.isVoid = false,
    this.byValue = false,
    this.pinned = false,
  });
  final LuaCallback invoke;
  final bool isVoid;
  final bool byValue;

  /// Owned by a registered module rather than by the Lua function object.
  final bool pinned;
}

/// One Lua state and the only entry point to it.
///
/// Values cross as `null`, `bool`, `int`, `double` and `String`. Tables,
/// functions, coroutines and userdata arrive as [LuaTable], [LuaFunction],
/// [LuaThread] and [LuaUserdata] handles. A Dart `Map` or `List` passed to
/// Lua becomes a new table.
///
/// Calls are synchronous and confined to the creating isolate. Lua errors are
/// thrown as [LuaBridgeException]. Close the runtime in a `finally` block.
final class LuaRuntime implements Finalizable {
  LuaRuntime._(this._state, this._scratch);

  /// Opens a state with the selected [libraries] (a [LuaLibrary] mask).
  /// [memoryLimit] is in bytes; 0 means unlimited.
  static LuaRuntime create({
    int libraries = LuaLibrary.safe,
    int memoryLimit = 0,
  }) {
    if (flb_abi_version() != FLB_ABI_VERSION) {
      throw LuaBridgeException('Incompatible flutter_lua_bridge native ABI');
    }
    final state = using((arena) {
      final options = arena<flb_options>();
      options.ref
        ..libraries = libraries
        ..memory_limit = memoryLimit
        ..call = _hostCall.nativeFunction
        ..release = _hostRelease.nativeFunction;
      return flb_open(options);
    });
    if (state == nullptr) {
      throw LuaBridgeException(
        'Could not create the Lua state',
        status: LuaStatus.memory,
      );
    }
    final scratch = calloc<Uint8>(64);
    final runtime = LuaRuntime._(state, scratch);
    _stateFinalizer.attach(runtime, state.cast(), detach: runtime);
    _scratchFinalizer.attach(runtime, scratch.cast());
    _runtimes[state.address] = WeakReference(runtime);
    return runtime;
  }

  /// 503, 504 or 505, depending on the Lua release the package was built with.
  static int get luaVersion => flb_lua_version();

  /// For example `Lua 5.4.9`.
  static String get luaRelease => flb_lua_release().cast<Utf8>().toDartString();

  final Pointer<flb_state> _state;
  final Pointer<Uint8> _scratch;
  Pointer<Pointer<flb_value>> get _out => _scratch.cast();
  Pointer<Size> get _count => (_scratch + 16).cast();
  Pointer<Int64> get _int64 => (_scratch + 32).cast();
  Pointer<Int32> get _int32 => (_scratch + 48).cast();

  final _functions = <int, _HostFunction>{};
  final _objects = <int, Object>{};
  final _hostErrors = <int, (Object, StackTrace)>{};
  final _moduleTables = <String, LuaTable>{};
  final _moduleIds = <String, Map<String, int>>{};
  final _loadedSources = <String, String>{};
  LuaTable? _pendingClass;
  int _nextId = 1;
  int _depth = 0;
  bool _closed = false;
  bool get isClosed => _closed;

  // ---- Running code -------------------------------------------------------

  /// Runs a text chunk and returns everything it returns.
  List<Object?> run(String code, {String? name}) => _enter((arena) {
    final (bytes, length) = _bytes(arena, code);
    _ok(flb_run(_state, bytes, length, _name(arena, name), _out, _count));
    return _readAll(_out.value, _count.value);
  });

  /// Runs a text chunk and returns its first result.
  Object? eval(String code, {String? name}) {
    final results = run(code, name: name);
    for (final extra in results.skip(1)) {
      if (extra is LuaRef) extra.release();
    }
    return results.isEmpty ? null : results.first;
  }

  /// Compiles a chunk without running it. [environment] replaces the globals
  /// seen by the chunk. Binary chunks (see [LuaFunction.dump]) are accepted
  /// only with [allowBinary].
  LuaFunction load(
    Object code, {
    String? name,
    LuaTable? environment,
    bool allowBinary = false,
  }) => _enter((arena) {
    final (bytes, length) = _bytes(arena, code);
    _ok(
      flb_load(
        _state,
        bytes,
        length,
        _name(arena, name),
        allowBinary ? FLB_MODE_TEXT | FLB_MODE_BINARY : FLB_MODE_TEXT,
        environment?._use ?? 0,
        _int64,
      ),
    );
    return LuaFunction._(this, _int64.value);
  });

  // ---- Globals, tables and functions ---------------------------------------

  LuaTable get globals => _enter((arena) {
    _ok(flb_globals(_state, _int64));
    return LuaTable._(this, _int64.value);
  });

  /// Reads a global variable.
  Object? operator [](String name) => _enter((arena) {
    _ok(flb_get_global(_state, _name(arena, name), _out));
    return _read(_out.value.ref);
  });

  /// Writes a global variable.
  void operator []=(String name, Object? value) => _enter((arena) {
    _ok(flb_set_global(_state, _name(arena, name), _value(arena, value)));
  });

  /// Creates a table, optionally filled from a `Map` or a `List`.
  LuaTable table([Object? contents]) => _enter((arena) {
    final value = arena<flb_value>();
    _write(arena, value.ref, contents ?? const <Object, Object?>{}, 0);
    if (value.ref.type != FLB_TABLE_VALUE) {
      throw ArgumentError.value(contents, 'contents', 'must be a Map or List');
    }
    _ok(flb_table_new(_state, value.ref.items, value.ref.length, _int64));
    return LuaTable._(this, _int64.value);
  });

  /// Wraps a Dart function as a Lua function. A Dart exception becomes a Lua
  /// error; if Lua does not catch it, it comes back as a
  /// [LuaBridgeException] whose `cause` is the original error.
  LuaFunction function(LuaCallback body) => _enter((arena) {
    final id = _nextId++;
    _functions[id] = _HostFunction(body);
    final status = flb_function_new(_state, id, 0, _int64);
    if (status != FLB_OK) _functions.remove(id);
    _ok(status);
    return LuaFunction._(this, _int64.value);
  });

  /// Creates the metatable shared by Dart objects of one kind; see [wrap].
  LuaTable createClass(String name) => _enter((arena) {
    _ok(flb_class_new(_state, _name(arena, name), _int64));
    return LuaTable._(this, _int64.value);
  });

  /// Hands a Dart object to Lua as a userdata of [type]. The object is kept
  /// alive until Lua collects the userdata.
  LuaUserdata wrap(Object object, LuaTable type) => _enter((arena) {
    final id = _nextId++;
    _objects[id] = object;
    final status = flb_object_new(_state, type._use, id, _int64);
    if (status != FLB_OK) _objects.remove(id);
    _ok(status);
    return LuaUserdata._(this, _int64.value, id);
  });

  /// `tostring(value)`.
  String describe(Object? value) => _enter((arena) {
    _ok(flb_tostring(_state, _value(arena, value), _out));
    return _read(_out.value.ref, lenient: true)! as String;
  });

  // ---- Modules -------------------------------------------------------------

  /// Makes `require(name)` return [value]. `null` removes the module.
  void setModule(String name, Object? value) => _enter((arena) {
    _ok(flb_set_module(_state, _name(arena, name), _value(arena, value)));
  });

  /// What `require(name)` returns, or `null` if the module is not loaded.
  Object? module(String name) => _enter((arena) {
    _ok(flb_get_module(_state, _name(arena, name), _out));
    return _read(_out.value.ref);
  });

  /// Runs [loader] the first time Lua calls `require(name)`.
  void preload(String name, LuaFunction loader) => _enter((arena) {
    _ok(flb_preload(_state, _name(arena, name), loader._use));
  });

  /// Adds a searcher: called with a module name, it returns a loader function
  /// or a string explaining why the module was not found.
  void addSearcher(LuaFunction searcher) => _enter((arena) {
    _ok(flb_add_searcher(_state, searcher._use));
  });

  // ---- Resources -----------------------------------------------------------

  int get memoryUsed => _closed ? 0 : flb_memory_used(_state);
  int get memoryLimit => _closed ? 0 : flb_memory_limit(_state);
  set memoryLimit(int bytes) {
    _check();
    flb_set_memory_limit(_state, bytes);
  }

  /// Runs a full garbage collection cycle.
  void collectGarbage() => _enter((arena) {
    _ok(flb_gc(_state, FLB_GC_COLLECT));
  });

  /// Stops the running Lua code with a [LuaStatus.interrupted] failure that
  /// Lua cannot catch. Usually called from a host function or a timer.
  void interrupt() {
    if (!_closed) flb_interrupt(_state);
  }

  /// Idempotent. Every handle and generated proxy fails with [StateError]
  /// afterwards.
  void close() {
    if (_closed) return;
    if (_depth > 0) {
      throw StateError('Cannot close LuaRuntime during a callback');
    }
    _closed = true;
    try {
      flb_close(_state);
    } finally {
      _runtimes.remove(_state.address);
      _stateFinalizer.detach(this);
      flb_state_release(_state.cast());
      _functions.clear();
      _objects.clear();
      _hostErrors.clear();
      _moduleTables.clear();
      _moduleIds.clear();
      _loadedSources.clear();
    }
  }

  // ---- Generated bindings --------------------------------------------------

  /// Executes a text chunk that returns a module table. The table is available
  /// to generated APIs and require(). Bytecode is deliberately unsupported.
  void loadModule(String module, {required String source}) {
    _moduleName(module);
    final chunk = load(source, name: module);
    final List<Object?> results;
    try {
      results = chunk.call();
    } finally {
      chunk.release();
    }
    final table = results.isEmpty ? null : results.first;
    for (final extra in results.skip(1)) {
      if (extra is LuaRef) extra.release();
    }
    if (table is! LuaTable) {
      if (table is LuaRef) table.release();
      throw LuaBridgeException("module '$module' must return a table");
    }
    _moduleTables[module]?.release();
    setModule(module, table);
    _moduleTables[module] = table;
    _loadedSources[module] = source;
  }

  /// Loads generated protocol glue once per runtime. Generated API helpers use
  /// this method so applications only need to provide their business module.
  void ensureModule(String module, {required String source}) {
    _check();
    if (_loadedSources[module] == source) return;
    loadModule(module, source: source);
  }

  /// Generator support; application code uses the generated API constructor.
  LuaBinding bindLua({required String module, required List<String> methods}) {
    _moduleName(module);
    final table = _moduleTable(module);
    for (final method in methods) {
      final value = table.get(method, raw: true);
      if (value is! LuaFunction) {
        if (value is LuaRef) value.release();
        throw LuaBridgeException('declared Lua method is missing: $method');
      }
      value.release();
    }
    return LuaBinding._(this, module);
  }

  /// Generator support; passing null unregisters an interface.
  void registerDart({
    required String module,
    required Map<String, BridgeHostMethod>? methods,
  }) {
    _moduleName(module);
    final previous = _moduleIds[module] ?? const <String, int>{};
    if (methods == null) {
      setModule(module, null);
      previous.values.forEach(_functions.remove);
      _moduleIds.remove(module);
      return;
    }
    final ids = <String, int>{
      for (final name in methods.keys) name: previous[name] ?? _nextId++,
    };
    final handlers = <int, _HostFunction>{
      for (final entry in methods.entries)
        ids[entry.key]!: _HostFunction(
          entry.value.invoke,
          isVoid: entry.value.isVoid,
          byValue: true,
          pinned: true,
        ),
    };
    // The handlers must be in place before Lua can see the functions, and the
    // previous ones stay until the new module table is installed.
    final replaced = {
      for (final id in handlers.keys)
        if (_functions.containsKey(id)) id: _functions[id]!,
    };
    _functions.addAll(handlers);
    try {
      _enter((arena) {
        final entries = <Object, Object?>{};
        final created = <LuaFunction>[];
        try {
          for (final entry in ids.entries) {
            _ok(
              flb_function_new(
                _state,
                entry.value,
                FLB_FUNCTION_BY_VALUE,
                _int64,
              ),
            );
            final function = LuaFunction._(this, _int64.value);
            created.add(function);
            entries[entry.key] = function;
          }
          _ok(
            flb_set_module(
              _state,
              _name(arena, module),
              _value(arena, entries),
            ),
          );
        } finally {
          for (final function in created) {
            function.release();
          }
        }
      });
    } catch (_) {
      handlers.keys.forEach(_functions.remove);
      _functions.addAll(replaced);
      rethrow;
    }
    for (final id in previous.values) {
      if (!handlers.containsKey(id)) _functions.remove(id);
    }
    _moduleIds[module] = ids;
  }

  LuaTable _moduleTable(String module) {
    _check();
    final table = _moduleTables[module];
    if (table == null) {
      throw LuaBridgeException("module '$module' is not loaded");
    }
    return table;
  }

  Object? _callBinding(
    LuaBinding binding,
    String method,
    List<Object?> arguments,
    bool isVoid,
  ) {
    final table = _moduleTable(binding._module);
    return _enter((arena) {
      _ok(
        flb_call_field(
          _state,
          table._use,
          _name(arena, method),
          _values(arena, arguments),
          arguments.length,
          FLB_CALL_BY_VALUE,
          _out,
          _count,
        ),
      );
      final expected = isVoid ? 0 : 1;
      if (_count.value != expected) {
        throw LuaBridgeException(
          "method '$method' must return exactly $expected values",
        );
      }
      return isVoid ? null : _read(_out.value.ref);
    });
  }

  // ---- Host callbacks ------------------------------------------------------

  void _dispatch(int id, Pointer<flb_value> arguments, int count) {
    final function = _functions[id];
    _depth++;
    try {
      if (function == null) {
        throw StateError('Dart API has been unregistered');
      }
      final result = function.invoke(_readAll(arguments, count));
      if (result is LuaYield) {
        using((arena) {
          _ok(
            flb_yield(
              _state,
              _values(arena, result.values),
              result.values.length,
            ),
          );
        });
        return;
      }
      if (result is Future<Object?>) {
        _suspendFor(result, isVoid: function.isVoid);
        return;
      }
      final values = function.isVoid
          ? const <Object?>[]
          : result is LuaValues
          ? result.values
          : [result];
      using((arena) {
        _ok(flb_return(_state, _values(arena, values), values.length));
      });
    } catch (error, stackTrace) {
      final errorId = _nextId++;
      _hostErrors[errorId] = (error, stackTrace);
      using((arena) {
        final (bytes, length) = _bytes(arena, error.toString());
        flb_fail(_state, errorId, bytes, length);
      });
    } finally {
      _depth--;
    }
  }

  /// Suspends the calling coroutine until [future] completes, yielding a
  /// token that [LuaThread.resumeAsync] recognises.
  void _suspendFor(Future<Object?> future, {required bool isVoid}) {
    if (flb_can_yield(_state) == 0) {
      future.ignore();
      throw StateError(
        'A Dart function returned a Future, but the Lua code that called it '
        'cannot be suspended: call it in a coroutine, for example with '
        'LuaFunction.callAsync, and not through another Dart function',
      );
    }
    final token = wrap(
      _Pending(future, isVoid: isVoid),
      _pendingClass ??= createClass('flutter_lua_bridge.pending'),
    );
    try {
      using((arena) {
        _ok(flb_yield(_state, _values(arena, [token]), 1));
      });
    } finally {
      token.release();
    }
  }

  void _released(int id, bool isObject) {
    if (isObject) {
      _objects.remove(id);
    } else if (_functions[id]?.pinned == false) {
      _functions.remove(id);
    }
  }

  // ---- Plumbing ------------------------------------------------------------

  void _check() {
    if (_closed) throw StateError('LuaRuntime is closed');
  }

  T _enter<T>(T Function(Arena arena) body) {
    _check();
    if (_depth == 0) _hostErrors.clear();
    return using(body);
  }

  void _ok(int status) {
    if (status != FLB_OK) throw _failure(status);
  }

  Object _failure(int status) {
    if (status == FLB_ERROR_CLOSED) return StateError('LuaRuntime is closed');
    String text(
      Pointer<Char> Function(Pointer<flb_state>, Pointer<Size>) read,
    ) {
      final bytes = read(_state, _count);
      return utf8.decode(
        bytes.cast<Uint8>().asTypedList(_count.value),
        allowMalformed: true,
      );
    }

    final cause = _hostErrors[flb_error_host_id(_state)];
    return LuaBridgeException(
      text(flb_error_message),
      status: switch (status) {
        FLB_ERROR_SYNTAX => LuaStatus.syntax,
        FLB_ERROR_MEMORY => LuaStatus.memory,
        FLB_ERROR_HANDLER => LuaStatus.handler,
        FLB_ERROR_ARGUMENT => LuaStatus.argument,
        FLB_ERROR_INTERRUPTED => LuaStatus.interrupted,
        FLB_ERROR_HOST => LuaStatus.host,
        _ => LuaStatus.runtime,
      },
      traceback: text(flb_error_traceback),
      cause: cause?.$1,
      causeStackTrace: cause?.$2,
    );
  }

  Pointer<Char> _name(Arena arena, String? name) =>
      name == null ? nullptr : name.toNativeUtf8(allocator: arena).cast();

  (Pointer<Char>, int) _bytes(Arena arena, Object text) {
    final bytes = switch (text) {
      String() => utf8.encode(text),
      Uint8List() => text,
      _ => throw ArgumentError.value(text, 'code', 'must be String or bytes'),
    };
    final native = arena<Uint8>(bytes.length + 1);
    native.asTypedList(bytes.length).setAll(0, bytes);
    return (native.cast(), bytes.length);
  }

  Pointer<flb_value> _value(Arena arena, Object? value) {
    final native = arena<flb_value>();
    _write(arena, native.ref, value, 0);
    return native;
  }

  Pointer<flb_value> _values(Arena arena, List<Object?> values) {
    if (values.isEmpty) return nullptr;
    final native = arena<flb_value>(values.length);
    for (var i = 0; i < values.length; i++) {
      _write(arena, (native + i).ref, values[i], 0);
    }
    return native;
  }

  void _write(Arena arena, flb_value slot, Object? value, int depth) {
    void pairs(int count, Iterable<(Object?, Object?)> entries) {
      if (depth >= 64) {
        throw LuaBridgeException('Bridge value exceeds nesting limit');
      }
      final items = count == 0 ? nullptr : arena<flb_value>(count * 2);
      var i = 0;
      for (final (key, item) in entries) {
        _write(arena, (items + i++).ref, key, depth + 1);
        _write(arena, (items + i++).ref, item, depth + 1);
      }
      slot
        ..type = FLB_TABLE_VALUE
        ..items = items
        ..length = count;
    }

    switch (value) {
      case null:
        slot.type = FLB_NIL;
      case bool():
        slot
          ..type = FLB_BOOLEAN
          ..i = value ? 1 : 0;
      case int():
        slot
          ..type = FLB_INTEGER
          ..i = value;
      case double():
        slot
          ..type = FLB_NUMBER
          ..n = value;
      case String() || Uint8List():
        final (bytes, length) = _bytes(arena, value);
        slot
          ..type = FLB_STRING
          ..bytes = bytes
          ..length = length;
      case LuaRef():
        if (!identical(value.runtime, this)) {
          throw ArgumentError('The Lua value belongs to another LuaRuntime');
        }
        slot
          ..type = value._type
          ..i = value._use;
      case BridgeTable():
        pairs(
          value.entries.length,
          value.entries.entries.map((e) => (e.key, e.value)),
        );
      case Map():
        pairs(value.length, value.entries.map((e) => (e.key, e.value)));
      case List():
        var index = 1;
        pairs(value.length, value.map((item) => (index++, item)));
      default:
        throw LuaTypeException('value', 'a value Lua can hold', value);
    }
  }

  /// Decodes one value. Tables received by value become [BridgeTable]s.
  Object? _read(flb_value value, {bool lenient = false}) {
    switch (value.type) {
      case FLB_NIL:
        return null;
      case FLB_BOOLEAN:
        return value.i != 0;
      case FLB_INTEGER:
        return value.i;
      case FLB_NUMBER:
        return value.n;
      case FLB_STRING:
        final bytes = value.bytes.cast<Uint8>().asTypedList(value.length);
        if (lenient) return utf8.decode(bytes, allowMalformed: true);
        try {
          return utf8.decode(bytes);
        } on FormatException {
          throw LuaBridgeException('Lua string is not valid UTF-8');
        }
      case FLB_TABLE:
        return LuaTable._(this, value.i);
      case FLB_FUNCTION:
        return LuaFunction._(this, value.i);
      case FLB_THREAD:
        return LuaThread._(this, value.i);
      case FLB_USERDATA:
        return LuaUserdata._(this, value.i, value.id);
      case FLB_LIGHTUSERDATA:
        return Pointer<Void>.fromAddress(value.i);
      case FLB_TABLE_VALUE:
        return BridgeTable({
          for (var i = 0; i < value.length; i++)
            _read((value.items + 2 * i).ref)!: _read(
              (value.items + 2 * i + 1).ref,
            ),
        });
      default:
        throw LuaBridgeException('Invalid native value type ${value.type}');
    }
  }

  /// Decodes values the host now owns. Handles are created for every
  /// reference before anything that can throw, so none is leaked.
  List<Object?> _readAll(Pointer<flb_value> items, int count) {
    final result = List<Object?>.filled(count, null);
    for (var i = 0; i < count; i++) {
      final type = (items + i).ref.type;
      if (type >= FLB_TABLE && type <= FLB_THREAD) {
        result[i] = _read((items + i).ref);
      }
    }
    for (var i = 0; i < count; i++) {
      final type = (items + i).ref.type;
      if (type < FLB_TABLE || type > FLB_THREAD) {
        result[i] = _read((items + i).ref);
      }
    }
    return result;
  }
}

/// A handle to a Lua value that lives in the Lua state. It keeps the value
/// alive until [release] is called or the handle is garbage collected.
sealed class LuaRef implements Finalizable {
  LuaRef._(this.runtime, this._ref)
    : _token = flb_token_new(runtime._state, _ref) {
    if (_token != nullptr) _tokenFinalizer.attach(this, _token, detach: this);
  }

  final LuaRuntime runtime;
  final int _ref;
  final Pointer<Void> _token;
  bool _released = false;
  int get _type;

  int get _use {
    runtime._check();
    if (_released) throw StateError('The Lua value has been released');
    return _ref;
  }

  /// Lets Lua collect the value now instead of waiting for Dart's collector.
  void release() {
    if (_released) return;
    _released = true;
    if (_token != nullptr) {
      _tokenFinalizer.detach(this);
      flb_token_release(_token);
    }
  }

  /// Whether both handles refer to the same Lua value.
  bool sameAs(LuaRef other) => runtime._enter((arena) {
    runtime._ok(
      flb_equals(
        runtime._state,
        runtime._value(arena, this),
        runtime._value(arena, other),
        runtime._int32,
      ),
    );
    return runtime._int32.value != 0;
  });

  @override
  String toString() => runtime.isClosed || _released
      ? '$runtimeType(released)'
      : runtime.describe(this);
}

final class LuaTable extends LuaRef {
  LuaTable._(super.runtime, super.ref) : super._();
  @override
  int get _type => FLB_TABLE;

  /// `table[key]`. With [raw], metamethods are bypassed.
  Object? get(Object? key, {bool raw = false}) => runtime._enter((arena) {
    final r = runtime;
    r._ok(flb_get(r._state, _use, r._value(arena, key), raw ? 1 : 0, r._out));
    return r._read(r._out.value.ref);
  });

  /// `table[key] = value`. With [raw], metamethods are bypassed.
  void set(Object? key, Object? value, {bool raw = false}) =>
      runtime._enter((arena) {
        final r = runtime;
        r._ok(
          flb_set(
            r._state,
            _use,
            r._value(arena, key),
            r._value(arena, value),
            raw ? 1 : 0,
          ),
        );
      });

  Object? operator [](Object? key) => get(key);
  void operator []=(Object? key, Object? value) => set(key, value);

  /// `#table`.
  int get length => runtime._enter((arena) {
    final r = runtime;
    r._ok(flb_length(r._state, _use, 0, r._int64));
    return r._int64.value;
  });

  /// A snapshot of every key and value.
  Map<Object, Object?> get entries => runtime._enter((arena) {
    final r = runtime;
    r._ok(flb_pairs(r._state, _use, r._out, r._count));
    final values = r._readAll(r._out.value, r._count.value * 2);
    return {
      for (var i = 0; i < values.length; i += 2) values[i]!: values[i + 1],
    };
  });

  /// The values at `1..#table`.
  List<Object?> get sequence => runtime._enter((arena) {
    final r = runtime;
    r._ok(flb_sequence(r._state, _use, r._out, r._count));
    return r._readAll(r._out.value, r._count.value);
  });

  /// Calls `table.name(arguments...)`.
  List<Object?> call(String name, [List<Object?> arguments = const []]) =>
      _invoke(name, arguments, flb_call_field);

  /// Calls `table:name(arguments...)`.
  List<Object?> callMethod(String name, [List<Object?> arguments = const []]) =>
      _invoke(name, arguments, flb_call_method);

  List<Object?> _invoke(
    String name,
    List<Object?> arguments,
    int Function(
      Pointer<flb_state>,
      int,
      Pointer<Char>,
      Pointer<flb_value>,
      int,
      int,
      Pointer<Pointer<flb_value>>,
      Pointer<Size>,
    )
    function,
  ) => runtime._enter((arena) {
    final r = runtime;
    r._ok(
      function(
        r._state,
        _use,
        r._name(arena, name),
        r._values(arena, arguments),
        arguments.length,
        0,
        r._out,
        r._count,
      ),
    );
    return r._readAll(r._out.value, r._count.value);
  });

  LuaTable? get metatable => runtime._enter((arena) {
    final r = runtime;
    r._ok(flb_get_metatable(r._state, _use, r._int64));
    return r._int64.value == 0 ? null : LuaTable._(r, r._int64.value);
  });

  set metatable(LuaTable? value) => runtime._enter((arena) {
    runtime._ok(flb_set_metatable(runtime._state, _use, value?._use ?? 0));
  });

  /// A deep copy as plain Dart data, read without running metamethods. A
  /// table whose keys are exactly `1..n` becomes a `List`, any other table a
  /// `Map` (an empty table is an empty `Map`). Fails if the table holds a
  /// cycle, a function, a userdata or a coroutine.
  Object toDart() => runtime._enter((arena) {
    final r = runtime;
    r._ok(flb_copy(r._state, r._value(arena, this), r._out));
    return _plain(r._read(r._out.value.ref))!;
  });
}

Object? _plain(Object? value) {
  if (value is! BridgeTable) return value;
  final entries = value.entries;
  var isList = entries.isNotEmpty;
  for (var i = 1; isList && i <= entries.length; i++) {
    isList = entries.containsKey(i);
  }
  if (isList) {
    return [for (var i = 1; i <= entries.length; i++) _plain(entries[i])];
  }
  return {for (final e in entries.entries) e.key: _plain(e.value)};
}

final class LuaFunction extends LuaRef {
  LuaFunction._(super.runtime, super.ref) : super._();
  @override
  int get _type => FLB_FUNCTION;

  /// Calls the function and returns everything it returns.
  List<Object?> call([List<Object?> arguments = const []]) =>
      runtime._enter((arena) {
        final r = runtime;
        r._ok(
          flb_call(
            r._state,
            _use,
            r._values(arena, arguments),
            arguments.length,
            0,
            r._out,
            r._count,
          ),
        );
        return r._readAll(r._out.value, r._count.value);
      });

  /// The function as a binary chunk for [LuaRuntime.load].
  Uint8List dump({bool strip = false}) => runtime._enter((arena) {
    final r = runtime;
    r._ok(flb_dump(r._state, _use, strip ? 1 : 0, r._out));
    final value = r._out.value.ref;
    return Uint8List.fromList(
      value.bytes.cast<Uint8>().asTypedList(value.length),
    );
  });

  /// A coroutine running this function.
  LuaThread coroutine() => runtime._enter((arena) {
    final r = runtime;
    r._ok(flb_thread_new(r._state, _use, r._int64));
    return LuaThread._(r, r._int64.value);
  });

  /// Calls the function in a new coroutine and awaits every [Future] that a
  /// Dart function it calls returns (see [LuaThread.resumeAsync]), so Lua
  /// calls asynchronous Dart functions as if they were synchronous.
  ///
  /// Throws a [StateError] if the function yields by itself; use
  /// [coroutine] and [LuaThread.resumeAsync] to handle its own yields.
  Future<List<Object?>> callAsync([List<Object?> arguments = const []]) async {
    final thread = coroutine();
    try {
      final results = await thread.resumeAsync(arguments);
      if (!thread.isDead) {
        throw StateError(
          'The Lua function yielded instead of returning; use coroutine() and '
          'LuaThread.resumeAsync to handle its own yields',
        );
      }
      return results;
    } finally {
      if (!runtime.isClosed) thread.release();
    }
  }
}

final class LuaThread extends LuaRef {
  LuaThread._(super.runtime, super.ref) : super._();
  @override
  int get _type => FLB_THREAD;

  /// Starts or continues the coroutine and returns what it yielded or
  /// returned; check [isDead] to tell which.
  List<Object?> resume([List<Object?> arguments = const []]) =>
      runtime._enter((arena) {
        final r = runtime;
        final status = flb_resume(
          r._state,
          _use,
          r._values(arena, arguments),
          arguments.length,
          r._out,
          r._count,
        );
        if (status != FLB_YIELD) r._ok(status);
        return r._readAll(r._out.value, r._count.value);
      });

  /// Continues a coroutine suspended by a Dart function that returned a
  /// [LuaYield]: instead of returning, that call raises [error] in Lua, where
  /// it is an ordinary string error. If Lua does not handle it, this throws a
  /// [LuaBridgeException] whose `cause` is [error].
  List<Object?> resumeWithError(Object error, [StackTrace? stackTrace]) =>
      runtime._enter((arena) {
        final r = runtime;
        final errorId = r._nextId++;
        r._hostErrors[errorId] = (error, stackTrace ?? StackTrace.current);
        final (bytes, length) = r._bytes(arena, error.toString());
        final status = flb_resume_failure(
          r._state,
          _use,
          errorId,
          bytes,
          length,
          r._out,
          r._count,
        );
        if (status != FLB_YIELD) r._ok(status);
        return r._readAll(r._out.value, r._count.value);
      });

  /// Like [resume], but awaits the futures that Dart functions called by the
  /// coroutine return. Each one suspends the coroutine until it completes;
  /// Lua then receives its value as the call's result, or its error raised
  /// by the call. Completes with what the coroutine yields by itself or
  /// returns: check [isDead] to tell which.
  Future<List<Object?>> resumeAsync([
    List<Object?> arguments = const [],
  ]) async {
    var results = resume(arguments);
    while (true) {
      final pending = _pendingOf(results);
      if (pending == null) return results;
      Object? value;
      (Object, StackTrace)? failure;
      try {
        value = await pending.future;
      } catch (error, stackTrace) {
        failure = (error, stackTrace);
      }
      results = failure != null
          ? resumeWithError(failure.$1, failure.$2)
          : resume(
              pending.isVoid
                  ? const []
                  : value is LuaValues
                  ? value.values
                  : [value],
            );
    }
  }

  /// The future behind the token a Dart function yielded, if [results] is it.
  _Pending? _pendingOf(List<Object?> results) {
    if (results.length != 1) return null;
    final token = results.single;
    if (token is! LuaUserdata) return null;
    final pending = token.object;
    if (pending is! _Pending || isDead) return null;
    token.release();
    return pending;
  }

  LuaThreadStatus get status => runtime._enter((arena) {
    final r = runtime;
    r._ok(flb_thread_status(r._state, _use, r._int32));
    return LuaThreadStatus.values[r._int32.value];
  });

  bool get isDead => status == LuaThreadStatus.dead;

  /// Closes a suspended coroutine, running its pending to-be-closed variables.
  void close() => runtime._enter((arena) {
    runtime._ok(flb_thread_close(runtime._state, _use));
  });
}

final class LuaUserdata extends LuaRef {
  LuaUserdata._(super.runtime, super.ref, this._id) : super._();
  final int _id;
  @override
  int get _type => FLB_USERDATA;

  /// The Dart object given to [LuaRuntime.wrap], or `null` for a userdata
  /// that was not created by Dart.
  Object? get object => runtime._objects[_id];
}

/// Generator support: the Lua side of one generated interface.
class LuaBinding {
  LuaBinding._(this._runtime, this._module);
  final LuaRuntime _runtime;
  final String _module;
  Object? call(String method, List<Object?> arguments, {bool isVoid = false}) =>
      _runtime._callBinding(this, method, arguments, isVoid);
}

/// Generator support: one Dart method callable from Lua.
class BridgeHostMethod {
  const BridgeHostMethod(this.invoke, {this.isVoid = false});
  final Object? Function(List<Object?> arguments) invoke;
  final bool isVoid;
}

void _moduleName(String name) {
  if (name.isEmpty || name.contains('\u0000')) {
    throw ArgumentError.value(
      name,
      'module',
      'must be a nonempty name without NUL',
    );
  }
}
