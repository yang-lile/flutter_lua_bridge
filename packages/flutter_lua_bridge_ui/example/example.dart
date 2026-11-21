// A counter list whose items are Lua components: tapping one renders only
// that item again.
import 'package:flutter/widgets.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge_ui/flutter_lua_bridge_ui.dart';

const source = r'''
local Counter = ui.component(function(props)
  local state = ui.state { taps = 0 }
  return function(props)
    return GestureDetector {
      onTap = function() state.taps = state.taps + 1 end,
      child = Container {
        padding = EdgeInsets.all(12),
        decoration = BoxDecoration {
          color = Color(0xFFE0E7FF),
          borderRadius = BorderRadius.circular(8),
        },
        child = Text { props.name .. ": " .. state.taps },
      },
    }
  end
end)

return App {
  store = { names = { "apples", "pears", "plums" } },
  view = function(store)
    local children = {}
    for i, name in ipairs(store.names) do
      children[i] = Counter { key = name, name = name }
    end
    return Center {
      child = Column {
        mainAxisSize = MainAxisSize.min,
        spacing = 8,
        children = children,
      },
    }
  end,
}
''';

void main() {
  final lua = LuaRuntime.create(memoryLimit: 16 << 20);
  runApp(
    WidgetsApp(
      color: const Color(0xFF3F51B5),
      builder: (context, _) => LuaView(runtime: lua, source: source),
    ),
  );
}
