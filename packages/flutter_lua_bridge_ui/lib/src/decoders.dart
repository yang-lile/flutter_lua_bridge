import 'package:flutter/widgets.dart';

import 'args.dart';

/// Decoders from Lua values to the Flutter types of
/// `package:flutter/widgets.dart`.
///
/// Every decoder returns `null` when the value is absent or not understood,
/// so a builder can fall back to the widget's default. Lua scripts write
/// values with the Flutter-style constructors of `flb.ui`
/// (`EdgeInsets.all(8)`, `Color(0xFF2196F3)`, `MainAxisAlignment.center`),
/// which produce these representations:
///
/// * colors: `0xAARRGGBB`, a string `"#RGB"`, `"#RRGGBB"`, `"#AARRGGBB"`,
///   or a swatch table `{value = 0xAARRGGBB, ...}`;
/// * edge insets: a number for every side, or a table with `all`,
///   `horizontal`, `vertical`, `left`, `top`, `right`, `bottom`;
/// * alignments: a name such as `"center"` or `"topLeft"`, or `{x = , y = }`;
/// * offsets: `{dx = , dy = }`;
/// * border radii: a number, or a table with `topLeft`, `topRight`,
///   `bottomLeft`, `bottomRight`;
/// * enums: the name of the value, such as `"spaceBetween"`;
/// * durations: milliseconds;
/// * font weights: `"bold"`, `"normal"`, `"w500"` or a number 100 to 900.
abstract final class LuaDecoders {
  /// A color at [key].
  static Color? color(LuaWidgetArgs args, List<Object> key) =>
      parseColor(args[key]);

  /// Parses a Lua color value.
  static Color? parseColor(Object? value) {
    if (value is int) return Color(value);
    // A swatch such as `Colors.red` of flb.ui.material: its primary value.
    if (value is Map && value['value'] is int) return Color(value['value']);
    if (value is! String || !value.startsWith('#')) return null;
    var hex = value.substring(1);
    if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
    if (hex.length == 6) hex = 'ff$hex';
    if (hex.length != 8) return null;
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? null : Color(parsed);
  }

  /// A number at [key] as a `double`.
  static double? number(LuaWidgetArgs args, List<Object> key) =>
      args.v<double>(key);

  /// Edge insets at [key].
  static EdgeInsets? edgeInsets(LuaWidgetArgs args, List<Object> key) {
    final value = args[key];
    if (value is num) return EdgeInsets.all(value.toDouble());
    if (value is! Map) return null;
    double side(String name, double fallback) =>
        args.v<double>([...key, name]) ?? fallback;
    final all = side('all', 0);
    final horizontal = side('horizontal', all);
    final vertical = side('vertical', all);
    return EdgeInsets.fromLTRB(
      side('left', horizontal),
      side('top', vertical),
      side('right', horizontal),
      side('bottom', vertical),
    );
  }

  static const Map<String, Alignment> _alignments = {
    'topLeft': Alignment.topLeft,
    'topCenter': Alignment.topCenter,
    'topRight': Alignment.topRight,
    'centerLeft': Alignment.centerLeft,
    'center': Alignment.center,
    'centerRight': Alignment.centerRight,
    'bottomLeft': Alignment.bottomLeft,
    'bottomCenter': Alignment.bottomCenter,
    'bottomRight': Alignment.bottomRight,
  };

  /// An alignment at [key].
  static Alignment? alignment(LuaWidgetArgs args, List<Object> key) {
    final value = args[key];
    if (value is String) return _alignments[value];
    if (value is! Map) return null;
    return Alignment(
      args.v<double>([...key, 'x']) ?? 0,
      args.v<double>([...key, 'y']) ?? 0,
    );
  }

  /// A border radius at [key].
  static BorderRadius? borderRadius(LuaWidgetArgs args, List<Object> key) {
    final value = args[key];
    if (value is num) return BorderRadius.circular(value.toDouble());
    if (value is! Map) return null;
    Radius corner(String name) =>
        Radius.circular(args.v<double>([...key, name]) ?? 0);
    return BorderRadius.only(
      topLeft: corner('topLeft'),
      topRight: corner('topRight'),
      bottomLeft: corner('bottomLeft'),
      bottomRight: corner('bottomRight'),
    );
  }

  /// A uniform border at [key]: `{color = , width = }`.
  static Border? border(LuaWidgetArgs args, List<Object> key) {
    if (!args.isMap(key)) return null;
    return Border.all(
      color: color(args, [...key, 'color']) ?? const Color(0xFF000000),
      width: args.v<double>([...key, 'width']) ?? 1,
    );
  }

  /// A linear gradient at [key]:
  /// `{colors = {...}, stops = {...}, begin = "topLeft", ["end"] = "bottomRight"}`.
  static Gradient? gradient(LuaWidgetArgs args, List<Object> key) {
    final count = args.length([...key, 'colors']);
    if (count < 2) return null;
    final colors = [
      for (var i = 0; i < count; i++)
        color(args, [...key, 'colors', i]) ?? const Color(0x00000000),
    ];
    final stopCount = args.length([...key, 'stops']);
    return LinearGradient(
      colors: colors,
      stops: stopCount == count
          ? [
              for (var i = 0; i < count; i++)
                args.v<double>([...key, 'stops', i]) ?? 0,
            ]
          : null,
      begin: alignment(args, [...key, 'begin']) ?? Alignment.centerLeft,
      end: alignment(args, [...key, 'end']) ?? Alignment.centerRight,
    );
  }

  /// Box shadows at [key]: a list of `BoxShadow {color = , blurRadius = ,
  /// spreadRadius = , offset = Offset(dx, dy)}`.
  static List<BoxShadow>? boxShadows(LuaWidgetArgs args, List<Object> key) {
    final count = args.length(key);
    if (count == 0) return null;
    return [
      for (var i = 0; i < count; i++)
        BoxShadow(
          color: color(args, [...key, i, 'color']) ?? const Color(0x33000000),
          blurRadius: args.v<double>([...key, i, 'blurRadius']) ?? 0,
          spreadRadius: args.v<double>([...key, i, 'spreadRadius']) ?? 0,
          offset: Offset(
            args.v<double>([...key, i, 'offset', 'dx']) ?? 0,
            args.v<double>([...key, i, 'offset', 'dy']) ?? 0,
          ),
        ),
    ];
  }

  /// A box decoration at [key]: `{color = , borderRadius = , border = ,
  /// gradient = , boxShadow = , shape = "circle"}`.
  static BoxDecoration? boxDecoration(LuaWidgetArgs args, List<Object> key) {
    if (!args.isMap(key)) return null;
    final circle = args.v<String>([...key, 'shape']) == 'circle';
    return BoxDecoration(
      color: color(args, [...key, 'color']),
      borderRadius: circle
          ? null
          : borderRadius(args, [...key, 'borderRadius']),
      border: border(args, [...key, 'border']),
      gradient: gradient(args, [...key, 'gradient']),
      boxShadow: boxShadows(args, [...key, 'boxShadow']),
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
    );
  }

  static const Map<String, FontWeight> _weights = {
    'normal': FontWeight.normal,
    'bold': FontWeight.bold,
    'w100': FontWeight.w100,
    'w200': FontWeight.w200,
    'w300': FontWeight.w300,
    'w400': FontWeight.w400,
    'w500': FontWeight.w500,
    'w600': FontWeight.w600,
    'w700': FontWeight.w700,
    'w800': FontWeight.w800,
    'w900': FontWeight.w900,
  };

  /// A font weight at [key].
  static FontWeight? fontWeight(LuaWidgetArgs args, List<Object> key) {
    final value = args[key];
    if (value is String) return _weights[value];
    if (value is int && value >= 100 && value <= 900 && value % 100 == 0) {
      return FontWeight.values[value ~/ 100 - 1];
    }
    return null;
  }

  static const Map<String, TextDecoration> _decorations = {
    'none': TextDecoration.none,
    'underline': TextDecoration.underline,
    'overline': TextDecoration.overline,
    'lineThrough': TextDecoration.lineThrough,
  };

  /// A text style at [key]: `{color = , fontSize = , fontWeight = ,
  /// fontStyle = "italic", fontFamily = , letterSpacing = , height = ,
  /// decoration = "underline", backgroundColor = }`.
  static TextStyle? textStyle(LuaWidgetArgs args, List<Object> key) {
    if (!args.isMap(key)) return null;
    return TextStyle(
      color: color(args, [...key, 'color']),
      backgroundColor: color(args, [...key, 'backgroundColor']),
      fontSize: args.v<double>([...key, 'fontSize']),
      fontWeight: fontWeight(args, [...key, 'fontWeight']),
      fontStyle: enumValue(FontStyle.values, args, [...key, 'fontStyle']),
      fontFamily: args.v<String>([...key, 'fontFamily']),
      letterSpacing: args.v<double>([...key, 'letterSpacing']),
      height: args.v<double>([...key, 'height']),
      decoration: _decorations[args.v<String>([...key, 'decoration'])],
    );
  }

  /// The value of [values] named by the string at [key].
  static T? enumValue<T extends Enum>(
    List<T> values,
    LuaWidgetArgs args,
    List<Object> key,
  ) {
    final name = args.v<String>(key);
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  /// A duration in milliseconds at [key].
  static Duration? duration(LuaWidgetArgs args, List<Object> key) {
    final value = args[key];
    return value is num ? Duration(microseconds: (value * 1000).round()) : null;
  }

  /// An image at [key]: an `http(s)` URL, `{network = url}` or
  /// `{asset = name}`.
  static ImageProvider? image(LuaWidgetArgs args, List<Object> key) {
    final value = args[key];
    if (value is String) {
      return value.startsWith('http://') || value.startsWith('https://')
          ? NetworkImage(value)
          : AssetImage(value);
    }
    final network = args.v<String>([...key, 'network']);
    if (network != null) return NetworkImage(network);
    final asset = args.v<String>([...key, 'asset']);
    if (asset != null) return AssetImage(asset);
    return null;
  }
}
