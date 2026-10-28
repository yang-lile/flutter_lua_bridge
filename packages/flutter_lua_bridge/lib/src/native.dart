// Private ABI, deliberately independent of the raw Lua bindings.
// ignore_for_file: non_constant_identifier_names
@DefaultAsset('package:flutter_lua_bridge/flutter_lua_bridge.dart')
library;

import 'dart:ffi';

final class NativeValue extends Struct {
  @Int()
  external int kind;
  @Int64()
  external int integer;
  @Double()
  external double number;
  @Size()
  external int length;
  external Pointer<Char> bytes;
  external Pointer<NativeValue> children;
}

final class NativeResult extends Struct {
  @Int()
  external int failed;
  @Int()
  external int is_void;
  external NativeValue value;
}

final class NativeRuntime extends Opaque {}

typedef NativeCallback =
    Pointer<NativeResult> Function(Int64, Pointer<NativeValue>);

@Native<Pointer<NativeValue> Function(Int, Size)>()
external Pointer<NativeValue> flb_value_new(int kind, int length);
@Native<Void Function(Pointer<NativeValue>)>()
external void flb_value_free(Pointer<NativeValue> value);
@Native<Void Function(Pointer<NativeValue>, Pointer<NativeValue>)>()
external void flb_value_move(
  Pointer<NativeValue> target,
  Pointer<NativeValue> source,
);
@Native<Pointer<NativeResult> Function()>()
external Pointer<NativeResult> flb_result_new();
@Native<Void Function(Pointer<NativeResult>)>()
external void flb_result_free(Pointer<NativeResult> value);
@Native<Pointer<NativeValue> Function(Pointer<NativeResult>)>()
external Pointer<NativeValue> flb_result_value(Pointer<NativeResult> result);
@Native<
  Pointer<NativeRuntime> Function(Pointer<NativeFunction<NativeCallback>>, Int)
>()
external Pointer<NativeRuntime> flb_create(
  Pointer<NativeFunction<NativeCallback>> callback,
  int openLibraries,
);
@Native<Void Function(Pointer<NativeRuntime>)>()
external void flb_close(Pointer<NativeRuntime> runtime);
@Native<
  Pointer<NativeResult> Function(
    Pointer<NativeRuntime>,
    Pointer<Char>,
    Pointer<Char>,
    Size,
  )
>()
external Pointer<NativeResult> flb_load(
  Pointer<NativeRuntime> runtime,
  Pointer<Char> module,
  Pointer<Char> source,
  int length,
);
@Native<
  Pointer<NativeResult> Function(
    Pointer<NativeRuntime>,
    Pointer<Char>,
    Pointer<Char>,
    Pointer<Char>,
    Pointer<NativeValue>,
    Int,
  )
>()
external Pointer<NativeResult> flb_call(
  Pointer<NativeRuntime> runtime,
  Pointer<Char> module,
  Pointer<Char> contract,
  Pointer<Char> method,
  Pointer<NativeValue> arguments,
  int isVoid,
);
@Native<
  Pointer<NativeResult> Function(
    Pointer<NativeRuntime>,
    Pointer<Char>,
    Pointer<Char>,
    Pointer<NativeValue>,
  )
>()
external Pointer<NativeResult> flb_bind(
  Pointer<NativeRuntime> runtime,
  Pointer<Char> module,
  Pointer<Char> contract,
  Pointer<NativeValue> methods,
);
@Native<
  Pointer<NativeResult> Function(
    Pointer<NativeRuntime>,
    Pointer<Char>,
    Pointer<Char>,
    Pointer<NativeValue>,
  )
>()
external Pointer<NativeResult> flb_register(
  Pointer<NativeRuntime> runtime,
  Pointer<Char> module,
  Pointer<Char> contract,
  Pointer<NativeValue> methods,
);
