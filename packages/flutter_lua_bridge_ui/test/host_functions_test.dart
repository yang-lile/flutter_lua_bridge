import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge_ui/flutter_lua_bridge_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Future's callback runs in the microtasks after the next frame; Lua
/// resumes there and the frame after shows the result.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Widget host(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

/// `Api.add(a, b)` returns at once, `Api.later()` returns [pending]'s
/// future and `Api.echo(...)` its arguments.
Completer<Object?> pending = Completer();
final api = LuaWidgetLibrary(
  name: 'app',
  widgets: const {},
  functions: {
    'Api.add': (context, args) => (args[0]! as num) + (args[1]! as num),
    'Api.later': (context, args) => pending.future,
    'Api.echo': (context, args) => args,
  },
  luaModules: const {
    'app.api':
        'return require("flb.ui").functions("app", '
        '{ "Api.add", "Api.later", "Api.echo" })',
  },
  luaGlobals: 'app.api',
);

void main() {
  late LuaRuntime lua;
  setUp(() {
    lua = LuaRuntime.create();
  });
  tearDown(() => lua.close());

  testWidgets('Lua calls a Dart function and gets its result', (tester) async {
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          libraries: [api],
          source: r'''
return App {
  store = { sum = 0, echo = "" },
  view = function(store)
    return GestureDetector {
      onTap = function()
        store.sum = Api.add(2, 3)
        local e = Api.echo("a", nil, { x = 1 })
        store.echo = e[1] .. ":" .. tostring(e[2]) .. ":" .. e[3].x
      end,
      child = Text { store.sum .. " " .. store.echo },
    }
  end,
}
''',
        ),
      ),
    );
    await tester.tap(find.byType(Text));
    await tester.pump();
    expect(find.text('5 a:nil:1'), findsOneWidget);
  });

  testWidgets('an event handler waits for a Future', (tester) async {
    // Created in the test's zone, so completing it runs in the test.
    pending = Completer();
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          libraries: [api],
          source: r'''
return App {
  store = { state = "idle" },
  view = function(store)
    return GestureDetector {
      onTap = function()
        store.state = "waiting"
        local ok, value = pcall(Api.later)
        store.state = ok and ("got " .. value) or ("failed " .. value)
      end,
      child = Text { store.state },
    }
  end,
}
''',
        ),
      ),
    );
    await tester.tap(find.text('idle'));
    await tester.pump();
    expect(find.text('waiting'), findsOneWidget);

    pending.complete('data');
    await settle(tester);
    expect(find.text('got data'), findsOneWidget);

    pending = Completer();
    await tester.tap(find.text('got data'));
    await tester.pump();
    pending.completeError(StateError('offline'));
    await settle(tester);
    expect(find.textContaining('failed'), findsOneWidget);
    expect(find.textContaining('offline'), findsOneWidget);
  });

  testWidgets('a method waits too, and returns nil while it waits', (
    tester,
  ) async {
    pending = Completer();
    final controller = LuaViewController();
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          libraries: [api],
          controller: controller,
          source: r'''
return App {
  store = { value = "none" },
  methods = { load = function(store) store.value = Api.later() end },
  view = function(store) return Text { store.value } end,
}
''',
        ),
      ),
    );
    expect(controller.call('load'), isNull);
    pending.complete('loaded');
    await settle(tester);
    expect(find.text('loaded'), findsOneWidget);
  });

  testWidgets('a Future that completes after the view is gone is dropped', (
    tester,
  ) async {
    pending = Completer();
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          libraries: [api],
          source: r'''
return App { view = function()
  return GestureDetector { onTap = function() Api.later() end, child = Text { "x" } }
end }
''',
        ),
      ),
    );
    await tester.tap(find.text('x'));
    await tester.pumpWidget(host(const SizedBox()));
    pending.complete(1);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unknown host function is a Lua error', (tester) async {
    final errors = <Object>[];
    await tester.pumpWidget(
      host(
        LuaView(
          runtime: lua,
          onError: (error, stack) => errors.add(error),
          source: r'''
return App { view = function()
  return GestureDetector { onTap = function() ui.invoke("app.Nope") end, child = Text { "x" } }
end }
''',
        ),
      ),
    );
    await tester.tap(find.text('x'));
    expect(errors.single.toString(), contains('no host function app.Nope'));
  });

  testWidgets('Navigator pushes a Lua route and receives its result', (
    tester,
  ) async {
    const scripts = {
      '/': r'''
return App {
  store = { picked = "nothing" },
  view = function(store)
    return GestureDetector {
      onTap = function()
        store.picked = Navigator.pushNamed("/pick", { arguments = { from = "home" } }) or "cancelled"
      end,
      child = Text { "picked " .. store.picked },
    }
  end,
}
''',
      '/pick': r'''
return App {
  view = function(store, props)
    return Column { children = {
      Text { "from " .. props.arguments.from .. ", can pop " .. tostring(Navigator.canPop()) },
      GestureDetector { onTap = function() Navigator.pop("red") end, child = Text { "red" } },
      GestureDetector { onTap = function() Navigator.pop() end, child = Text { "back" } },
    } }
  end,
}
''',
    };
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        onGenerateRoute: (settings) => PageRouteBuilder<Object?>(
          settings: settings,
          pageBuilder: (context, _, _) => _LuaRoute(
            name: settings.name!,
            source: scripts[settings.name]!,
            arguments: settings.arguments,
          ),
        ),
      ),
    );
    await tester.tap(find.text('picked nothing'));
    await tester.pumpAndSettle();
    expect(find.text('from home, can pop true'), findsOneWidget);

    await tester.tap(find.text('red'));
    await tester.pumpAndSettle();
    expect(find.text('picked red'), findsOneWidget);

    await tester.tap(find.text('picked red'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    expect(find.text('picked cancelled'), findsOneWidget);
    expect(_LuaRoute.open, 1);
  });
}

/// A route that runs its own script in its own runtime.
class _LuaRoute extends StatefulWidget {
  const _LuaRoute({required this.name, required this.source, this.arguments});

  final String name;
  final String source;
  final Object? arguments;

  static int open = 0;

  @override
  State<_LuaRoute> createState() => _LuaRouteState();
}

class _LuaRouteState extends State<_LuaRoute> {
  final runtime = LuaRuntime.create();

  @override
  void initState() {
    super.initState();
    _LuaRoute.open++;
  }

  @override
  void dispose() {
    _LuaRoute.open--;
    super.dispose();
    runtime.close();
  }

  @override
  Widget build(BuildContext context) => LuaView(
    runtime: runtime,
    name: widget.name,
    source: widget.source,
    props: {'arguments': widget.arguments},
  );
}
