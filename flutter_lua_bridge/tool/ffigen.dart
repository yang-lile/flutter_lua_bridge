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
/// 将 Flb* 枚举保持 Flb* 前缀。
String _renameType(Declaration decl) {
  final name = decl.originalName;
  // FlbType, FlbStatus, FlbGC, FlbArith, FlbCompare 等保持原样
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
  const packageName = 'flutter_lua_bridge';

  FfiGenerator(
    output: Output(
      dartFile: packageRoot.resolve('lib/src/gen/flutter_lua_bridge.g.dart'),
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
      entryPoints: [
        packageRoot.resolve('src/flutter_lua_bridge.h'),
      ],
    ),
    enums: Enums(
      include: Declarations.includeAll,
      rename: _renameType,
      renameMember: _renameEnumMember,
      style: (decl, suggested) => EnumStyle.dartEnum,
      silenceWarning: true,
    ),
    functions: Functions(
      include: Declarations.includeAll,
      rename: _renameFunction,
    ),
    structs: Structs(
      include: Declarations.includeAll,
      rename: _renameType,
      dependencies: CompoundDependencies.full,
    ),
    typedefs: Typedefs(include: Declarations.includeAll, rename: _renameType),
    globals: Globals(
      include: Declarations.includeSet({'kLuaVersionReleaseNum', 'kLuaRegistryIndex'}),
      rename: _renameFunction,
    ),
  ).generate();
}
