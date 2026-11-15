import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

part 'levels.g.dart';

/// The same interface at each safety level, plus a data class with
/// positional constructor parameters.
class Point {
  const Point(this.x, this.y);
  final int x;
  final int y;
}

@LuaApi(module: 'checked', optimization: LuaOptimization.o1)
abstract class CheckedApi {
  int half(int value);
  Point move(Point point, int by);
  void ping();
}

@LuaApi(module: 'guarded', optimization: LuaOptimization.o2)
abstract class GuardedApi {
  int half(int value);
  Point move(Point point, int by);
  void ping();
}

@LuaApi(module: 'direct', optimization: LuaOptimization.o3)
abstract class DirectApi {
  int half(int value);
  Point move(Point point, int by);
  void ping();
}
