import 'dart:io';

import 'package:ffigen/ffigen.dart';

/// Generates the Dart bindings for the flb shim (`native/flb.h`).
///
/// The header exposes no Lua type, so the generated file is the same for
/// every supported Lua release:
///
///     dart run tool/ffigen.dart
void main(List<String> args) {
  final packageRoot = Platform.script.resolve('../');
  const packageName = 'flutter_lua_bridge';
  FfiGenerator(
    output: Output(
      dart: DartOutput(path: packageRoot.resolve('lib/src/flb.g.dart')),
      commentType: CommentType(CommentStyle.any, CommentLength.full),
      preamble:
          '''
// Generated from native/flb.h by tool/ffigen.dart. Do not edit.
// ignore_for_file: always_specify_types
// ignore_for_file: camel_case_types
// ignore_for_file: constant_identifier_names
// ignore_for_file: non_constant_identifier_names
@ffi.DefaultAsset('package:$packageName/$packageName.dart')
library;
''',
      style: NativeExternalBindings(),
    ),
    input: Input(entryPoints: [packageRoot.resolve('native/flb.h')]),
    visitors: [
      Visitor(
        func: (node) => node.isIncluded = node.originalName.startsWith('flb_'),
        struct: (node) =>
            node.isIncluded = node.originalName.startsWith('flb_'),
        typealias: (node) =>
            node.isIncluded = node.originalName.startsWith('flb_')
            ? TypealiasInclude.ifUsed
            : TypealiasInclude.never,
        macroConstant: (node) =>
            node.isIncluded = node.originalName.startsWith('FLB_ABI'),
        unnamedEnumConstant: (node) =>
            node.isIncluded = node.originalName.startsWith('FLB_'),
      ),
    ],
  ).generate();
}
