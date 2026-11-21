import 'package:flutter/widgets.dart';

import 'args.dart';
import 'decoders.dart';
import 'library.dart';

/// The `core` library: widgets of `package:flutter/widgets.dart`.
///
/// [icons] maps the names Lua may use for `Icon` to icon data, for example
/// `{'add': Icons.add}`. Because the map holds constant [IconData], the icon
/// font tree shaker keeps working: Lua can only show registered icons.
LuaWidgetLibrary coreLibrary({Map<String, IconData> icons = const {}}) {
  return LuaWidgetLibrary(
    name: 'core',
    widgets: {
      'Align': (context, args) => Align(
        alignment:
            LuaDecoders.alignment(args, ['alignment']) ?? Alignment.center,
        widthFactor: args.v<double>(['widthFactor']),
        heightFactor: args.v<double>(['heightFactor']),
        child: args.optionalChild(['child']),
      ),
      'AspectRatio': (context, args) => AspectRatio(
        aspectRatio: args.v<double>(['aspectRatio']) ?? 1,
        child: args.optionalChild(['child']),
      ),
      'Center': (context, args) => Center(
        widthFactor: args.v<double>(['widthFactor']),
        heightFactor: args.v<double>(['heightFactor']),
        child: args.optionalChild(['child']),
      ),
      'ClipRRect': (context, args) => ClipRRect(
        borderRadius:
            LuaDecoders.borderRadius(args, ['borderRadius']) ??
            BorderRadius.zero,
        child: args.optionalChild(['child']),
      ),
      'ColoredBox': (context, args) => ColoredBox(
        color: LuaDecoders.color(args, ['color']) ?? const Color(0x00000000),
        child: args.optionalChild(['child']),
      ),
      'Column': (context, args) => Column(
        mainAxisAlignment: _mainAxis(args),
        crossAxisAlignment: _crossAxis(args),
        mainAxisSize: _mainAxisSize(args),
        spacing: args.v<double>(['spacing']) ?? 0,
        children: args.childList(['children']),
      ),
      'Container': (context, args) => Container(
        alignment: LuaDecoders.alignment(args, ['alignment']),
        padding: LuaDecoders.edgeInsets(args, ['padding']),
        margin: LuaDecoders.edgeInsets(args, ['margin']),
        color: args.isMap(['decoration'])
            ? null
            : LuaDecoders.color(args, ['color']),
        decoration: LuaDecoders.boxDecoration(args, ['decoration']),
        width: args.v<double>(['width']),
        height: args.v<double>(['height']),
        child: args.optionalChild(['child']),
      ),
      'DecoratedBox': (context, args) => DecoratedBox(
        decoration:
            LuaDecoders.boxDecoration(args, ['decoration']) ??
            const BoxDecoration(),
        child: args.optionalChild(['child']),
      ),
      'DefaultTextStyle': (context, args) => DefaultTextStyle.merge(
        style: LuaDecoders.textStyle(args, ['style']),
        textAlign: LuaDecoders.enumValue(TextAlign.values, args, ['textAlign']),
        maxLines: args.v<int>(['maxLines']),
        child: args.child(['child']),
      ),
      'Expanded': (context, args) => Expanded(
        flex: args.v<int>(['flex']) ?? 1,
        child: args.child(['child']),
      ),
      'Flexible': (context, args) => Flexible(
        flex: args.v<int>(['flex']) ?? 1,
        fit:
            LuaDecoders.enumValue(FlexFit.values, args, ['fit']) ??
            FlexFit.loose,
        child: args.child(['child']),
      ),
      'GestureDetector': (context, args) => GestureDetector(
        onTap: args.voidHandler(['onTap']),
        onDoubleTap: args.voidHandler(['onDoubleTap']),
        onLongPress: args.voidHandler(['onLongPress']),
        behavior: LuaDecoders.enumValue(HitTestBehavior.values, args, [
          'behavior',
        ]),
        child: args.optionalChild(['child']),
      ),
      'Icon': (context, args) {
        final name = args.v<String>(['icon']);
        final data = icons[name];
        if (data == null) {
          return ErrorWidget.withDetails(
            message: 'Icon "$name" is not registered in coreLibrary(icons:)',
          );
        }
        return Icon(
          data,
          size: args.v<double>(['size']),
          color: LuaDecoders.color(args, ['color']),
          semanticLabel: args.v<String>(['semanticLabel']),
        );
      },
      'Image': (context, args) {
        final image = LuaDecoders.image(args, ['source']);
        if (image == null) {
          return ErrorWidget.withDetails(message: 'Image needs a source');
        }
        return Image(
          image: image,
          width: args.v<double>(['width']),
          height: args.v<double>(['height']),
          fit: LuaDecoders.enumValue(BoxFit.values, args, ['fit']),
          semanticLabel: args.v<String>(['semanticLabel']),
        );
      },
      'ListView': (context, args) => ListView(
        scrollDirection: _axis(args),
        reverse: args.v<bool>(['reverse']) ?? false,
        shrinkWrap: args.v<bool>(['shrinkWrap']) ?? false,
        padding: LuaDecoders.edgeInsets(args, ['padding']),
        itemExtent: args.v<double>(['itemExtent']),
        children: args.childList(['children']),
      ),
      'Opacity': (context, args) => Opacity(
        opacity: (args.v<double>(['opacity']) ?? 1).clamp(0, 1),
        child: args.optionalChild(['child']),
      ),
      'Padding': (context, args) => Padding(
        padding: LuaDecoders.edgeInsets(args, ['padding']) ?? EdgeInsets.zero,
        child: args.optionalChild(['child']),
      ),
      'Positioned': (context, args) => Positioned(
        left: args.v<double>(['left']),
        top: args.v<double>(['top']),
        right: args.v<double>(['right']),
        bottom: args.v<double>(['bottom']),
        width: args.v<double>(['width']),
        height: args.v<double>(['height']),
        child: args.child(['child']),
      ),
      'Row': (context, args) => Row(
        mainAxisAlignment: _mainAxis(args),
        crossAxisAlignment: _crossAxis(args),
        mainAxisSize: _mainAxisSize(args),
        spacing: args.v<double>(['spacing']) ?? 0,
        children: args.childList(['children']),
      ),
      'SafeArea': (context, args) => SafeArea(
        left: args.v<bool>(['left']) ?? true,
        top: args.v<bool>(['top']) ?? true,
        right: args.v<bool>(['right']) ?? true,
        bottom: args.v<bool>(['bottom']) ?? true,
        child: args.child(['child']),
      ),
      'SingleChildScrollView': (context, args) => SingleChildScrollView(
        scrollDirection: _axis(args),
        reverse: args.v<bool>(['reverse']) ?? false,
        padding: LuaDecoders.edgeInsets(args, ['padding']),
        child: args.optionalChild(['child']),
      ),
      'SizedBox': (context, args) => SizedBox(
        width: args.v<double>(['width']),
        height: args.v<double>(['height']),
        child: args.optionalChild(['child']),
      ),
      'Spacer': (context, args) => Spacer(flex: args.v<int>(['flex']) ?? 1),
      'Stack': (context, args) => Stack(
        alignment:
            LuaDecoders.alignment(args, ['alignment']) ??
            AlignmentDirectional.topStart,
        fit:
            LuaDecoders.enumValue(StackFit.values, args, ['fit']) ??
            StackFit.loose,
        children: args.childList(['children']),
      ),
      'Text': (context, args) => Text(
        args.v<String>(['text']) ?? '',
        style: LuaDecoders.textStyle(args, ['style']),
        textAlign: LuaDecoders.enumValue(TextAlign.values, args, ['textAlign']),
        maxLines: args.v<int>(['maxLines']),
        softWrap: args.v<bool>(['softWrap']),
        overflow: LuaDecoders.enumValue(TextOverflow.values, args, [
          'overflow',
        ]),
      ),
      'Wrap': (context, args) => Wrap(
        direction:
            LuaDecoders.enumValue(Axis.values, args, ['direction']) ??
            Axis.horizontal,
        spacing: args.v<double>(['spacing']) ?? 0,
        runSpacing: args.v<double>(['runSpacing']) ?? 0,
        alignment:
            LuaDecoders.enumValue(WrapAlignment.values, args, ['alignment']) ??
            WrapAlignment.start,
        crossAxisAlignment:
            LuaDecoders.enumValue(WrapCrossAlignment.values, args, [
              'crossAxisAlignment',
            ]) ??
            WrapCrossAlignment.start,
        children: args.childList(['children']),
      ),
    },
  );
}

MainAxisAlignment _mainAxis(LuaWidgetArgs args) =>
    LuaDecoders.enumValue(MainAxisAlignment.values, args, [
      'mainAxisAlignment',
    ]) ??
    MainAxisAlignment.start;

CrossAxisAlignment _crossAxis(LuaWidgetArgs args) =>
    LuaDecoders.enumValue(CrossAxisAlignment.values, args, [
      'crossAxisAlignment',
    ]) ??
    CrossAxisAlignment.center;

MainAxisSize _mainAxisSize(LuaWidgetArgs args) =>
    LuaDecoders.enumValue(MainAxisSize.values, args, ['mainAxisSize']) ??
    MainAxisSize.max;

Axis _axis(LuaWidgetArgs args) =>
    LuaDecoders.enumValue(Axis.values, args, ['scrollDirection']) ??
    Axis.vertical;
