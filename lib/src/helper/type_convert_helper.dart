import 'dart:ffi';

import 'package:ffi/ffi.dart';

extension PointCharX on Pointer<Char> {
  String toDartString() => cast<Utf8>().toDartString();
}

extension NativePointCharX on String {
  Pointer<Char> toPointChar() => toNativeUtf8().cast<Char>();
}
