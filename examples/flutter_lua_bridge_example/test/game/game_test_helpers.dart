import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_bridge_example/game/game_scripts.dart';
import 'package:flutter_lua_bridge_example/game/models.dart';

Future<GameSources> gameSources({String formulas = 'formulas.lua'}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  return GameSources.load(rootBundle, formulas: formulas);
}

MonsterCard card(List<MonsterCard> catalog, String id) =>
    catalog.firstWhere((card) => card.id == id).copy();
