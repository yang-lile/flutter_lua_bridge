import 'package:flutter_lua_bridge_codegen/flutter_lua_bridge_codegen.dart';
import 'package:test/test.dart';

void main() {
  test('parses annotation options into the shared schema model', () {
    const source = '''
import 'package:flutter_lua_bridge_codegen_annotation/flutter_lua_bridge_codegen_annotation.dart';

@ConfigureLuaBridge(
  dartOut: 'lib/game.g.dart',
  luaOut: 'lua/game.lua',
  tealOut: 'lua/game.d.tl',
  optimization: 'O2',
)
@LuaApi(module: 'game')
abstract class GameApi {
  @LuaName('run_game')
  Result run(int seed, {required String mode});
}

enum Mode { @LuaName('easy_mode') easy, hard }

class Result {
  final Mode mode;
  final List<int> scores;
  Result(this.mode, this.scores);
}
''';

    final schema = parseBridgeSchema(source);
    expect(schema.optimization, BridgeOptimization.o2);
    expect(schema.outputs, {
      'dartOut': 'lib/game.g.dart',
      'luaOut': 'lua/game.lua',
      'tealOut': 'lua/game.d.tl',
    });
    expect(schema.apis.single.module, 'game');
    expect(schema.apis.single.methods.single.luaName, 'run_game');
    expect(schema.apis.single.methods.single.parameters.last.named, isTrue);
    expect(schema.data.single.fields.map((field) => field.name), [
      'mode',
      'scores',
    ]);
    expect(schema.enums.single.values['easy'], 'easy_mode');
  });

  test('formats nested nullable bridge types', () {
    const type = BridgeType(
      'Map',
      arguments: [
        BridgeType('String'),
        BridgeType('List', arguments: [BridgeType('int')]),
      ],
      nullable: true,
    );

    expect(type.dart, 'Map<String, List<int>>?');
    expect(type.nonNullable.dart, 'Map<String, List<int>>');
  });

  test('renders nested nullable collection types', () {
    const type = BridgeType(
      'Map',
      arguments: [
        BridgeType('String'),
        BridgeType('List', arguments: [BridgeType('int')], nullable: true),
      ],
    );

    expect(type.dart, 'Map<String, List<int>?>');
    expect(type.nonNullable.dart, 'Map<String, List<int>?>');
  });

  test('exposes optimization policy flags', () {
    expect(BridgeOptimization.o1.label, 'O1');
    expect(BridgeOptimization.o1.checksTypes, isTrue);
    expect(BridgeOptimization.o1.catchesErrors, isTrue);
    expect(BridgeOptimization.o2.checksTypes, isFalse);
    expect(BridgeOptimization.o2.catchesErrors, isTrue);
    expect(BridgeOptimization.o3.checksTypes, isFalse);
    expect(BridgeOptimization.o3.catchesErrors, isFalse);
  });

  test('parses optimization names case-insensitively', () {
    expect(parseBridgeOptimization('o1'), BridgeOptimization.o1);
    expect(parseBridgeOptimization('O2'), BridgeOptimization.o2);
    expect(parseBridgeOptimization('o3'), BridgeOptimization.o3);
    expect(() => parseBridgeOptimization('O4'), throwsFormatException);
  });
}
