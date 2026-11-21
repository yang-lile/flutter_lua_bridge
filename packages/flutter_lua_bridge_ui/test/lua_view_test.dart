import 'package:flutter/widgets.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge_ui/flutter_lua_bridge_ui.dart';
import 'package:flutter_test/flutter_test.dart';

const counter = r'''
local ui = require("flb.ui")
return ui.app {
  store = { count = 0 },
  methods = {
    add = function(store, args) store.count = store.count + args.by; return store.count end,
  },
  view = function(store, props)
    return ui.Column {
      ui.Text { (props.label or "count") .. ": " .. store.count },
      ui.GestureDetector {
        key = "plus",
        onTap = function() store.count = store.count + 1 end,
        child = ui.Text { "+1" },
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
  },
);
final probeLibraries = [probes];

/// A list of components that each read one item of the store.
const items = r'''
local ui = require("flb.ui")
local test = ui.library("test", { "Probe" })
local Item = ui.component(function(props)
  return function(props)
    return ui.GestureDetector {
      onTap = function() props.item.value = props.item.value + 10 end,
      child = test.Probe { name = props.item.name, value = props.item.value },
    }
  end
end)
return ui.app {
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
    local children = { test.Probe { name = "title", value = store.title } }
    for i, item in ipairs(store.items) do
      children[#children + 1] = Item { key = item.name, item = item }
    end
    return ui.Column { children = children }
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
local ui = require("flb.ui")
local test = ui.library("test", { "Probe" })
local Counter = ui.component(function(props)
  local state = ui.state { n = 0 }
  return function(props)
    return ui.GestureDetector {
      onTap = function() state.n = state.n + 1 end,
      child = test.Probe { name = props.name, value = state.n },
    }
  end
end)
return ui.app { view = function()
  return ui.Row { Counter { name = "x" }, Counter { name = "y" } }
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

  testWidgets('positional entries become children and text', (tester) async {
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          source: r'''
local ui = require("flb.ui")
return ui.app { view = function()
  return ui.Center { ui.Row { ui.Text { "a" }, ui.Text { text = "b" } } }
end }
''',
        ),
      ),
    );
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.byType(Center), findsOneWidget);
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
local ui = require("flb.ui")
local app = ui.library("app", { "Text" })
return ui.app { view = function()
  return ui.Column { app.Text { "x" }, ui.Text { "y" }, ui.node("app.Text", { text = "z" }) }
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
local ui = require("flb.ui")
return ui.app { view = function() error("boom") end }
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
local ui = require("flb.ui")
return ui.app { view = function()
  return ui.Stack { ui.node("nope.Thing"), ui.Icon { icon = "missing" } }
end }
''',
        ),
      ),
    );
    expect(find.byType(ErrorWidget), findsNWidgets(2));
  });
}
