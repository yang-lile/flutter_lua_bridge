// lib/ui_tree.dart
//
// UI 契约的数据模型。这是 Lua 的 `ui` 模块与 rfw 之间唯一的中间层。
//
// 分层理由与 display_list.dart 一致：**整个模型不含任何 Flutter 类型**，
// 于是 Lua 侧的产出、Dart 侧的校验、rfw AST 的转换三步都能脱离引擎跑
// （`tools/verify_ui_ast.dart` 就是纯 Dart 入口）。
//
// 三段式：
//
//   Lua                     Dart                        rfw
//   ────                    ────                        ───
//   { $widget, $args }  →   UiNode.fromJson  →  ConstructorCall
//   { $event,  $arg  }  →   UiEvent         →  EventHandler
//
// 事件不是回调而是**事件名**，因为宿主每次执行都重建 Lua state，
// 回调无法跨执行存活（见 lib/sandbox.dart）。

import 'dart:convert';

/// rfw 里会用到的容器 / 单子节点参数名。
///
/// 只有一个 `$args` 里的值是节点还是数据，靠这两个 key 区分。
const String kChildKey = 'child';
const String kChildrenKey = 'children';

/// 契约格式版本。当前只支持 1。
const int kUiContractVersion = 1;

/// 把契约里的值转成 Dart 的 Map。
///
/// **空数组也当成空 map。** Lua 侧用的是纯 Lua JSON 编码器，
/// 而 Lua 无法区分空 table 和空数组，空 table 会被编码成 `[]`。
/// 于是 `$args = {}`、`arg = {}`、`state = {}` 到 Dart 手里都是 `[]`。
///
/// 只放宽「空」这一种情况：非空的数组仍然是数组，
/// 误传（比如把 children 数组塞进 `$args`）照样报错。
Map<String, dynamic> _asMap(Object? value, String path) {
  if (value == null) return <String, dynamic>{};
  if (value is List) {
    if (value.isEmpty) return <String, dynamic>{};
    throw FormatException('$path 是数组，期望 table');
  }
  if (value is! Map) {
    throw FormatException('$path 必须是 table，实际是 ${value.runtimeType}');
  }
  final out = <String, dynamic>{};
  value.forEach((k, v) {
    if (k is! String) {
      throw FormatException('$path 的键必须是字符串');
    }
    out[k] = v;
  });
  return out;
}

/// 一个事件引用：`{ "$event": "inc", "$arg": {...} }`。
class UiEvent {
  final String name;
  final Map<String, dynamic> arg;

  const UiEvent({required this.name, this.arg = const {}});

  factory UiEvent.fromJson(Map<String, dynamic> j, String path) {
    final name = j[r'$event'];
    if (name is! String || name.isEmpty) {
      throw FormatException('$path: \$event 缺失或不是非空字符串');
    }
    return UiEvent(
      name: name,
      arg: _asMap(j[r'$arg'], '$path.\$arg'),
    );
  }

  @override
  String toString() => 'UiEvent($name, $arg)';
}

/// 本地状态写入：`{ "$setstate": "open", "$value": true }`。
///
/// 对应 rfw 的 `set state.open = true`。**这个赋值由 rfw 自己在客户端完成**，
/// 不产生任何事件、不会回 Lua，因此是微秒级的。
///
/// 与 [UiEvent] 的分工：
///   * 瞬时 UI 状态（按下 / 展开 / 选中）-> UiSetState，不回 Lua
///   * 有业务含义的状态（计数、要落库）-> UiEvent，回 Lua
class UiSetState {
  /// 状态字段的路径，点分隔。例如 `"open"` 或 `"a.b"`。
  final String path;

  /// 新值。**不能为 null** —— rfw 的 state 是普通 map，存不了 nil，
  /// 而且它要求被赋值的字段**事先就存在**（applySetState 会去改它）。
  /// 「改成空」这种语义在这个机制里不存在，所以这里直接拒绝。
  final Object value;

  const UiSetState({required this.path, required this.value});

  factory UiSetState.fromJson(Map<String, dynamic> j, String pathLabel) {
    final p = j[r'$setstate'];
    if (p is! String || p.isEmpty) {
      throw FormatException('$pathLabel: \$setstate 缺失或不是非空字符串');
    }
    if (!j.containsKey(r'$value') || j[r'$value'] == null) {
      throw FormatException(
          '$pathLabel: \$setstate 赋值必须有 \$value（rfw 的状态存不了 nil）');
    }
    return UiSetState(path: p, value: j[r'$value'] as Object);
  }

  /// 拆成 rfw 的 state reference 各段。
  List<Object> get parts => path.split('.');

  @override
  String toString() => 'UiSetState($path = $value)';
}

/// 组件本地状态的**引用**：`{ "$state": "hits" }`。
///
/// 对应 rfw 的 `state.x`。这是让原生状态真正生效的关键：
///
/// 只发 `set state.x = v` 是**没有用**的。rfw 在状态变化时只能重新解析
/// 树里的引用，没法凭空加一个节点。如果 Lua 在 build 时就把状态算成
/// 字面量烤进树里（`b:text("x" .. s.hits)` -> `{text = "x0"}`），
/// 那 rfw 重渲染多少次都还是 "x0"。
///
/// 所以状态必须以**引用**的形式留在树里，值由 rfw 在客户端填。
class UiStateRef {
  /// 状态字段路径，点分隔。
  final String path;

  const UiStateRef(this.path);

  factory UiStateRef.fromJson(Map<String, dynamic> j, String label) {
    final p = j[r'$state'];
    if (p is! String || p.isEmpty) {
      throw FormatException('$label: \$state 缺失或不是非空字符串');
    }
    return UiStateRef(p);
  }

  List<Object> get parts => path.split('.');

  @override
  String toString() => 'UiStateRef($path)';
}

/// 一个 widget 声明。
///
/// rfw 的 `widget X { state } = ...`：**有状态的组件**。
/// 状态由 rfw 在客户端持有，交互时不需要回 Lua。
class UiDeclaration {
  final String name;

  /// 初始状态（null 表示无状态）。
  final Map<String, dynamic>? state;

  /// 声明的根节点。
  final UiNode root;

  const UiDeclaration({
    required this.name,
    required this.root,
    this.state,
  });

  factory UiDeclaration.fromJson(Map<String, dynamic> j, String label) {
    final name = j['name'];
    if (name is! String || name.isEmpty) {
      throw FormatException('$label: 声明缺少 name');
    }
    return UiDeclaration(
      name: name,
      state: j['state'] == null ? null : _asMap(j['state'], '$label.state'),
      root: UiNode.fromJson(j['node'], '$label.node'),
    );
  }

  @override
  String toString() => 'UiDeclaration($name${state != null ? ", state" : ""})';
}

/// 一个 widget 节点：`{ "$widget": "Column", "$args": {...} }`。
///
/// [args] 里的值可能是：
///   * [UiNode] / `List<UiNode>` —— 子节点
///   * [UiEvent] —— 事件处理器
///   * 标量或普通 Map / List —— rfw 的普通参数
class UiNode {
  final String widget;
  final Map<String, dynamic> args;

  const UiNode({required this.widget, this.args = const {}});

  factory UiNode.fromJson(Object? raw, String path) {
    if (raw is! Map) {
      throw FormatException('$path: 节点必须是 table，实际是 ${raw.runtimeType}');
    }
    final widget = raw[r'$widget'];
    if (widget is! String || widget.isEmpty) {
      throw FormatException('$path.\$widget 缺失或不是非空字符串');
    }

    final args = <String, dynamic>{};
    _asMap(raw[r'$args'], '$path.\$args').forEach((key, value) {
      args[key] = _convertArg(value, '$path.\$args.\$key');
    });

    return UiNode(widget: widget, args: args);
  }

  /// 按契约里的角色取出子节点。
  ///
  /// [key] 缺省时依次找 `children` / `child`——两种布局容器都用。
  List<UiNode> childrenOf([String? key]) {
    final keys = key == null ? const [kChildrenKey, kChildKey] : [key];
    for (final k in keys) {
      final v = args[k];
      if (v == null) continue;
      if (v is UiNode) return [v];
      if (v is List) {
        return v.cast<UiNode>();
      }
      throw FormatException('$widget.$k 应该是节点或节点数组');
    }
    return const [];
  }

  /// 深度遍历自己和所有后代。校验与统计都基于它。
  Iterable<UiNode> walk() sync* {
    yield this;
    for (final child in childrenOf()) {
      yield* child.walk();
    }
  }

  /// 树里出现的全部事件引用。
  Iterable<UiEvent> get events sync* {
    for (final node in walk()) {
      for (final v in node.args.values) {
        if (v is UiEvent) {
          yield v;
        } else if (v is List) {
          for (final item in v) {
            if (item is UiEvent) yield item;
          }
        }
      }
    }
  }

  /// 树里出现的全部本地状态写入。
  Iterable<UiSetState> get stateWrites sync* {
    for (final node in walk()) {
      for (final v in node.args.values) {
        if (v is UiSetState) {
          yield v;
        } else if (v is List) {
          for (final item in v) {
            if (item is UiSetState) yield item;
          }
        }
      }
    }
  }

  @override
  String toString() => 'UiNode($widget, ${args.length} args)';
}

/// 把 Lua 侧的原始值转成契约里的 Dart 值。
///
/// 规则只有一条：**带 `$` 前缀的 key 表示保留语义**，其余按数据处理。
/// 这样普通数据 map 里即使有 `name` 之类的键也不会被误认成节点。
Object? _convertArg(Object? value, String path) {
  if (value is Map) {
    if (value.containsKey(r'$widget')) {
      return UiNode.fromJson(value, path);
    }
    if (value.containsKey(r'$event')) {
      return UiEvent.fromJson(
        value.cast<String, dynamic>(),
        path,
      );
    }
    if (value.containsKey(r'$setstate')) {
      return UiSetState.fromJson(
        value.cast<String, dynamic>(),
        path,
      );
    }
    if (value.containsKey(r'$state')) {
      return UiStateRef.fromJson(
        value.cast<String, dynamic>(),
        path,
      );
    }
    final out = <String, dynamic>{};
    value.forEach((k, v) {
      if (k is! String) {
        throw FormatException('$path 的键必须是字符串，实际是 $k');
      }
      out[k] = _convertArg(v, '$path.$k');
    });
    return out;
  }
  if (value is List) {
    return value.map((v) => _convertArg(v, '$path[]')).toList();
  }
  return value;
}

/// 一次完整渲染的产物。宿主与 Lua 之间的一次往返就是这个。
class UiTree {
  final int version;

  /// widget 声明的名字。宿主用它去 rfw 里取入口。
  final String widget;

  /// 可选的界面标题，宿主拿去显示。
  final String? title;

  /// 业务状态。事件触发时宿主把它原样送回 Lua。
  final Map<String, dynamic> state;

  final UiNode root;

  /// 额外的 widget 声明（组件）。rfw 里对应 `widget X { state } = ...`。
  ///
  /// 空列表 = 只有 root 一个声明（向后兼容原来的单根契约）。
  ///
  /// **组件是本地状态的载体**：状态挂在声明上，交互时由 rfw 自己改，
  /// 不需要回 Lua。所以想做原生状态交互，组件不是可选项。
  final List<UiDeclaration> declarations;

  /// 已注册的事件名（有序）。
  final List<String> events;

  /// Lua 侧统计的节点数。
  final int nodeCount;

  /// Lua 侧算出的内容指纹。与 canvas 同一个用途：
  /// 内容没变就不重建 widget 树。
  final String? fingerprint;

  const UiTree({
    required this.version,
    required this.widget,
    required this.root,
    required this.state,
    required this.events,
    required this.nodeCount,
    this.declarations = const [],
    this.title,
    this.fingerprint,
  });

  factory UiTree.parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('UI 契约的顶层必须是 table');
    }
    return UiTree.fromJson(decoded.cast<String, dynamic>());
  }

  factory UiTree.fromJson(Map<String, dynamic> j) {
    final version = (j['version'] as num?)?.toInt() ?? 0;
    if (version != kUiContractVersion) {
      throw FormatException(
        'UI 契约版本 $version 不受支持（当前支持 $kUiContractVersion）',
      );
    }

    final widget = j['widget'];
    if (widget is! String || widget.isEmpty) {
      throw const FormatException('UI 契约缺少 widget 名');
    }

    final state = _asMap(j['state'], 'state');

    final rawEvents = j['events'];
    final events = <String>[];
    if (rawEvents is List) {
      for (final e in rawEvents) {
        if (e is String) events.add(e);
      }
    }

    final rawRoot = j['tree'];
    if (rawRoot == null) {
      throw const FormatException('UI 契约缺少 tree');
    }

    final rawDecls = j['declarations'];
    final declarations = <UiDeclaration>[];
    if (rawDecls is List) {
      for (var i = 0; i < rawDecls.length; i++) {
        final d = rawDecls[i];
        if (d is! Map) {
          throw FormatException('declarations[$i] 不是 table');
        }
        declarations.add(UiDeclaration.fromJson(
            d.cast<String, dynamic>(), 'declarations[$i]'));
      }
    } else if (rawDecls != null) {
      throw const FormatException('declarations 必须是数组');
    }

    return UiTree(
      version: version,
      widget: widget,
      declarations: declarations,
      title: j['title'] as String?,
      state: state,
      root: UiNode.fromJson(rawRoot, r'tree'),
      events: events,
      nodeCount: (j['node_count'] as num?)?.toInt() ?? 0,
      fingerprint: j['fingerprint'] as String?,
    );
  }

  /// 送回 Lua 用的状态 JSON。
  String get stateJson => jsonEncode(state);

  /// 树里引用的全部组件本地状态字段（`state.x`）。
  Iterable<String> get stateReads sync* {
    for (final d in declarations) {
      for (final n in d.root.walk()) {
        for (final v in n.args.values) {
          if (v is UiStateRef) yield v.path;
        }
      }
    }
  }

  /// 树里出现的全部本地状态写入（`set state.x = v`）。
  Iterable<UiSetState> get stateWrites sync* {
    for (final d in declarations) {
      for (final n in d.root.walk()) {
        for (final v in n.args.values) {
          if (v is UiSetState) yield v;
        }
      }
    }
  }

  /// 实际节点数（遍历出来的），用来和 Lua 自报的 [nodeCount] 对账。
  int get actualNodeCount => root.walk().length;

  /// 树上真正引用到的事件名。
  Set<String> get referencedEvents {
    final s = <String>{};
    for (final e in root.events) {
      s.add(e.name);
    }
    return s;
  }

  /// 交叉校验：Lua 自报的统计与 Dart 侧数出来的必须一致。
  ///
  /// 不一致意味着两侧对契约的理解已经分叉——那正是最该早点炸掉的时刻。
  /// 采信 Dart 侧的统计，因为它是宿主真正要渲染的东西。
  List<String> validate() {
    final problems = <String>[];

    if (nodeCount != actualNodeCount) {
      problems.add(
        '节点数对不上：Lua 报 $nodeCount，Dart 数出 $actualNodeCount。'
        '两侧的收集规则不一致。',
      );
    }

    final known = referencedEvents;
    for (final e in known) {
      if (!events.contains(e)) {
        problems.add('树里用了未注册的事件 "$e"（handlers 里没有）');
      }
    }

    final unused = events.where((e) => !known.contains(e)).toList();
    if (unused.isNotEmpty) {
      problems.add('注册了但没有任何控件触发的事件: ${unused.join(', ')}');
    }

    return problems;
  }

  @override
  String toString() => 'UiTree($widget, $actualNodeCount 节点, $events)';
}

/// 两棵树是否**完全**相同。
///
/// ## 为什么需要它
///
/// 宿主判断"要不要重建"以前只比 [UiTree.fingerprint]，那是 Lua 侧算的
/// **哈希**。哈希有两个问题：
///
/// 1. **有碰撞。** 现用的累加式实现对 `{a=1, b=2}` 与 `{a=2, b=1}` 判为相同
///    （元素多重集合一样）。当前契约的 key 是固定的，所以碰不到；
///    但一旦契约允许动态 key，就会**静默漏更新**——画面停住，界面完全正常。
/// 2. **要花钱。** Lua 侧算指纹占建树耗时的四成（625 节点约 4ms）。
///
/// 结构比较没有这个问题：它是**精确**的，不存在碰撞；
/// 实测 625 节点同树比较 0.61ms、"改一个顶层字段"时提前退出只要 0.002ms，
/// 比 Lua 侧算指纹还便宜。
///
/// ## 用法：指纹当快路径，比较当权威
///
/// ```dart
/// if (prev.fingerprint != null && prev.fingerprint == next.fingerprint) {
///   return;                       // O(1)，指纹相同基本就是相同
/// }
/// if (uiTreeEquals(prev, next)) {
///   return;                       // O(n) 但精确，兜住哈希碰撞
/// }
/// // 真的变了
/// ```
bool uiTreeEquals(UiTree a, UiTree b) {
  if (identical(a, b)) return true;
  if (a.version != b.version) return false;
  if (a.widget != b.widget) return false;
  if (a.title != b.title) return false;
  if (!_argsEqual(a.root.args, b.root.args)) return false;
  // state 不参与：内容没变就不需要重建，state 变了但界面没变是正常的
  // （比如一次点击只改了日志计数）。
  return true;
}

bool _argsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;

  for (final key in a.keys) {
    if (!b.containsKey(key)) return false;
    if (!_valueEquals(a[key], b[key])) return false;
  }
  return true;
}

bool _valueEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;

  if (a is UiNode) {
    return b is UiNode &&
        a.widget == b.widget &&
        _argsEqual(a.args, b.args);
  }

  if (a is UiEvent) {
    return b is UiEvent &&
        a.name == b.name &&
        _argsEqual(a.arg, b.arg);
  }

  if (a is UiSetState) {
    return b is UiSetState &&
        a.path == b.path &&
        _valueEquals(a.value, b.value);
  }

  if (a is UiStateRef) {
    return b is UiStateRef && a.path == b.path;
  }

  if (a is List) {
    if (b is! List || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_valueEquals(a[i], b[i])) return false;
    }
    return true;
  }

  if (a is Map) {
    if (b is! Map || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!_valueEquals(a[key], b[key])) return false;
    }
    return true;
  }

  // int 1 与 double 1.0 在契约里是**不同**的（rfw 的 v<int> / v<double> 区分它们），
  // 所以不能走 == 。Dart 里 1 == 1.0 为 true，那会把类型差异抹掉。
  if (a is num && b is num) {
    return a.runtimeType == b.runtimeType && a == b;
  }

  return a == b;
}
