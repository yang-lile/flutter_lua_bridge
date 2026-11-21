import 'package:flutter/widgets.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge_ui/flutter_lua_bridge_ui.dart';
import 'package:flutter_test/flutter_test.dart';

const counter = r'''
return App {
  store = { count = 0 },
  methods = {
    add = function(store, args) store.count = store.count + args.by; return store.count end,
  },
  view = function(store, props)
    return Column {
      children = {
        Text { (props.label or "count") .. ": " .. store.count },
        GestureDetector {
          key = "plus",
          onTap = function() store.count = store.count + 1 end,
          child = Text { "+1" },
        },
      },
    }
  end,
}
''';

/// Counts the builds of `test.Probe{ name = ... }`.
final builds = <String, int>{};
final probes = LuaWidgetLibrary(
  name: 'test',
  widgets: {
    'Probe': (context, args) {
      final name = args.v<String>(['name'])!;
      builds[name] = (builds[name] ?? 0) + 1;
      return Text('$name=${args.v<Object>(['value'])}');
    },
    // Calls onChanged(value, label) like a ValueChanged with two arguments.
    'Toggle': (context, args) => GestureDetector(
      onTap: () => args
          .handler<void Function(bool, String?)>(
            ['onChanged'],
            (trigger) =>
                (value, label) => trigger([value, label]),
          )
          ?.call(!(args.v<bool>(['value']) ?? false), null),
      child: Text('toggle ${args.v<bool>(['value'])}'),
    ),
  },
  luaModules: const {
    'test.widgets': '''
local ui = require("flb.ui")
return ui.library("test", { "Probe", "Toggle" })
''',
  },
  luaGlobals: 'test.widgets',
);
final probeLibraries = [probes];

/// A list of components that each read one item of the store.
const items = r'''
local Item = ui.component(function(props)
  return function(props)
    return GestureDetector {
      onTap = function() props.item.value = props.item.value + 10 end,
      child = Probe { name = props.item.name, value = props.item.value },
    }
  end
end)
return App {
  store = { title = "t", items = {
    { name = "a", value = 0 }, { name = "b", value = 0 }, { name = "c", value = 0 },
  } },
  methods = {
    bump = function(store, i) store.items[i].value = store.items[i].value + 1 end,
    push = function(store, name) table.insert(store.items, { name = name, value = 0 }) end,
    pop = function(store) table.remove(store.items) end,
    retitle = function(store, t) store.title = t end,
  },
  view = function(store)
    local children = { Probe { name = "title", value = store.title } }
    for i, item in ipairs(store.items) do
      children[#children + 1] = Item { key = item.name, item = item }
    end
    return Column { children = children }
  end,
}
''';

Widget host(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  late LuaRuntime lua;
  setUp(() {
    lua = LuaRuntime.create();
    builds.clear();
  });
  tearDown(() => lua.close());

  testWidgets('an event handler updates the store and the view', (
    tester,
  ) async {
    await tester.pumpWidget(host(LuaView(runtime: lua, source: counter)));
    expect(find.text('count: 0'), findsOneWidget);

    await tester.tap(find.text('+1'));
    await tester.pump();
    expect(find.text('count: 1'), findsOneWidget);
  });

  testWidgets('props reach the view and changes render again', (tester) async {
    await tester.pumpWidget(
      host(LuaView(runtime: lua, source: counter, props: const {'label': 'a'})),
    );
    expect(find.text('a: 0'), findsOneWidget);
    await tester.pumpWidget(
      host(LuaView(runtime: lua, source: counter, props: const {'label': 'b'})),
    );
    expect(find.text('b: 0'), findsOneWidget);
  });

  testWidgets('the controller calls app methods', (tester) async {
    final controller = LuaViewController();
    await tester.pumpWidget(
      host(LuaView(runtime: lua, source: counter, controller: controller)),
    );
    expect(controller.call('add', {'by': 5}), 5);
    await tester.pump();
    expect(find.text('count: 5'), findsOneWidget);
  });

  testWidgets('only components that read a changed key rebuild', (
    tester,
  ) async {
    final controller = LuaViewController();
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          source: items,
          libraries: probeLibraries,
          controller: controller,
        ),
      ),
    );
    expect(builds, {'title': 1, 'a': 1, 'b': 1, 'c': 1});

    controller.call('bump', 2);
    await tester.pump();
    expect(find.text('b=1'), findsOneWidget);
    expect(builds, {'title': 1, 'a': 1, 'b': 2, 'c': 1});

    // A handler inside a component still works after its siblings changed.
    await tester.tap(find.text('a=0'));
    await tester.pump();
    expect(find.text('a=10'), findsOneWidget);
    expect(builds, {'title': 1, 'a': 2, 'b': 2, 'c': 1});

    // The root read the title: it renders again, but the items keep their
    // widgets because their props are unchanged.
    controller.call('retitle', 'u');
    await tester.pump();
    expect(find.text('title=u'), findsOneWidget);
    expect(builds, {'title': 2, 'a': 2, 'b': 2, 'c': 1});
  });

  testWidgets('adding and removing items mounts and unmounts components', (
    tester,
  ) async {
    final controller = LuaViewController();
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          source: items,
          libraries: probeLibraries,
          controller: controller,
        ),
      ),
    );
    controller.call('push', 'd');
    await tester.pump();
    expect(find.text('d=0'), findsOneWidget);
    expect(builds['a'], 1);

    controller.call('pop');
    controller.call('pop');
    await tester.pump();
    expect(find.text('d=0'), findsNothing);
    expect(find.text('c=0'), findsNothing);
    expect(find.text('b=0'), findsOneWidget);
  });

  testWidgets('component state is local and survives parent renders', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          libraries: probeLibraries,
          source: r'''
local Counter = ui.component(function(props)
  local state = ui.state { n = 0 }
  return function(props)
    return GestureDetector {
      onTap = function() state.n = state.n + 1 end,
      child = Probe { name = props.name, value = state.n },
    }
  end
end)
return App { view = function()
  return Row { children = { Counter { name = "x" }, Counter { name = "y" } } }
end }
''',
        ),
      ),
    );
    await tester.tap(find.text('x=0'));
    await tester.pump();
    await tester.tap(find.text('x=1'));
    await tester.pump();
    expect(find.text('x=2'), findsOneWidget);
    expect(find.text('y=0'), findsOneWidget);
    expect(builds, {'x': 3, 'y': 1});
  });

  testWidgets('the store syncs from Lua to Dart and from Dart to Lua', (
    tester,
  ) async {
    final store = LuaStore();
    final controller = LuaViewController();
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          source: items,
          libraries: probeLibraries,
          controller: controller,
          store: store,
        ),
      ),
    );
    expect(store.get(['items', 1, 'name']), 'b');

    final watched = store.watch(['items', 1, 'value']);
    var notified = 0;
    watched.addListener(() => notified++);

    controller.call('bump', 2);
    expect(store.get(['items', 1, 'value']), 1);
    expect(notified, 1);

    store.set(['items', 1, 'value'], 42);
    await tester.pump();
    expect(find.text('b=42'), findsOneWidget);
    expect(watched.value, 42);
    // Both writes happened before the frame: b rebuilt once.
    expect(builds, {'title': 1, 'a': 1, 'b': 2, 'c': 1});

    controller.call('push', 'd');
    expect(store.get(['items', 3, 'name']), 'd');
    controller.call('pop');
    expect((store.get(['items']) as List).length, 3);
  });

  testWidgets('positional entries are Flutter positional parameters', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          source: r'''
return App { view = function()
  return Center { child = Row { children = { Text { "a" }, Text { data = "b" } } } }
end }
''',
        ),
      ),
    );
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.byType(Center), findsOneWidget);
  });

  testWidgets('positional children are rejected with a hint', (tester) async {
    final errors = <Object>[];
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          onError: (error, stack) => errors.add(error),
          source: r'''
return App { view = function() return Column { Text { "a" } } end }
''',
        ),
      ),
    );
    expect(errors.single.toString(), contains('Column takes no positional'));
    expect(errors.single.toString(), contains('children = {'));
  });

  testWidgets('value types are written like Flutter', (tester) async {
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          source: r'''
return App { view = function()
  return Container {
    key = "box",
    padding = EdgeInsets.symmetric { horizontal = 8, vertical = 4 },
    margin = EdgeInsets.fromLTRB(1, 2, 3, 4),
    alignment = Alignment.bottomRight,
    decoration = BoxDecoration {
      color = Color.fromARGB(255, 0, 128, 255),
      borderRadius = BorderRadius.circular(6),
      boxShadow = { BoxShadow { blurRadius = 3, offset = Offset(1, 2) } },
    },
    child = Column {
      mainAxisSize = MainAxisSize.min,
      crossAxisAlignment = CrossAxisAlignment["end"],
      children = {
        Text { "styled", style = TextStyle { fontWeight = FontWeight.w600, fontSize = 18 } },
        SizedBox.shrink {},
      },
    },
  }
end }
''',
        ),
      ),
    );
    final container = tester.widget<Container>(find.byType(Container));
    expect(
      container.padding,
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
    expect(container.margin, const EdgeInsets.fromLTRB(1, 2, 3, 4));
    expect(container.alignment, Alignment.bottomRight);
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFF0080FF));
    expect(decoration.borderRadius, BorderRadius.circular(6));
    expect(decoration.boxShadow!.single.offset, const Offset(1, 2));
    expect(decoration.boxShadow!.single.blurRadius, 3);
    final column = tester.widget<Column>(find.byType(Column));
    expect(column.crossAxisAlignment, CrossAxisAlignment.end);
    final text = tester.widget<Text>(find.text('styled'));
    expect(text.style!.fontWeight, FontWeight.w600);
    expect(text.style!.fontSize, 18);
  });

  testWidgets('a misspelled enum value is a Lua error', (tester) async {
    final errors = <Object>[];
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          onError: (error, stack) => errors.add(error),
          source: r'''
return App { view = function()
  return Row { mainAxisAlignment = MainAxisAlignment.centre, children = {} }
end }
''',
        ),
      ),
    );
    expect(
      errors.single.toString(),
      contains('MainAxisAlignment has no member centre'),
    );
  });

  testWidgets('handlers receive the Flutter callback parameters', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          libraries: probeLibraries,
          source: r'''
return App {
  store = { on = false, n = 0 },
  view = function(store)
    return Toggle {
      value = store.on,
      onChanged = function(value, label)
        store.on = value
        store.n = select("#", value, label)
      end,
    }
  end,
}
''',
        ),
      ),
    );
    expect(find.text('toggle false'), findsOneWidget);
    await tester.tap(find.text('toggle false'));
    await tester.pump();
    expect(find.text('toggle true'), findsOneWidget);
  });

  testWidgets('ListView.builder builds items lazily as components', (
    tester,
  ) async {
    final controller = LuaViewController();
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          libraries: probeLibraries,
          controller: controller,
          source: r'''
local values = {}
for i = 1, 1000 do values[i] = 0 end
return App {
  store = { values = values, title = "list" },
  methods = {
    bump = function(store, i) store.values[i] = store.values[i] + 1 end,
    live = function(store) return ui.instances(store) end,
  },
  view = function(store)
    return ListView.builder {
      itemCount = #store.values,
      itemExtent = 20,
      itemBuilder = function(context, index)
        return Probe { name = "i" .. index, value = store.values[index + 1] }
      end,
    }
  end,
}
''',
        ),
      ),
    );
    // Only the visible items were built (600 px / 20 px).
    expect(builds.length, lessThan(50));
    expect(builds['i0'], 1);
    expect(builds.containsKey('i999'), isFalse);

    // A store write renders only the item that read it.
    controller.call('bump', 2);
    await tester.pump();
    expect(find.text('i1=1'), findsOneWidget);
    expect(builds['i1'], 2);
    expect(builds['i0'], 1);

    // Scrolling far releases the items that left in Lua, and builds new ones.
    final before = controller.call('live')! as int;
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pump();
    expect(find.text('i0=0'), findsNothing);
    expect(
      builds.keys.where((k) => int.parse(k.substring(1)) > 200),
      isNotEmpty,
    );
    final after = controller.call('live')! as int;
    expect(after, lessThan(before + 20));
  });

  testWidgets('events before the next frame reach the current handlers', (
    tester,
  ) async {
    await tester.pumpWidget(host(LuaView(runtime: lua, source: counter)));
    // The first tap renders the root again; the second tap still uses the
    // widget of the previous render, whose handler id must stay valid.
    await tester.tap(find.text('+1'));
    await tester.tap(find.text('+1'));
    await tester.pump();
    expect(find.text('count: 2'), findsOneWidget);
  });

  testWidgets('list items keep their state when the list renders again', (
    tester,
  ) async {
    final controller = LuaViewController();
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          libraries: probeLibraries,
          controller: controller,
          source: r'''
local Row = ui.component(function(props)
  local state = ui.state { n = 0 }
  return function(props)
    return GestureDetector {
      onTap = function() state.n = state.n + 1 end,
      child = Probe { name = props.title .. props.index, value = state.n },
    }
  end
end)
return App {
  store = { title = "a" },
  methods = { retitle = function(store, t) store.title = t end },
  view = function(store)
    return ListView.builder {
      itemCount = 3,
      itemExtent = 40,
      itemBuilder = function(context, index)
        return Row { index = index, title = store.title }
      end,
    }
  end,
}
''',
        ),
      ),
    );
    await tester.tap(find.text('a1=0'));
    await tester.pump();
    expect(find.text('a1=1'), findsOneWidget);

    controller.call('retitle', 'b');
    await tester.pump();
    expect(find.text('b1=1'), findsOneWidget);
    expect(find.text('b0=0'), findsOneWidget);
  });

  testWidgets('libraries are looked up as library.Widget', (tester) async {
    final app = LuaWidgetLibrary(
      name: 'app',
      widgets: {
        'Text': (context, args) => Text('app:${args.v<String>(['text'])}'),
      },
    );
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          libraries: [app],
          source: r'''
local app = ui.library("app", { "Text" }, { Text = { "text" } })
return App { view = function()
  return Column { children = { app.Text { "x" }, Text { "y" }, ui.node("app.Text", { text = "z" }) } }
end }
''',
        ),
      ),
    );
    expect(find.text('app:x'), findsOneWidget);
    expect(find.text('y'), findsOneWidget);
    expect(find.text('app:z'), findsOneWidget);
  });

  testWidgets('Lua errors show the fallback and reach onError', (tester) async {
    final errors = <Object>[];
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          onError: (error, stack) => errors.add(error),
          fallback: (context, error) => const Text('fallback'),
          source: r'''
return App { view = function() error("boom") end }
''',
        ),
      ),
    );
    expect(find.text('fallback'), findsOneWidget);
    expect(errors.single, isA<LuaBridgeException>());
    expect(errors.single.toString(), contains('boom'));
  });

  testWidgets('unknown widgets and icons become error widgets', (tester) async {
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          source: r'''
return App { view = function()
  return Stack { children = { ui.node("nope.Thing"), Icon { Icons.missing } } }
end }
''',
        ),
      ),
    );
    expect(find.byType(ErrorWidget), findsNWidgets(2));
  });
}
