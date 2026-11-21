import 'package:flutter/foundation.dart';

/// Writes [value] at the Lua path [luaPath] of the store.
typedef LuaStoreWriter = void Function(List<Object> luaPath, Object? value);

/// A Dart mirror of a Lua app's `store`, kept in sync in both directions.
///
/// The store lives in Lua: `spec.store` of `ui.app{...}`. Writes in Lua
/// (from event handlers or methods) are sent to the mirror with the update
/// that renders them, and [set] writes into Lua, which renders only the
/// components that read the changed keys.
///
/// Paths use Dart conventions: map keys, and zero-based indices into lists
/// (Lua's 1-based indices are translated).
class LuaStore extends ChangeNotifier {
  Object? _data;
  LuaStoreWriter? _writer;
  final Map<String, _StoreWatch> _watches = {};

  /// Whether the store is attached to a mounted [LuaView].
  bool get isAttached => _writer != null;

  /// The value at [path] (the whole store for an empty path), or `null`.
  Object? get([List<Object> path = const []]) {
    Object? current = _data;
    for (final part in path) {
      current = switch ((current, part)) {
        (Map<Object?, Object?> map, _) => map[part],
        (List<Object?> list, int i) =>
          i >= 0 && i < list.length ? list[i] : null,
        _ => null,
      };
    }
    return current;
  }

  /// Writes [value] at [path] in Lua; components that read it render again.
  void set(List<Object> path, Object? value) {
    final writer = _writer;
    if (writer == null) throw StateError('The store is not attached');
    if (path.isEmpty) throw ArgumentError.value(path, 'path', 'is empty');
    final luaPath = _toLua(path);
    writer(luaPath, value);
    _write(luaPath, _copy(value));
    _notify([luaPath]);
  }

  /// A listenable for the value at [path]. It notifies when a write touches
  /// [path], one of its parents or one of its children.
  ValueListenable<Object?> watch(List<Object> path) {
    final key = path.join('\u0000');
    return _watches.putIfAbsent(key, () => _StoreWatch(this, path));
  }

  /// Called by [LuaView] with the store as plain data.
  void attach(Object? data, LuaStoreWriter writer) {
    _data = data;
    _writer = writer;
    notifyListeners();
    for (final watch in _watches.values) {
      watch.changed();
    }
  }

  void detach(LuaStoreWriter writer) {
    if (identical(_writer, writer)) _writer = null;
  }

  /// Applies the `changes` Lua reported: `{path = {...}, value = v}` items.
  void applyChanges(Object? changes) {
    if (changes is! List || changes.isEmpty) return;
    final paths = <List<Object>>[];
    for (final change in changes) {
      if (change is! Map) continue;
      final path = change['path'];
      if (path is! List || path.isEmpty) continue;
      final luaPath = path.cast<Object>();
      _write(luaPath, change['value']);
      paths.add(luaPath);
    }
    _notify(paths);
  }

  void _notify(List<List<Object>> luaPaths) {
    if (luaPaths.isEmpty) return;
    notifyListeners();
    for (final watch in _watches.values) {
      final watched = _toLua(watch.path);
      if (luaPaths.any((p) => _related(p, watched))) watch.changed();
    }
  }

  /// Translates a Dart path into Lua keys using the shape of the mirror.
  List<Object> _toLua(List<Object> path) {
    Object? current = _data;
    final result = <Object>[];
    for (final part in path) {
      if (current is List && part is int) {
        result.add(part + 1);
        current = part >= 0 && part < current.length ? current[part] : null;
      } else {
        result.add(part);
        current = current is Map ? current[part] : null;
      }
    }
    return result;
  }

  /// Writes into the mirror at a Lua path.
  void _write(List<Object> luaPath, Object? value) {
    _data ??= <Object?, Object?>{};
    Object? container = _data;
    for (var i = 0; i < luaPath.length; i++) {
      final key = luaPath[i];
      final last = i == luaPath.length - 1;
      if (container is List && key is int) {
        final index = key - 1;
        if (last) {
          if (index == container.length) {
            if (value != null) container.add(value);
          } else if (index >= 0 && index < container.length) {
            container[index] = value;
            while (container.isNotEmpty && container.last == null) {
              container.removeLast();
            }
          } else if (index > container.length && value != null) {
            container
              ..addAll(List<Object?>.filled(index - container.length, null))
              ..add(value);
          }
          return;
        }
        if (index < 0 || index >= container.length) return;
        container[index] ??= <Object?, Object?>{};
        container = container[index];
      } else if (container is Map) {
        if (last) {
          if (value == null) {
            container.remove(key);
          } else if (container.isEmpty && key == 1) {
            // An empty Lua table that becomes a list.
            final parent = luaPath.sublist(0, i);
            _replace(parent, <Object?>[value]);
          } else {
            container[key] = value;
          }
          return;
        }
        container = container.putIfAbsent(key, () => <Object?, Object?>{});
      } else {
        return;
      }
    }
  }

  void _replace(List<Object> luaPath, Object value) {
    if (luaPath.isEmpty) {
      _data = value;
      return;
    }
    _write(luaPath, value);
  }
}

/// A mutable deep copy, so that later Lua writes can update it in place.
Object? _copy(Object? value) => switch (value) {
  Map() => {for (final e in value.entries) e.key: _copy(e.value)},
  List() => [for (final item in value) _copy(item)],
  _ => value,
};

bool _related(List<Object> a, List<Object> b) {
  final n = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < n; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class _StoreWatch extends ChangeNotifier implements ValueListenable<Object?> {
  _StoreWatch(this.store, this.path);
  final LuaStore store;
  final List<Object> path;

  @override
  Object? get value => store.get(path);

  void changed() => notifyListeners();
}
