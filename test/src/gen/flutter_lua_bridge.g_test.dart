import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:test/test.dart';

void main() {
  test('load version', () {
    var l = luaL_newstate();
    expect(lua_version(l), equals(504));
  });
}
