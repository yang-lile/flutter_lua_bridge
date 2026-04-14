import 'package:flutter_lua_bridge/src/gen/lua_aux_api.dart';
import 'package:flutter_lua_bridge/src/gen/lua_c_api.dart';
import 'package:flutter_lua_bridge/src/lua_aux_api_impl.dart';
import 'package:flutter_lua_bridge/src/lua_c_api_impl.dart';

class FlutterLuaBridge {
  static LuaCApi cApi = LuaCApiImpl();
  static LuaAuxApi auxApi = LuaAuxApiImpl(luaCApi: cApi);
}
