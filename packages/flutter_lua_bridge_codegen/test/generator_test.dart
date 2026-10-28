import 'package:flutter_lua_bridge_codegen/flutter_lua_bridge_codegen.dart';
import 'package:test/test.dart';

BridgeSchema parse(String methods, [String data = '']) => parseBridgeSchema('''
import 'package:flutter_lua_bridge_codegen_annotation/flutter_lua_bridge_codegen_annotation.dart';
$data
@LuaApi(module: 'test')
abstract class TestApi { $methods }
''');

void main() {
  test('emits all three artifacts from one schema', () {
    final schema = parse('int add(int value);');
    expect(emitDart(schema), contains('class _TestApi'));
    expect(emitLua(schema), contains('bindTestApi'));
    expect(emitTeal(schema), contains('record TestApi'));
  });
  test('emits the requested safety level', () {
    BridgeSchema schema(String level) => parseBridgeSchema('''
import 'package:flutter_lua_bridge_codegen_annotation/flutter_lua_bridge_codegen_annotation.dart';
@ConfigureLuaBridge(dartOut: 'a.dart', luaOut: 'a.lua', tealOut: 'a.d.tl', optimization: '$level')
@LuaApi(module: 'test')
abstract class TestApi { int add(int value); }
''');
    expect(emitLua(schema('O1')), contains('runtime type checks + pcall'));
    expect(emitLua(schema('O1')), contains('_check_int'));
    expect(emitLua(schema('O2')), contains('pcall'));
    expect(emitLua(schema('O2')), isNot(contains('_check_int')));
    expect(emitLua(schema('O3')), isNot(contains('pcall')));
    expect(emitLua(schema('O3')), isNot(contains('status =')));
    expect(() => schema('O4'), throwsFormatException);
  });
  test('fingerprint changes with method and DTO contracts', () {
    final original = parse('int add(int value);');
    expect(
      contractFingerprint(parse('int add(String value);')),
      isNot(contractFingerprint(original)),
    );
    expect(
      contractFingerprint(parse('int add(int value);')),
      contractFingerprint(original),
    );
    expect(
      contractFingerprint(
        parse(
          'Data get();',
          'class Data { final int value; Data(this.value); }',
        ),
      ),
      isNot(
        contractFingerprint(
          parse(
            'Data get();',
            'class Data { final String value; Data(this.value); }',
          ),
        ),
      ),
    );
  });
  final unsupported = {
    'Future': 'Future<int> get();',
    'Stream': 'Stream<int> get();',
    'dynamic': 'dynamic get();',
    'Object': 'Object get();',
    'nullable array elements': 'List<int?> get();',
    'nullable map values': 'Map<String, int?> get();',
    'integer map keys': 'Map<int, String> get();',
    'untyped collections': 'List get();',
    'function parameter': 'void get(void Function() callback);',
    'optional parameter': 'int get([int value = 1]);',
    'optional named parameter': 'int get({int value = 1});',
    'generic method': 'T get<T>(T value);',
    'getter': 'int get value;',
    'concrete method': 'int getValue() => 1;',
    'reserved setup name': 'void setUp();',
  };
  for (final entry in unsupported.entries) {
    test('rejects ${entry.key} during generation', () {
      expect(() => parse(entry.value), throwsFormatException);
    });
  }
  test('rejects recursive DTOs, inheritance and mutable fields', () {
    expect(
      () => parse(
        'Data get();',
        'class Data { final Data? child; Data(this.child); }',
      ),
      throwsFormatException,
    );
    expect(
      () => parse(
        'Data get();',
        'class Data extends Object { final int value; Data(this.value); }',
      ),
      throwsFormatException,
    );
    expect(
      () => parse('Data get();', 'class Data { int value; Data(this.value); }'),
      throwsFormatException,
    );
  });
  test('rejects duplicate module and Lua field names', () {
    expect(
      () => parseBridgeSchema(
        '@LuaApi(module: "a") abstract class A { int get(); } @DartApi(module: "a") abstract class B { int get(); }',
      ),
      throwsFormatException,
    );
    expect(
      () => parse(
        'Data get();',
        'class Data { @LuaName("value") final int a; @LuaName("value") final int b; Data(this.a, this.b); }',
      ),
      throwsFormatException,
    );
  });
  test('rejects unknown annotation options and generated name collisions', () {
    expect(
      () => parseBridgeSchema(
        '@LuaApi(module: "test", luaVersion: "5.3") abstract class TestApi { int add(); }',
      ),
      throwsFormatException,
    );
    expect(() => parse('int hashCode();'), throwsFormatException);
    expect(
      () => parse(
        'Data get();',
        'class Data { final int toString; Data(this.toString); }',
      ),
      throwsFormatException,
    );
  });
  test('allows explicit renaming of Lua keywords in Dart members', () {
    expect(
      emitLua(parse('@LuaName("finish") int end();')),
      contains('"finish"'),
    );
  });
  test('supports required named parameters and reachable DTOs only', () {
    final schema = parse(
      'int add(int value, {required int bonus});',
      'class Unused { final dynamic ignored; Unused(this.ignored); }',
    );
    expect(schema.data, isEmpty);
    expect(emitDart(schema), contains('required int bonus'));
    expect(emitTeal(schema), contains('function(integer, integer): integer'));
  });
}
