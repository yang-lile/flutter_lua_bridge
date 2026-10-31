// lib/ui_rfw_ast.dart
//
// UiTree -> rfw 的 RemoteWidgetLibrary。
//
// **只 import package:rfw/formats.dart**，不用 package:rfw/rfw.dart。
//
// 这不是随手选的：rfw 把「格式层」和「Flutter 渲染层」拆成了两个库，
// 前者明确声明不依赖 dart:ui（rfw 自己的注释说这是给服务端生成
// library blob 用的）。于是这一步转换可以在纯 Dart VM 里跑，
// `tools/verify_ui_ast.dart` 因此能做到「真实 Lua 产出 + 真实 rfw 编解码」
// 的端到端校验，不需要 Flutter 引擎。
//
// 这也正是 rfw 官方的用法：服务端就是纯 Dart 跑的。

import 'package:rfw/formats.dart';

import 'ui_tree.dart';

/// 宿主本地库的名字。rfw 内置的两个库之外的组件都放这里。
const LibraryName kStudioLibrary = LibraryName(<String>['studio']);

/// 远端库名。真实场景下这是从服务端拿到的库名。
const LibraryName kRemoteLibrary = LibraryName(<String>['lua']);

// 入口 widget 声明的名字。
const String kRootWidget = 'root';

/// 把一棵树编成一个 rfw 库。
///
/// 产出的库 import 了三个本地库：Flutter 自带的 widgets / material，
/// 以及宿主的自定义组件（studio.*）。
///
/// 名字解析在 rfw 侧完成——ConstructorCall 先在自己的库里找，
/// 找不到再按 import 列表深度优先搜。所以树里写 `"Column"` 就行，
/// 不需要写全名。
RemoteWidgetLibrary buildUiLibrary(UiTree tree) {
  // 声明顺序：**组件先、root 后**。
  //
  // rfw 解析时先收集所有声明再解析引用，所以顺序其实不影响正确性；
  // 固定下来是为了让产出的 blob 字节稳定，便于 diff 与缓存。
  final declarations = <WidgetDeclaration>[
    for (final d in tree.declarations) _toDeclaration(d),
    WidgetDeclaration(
      tree.widget.isEmpty ? kRootWidget : tree.widget,
      null, // root 自己不用 rfw 的 state：业务状态归 Lua
      _toConstructor(tree.root),
    ),
  ];

  return RemoteWidgetLibrary(
    <Import>[
      const Import(LibraryName(<String>['core', 'widgets'])),
      const Import(LibraryName(<String>['core', 'material'])),
      const Import(kStudioLibrary),
    ],
    declarations,
  );
}

/// 节点 -> ConstructorCall。
///
/// 契约里 [UiNode] 的参数与 rfw 的命名参数是一一对应的，
/// 所以这里只做**值的**转换，不做名字映射。
ConstructorCall _toConstructor(UiNode node) {
  return ConstructorCall(node.widget, _convertArgs(node.args));
}

/// 一条 widget 声明 -> rfw 的 [WidgetDeclaration]。
///
/// [UiDeclaration.state] 非空时，rfw 会在客户端为**这个声明的每个实例**
/// 持有一份状态；交互时 `set state.x` 由 rfw 自己改，
/// 不产生事件、不回 Lua。
WidgetDeclaration _toDeclaration(UiDeclaration decl) {
  return WidgetDeclaration(
    decl.name,
    decl.state == null
        ? null
        : DynamicMap.from(
            decl.state!.map((k, v) => MapEntry(k, _convertValue(v)))),
    _toConstructor(decl.root),
  );
}

/// 参数表的递归转换。
DynamicMap _convertArgs(Map<String, dynamic> args) {
  final out = <String, dynamic>{};
  args.forEach((k, v) {
    out[k] = _convertValue(v);
  });
  return out;
}

/// 单个值的转换。分支就是契约里允许的全部形态。
///
/// 返回类型是 `Object?`：rfw 允许 null 作为参数值（表示"用默认值"）。
Object? _convertValue(Object? v) {
  if (v is UiNode) return _toConstructor(v);
  if (v is UiEvent) {
    return EventHandler(
      v.name,
      v.arg.map((k, val) => MapEntry(k, _convertValue(val))),
    );
  }

  if (v is UiStateRef) {
    // 状态引用：值由 rfw 在客户端填。这是原生状态能生效的前提。
    return StateReference(v.parts);
  }

  if (v is UiSetState) {
    // 本地状态写入：rfw 接到这种 handler 时**自己改状态**，
    // 既不上报事件也不通知宿主 —— 这就是交互不回 Lua 的机制。
    return SetStateHandler(
      StateReference(v.parts),
      _convertValue(v.value) as Object,
    );
  }
  if (v is List) {
    return DynamicList.from(v.map(_convertValue));
  }
  if (v is Map) {
    return DynamicMap.from(
      v.map((k, val) => MapEntry(k.toString(), _convertValue(val))),
    );
  }
  // num / bool / String 是 rfw 的基本值类型，原样传过去。
  if (v == null || v is num || v is bool || v is String) return v;

  throw FormatException('无法转成 rfw 参数的值类型：${v.runtimeType}');
}

/// 树里用到的全部 widget 名（去重、有序）。
///
/// 校验工具用它对照 rfw 内置的 widget 清单，
/// 提前发现「Lua 拼错了一个 widget 名」——否则只会在画面上显示 ErrorWidget。
List<String> collectWidgetNames(UiTree tree) {
  final seen = <String>{};

  // **本树自己声明的组件名要排除掉。**
  //
  // rfw 解析引用时先看本库的 widget 声明，再按 import 深度优先找，
  // 所以组件名根本不需要出现在本地库里。之前把它们一律拿去和
  // kBuiltinWidgets 比对，于是每个组件都报一句
  // 「树里用了 rfw 不认识的 widget: Item。画面上会显示 ErrorWidget。」
  //
  // 组件越多噪音越大，最后没人看这条警告——而真正的拼写错误
  // 就混在里面了。这是真机上点出来的。
  final declared = <String>{for (final d in tree.declarations) d.name};

  void collect(UiNode root) {
    for (final n in root.walk()) {
      if (!declared.contains(n.widget)) seen.add(n.widget);
    }
  }

  for (final d in tree.declarations) {
    collect(d.root);
  }
  collect(tree.root);
  final list = seen.toList()..sort();
  return list;
}

/// rfw 内置的本地库提供的 widget 名。
///
/// 与 rfw 的 `_coreWidgetsDefinitions` / `_materialWidgetsDefinitions`
/// 对应。注意 rfw 没提供 Switch，交互开关走 studio.Toggle。
const Set<String> kBuiltinWidgets = <String>{
  // 由 rfw 1.1.4 的 core_widgets / material_widgets 定义逐字抄来，
  // 加上本项目的 studio.* 三个自定义组件。
  //
  // 手抄的东西一定会过期，所以 `_LuaUiViewState._verifyCatalog` 启动时会拿它
  // 和 `createCoreWidgets().widgets.keys` 对账，不一致就在界面上提示。
  // 第一次真机验证时就靠它抓到了差异（当时少了 Image / Spacer，多了 Transform）。
  'AboutListTile', 'Align', 'AnimationDefaults', 'AppBar', 'AspectRatio',
  'ButtonBar', 'Card', 'Center', 'CircularProgressIndicator', 'ClipRRect',
  'ColoredBox', 'Column', 'Container', 'DefaultTextStyle', 'Directionality',
  'Divider', 'Drawer', 'DrawerHeader', 'DropdownButton', 'ElevatedButton',
  'Expanded', 'FittedBox', 'Flexible', 'FloatingActionButton', 'FractionallySizedBox',
  'GestureDetector', 'GridView', 'Icon', 'IconTheme', 'Image',
  'InkResponse', 'InkWell', 'IntrinsicHeight', 'IntrinsicWidth', 'LinearProgressIndicator',
  'ListBody', 'ListTile', 'ListView', 'Material', 'Opacity',
  'OutlinedButton', 'OverflowBar', 'Padding', 'Placeholder', 'Positioned',
  'Rotation', 'Row', 'SafeArea', 'Scaffold', 'Scale',
  'SingleChildScrollView', 'SizedBox', 'SizedBoxExpand', 'SizedBoxShrink', 'Slider',
  'Spacer', 'Stack', 'Text', 'TextButton', 'VerticalDivider',
  'Wrap', 'studio.Kpi', 'studio.Slider', 'studio.Toggle',
};
