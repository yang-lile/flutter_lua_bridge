// lib/deep_equality.dart
//
// 纯 Dart 的深比较，用来判断"两次产出的内容是否完全一样"。
//
// ## 为什么单独抽出来
//
// 它是**唯一**的裁判：指纹（Lua 侧算的哈希）只当 O(1) 快路径，
// 最终判断由这里做。哈希会碰撞，碰撞的表现是**静默漏更新**——
// 画面停住不刷新，界面上没有任何报错。这类 bug 靠"跑一遍看看"发现不了。
//
// 抽成独立文件还带来一个好处：`display_list.dart` 用了 `dart:ui`
// （Color / Offset），在纯 Dart VM 下**根本跑不起来**（本项目的已知限制）。
// 比较发生在**原始 JSON** 上，所以这一层可以被
// `tools/verify_change_detect.dart` 完整覆盖，不需要 Flutter 引擎。
//
// ## 关键规则：int 和 double 不相等
//
// Dart 里 `1 == 1.0` 为 true，但在这个契约里它们是**不同的**：
// rfw 的 `v<int>()` 与 `v<double>()` 是两套解码，对不上就静默返回 null，
// 参数被丢掉、控件退回默认值。这个坑真实发生过
// （`slider(max=100)` 变成 0..1），所以比较时必须保住类型差异。

/// 从内容里**派生**出来的字段名。
///
/// 它由内容算出，因此**不能参与内容比较** —— 否则会出现
/// "内容完全相同，但因为指纹不同而判定为变了"，白白重建。
const String kDerivedFingerprintKey = 'fingerprint';

/// 取出「内容部分」：剥掉派生字段。
///
/// 生产代码（`DisplayList.fromJson`）与测试用的是同一个函数，
/// 所以规则不会在两边跑偏。
Map<String, dynamic> contentOf(Map<String, dynamic> raw) {
  if (!raw.containsKey(kDerivedFingerprintKey)) return raw;
  return Map<String, dynamic>.from(raw)..remove(kDerivedFingerprintKey);
}

/// 深比较两个 JSON 形态的值。
///
/// 形状：`Map` / `List` / `int` / `double` / `bool` / `String` / `null`。
/// 其它类型按 `==` 处理。
bool deepEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;

  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!deepEquals(a[key], b[key])) return false;
    }
    return true;
  }

  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!deepEquals(a[i], b[i])) return false;
    }
    return true;
  }

  // 类型不同直接判不等：1 与 1.0 在这个契约里是两回事
  if (a is num && b is num) {
    return a.runtimeType == b.runtimeType && a == b;
  }

  // 一边是 num 一边不是（或者 bool/String 等）：交给 == 自然为 false
  return a == b;
}

/// 找出两个值的第一处差异，写进 [out]。
///
/// 诊断用：告诉用户"到底哪一行变了"比只说"变了"有用得多。
/// 返回 true 表示有差异。
bool findFirstDifference(Object? a, Object? b, String path, List<String> out) {
  if (deepEquals(a, b)) return false;

  if (a is Map && b is Map) {
    // 先看键集合
    for (final key in a.keys) {
      if (!b.containsKey(key)) {
        out.add('$path.$key：只在左边有');
        return true;
      }
    }
    for (final key in a.keys) {
      if (findFirstDifference(a[key], b[key], '$path.$key', out)) return true;
    }
    for (final key in b.keys) {
      if (!a.containsKey(key)) {
        out.add('$path.$key：只在右边有');
        return true;
      }
    }
    return false;   // 键集合与逐项都比较过了却还没找到差异 —— 理论上到不了这
  }

  if (a is List && b is List) {
    if (a.length != b.length) {
      out.add('$path：长度 ${a.length} vs ${b.length}');
      return true;
    }
    for (var i = 0; i < a.length; i++) {
      if (findFirstDifference(a[i], b[i], '$path[$i]', out)) return true;
    }
    return false;
  }

  out.add('$path：${_brief(a)} vs ${_brief(b)}');
  return true;
}

String _brief(Object? v) {
  final s = v?.toString() ?? 'null';
  return s.length > 40 ? '${s.substring(0, 40)}…' : s;
}
