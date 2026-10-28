import 'package:flutter_lua_bridge_codegen_annotation/flutter_lua_bridge_codegen_annotation.dart';

enum Mode {
  @LuaName('easy_mode')
  easy,
  hard,
}

class Payload {
  const Payload({
    required this.count,
    required this.ratio,
    required this.enabled,
    required this.text,
    required this.note,
    required this.mode,
    required this.items,
    required this.scores,
  });
  @LuaName('total')
  final int count;
  final double ratio;
  final bool enabled;
  final String text;
  final String? note;
  final Mode mode;
  final List<int> items;
  final Map<String, int> scores;
}

@ConfigureLuaBridge(
  dartOut: 'test/fixtures/values.g.dart',
  luaOut: 'test/fixtures/values_bridge.lua',
  tealOut: 'test/fixtures/values_bridge.d.tl',
  optimization: 'O3',
)
@LuaApi(module: 'values')
abstract class ValuesApi {
  Payload echo(Payload value);
  List<Payload> team(List<Payload> values);
  Map<String, List<int>> scores(Map<String, List<int>> values);
  String? text(String? value);
  int add(int a, {required int b});
  void notify(String message);
}

@DartApi(module: 'callbacks')
abstract class CallbacksApi {
  Payload echo(Payload value);
  void notify(String message);
}
