import 'dart:ffi';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

extension QuickCallMethod on FlutterLuaBridgeBindings {
  String debugValue(Pointer<lua_State> l, int index) =>
      lua_typename(l, lua_type(l, index)).toDartString();
}
