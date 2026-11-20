import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

part 'levels.g.dart';

/// The interface, declared once. Each API below implements it at one safety
/// level, and a data class with positional constructor parameters.
class Point {
  const Point(this.x, this.y);
  final int x;
  final int y;
}

abstract interface class Halver {
  int half(int value);
  Point move(Point point, int by);
  void ping();

  /// Waits for [ClockApi] in Lua, then halves like [half].
  Future<int> halfLater(int value);

  /// Calls the asynchronous [ClockApi] without waiting for it: an error.
  int syncWait(int value);

  /// Yields [from] down to 1, each after waiting for [ClockApi.later].
  Stream<int> countdown(int from);

  /// Sums the items of [ClockApi.ticks] in a Lua loop.
  Future<int> sumTicks(int count);
}

/// Implemented in Dart, asynchronously; Lua calls it as plain functions.
@DartApi(module: 'clock')
abstract class ClockApi {
  Future<int> later(int value);
  Future<void> tick();
  Stream<int> ticks(int count);
}

@LuaApi(module: 'checked', optimization: LuaOptimization.o1)
abstract class CheckedApi implements Halver {}

@LuaApi(module: 'guarded', optimization: LuaOptimization.o2)
abstract class GuardedApi implements Halver {}

@LuaApi(module: 'direct', optimization: LuaOptimization.o3)
abstract class DirectApi implements Halver {}
