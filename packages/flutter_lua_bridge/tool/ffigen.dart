import 'dart:io';

import 'package:ffigen/ffigen.dart';

void main(List<String> args) {
  final packageRoot = Platform.script.resolve('../');
  const packageName = 'flutter_lua_bridge';
  FfiGenerator(
    output: Output(
      dartFile: packageRoot.resolve('lib/src/raw/gen/$packageName.g.dart'),
      commentType: CommentType(CommentStyle.any, CommentLength.full),
      preamble:
          '''
// ignore_for_file: always_specify_types
// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_names
@ffi.DefaultAsset('package:$packageName/$packageName.dart')
library $packageName;
''',

      style: NativeExternalBindings(),
    ),
    headers: Headers(
      entryPoints: [
        packageRoot.resolve('lua_src/src/lua.h'),
        packageRoot.resolve('lua_src/src/lualib.h'),
        packageRoot.resolve('lua_src/src/lauxlib.h'),
      ],
    ),

    enums: Enums.includeAll,
    functions: Functions(include: (d) => d.originalName.startsWith("lua")),
    globals: Globals(include: (d) => d.originalName.startsWith("lua")),
    macros: Macros(include: (d) => d.originalName.startsWith("LUA")),
    structs: Structs(
      include: (d) => d.originalName.startsWith("lua"),
      dependencies: CompoundDependencies.full,
    ),
    typedefs: Typedefs(
      include: (d) =>
          d.originalName.startsWith("lua") ||
          d.originalName == "FILE" ||
          d.originalName == "va_list",
    ),
    unions: Unions(
      include: (d) => d.originalName.startsWith("lua"),
      dependencies: CompoundDependencies.full,
    ),
    unnamedEnums: UnnamedEnums.includeAll,
  ).generate();
}
