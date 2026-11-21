import 'package:flutter/widgets.dart';

import 'args.dart';

/// Keeps a [TextEditingController] for a Lua text field across rebuilds.
///
/// Flutter text fields own their text through a controller, which Lua cannot
/// hold. A library builder wraps its field in this widget: [text] is the
/// value Lua passes (an extension argument named `text`), applied to the
/// controller only when it differs from what the field shows, so typing is
/// not interrupted and Lua can still clear or replace the text.
///
/// ```dart
/// 'TextField': (context, args) => LuaControlledText(
///   text: args.v<String>(['text']),
///   builder: (context, controller) => TextField(controller: controller),
/// ),
/// ```
class LuaControlledText extends StatefulWidget {
  const LuaControlledText({
    super.key,
    required this.text,
    required this.builder,
  });

  /// Builds a text field with [LuaControlledText.text] from [args]:
  /// `args.v<String>(['text'])`.
  LuaControlledText.fromArgs({
    Key? key,
    required LuaWidgetArgs args,
    required Widget Function(BuildContext, TextEditingController) builder,
  }) : this(key: key, text: args.v<String>(['text']), builder: builder);

  /// The text Lua wants the field to show, or `null` to leave it alone.
  final String? text;

  /// Builds the field around the kept controller.
  final Widget Function(BuildContext context, TextEditingController controller)
  builder;

  @override
  State<LuaControlledText> createState() => _LuaControlledTextState();
}

class _LuaControlledTextState extends State<LuaControlledText> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void didUpdateWidget(LuaControlledText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.text;
    if (text != null && text != _controller.text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}
