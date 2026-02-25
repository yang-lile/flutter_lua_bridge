import 'dart:io';

import 'package:ffigen/ffigen.dart';

void main(List<String> args) {
  final packageRoot = Platform.script.resolve('../');
  const packageName = 'flutter_lua_bridge';
  FfiGenerator(
    output: Output(
      dartFile: packageRoot.resolve('lib/src/gen/$packageName.g.dart'),
      commentType: CommentType(CommentStyle.any, CommentLength.full),
      preamble: '''
// ignore_for_file: always_specify_types
// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_names
''',
    ),
    headers: Headers(
      entryPoints: [
        packageRoot.resolve('src/lua/src/lua.h'),
        packageRoot.resolve('src/lua/src/lualib.h'),
        packageRoot.resolve('src/lua/src/lauxlib.h'),
      ],
    ),
    
    enums: Enums.includeAll,
    functions: Functions.includeAll,
    globals: Globals.includeAll,
    macros: Macros.includeAll,
    structs: Structs(include: Declarations.includeAll, dependencies: CompoundDependencies.full),
    typedefs: Typedefs.includeAll,
    unions: Unions(include: Declarations.includeAll, dependencies: CompoundDependencies.full),
    unnamedEnums: UnnamedEnums.includeAll,
  ).generate();
}
