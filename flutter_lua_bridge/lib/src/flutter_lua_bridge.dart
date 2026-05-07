import 'package:flutter_lua_bridge/src/raw/lua_aux_api.dart';
import 'package:flutter_lua_bridge/src/raw/lua_c_api.dart';
import 'package:flutter_lua_bridge/src/raw/lua_aux_api_impl.dart';
import 'package:flutter_lua_bridge/src/raw/lua_c_api_impl.dart';

class FlutterLuaBridge {
  static LuaCApi cApi = LuaCApiImpl();
  static LuaAuxApi auxApi = LuaAuxApiImpl(luaCApi: cApi);
}
