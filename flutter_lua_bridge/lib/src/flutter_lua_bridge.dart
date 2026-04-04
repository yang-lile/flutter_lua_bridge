import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

class FlutterLuaBridge {
  static LuaCApi cApi = LuaCApiImpl();
  static LuaAuxApi auxApi = LuaAuxApiImpl(luaCApi: cApi);
}
