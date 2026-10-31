// lib/ui_view.dart
//
// 渲染 UI 契约。这是整个 UI 链路里**唯一**接触 Flutter 渲染 API 的文件，
// 与 display_list_renderer.dart 在画布链路里的地位相同。
//
// ```
// Lua 源码
//   ↓ worker isolate 执行
// UI 契约 JSON
//   ↓ UiTree.parse            （lib/ui_tree.dart，纯 Dart）
//   ↓ buildUiLibrary          （lib/ui_rfw_ast.dart，纯 Dart，只 import rfw/formats）
// RemoteWidgetLibrary
//   ↓ Runtime.update
// RemoteWidget  →  真正的 Flutter widget
//        ↑ onEvent
//        └→ 事件名送回 Lua → 重新渲染 → 换一棵树
// ```
//
// 状态归 Lua，宿主只做两件事：把树喂给 rfw、把事件名送回去。
// 所以这里没有 rfw 的 state（WidgetDeclaration.initialState 传的是 null），
// 也没有 DynamicContent——所有值都是随树一起下发的字面量。
//
// ## 为什么要注册 studio.* 自定义组件
//
// rfw 内置的库没有 Switch（Slider 有，但语义是"只读展示"），
// 而"一个可点击的开关"正是最典型的业务交互。
// 注册自定义本地库是 rfw 官方支持的扩展点，
// 也验证了「Lua 下发的东西不限于 Flutter 自带控件」这条路径。

import 'dart:convert';

import 'package:flutter/material.dart';

// rfw 自己也有一个 `Switch`（blob 里的 switch 表达式节点），
// 与 Material 的开关同名。不 hide 的话下面写 Switch 会二义。
import 'package:rfw/rfw.dart' hide Switch;

import 'ui_rfw_ast.dart';
import 'ui_tree.dart';

/// 渲染一棵树。
///
/// 树变了就重建 rfw 库。指纹没变则整个跳过——与画布链路同一个策略。
class LuaUiView extends StatefulWidget {
  const LuaUiView({
    super.key,
    required this.tree,
    required this.onEvent,
    this.onWarning,
  });

  final UiTree? tree;

  /// rfw 事件回调。宿主在这里把事件送回 Lua。
  final void Function(String eventName, Map<String, dynamic> args) onEvent;

  /// 非致命问题（例如 widget 名不在 rfw 清单里）。
  final void Function(String message)? onWarning;

  @override
  State<LuaUiView> createState() => _LuaUiViewState();
}

class _LuaUiViewState extends State<LuaUiView> {
  final Runtime _runtime = Runtime();
  final DynamicContent _data = DynamicContent();

  /// 已经喂进 runtime 的那棵树。
  ///
  /// 与 [UiTree.fingerprint] 配合：**指纹相同直接跳过（O(1)）**，
  /// 指纹不同再用结构比较裁决（精确，但 O(n)）。
  ///
  /// 以前只看指纹，而指纹是哈希——一旦碰撞就会静默漏更新。
  /// 现在哈希只当快路径，最终判断由 [uiTreeEquals] 做。
  UiTree? _applied;

  /// rfw 的 RemoteWidget 要求 data 非空，我们没有动态数据。
  bool _dataSeeded = false;

  /// 待上报的诊断信息。
  ///
  /// **不能直接调 widget.onWarning。**
  ///
  /// 校验发生在 initState 与 build 里，而 onWarning 的实现方会 setState。
  /// 在 build 期间 setState 会抛 "setState() or markNeedsBuild() called
  /// during build"，并且报错位置指向正在构建的子树（rfw 的 DefaultTextStyle），
  /// 而不是真正的罪魁祸首，极难定位。
  ///
  /// 所以一律缓到这里，帧后再发出去——那时框架已经不在 build 阶段了。
  final List<String> _pendingDiagnostics = <String>[];
  bool _diagnosticsScheduled = false;

  /// 上报一条诊断。同一帧内重复的只报一次。
  void _report(String message) {
    if (_pendingDiagnostics.contains(message)) return;
    _pendingDiagnostics.add(message);
    if (_diagnosticsScheduled) return;
    _diagnosticsScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _diagnosticsScheduled = false;
      final messages = List<String>.from(_pendingDiagnostics);
      _pendingDiagnostics.clear();
      for (final m in messages) {
        widget.onWarning?.call(m);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // 三个本地库：Flutter 自带的 widgets / material，加上宿主的自定义组件。
    _runtime.update(
      const LibraryName(<String>['core', 'widgets']),
      createCoreWidgets(),
    );
    _runtime.update(
      const LibraryName(<String>['core', 'material']),
      createMaterialWidgets(),
    );
    _runtime.update(kStudioLibrary, createStudioWidgets());

    _verifyCatalog();
  }

  /// 校验内置 widget 清单没和 rfw 的实际定义脱节。
  ///
  /// [kBuiltinWidgets] 是手抄的常量，rfw 升级时可能变。
  /// 与其等到画面上出现 ErrorWidget，不如启动时就说清楚。
  void _verifyCatalog() {
    final actual = <String>{
      ...createCoreWidgets().widgets.keys,
      ...createMaterialWidgets().widgets.keys,
      ...createStudioWidgets().widgets.keys,
    };
    final missing = actual.difference(kBuiltinWidgets);
    final stale = kBuiltinWidgets.difference(actual);
    if (missing.isEmpty && stale.isEmpty) return;

    final parts = <String>[
      if (missing.isNotEmpty) '清单缺少: ${missing.join(', ')}',
      if (stale.isNotEmpty) '清单多出: ${stale.join(', ')}',
    ];
    _report(
      'widget 清单与 rfw 实际定义不一致（${parts.join('；')}）。'
      '请更新 lib/ui_rfw_ast.dart 里的 kBuiltinWidgets。',
    );
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }

  void _applyTree(UiTree tree) {
    final prev = _applied;

    // 1) 快路径：指纹相同。对绝大多数编辑场景（内容没变）这是 O(1) 的。
    if (prev != null &&
        tree.fingerprint != null &&
        prev.fingerprint == tree.fingerprint) {
      return;
    }

    // 2) 权威判断：结构比较。指纹不同只说明"可能变了"，
    //    哈希碰撞时会走到这里被拦下，不会白白重建。
    if (prev != null && uiTreeEquals(prev, tree)) {
      _applied = tree;
      return;
    }

    _applied = tree;

    for (final problem in tree.validate()) {
      _report(problem);
    }

    final unknown = collectWidgetNames(tree)
        .where((name) => !kBuiltinWidgets.contains(name))
        .toList();
    if (unknown.isNotEmpty) {
      _report(
        '树里用了 rfw 不认识的 widget: ${unknown.join(', ')}。'
        '画面上会显示 ErrorWidget。',
      );
    }

    _runtime.update(kRemoteLibrary, buildUiLibrary(tree));
  }

  @override
  Widget build(BuildContext context) {
    final tree = widget.tree;
    if (tree == null) {
      return const SizedBox.shrink();
    }

    if (!_dataSeeded) {
      _data.updateAll(const <String, Object?>{});
      _dataSeeded = true;
    }
    _applyTree(tree);

    return RemoteWidget(
      runtime: _runtime,
      data: _data,
      widget: FullyQualifiedWidgetName(
        kRemoteLibrary,
        tree.widget.isEmpty ? kRootWidget : tree.widget,
      ),
      onEvent: (name, arguments) {
        widget.onEvent(name, Map<String, dynamic>.from(arguments));
      },
    );
  }
}

/// 宿主自定义的本地 widget 库。
///
/// key 是**全名**（含库前缀）——rfw 的 LocalWidgetLibrary 就是按
/// ConstructorCall 的名字字符串直接查表，不做前缀拆分。
/// 所以树里写 'studio.Toggle'，这里就注册 'studio.Toggle'。
LocalWidgetLibrary createStudioWidgets() {
  return LocalWidgetLibrary(<String, LocalWidgetBuilder>{
    /// 把任意标量渲染成文字。
    ///
    /// rfw 自带的 `Text` 只吃 String：`source.v<String>(['text'])` 拿到 int
    /// 会返回 null，于是**静默渲染成空**。而组件的本地状态天然是数字
    /// （计数器、选中下标），所以缺这一个控件，状态就显示不出来。
    ///
    /// 这是真机点出来的：状态引用已经生效（rfw 确实解析了），
    /// 但界面上是个空字符串。
    'studio.ValueText': (BuildContext context, DataSource source) {
      // rfw 的 DataSource.v<T> 是按类型取的，没有"取任意类型"的口子，
      // 所以四种标量挨个试一遍。
      Object? value = source.v<int>(['text']);
      value ??= source.v<double>(['text']);
      value ??= source.v<bool>(['text']);
      value ??= source.v<String>(['text']);

      return Text(
        value == null ? '' : '$value',
        style: source.v<TextStyle>(['style']),
        textDirection: source.v<TextDirection>(['textDirection']),
        textAlign: source.v<TextAlign>(['textAlign']),
        maxLines: source.v<int>(['maxLines']),
        softWrap: source.v<bool>(['softWrap']),
      );
    },

    'studio.Toggle': (BuildContext context, DataSource source) {
      final label = source.v<String>(['label']);
      final onChanged = source.voidHandler(['onChange']);

      // rfw 没有 Switch，只能宿主自己提供。
      // value 为 null 表示"未指定"，此时开关不可交互——
      // 免得画出一个能点但点了没反应的控件。
      final value = source.v<bool>(['value']);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (label != null) ...<Widget>[
            Flexible(child: Text(label)),
            const SizedBox(width: 10),
          ],
          Switch(
            value: value ?? false,
            onChanged: value == null || onChanged == null
                ? null
                : (bool v) => onChanged(),
          ),
        ],
      );
    },

    'studio.Slider': (BuildContext context, DataSource source) {
      final min = source.v<double>(['min']) ?? 0.0;
      final max = source.v<double>(['max']) ?? 1.0;
      final value = source.v<double>(['value']) ?? min;
      final divisions = source.v<int>(['divisions']);

      // Slider 要求 max > min 且 value 在区间内，否则直接抛断言。
      // 下发的数据不合法时夹住，而不是让整棵树崩掉。
      final lo = min < max ? min : max;
      final hi = min < max ? max : min;
      final clamped = value.clamp(lo, hi).toDouble();

      // 用块体而不是表达式体：表达式体会把 trigger() 的 void 返回值
      // 当成 lambda 的返回类型，推断出一堆奇怪的函数类型。
      final onChanged = source.handler<void Function(double)>(
        ['onChange'],
        (HandlerTrigger trigger) => (double v) {
          trigger(<String, dynamic>{'value': v});
        },
      );

      return Slider(
        value: clamped,
        min: lo,
        max: hi,
        divisions: divisions,
        label: clamped.toStringAsFixed(2),
        onChanged: onChanged,
      );
    },

    'studio.Kpi': (BuildContext context, DataSource source) {
      final label = source.v<String>(['label']) ?? '';
      final value = source.v<String>(['value']) ?? '';
      final accent = source.v<int>(['accent']);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF14171F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF262B38)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (accent != null) ...<Widget>[
              Container(
                width: 4,
                height: 34,
                decoration: BoxDecoration(
                  color: Color(accent),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7488)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFE6E9EF)),
                ),
              ],
            ),
          ],
        ),
      );
    },
  });
}

/// 把 rfw 给的事件参数转成可读文本，日志面板用。
String describeUiEvent(String name, Map<String, dynamic> args) {
  if (args.isEmpty) return name;
  final parts = args.entries
      .map((e) => '${e.key}=${jsonEncode(e.value)}')
      .join(' ');
  return '$name($parts)';
}
