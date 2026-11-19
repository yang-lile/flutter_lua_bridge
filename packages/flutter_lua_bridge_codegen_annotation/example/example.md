# Example

Annotations describe a contract; `flutter_lua_bridge_codegen` generates the
code on both sides from it. Import them through `flutter_lua_bridge`, which
re-exports this package:

```dart
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

part 'battle.g.dart';

enum Element { fire, water }

class Fighter {
  // Every field is a required constructor parameter, nullable ones too.
  const Fighter({
    required this.name,
    required this.attack,
    required this.element,
  });
  final String name;
  final int attack;
  final Element? element;
}

/// Implemented in Lua or Teal, called from Dart.
@LuaApi(module: 'battle', optimization: LuaOptimization.o3)
abstract class BattleApi {
  @LuaName('calculate_damage')
  int calculateDamage(Fighter attacker, Fighter defender);
}

/// Implemented in Dart, called from Lua.
@DartApi(module: 'host')
abstract class HostApi {
  void log(String message);
}
```

See the
[`flutter_lua_bridge_codegen` example](https://pub.dev/packages/flutter_lua_bridge_codegen/example)
for the generated code and the Teal implementation.
