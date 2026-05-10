import 'package:test/test.dart';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

void main() {
  test('version number is available', () {
    expect(kLuaVersionReleaseNum, isNotNull);
  });

  test('type enums are defined', () {
    expect(LuaType.values, isNotEmpty);
    expect(LuaStatus.values, isNotEmpty);
    expect(LuaGC.values, isNotEmpty);
    expect(LuaArith.values, isNotEmpty);
    expect(LuaCompare.values, isNotEmpty);
  });

  test('type enum values match Lua constants', () {
    expect(LuaType.nil.value, 0);
    expect(LuaType.boolean.value, 1);
    expect(LuaType.number.value, 3);
    expect(LuaType.string.value, 4);
    expect(LuaType.table.value, 5);
    expect(LuaType.function.value, 6);
    expect(LuaType.userdata.value, 7);
    expect(LuaType.thread.value, 8);
  });

  test('status enum values match Lua constants', () {
    expect(LuaStatus.ok.value, 0);
    expect(LuaStatus.yield.value, 1);
    expect(LuaStatus.errRun.value, 2);
    expect(LuaStatus.errSyntax.value, 3);
    expect(LuaStatus.errMem.value, 4);
  });

  test('arith enum values match Lua constants', () {
    expect(LuaArith.add.value, 0);
    expect(LuaArith.sub.value, 1);
    expect(LuaArith.mul.value, 2);
    expect(LuaArith.div.value, 4);
    expect(LuaArith.mod.value, 5);
    expect(LuaArith.pow.value, 6);
    expect(LuaArith.unm.value, 7);
  });

  test('compare enum values match Lua constants', () {
    expect(LuaCompare.eq.value, 0);
    expect(LuaCompare.lt.value, 1);
    expect(LuaCompare.le.value, 2);
  });

  test('LuaType fromValue conversion', () {
    expect(LuaType.fromValue(0), equals(LuaType.nil));
    expect(LuaType.fromValue(1), equals(LuaType.boolean));
    expect(LuaType.fromValue(3), equals(LuaType.number));
    expect(LuaType.fromValue(4), equals(LuaType.string));
    expect(LuaType.fromValue(5), equals(LuaType.table));
    expect(LuaType.fromValue(6), equals(LuaType.function));
    expect(LuaType.fromValue(7), equals(LuaType.userdata));
    expect(LuaType.fromValue(8), equals(LuaType.thread));
  });

  test('LuaStatus fromValue conversion', () {
    expect(LuaStatus.fromValue(0), equals(LuaStatus.ok));
    expect(LuaStatus.fromValue(1), equals(LuaStatus.yield));
    expect(LuaStatus.fromValue(2), equals(LuaStatus.errRun));
    expect(LuaStatus.fromValue(3), equals(LuaStatus.errSyntax));
    expect(LuaStatus.fromValue(4), equals(LuaStatus.errMem));
  });

  test('LuaGC fromValue conversion', () {
    expect(LuaGC.fromValue(0), equals(LuaGC.stop));
    expect(LuaGC.fromValue(1), equals(LuaGC.restart));
    expect(LuaGC.fromValue(2), equals(LuaGC.collect));
    expect(LuaGC.fromValue(3), equals(LuaGC.count));
    expect(LuaGC.fromValue(4), equals(LuaGC.countB));
    expect(LuaGC.fromValue(5), equals(LuaGC.step));
    expect(LuaGC.fromValue(6), equals(LuaGC.setPause));
    expect(LuaGC.fromValue(7), equals(LuaGC.setStepMul));
    expect(LuaGC.fromValue(9), equals(LuaGC.isRunning));
  });

  test('LuaArith fromValue conversion', () {
    expect(LuaArith.fromValue(0), equals(LuaArith.add));
    expect(LuaArith.fromValue(1), equals(LuaArith.sub));
    expect(LuaArith.fromValue(2), equals(LuaArith.mul));
    expect(LuaArith.fromValue(4), equals(LuaArith.div));
    expect(LuaArith.fromValue(5), equals(LuaArith.mod));
    expect(LuaArith.fromValue(6), equals(LuaArith.pow));
    expect(LuaArith.fromValue(7), equals(LuaArith.unm));
    expect(LuaArith.fromValue(8), equals(LuaArith.band));
    expect(LuaArith.fromValue(9), equals(LuaArith.bor));
    expect(LuaArith.fromValue(10), equals(LuaArith.bxor));
    expect(LuaArith.fromValue(11), equals(LuaArith.shl));
    expect(LuaArith.fromValue(12), equals(LuaArith.shr));
    expect(LuaArith.fromValue(13), equals(LuaArith.bnot));
  });

  test('LuaCompare fromValue conversion', () {
    expect(LuaCompare.fromValue(0), equals(LuaCompare.eq));
    expect(LuaCompare.fromValue(1), equals(LuaCompare.lt));
    expect(LuaCompare.fromValue(2), equals(LuaCompare.le));
  });
}
