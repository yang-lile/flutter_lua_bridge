import 'package:flutter_lua_bridge_codegen_annotation/flutter_lua_bridge_codegen_annotation.dart';
import 'package:test/test.dart';

void main() {
  test('LuaApi and DartApi retain their module names', () {
    const lua = LuaApi(module: 'game.battle');
    const dart = DartApi(module: 'host.commands');

    expect(lua.module, 'game.battle');
    expect(dart.module, 'host.commands');
  });

  test('LuaName retains an explicit Lua identifier', () {
    const annotation = LuaName('finish');

    expect(annotation.name, 'finish');
  });

  test('ConfigureLuaBridge keeps output paths and defaults to O1', () {
    const annotation = ConfigureLuaBridge(
      dartOut: 'lib/api.g.dart',
      luaOut: 'lua/api.lua',
      tealOut: 'lua/api.d.tl',
    );

    expect(annotation.dartOut, 'lib/api.g.dart');
    expect(annotation.luaOut, 'lua/api.lua');
    expect(annotation.tealOut, 'lua/api.d.tl');
    expect(annotation.optimization, 'O1');
  });

  test('ConfigureLuaBridge accepts an explicit optimization level', () {
    const annotation = ConfigureLuaBridge(
      dartOut: 'a.dart',
      luaOut: 'a.lua',
      tealOut: 'a.d.tl',
      optimization: 'O3',
    );

    expect(annotation.optimization, 'O3');
  });
}
