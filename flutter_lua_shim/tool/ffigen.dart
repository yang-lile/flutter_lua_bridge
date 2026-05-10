import 'dart:io';

import 'package:ffigen/ffigen.dart';

// ============================================================================
// ffigen 声明级 rename 回调
// ============================================================================

/// 函数 / 全局 / 宏 / 无名枚举重命名：保持原始 C 命名。
String _renameFunction(Declaration decl) {
  return decl.originalName;
}

/// 类型重命名（enum / struct / union / typedef）。
/// 将 lua_shim_* 枚举重命名为 Lua* 格式（大驼峰）。
String _renameType(Declaration decl) {
  final name = decl.originalName;
  if (name.startsWith('lua_shim_')) {
    // lua_shim_type -> LuaType
    // lua_shim_status -> LuaStatus
    // lua_shim_gc -> LuaGC
    // lua_shim_arith -> LuaArith
    // lua_shim_compare -> LuaCompare
    final suffix = name.substring('lua_shim_'.length);
    // 特殊处理 gc -> GC
    final suffixUpper = suffix == 'gc' ? 'GC' : suffix[0].toUpperCase() + suffix.substring(1);
    return 'Lua$suffixUpper';
  }
  return name;
}

/// 枚举成员重命名：保持原始 C 命名。
String _renameEnumMember(Declaration decl, String member) {
  return member;
}

// ============================================================================
// 4. 生成入口
// ============================================================================

void main(List<String> args) {
  final packageRoot = Platform.script.resolve('../');
  const packageName = 'flutter_lua_shim';

  FfiGenerator(
    output: Output(
      dartFile: packageRoot.resolve('lib/src/gen/$packageName.g.dart'),
      commentType: CommentType(CommentStyle.any, CommentLength.full),
      preamble:
          '''
// ignore_for_file: always_specify_types
// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: unused_element
// ignore_for_file: unused_field
@ffi.DefaultAsset('package:$packageName/$packageName.dart')
library $packageName;
''',
      style: NativeExternalBindings(),
    ),
    headers: Headers(
      entryPoints: [packageRoot.resolve('src/lua_api_types.h'), packageRoot.resolve('src/lua_api_shim.h')],
    ),
    enums: Enums(
      include: Declarations.includeAll,
      rename: _renameType,
      renameMember: _renameEnumMember,
      style: (decl, suggested) => EnumStyle.dartEnum,
      silenceWarning: true,
    ),
    functions: Functions(include: Declarations.includeAll, rename: _renameFunction),
    macros: Macros(include: Declarations.includeSet({'LUA_REGISTRYINDEX'}), rename: _renameFunction),
    structs: Structs(include: Declarations.includeAll, rename: _renameType, dependencies: CompoundDependencies.full),
    typedefs: Typedefs(include: Declarations.includeAll, rename: _renameType),
  ).generate();
}
