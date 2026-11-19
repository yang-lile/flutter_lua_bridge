import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:flutter_lua_bridge_codegen/flutter_lua_bridge_codegen.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

const _import =
    "import 'package:flutter_lua_bridge_codegen_annotation/flutter_lua_bridge_codegen_annotation.dart';";

/// One contract to resolve. Every case is declared while `main` runs, and
/// all of them are resolved together in `setUpAll`: one analysis context for
/// the whole file instead of one per case.
class Case {
  Case(this.libraries, this.optimizations);

  /// Library name to content; the contract is the library `contract`.
  final Map<String, String> libraries;
  final List<BridgeOptimization> optimizations;
  final _outcomes = <BridgeOptimization, Object?>{};

  Future<BridgeSchema?> schema([
    BridgeOptimization optimization = BridgeOptimization.o1,
  ]) {
    assert(_outcomes.containsKey(optimization), 'level not requested');
    final outcome = _outcomes[optimization];
    return outcome is InvalidGenerationSource
        ? Future.error(outcome)
        : Future.value(outcome as BridgeSchema?);
  }
}

final _cases = <Case>[];

Case read(
  Map<String, String> sources, {
  List<BridgeOptimization> optimizations = const [BridgeOptimization.o1],
}) {
  final contract = Case(sources, optimizations);
  _cases.add(contract);
  return contract;
}

Case parse(
  String methods, {
  String data = '',
  String annotation = "@LuaApi(module: 'test')",
  List<BridgeOptimization> optimizations = const [BridgeOptimization.o1],
}) => read({
  'contract': '$data\n$annotation\nabstract class TestApi { $methods }',
}, optimizations: optimizations);

Future<void> _resolveAll() => resolveSources(
  {
    for (final (index, contract) in _cases.indexed)
      for (final entry in contract.libraries.entries)
        'a|lib/c$index/${entry.key}.dart': '$_import\n${entry.value}',
  },
  (resolver) async {
    for (final (index, contract) in _cases.indexed) {
      final library = await resolver.libraryFor(
        AssetId('a', 'lib/c$index/contract.dart'),
      );
      for (final level in contract.optimizations) {
        try {
          contract._outcomes[level] = readBridgeSchema(
            library,
            name: 'contract',
            optimization: level,
          );
        } on InvalidGenerationSource catch (error) {
          contract._outcomes[level] = error;
        }
      }
    }
  },
  readAllSourcesFromFilesystem: true,
);

final Matcher rejects = throwsA(isA<InvalidGenerationSource>());

void main() {
  setUpAll(_resolveAll);

  final add = parse('int add(int value);');
  test('emits all three artifacts from one schema', () async {
    final schema = (await add.schema())!;
    expect(schema.bridgeModule, 'contract_bridge');
    expect(emitDart(schema), contains('class TestApiClient'));
    expect(emitLua(schema), contains('bindTestApi'));
    expect(emitTeal(schema), contains('record TestApi'));
  });

  final plain = read({'contract': 'class Plain { final int a = 1; }'});
  test('ignores libraries without an API', () async {
    expect(await plain.schema(), isNull);
  });

  final levels = parse(
    'int add(int value);',
    optimizations: BridgeOptimization.values,
  );
  final structured = parse('List<int> values();');
  test('emits the requested safety level', () async {
    Future<BridgeSchema> schema(BridgeOptimization level) async =>
        (await levels.schema(level))!;
    final o1 = await schema(BridgeOptimization.o1);
    expect(emitLua(o1), contains('runtime type checks + pcall'));
    expect(emitLua(o1), contains('_check_int'));
    expect(emitLua(o1), contains('select("#", ...)'));
    expect(emitLua(o1), contains('__mode = "k"'));
    expect(emitDart(o1), contains('LuaCallResult<int> add(int value)'));
    expect(emitDart(o1), isNot(contains('implements TestApi')));
    expect(
      emitLua((await structured.schema())!),
      contains('maximum nesting depth exceeded'),
    );
    final o2 = await schema(BridgeOptimization.o2);
    expect(emitLua(o2), contains('pcall'));
    expect(emitLua(o2), isNot(contains('_check_int')));
    expect(emitDart(o2), contains('LuaCallResult<int> add(int value)'));
    final o3 = await schema(BridgeOptimization.o3);
    expect(emitLua(o3), isNot(contains('pcall')));
    expect(emitLua(o3), isNot(contains('status =')));
    expect(emitDart(o3), contains('implements TestApi'));
    expect(emitDart(o3), contains('int add(int value)'));
    expect(emitDart(o3), isNot(contains('LuaCallResult')));
  });

  final mixed = read(
    {
      'contract': '''
@LuaApi(module: 'a', optimization: LuaOptimization.o3)
abstract class Fast { int get_(); }
@LuaApi(module: 'b')
abstract class Safe { int get_(); }
''',
    },
    optimizations: [BridgeOptimization.o2],
  );
  test('an interface can choose its own safety level', () async {
    final schema = (await mixed.schema(BridgeOptimization.o2))!;
    expect(schema.apis.map((api) => api.optimization), [
      BridgeOptimization.o3,
      BridgeOptimization.o2,
    ]);
    final lua = emitLua(schema);
    expect(lua, contains('_wrap_Safe_get_'));
    expect(lua, isNot(contains('_wrap_Fast_get_')));
    expect(lua, isNot(contains('_check_int')));
  });

  test('generated artifacts carry no contract fingerprint', () async {
    final schema = (await add.schema())!;
    for (final artifact in [
      emitDart(schema),
      emitLua(schema),
      emitTeal(schema),
    ]) {
      expect(artifact, isNot(contains('__flb_contract')));
    }
  });

  final crossLibrary = read({
    'models': '''
enum Mode { @LuaName('easy_mode') easy, hard }
class Unused { final dynamic ignored; Unused(this.ignored); }
class Result {
  const Result(this.mode, {required this.scores});
  final Mode mode;
  @LuaName('points')
  final List<int> scores;
}
''',
    'contract': '''
import 'models.dart';
@LuaApi(module: 'game')
abstract class GameApi {
  @LuaName('run_game')
  Result run(int seed, {required String mode});
}
''',
  });
  test('data classes and enums may come from other libraries', () async {
    final schema = (await crossLibrary.schema())!;
    expect(schema.apis.single.methods.single.luaName, 'run_game');
    expect(schema.apis.single.methods.single.parameters.last.named, isTrue);
    final result = schema.data.single;
    expect(result.name, 'Result');
    expect(result.fields.map((f) => (f.name, f.luaName, f.named)), [
      ('mode', 'mode', false),
      ('scores', 'points', true),
    ]);
    expect(schema.enums.single.values, {'easy': 'easy_mode', 'hard': 'hard'});
    final dart = emitDart(schema);
    // The application's own classes are used; none is re-declared.
    expect(dart, isNot(contains('class Result')));
    expect(dart, isNot(contains('enum Mode')));
    expect(dart, contains('return Result('));
    expect(dart, contains('scores: bridgeList(bridgeInt).decode('));
    expect(
      emitTeal(schema),
      contains('run_game: function(integer, string): Result'),
    );
  });

  final implied = parse(
    'Score get_(Grade grade);',
    data: '''
enum Grade { low, high; static const best = high; }
class Score {
  const Score(this.value);
  final int value;
  int get doubled => value * 2;
}
''',
  );
  test('getters and static members are not taken for fields', () async {
    final schema = (await implied.schema())!;
    expect(schema.data.single.fields.map((f) => f.name), ['value']);
    expect(schema.enums.single.values.keys, ['low', 'high']);
  });

  final named = parse('int add(int value, {required int bonus});');
  test('supports required named parameters', () async {
    final schema = (await named.schema())!;
    expect(emitDart(schema), contains('required int bonus'));
    expect(emitTeal(schema), contains('function(integer, integer): integer'));
  });

  final renamed = parse('@LuaName("finish") int end();');
  final keyword = parse('int end();');
  test('allows explicit renaming of Lua keywords in Dart members', () async {
    expect(emitLua((await renamed.schema())!), contains('"finish"'));
    expect(keyword.schema(), rejects);
  });

  final inherited = read({
    'contract': '''
abstract interface class Base { int add(int value); }
abstract interface class Shared implements Base {
  @LuaName('sub_one') int subOne(int value);
}
@LuaApi(module: 'fast', optimization: LuaOptimization.o3)
abstract class FastApi implements Shared {}
@LuaApi(module: 'safe')
abstract class SafeApi implements Shared { void reset(); }
@DartApi(module: 'host')
abstract class HostApi implements Base {}
''',
  });
  test('APIs may inherit methods from plain abstract interfaces', () async {
    final schema = (await inherited.schema())!;
    expect(
      {
        for (final api in schema.apis)
          api.name: [for (final m in api.methods) m.luaName],
      },
      {
        'FastApi': ['sub_one', 'add'],
        'SafeApi': ['reset', 'sub_one', 'add'],
        'HostApi': ['add'],
      },
    );
    final dart = emitDart(schema);
    expect(dart, contains('class FastApiClient implements FastApi'));
    expect(dart, contains('int subOne(int value)'));
    expect(emitTeal(schema), contains('sub_one: function(integer): integer'));
    expect(emitLua(schema), contains('_wrap_SafeApi_add'));
  });

  final invalidInterfaces = {
    'extends': '''
abstract class Base { int add(int value); }
@LuaApi(module: "a") abstract class A extends Base {}
''',
    'mixin': '''
mixin Base { int add(int value); }
@LuaApi(module: "a") abstract class A with Base {}
''',
    'generic interface': '''
abstract interface class Base<T> { T get_(); }
@LuaApi(module: "a") abstract class A implements Base<int> {}
''',
    'concrete interface method': '''
abstract interface class Base { int add(int value) => value; }
@LuaApi(module: "a") abstract class A implements Base {}
''',
    'interface field': '''
abstract interface class Base { int get size; int add(int value); }
@LuaApi(module: "a") abstract class A implements Base {}
''',
    'another API': '''
@LuaApi(module: "a") abstract class A { int add(int value); }
@LuaApi(module: "b") abstract class B implements A {}
''',
  }.map((name, source) => MapEntry(name, read({'contract': source})));
  test('rejects unsupported API inheritance', () {
    for (final entry in invalidInterfaces.entries) {
      expect(entry.value.schema(), rejects, reason: entry.key);
    }
  });

  final unsupported = {
    'Future': 'Future<int> get_();',
    'Stream': 'Stream<int> get_();',
    'dynamic': 'dynamic get_();',
    'Object': 'Object get_();',
    'nullable array elements': 'List<int?> get_();',
    'nullable map values': 'Map<String, int?> get_();',
    'integer map keys': 'Map<int, String> get_();',
    'untyped collections': 'List get_();',
    'function parameter': 'void get_(void Function() callback);',
    'optional parameter': 'int get_([int value = 1]);',
    'optional named parameter': 'int get_({int value = 1});',
    'generic method': 'T get_<T>(T value);',
    'getter': 'int get value;',
    'concrete method': 'int getValue() => 1;',
    'void parameter': 'int get_(void value);',
    'Object member name': 'int hashCode();',
    'no methods': '',
  };
  for (final entry in unsupported.entries) {
    final contract = parse(entry.value);
    test('rejects ${entry.key}', () {
      expect(contract.schema(), rejects);
    });
  }

  final dataCases = {
    'recursive': 'class Data { final Data? child; Data(this.child); }',
    'inheritance':
        'class Base {} class Data extends Base { final int value; Data(this.value); }',
    'mutable field': 'class Data { int value; Data(this.value); }',
    'field outside the constructor':
        'class Data { final int value; final int extra = 1; Data(this.value); }',
    'optional constructor parameter':
        'class Data { final int value; Data([this.value = 1]); }',
    'no unnamed constructor':
        'class Data { final int value; Data.named(this.value); }',
    'duplicate Lua field':
        'class Data { @LuaName("v") final int a; @LuaName("v") final int b; Data(this.a, this.b); }',
    'Object member field':
        'class Data { final int toString; Data(this.toString); }',
    'enhanced enum': 'enum Data { a; int get code => 1; }',
    'enum with a setter': 'enum Data { a; set code(int value) {} }',
    'enum with a field': 'enum Data { a; final int code = 1; }',
  }.map((name, data) => MapEntry(name, parse('Data get_();', data: data)));
  test('rejects unsupported data classes', () {
    for (final entry in dataCases.entries) {
      expect(entry.value.schema(), rejects, reason: entry.key);
    }
  });

  final invalidApis = {
    'duplicate module': '''
@LuaApi(module: "a") abstract class A { int get_(); }
@DartApi(module: "a") abstract class B { int get_(); }
''',
    'both directions':
        '@LuaApi(module: "a") @DartApi(module: "b") abstract class A { int get_(); }',
    'concrete class': '@LuaApi(module: "a") class A { int get_() => 1; }',
    'module name': '@LuaApi(module: "a b") abstract class A { int get_(); }',
    'API passed as data': '''
@LuaApi(module: "a") abstract class A { int get_(); }
@LuaApi(module: "b") abstract class B { A get_(); }
''',
  }.map((name, source) => MapEntry(name, read({'contract': source})));
  test('rejects invalid API declarations', () {
    for (final entry in invalidApis.entries) {
      expect(entry.value.schema(), rejects, reason: entry.key);
    }
  });
}
