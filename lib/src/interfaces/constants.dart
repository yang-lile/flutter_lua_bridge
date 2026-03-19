// AUTO GENERATED FILE by scripts/generate_dart_interfaces.lua
abstract final class LuaType {
  static const int none=-1, nil=0, boolean=1, lightUserdata=2, number=3,
    string=4, table=5, function=6, userdata=7, thread=8;
}
abstract final class LuaStatus {
  static const int ok=0, yield=1, errRun=2, errSyntax=3, errMem=4,
    errGcMM=5, errErr=6;
}
abstract final class LuaGC {
  static const int stop=0, restart=1, collect=2, count=3, countB=4,
    step=5, setPause=6, setStepMul=7;
}
abstract final class LuaOp {
  static const int eq=0, lt=1, le=2, add=0, sub=1, mul=2, div=3,
    idiv=4, mod=5, pow=6, unm=7, band=8, bor=9, bxor=10, shl=11,
    shr=12, bnot=13;
}
