// 此文件的功能已合并到 lib/src/utils/type_convert_helper.dart
// 使用 LuaStateX 扩展中的 getTypeName 方法
// 保留此文件以维持向后兼容

import 'dart:ffi';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

@Deprecated('使用 LuaStateX.getTypeName 扩展方法')
String debugValue(Pointer<lua_State> l, int index) =>
    lua_typename(l, lua_type(l, index)).toDartString();
