import 'package:flutter_lua_bridge/raw.dart';
import 'package:test/test.dart';

void main() {
  test('load version', () {
    var l = luaL_newstate();
    try {
      expect(lua_version(l), equals(504));
    } finally {
      lua_close(l);
    }
  });
}
