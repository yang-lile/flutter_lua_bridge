/// Build Flutter widget trees from Lua.
///
/// [LuaView] runs a Lua app on a `LuaRuntime` and shows the widgets it
/// returns. Widgets come from [LuaWidgetLibrary] registries: [coreLibrary]
/// covers `package:flutter/widgets.dart`, and Material, Cupertino or
/// application widgets are registered the same way.
library;

export 'src/args.dart'
    show
        LuaBuildSink,
        LuaBuilderTrigger,
        LuaEventSink,
        LuaHandlerTrigger,
        LuaWidgetArgs;
export 'src/controlled_text.dart' show LuaControlledText;
export 'src/core_library.dart' show coreLibrary;
export 'src/decoders.dart' show LuaDecoders;
export 'src/library.dart'
    show LuaHostFunction, LuaWidgetBuilder, LuaWidgetLibrary;
export 'src/lua_view.dart' show LuaView, LuaViewController, LuaViewErrorBuilder;
export 'src/store.dart' show LuaStore;
export 'src/tree.dart' show LuaComponentWidget, LuaNodeWidget;
export 'src/lua_modules.dart' show uiLuaModules;
