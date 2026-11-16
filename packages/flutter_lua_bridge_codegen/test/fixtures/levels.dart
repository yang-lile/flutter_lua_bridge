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
}

@LuaApi(module: 'checked', optimization: LuaOptimization.o1)
abstract class CheckedApi implements Halver {}

@LuaApi(module: 'guarded', optimization: LuaOptimization.o2)
abstract class GuardedApi implements Halver {}

@LuaApi(module: 'direct', optimization: LuaOptimization.o3)
abstract class DirectApi implements Halver {}
