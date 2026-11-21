import 'package:flutter_lua_bridge_ui/flutter_lua_bridge_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'lua_modules.dart';

/// The `material` library: Material widgets of `package:material_ui`.
///
/// Lua writes them like Flutter, after the view installed the globals of
/// `flb.ui.material`:
///
/// ```lua
/// Scaffold {
///   appBar = AppBar { title = Text { "Inbox" } },
///   body = ListView { children = { ListTile { title = Text { "Hello" } } } },
///   floatingActionButton = FloatingActionButton {
///     onPressed = function() store.count = store.count + 1 end,
///     child = Icon { Icons.add },
///   },
/// }
/// ```
///
/// Icons are core `Icon` nodes, so register the icon data with
/// `coreLibrary(icons: {...})`.
LuaWidgetLibrary materialLibrary() {
  return LuaWidgetLibrary(
    name: 'material',
    luaModules: materialLuaModules,
    luaGlobals: 'flb.ui.material',
    widgets: {
      'AppBar': (context, args) => AppBar(
        title: args.optionalChild(['title']),
        leading: args.optionalChild(['leading']),
        actions: args.isList(['actions']) ? args.childList(['actions']) : null,
        backgroundColor: LuaDecoders.color(args, ['backgroundColor']),
        foregroundColor: LuaDecoders.color(args, ['foregroundColor']),
        centerTitle: args.v<bool>(['centerTitle']),
        elevation: args.v<double>(['elevation']),
      ),
      'Card': (context, args) => Card(
        color: LuaDecoders.color(args, ['color']),
        elevation: args.v<double>(['elevation']),
        margin: LuaDecoders.edgeInsets(args, ['margin']),
        child: args.optionalChild(['child']),
      ),
      'Checkbox': (context, args) => Checkbox(
        value: args.v<bool>(['value']),
        tristate: args.v<bool>(['tristate']) ?? false,
        onChanged: args.handler<ValueChanged<bool?>>(
          ['onChanged'],
          (trigger) =>
              (value) => trigger([value]),
        ),
      ),
      'Chip': (context, args) => Chip(
        label: args.child(['label']),
        avatar: args.optionalChild(['avatar']),
        backgroundColor: LuaDecoders.color(args, ['backgroundColor']),
        onDeleted: args.voidHandler(['onDeleted']),
      ),
      'CircularProgressIndicator': (context, args) => CircularProgressIndicator(
        value: args.v<double>(['value']),
        color: LuaDecoders.color(args, ['color']),
        backgroundColor: LuaDecoders.color(args, ['backgroundColor']),
        strokeWidth: args.v<double>(['strokeWidth']),
      ),
      'Divider': (context, args) => Divider(
        height: args.v<double>(['height']),
        thickness: args.v<double>(['thickness']),
        indent: args.v<double>(['indent']),
        endIndent: args.v<double>(['endIndent']),
        color: LuaDecoders.color(args, ['color']),
      ),
      'ElevatedButton': (context, args) => ElevatedButton(
        onPressed: args.voidHandler(['onPressed']),
        onLongPress: args.voidHandler(['onLongPress']),
        child: args.optionalChild(['child']),
      ),
      'ElevatedButton.icon': (context, args) => ElevatedButton.icon(
        onPressed: args.voidHandler(['onPressed']),
        onLongPress: args.voidHandler(['onLongPress']),
        icon: args.optionalChild(['icon']),
        label: args.child(['label']),
      ),
      'FilledButton': (context, args) => FilledButton(
        onPressed: args.voidHandler(['onPressed']),
        onLongPress: args.voidHandler(['onLongPress']),
        child: args.optionalChild(['child']),
      ),
      'FilledButton.icon': (context, args) => FilledButton.icon(
        onPressed: args.voidHandler(['onPressed']),
        onLongPress: args.voidHandler(['onLongPress']),
        icon: args.optionalChild(['icon']),
        label: args.child(['label']),
      ),
      'FilledButton.tonal': (context, args) => FilledButton.tonal(
        onPressed: args.voidHandler(['onPressed']),
        onLongPress: args.voidHandler(['onLongPress']),
        child: args.optionalChild(['child']),
      ),
      'FloatingActionButton': (context, args) => FloatingActionButton(
        onPressed: args.voidHandler(['onPressed']),
        tooltip: args.v<String>(['tooltip']),
        backgroundColor: LuaDecoders.color(args, ['backgroundColor']),
        foregroundColor: LuaDecoders.color(args, ['foregroundColor']),
        mini: args.v<bool>(['mini']) ?? false,
        child: args.optionalChild(['child']),
      ),
      'FloatingActionButton.extended': (context, args) =>
          FloatingActionButton.extended(
            onPressed: args.voidHandler(['onPressed']),
            tooltip: args.v<String>(['tooltip']),
            backgroundColor: LuaDecoders.color(args, ['backgroundColor']),
            foregroundColor: LuaDecoders.color(args, ['foregroundColor']),
            icon: args.optionalChild(['icon']),
            label: args.child(['label']),
          ),
      'IconButton': (context, args) => IconButton(
        icon: args.child(['icon']),
        onPressed: args.voidHandler(['onPressed']),
        tooltip: args.v<String>(['tooltip']),
        color: LuaDecoders.color(args, ['color']),
        iconSize: args.v<double>(['iconSize']),
      ),
      'IconButton.filled': (context, args) => IconButton.filled(
        icon: args.child(['icon']),
        onPressed: args.voidHandler(['onPressed']),
        tooltip: args.v<String>(['tooltip']),
        color: LuaDecoders.color(args, ['color']),
        iconSize: args.v<double>(['iconSize']),
      ),
      'InkWell': (context, args) => InkWell(
        onTap: args.voidHandler(['onTap']),
        onLongPress: args.voidHandler(['onLongPress']),
        borderRadius: LuaDecoders.borderRadius(args, ['borderRadius']),
        child: args.optionalChild(['child']),
      ),
      'LinearProgressIndicator': (context, args) => LinearProgressIndicator(
        value: args.v<double>(['value']),
        color: LuaDecoders.color(args, ['color']),
        backgroundColor: LuaDecoders.color(args, ['backgroundColor']),
        minHeight: args.v<double>(['minHeight']),
      ),
      'ListTile': (context, args) => ListTile(
        leading: args.optionalChild(['leading']),
        title: args.optionalChild(['title']),
        subtitle: args.optionalChild(['subtitle']),
        trailing: args.optionalChild(['trailing']),
        onTap: args.voidHandler(['onTap']),
        onLongPress: args.voidHandler(['onLongPress']),
        dense: args.v<bool>(['dense']),
        selected: args.v<bool>(['selected']) ?? false,
        enabled: args.v<bool>(['enabled']) ?? true,
      ),
      'Material': (context, args) => Material(
        color: LuaDecoders.color(args, ['color']),
        elevation: args.v<double>(['elevation']) ?? 0,
        borderRadius: LuaDecoders.borderRadius(args, ['borderRadius']),
        child: args.optionalChild(['child']),
      ),
      'OutlinedButton': (context, args) => OutlinedButton(
        onPressed: args.voidHandler(['onPressed']),
        onLongPress: args.voidHandler(['onLongPress']),
        child: args.optionalChild(['child']),
      ),
      'OutlinedButton.icon': (context, args) => OutlinedButton.icon(
        onPressed: args.voidHandler(['onPressed']),
        onLongPress: args.voidHandler(['onLongPress']),
        icon: args.optionalChild(['icon']),
        label: args.child(['label']),
      ),
      'Scaffold': (context, args) => Scaffold(
        appBar: _appBar(args.optionalChild(['appBar'])),
        body: args.optionalChild(['body']),
        floatingActionButton: args.optionalChild(['floatingActionButton']),
        bottomNavigationBar: args.optionalChild(['bottomNavigationBar']),
        backgroundColor: LuaDecoders.color(args, ['backgroundColor']),
      ),
      'Slider': (context, args) => Slider(
        value: args.v<double>(['value']) ?? 0,
        min: args.v<double>(['min']) ?? 0,
        max: args.v<double>(['max']) ?? 1,
        divisions: args.v<int>(['divisions']),
        label: args.v<String>(['label']),
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
      'Switch': (context, args) => Switch(
        value: args.v<bool>(['value']) ?? false,
        onChanged: args.handler<ValueChanged<bool>>(
          ['onChanged'],
          (trigger) =>
              (value) => trigger([value]),
        ),
      ),
      'TextButton': (context, args) => TextButton(
        onPressed: args.voidHandler(['onPressed']),
        onLongPress: args.voidHandler(['onLongPress']),
        child: args.child(['child']),
      ),
      'TextButton.icon': (context, args) => TextButton.icon(
        onPressed: args.voidHandler(['onPressed']),
        onLongPress: args.voidHandler(['onLongPress']),
        icon: args.optionalChild(['icon']),
        label: args.child(['label']),
      ),
      'TextField': (context, args) => LuaControlledText.fromArgs(
        args: args,
        builder: (context, controller) => TextField(
          controller: controller,
          decoration: _inputDecoration(args, ['decoration']),
          obscureText: args.v<bool>(['obscureText']) ?? false,
          maxLines: args.v<int>(['maxLines']) ?? 1,
          enabled: args.v<bool>(['enabled']),
          autofocus: args.v<bool>(['autofocus']) ?? false,
          keyboardType: _keyboardTypes[args.v<String>(['keyboardType'])],
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

/// `Scaffold.appBar` must be a [PreferredSizeWidget]; a Lua node is not, so
/// it gets the toolbar height.
PreferredSizeWidget? _appBar(Widget? child) => child == null
    ? null
    : PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: child,
      );

const Map<String?, TextInputType> _keyboardTypes = {
  'text': TextInputType.text,
  'multiline': TextInputType.multiline,
  'number': TextInputType.number,
  'phone': TextInputType.phone,
  'datetime': TextInputType.datetime,
  'emailAddress': TextInputType.emailAddress,
  'url': TextInputType.url,
  'visiblePassword': TextInputType.visiblePassword,
  'name': TextInputType.name,
};

InputBorder? _inputBorder(LuaWidgetArgs args, List<Object> key) {
  final radius = LuaDecoders.borderRadius(args, [...key, 'borderRadius']);
  return switch (args.v<String>([...key, 'type'])) {
    'outline' => OutlineInputBorder(
      borderRadius: radius ?? const BorderRadius.all(Radius.circular(4)),
    ),
    'underline' => const UnderlineInputBorder(),
    'none' => InputBorder.none,
    _ => null,
  };
}

InputDecoration? _inputDecoration(LuaWidgetArgs args, List<Object> key) {
  if (!args.isMap(key)) return const InputDecoration();
  return InputDecoration(
    labelText: args.v<String>([...key, 'labelText']),
    hintText: args.v<String>([...key, 'hintText']),
    helperText: args.v<String>([...key, 'helperText']),
    errorText: args.v<String>([...key, 'errorText']),
    prefixIcon: args.optionalChild([...key, 'prefixIcon']),
    suffixIcon: args.optionalChild([...key, 'suffixIcon']),
    filled: args.v<bool>([...key, 'filled']),
    fillColor: LuaDecoders.color(args, [...key, 'fillColor']),
    border: _inputBorder(args, [...key, 'border']),
  );
}
