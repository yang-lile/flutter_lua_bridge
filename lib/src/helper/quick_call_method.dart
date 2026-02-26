import 'dart:ffi';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

String debugValue(Pointer<lua_State> l, int index) => lua_typename(l, lua_type(l, index)).toDartString();
