import 'package:flutter_lua_bridge_codegen/flutter_lua_bridge_codegen.dart';
import 'package:flutter_lua_bridge_codegen/src/builders/options.dart';
import 'package:test/test.dart';

void main() {
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

  test('builder options default to the conventional layout', () {
    final options = BridgeOptions.parse(const {});
    expect(options.contracts, 'lib/bridge');
    expect(options.types, 'lua/types');
    expect(options.sources, 'lua/src');
    expect(options.output, 'assets/lua');
    expect(options.optimization, BridgeOptimization.o1);
  });

  test('builder options are validated', () {
    final options = BridgeOptions.parse(const {
      'contracts': 'lib/api',
      'optimization': 'O3',
    });
    expect(options.contracts, 'lib/api');
    expect(options.optimization, BridgeOptimization.o3);
    expect(() => BridgeOptions.parse(const {'typo': 1}), throwsArgumentError);
    expect(
      () => BridgeOptions.parse(const {'output': '../elsewhere'}),
      throwsArgumentError,
    );
    expect(
      () => BridgeOptions.parse(const {'optimization': 'O9'}),
      throwsFormatException,
    );
  });

  test('contract names follow the path below the contracts directory', () {
    const options = BridgeOptions();
    expect(options.contractName('lib/bridge/battle.dart'), 'battle');
    expect(options.contractName('lib/bridge/game/battle.dart'), 'game.battle');
    expect(options.contractName('lib/other/battle.dart'), 'battle');
  });
}
