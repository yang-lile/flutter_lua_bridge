import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_lua_bridge_ui/flutter_lua_bridge_ui.dart';

import 'lua_modules.dart';

/// The `cupertino` library: iOS-style widgets of `package:cupertino_ui`.
///
/// Lua writes them like Flutter, after the view installed the globals of
/// `flb.ui.cupertino`:
///
/// ```lua
/// CupertinoPageScaffold {
///   navigationBar = CupertinoNavigationBar { middle = Text { "Settings" } },
///   child = CupertinoListSection.insetGrouped {
///     children = {
///       CupertinoListTile {
///         title = Text { "Wi-Fi" },
///         trailing = CupertinoSwitch {
///           value = store.wifi,
///           onChanged = function(value) store.wifi = value end,
///         },
///       },
///     },
///   },
/// }
/// ```
///
/// Lua tables have no order, so `CupertinoSegmentedControl.children` is a
/// list of `{ value = ..., child = ... }` instead of a map.
LuaWidgetLibrary cupertinoLibrary() {
  return LuaWidgetLibrary(
    name: 'cupertino',
    luaModules: cupertinoLuaModules,
    luaGlobals: 'flb.ui.cupertino',
    widgets: {
      'CupertinoActivityIndicator': (context, args) =>
          CupertinoActivityIndicator(
            radius: args.v<double>(['radius']) ?? 10,
            animating: args.v<bool>(['animating']) ?? true,
            color: LuaDecoders.color(args, ['color']),
          ),
      'CupertinoButton': (context, args) => CupertinoButton(
        onPressed: args.voidHandler(['onPressed']),
        onLongPress: args.voidHandler(['onLongPress']),
        color: LuaDecoders.color(args, ['color']),
        foregroundColor: LuaDecoders.color(args, ['foregroundColor']),
        padding: LuaDecoders.edgeInsets(args, ['padding']),
        borderRadius: LuaDecoders.borderRadius(args, ['borderRadius']),
        child: args.child(['child']),
      ),
      'CupertinoButton.filled': (context, args) => CupertinoButton.filled(
        onPressed: args.voidHandler(['onPressed']),
        onLongPress: args.voidHandler(['onLongPress']),
        padding: LuaDecoders.edgeInsets(args, ['padding']),
        borderRadius: LuaDecoders.borderRadius(args, ['borderRadius']),
        child: args.child(['child']),
      ),
      'CupertinoListSection': (context, args) => CupertinoListSection(
        header: args.optionalChild(['header']),
        footer: args.optionalChild(['footer']),
        children: args.isList(['children'])
            ? args.childList(['children'])
            : null,
      ),
      'CupertinoListSection.insetGrouped': (context, args) =>
          CupertinoListSection.insetGrouped(
            header: args.optionalChild(['header']),
            footer: args.optionalChild(['footer']),
            children: args.isList(['children'])
                ? args.childList(['children'])
                : null,
          ),
      'CupertinoListTile': (context, args) => CupertinoListTile(
        title: args.child(['title']),
        subtitle: args.optionalChild(['subtitle']),
        additionalInfo: args.optionalChild(['additionalInfo']),
        leading: args.optionalChild(['leading']),
        trailing: args.optionalChild(['trailing']),
        backgroundColor: LuaDecoders.color(args, ['backgroundColor']),
        onTap: args.voidHandler(['onTap']),
      ),
      'CupertinoNavigationBar': (context, args) => CupertinoNavigationBar(
        middle: args.optionalChild(['middle']),
        leading: args.optionalChild(['leading']),
        trailing: args.optionalChild(['trailing']),
        backgroundColor: LuaDecoders.color(args, ['backgroundColor']),
        previousPageTitle: args.v<String>(['previousPageTitle']),
      ),
      'CupertinoPageScaffold': (context, args) => CupertinoPageScaffold(
        navigationBar: _navigationBar(args.optionalChild(['navigationBar'])),
        backgroundColor: LuaDecoders.color(args, ['backgroundColor']),
        child: args.child(['child']),
      ),
      'CupertinoSegmentedControl': (context, args) {
        final count = args.length(['children']);
        final children = <String, Widget>{
          for (var i = 0; i < count; i++)
            if (args.v<Object>(['children', i, 'value']) case final value?)
              '$value': args.child(['children', i, 'child']),
        };
        if (children.length < 2) {
          return ErrorWidget.withDetails(
            message: 'CupertinoSegmentedControl needs two or more children',
          );
        }
        final selected = args.v<Object>(['groupValue']);
        return CupertinoSegmentedControl<String>(
          children: children,
          groupValue: selected == null ? null : '$selected',
          onValueChanged:
              args.handler<ValueChanged<String>>(
                ['onValueChanged'],
                (trigger) =>
                    (value) => trigger([_segmentValue(args, value)]),
              ) ??
              (value) {},
        );
      },
      'CupertinoSlider': (context, args) => CupertinoSlider(
        value: args.v<double>(['value']) ?? 0,
        min: args.v<double>(['min']) ?? 0,
        max: args.v<double>(['max']) ?? 1,
        divisions: args.v<int>(['divisions']),
        activeColor: LuaDecoders.color(args, ['activeColor']),
        onChanged: args.handler<ValueChanged<double>>(
          ['onChanged'],
          (trigger) =>
              (value) => trigger([value]),
        ),
        onChangeEnd: args.handler<ValueChanged<double>>(
          ['onChangeEnd'],
          (trigger) =>
              (value) => trigger([value]),
        ),
      ),
      'CupertinoSwitch': (context, args) => CupertinoSwitch(
        value: args.v<bool>(['value']) ?? false,
        activeTrackColor: LuaDecoders.color(args, ['activeTrackColor']),
        thumbColor: LuaDecoders.color(args, ['thumbColor']),
        onChanged: args.handler<ValueChanged<bool>>(
          ['onChanged'],
          (trigger) =>
              (value) => trigger([value]),
        ),
      ),
      'CupertinoTextField': (context, args) => LuaControlledText.fromArgs(
        args: args,
        builder: (context, controller) => CupertinoTextField(
          controller: controller,
          placeholder: args.v<String>(['placeholder']),
          prefix: args.optionalChild(['prefix']),
          suffix: args.optionalChild(['suffix']),
          padding:
              LuaDecoders.edgeInsets(args, ['padding']) ??
              const EdgeInsets.all(7),
          obscureText: args.v<bool>(['obscureText']) ?? false,
          maxLines: args.v<int>(['maxLines']) ?? 1,
          enabled: args.v<bool>(['enabled']) ?? true,
          autofocus: args.v<bool>(['autofocus']) ?? false,
          onChanged: args.handler<ValueChanged<String>>(
            ['onChanged'],
            (trigger) =>
                (value) => trigger([value]),
          ),
          onSubmitted: args.handler<ValueChanged<String>>(
            ['onSubmitted'],
            (trigger) =>
                (value) => trigger([value]),
          ),
        ),
      ),
    },
  );
}

/// The Lua value of the segment whose key is [key]: the segment values are
/// keyed by their string form, so a number comes back as a number.
Object? _segmentValue(LuaWidgetArgs args, String key) {
  final count = args.length(['children']);
  for (var i = 0; i < count; i++) {
    final value = args.v<Object>(['children', i, 'value']);
    if ('$value' == key) return value;
  }
  return key;
}

/// `CupertinoPageScaffold.navigationBar` must be an
/// [ObstructingPreferredSizeWidget]; a Lua node is not.
ObstructingPreferredSizeWidget? _navigationBar(Widget? child) =>
    child == null ? null : _NavigationBar(child);

class _NavigationBar extends StatelessWidget
    implements ObstructingPreferredSizeWidget {
  const _NavigationBar(this.child);

  final Widget child;

  @override
  Size get preferredSize =>
      const Size.fromHeight(kMinInteractiveDimensionCupertino);

  @override
  bool shouldFullyObstruct(BuildContext context) => true;

  @override
  Widget build(BuildContext context) => child;
}
