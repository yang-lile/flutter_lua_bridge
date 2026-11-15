import 'package:flutter_lua_bridge_codegen_annotation/flutter_lua_bridge_codegen_annotation.dart';
import 'package:test/test.dart';

void main() {
  test('LuaApi and DartApi retain their module names', () {
    const lua = LuaApi(module: 'game.battle');
    const dart = DartApi(module: 'host.commands');

    expect(lua.module, 'game.battle');
    expect(dart.module, 'host.commands');
  });

  test('LuaApi leaves the optimization to the builder by default', () {
    expect(const LuaApi(module: 'game').optimization, isNull);
    expect(
      const LuaApi(
        module: 'game',
        optimization: LuaOptimization.o3,
      ).optimization,
      LuaOptimization.o3,
    );
  });

  test('LuaName retains an explicit Lua identifier', () {
    const annotation = LuaName('finish');

    expect(annotation.name, 'finish');
  });
}
