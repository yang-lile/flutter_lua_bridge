// lib/main.dart
//
// Lua Canvas Studio
//
// 左：Lua 代码编辑器，改完即渲染
// 右：实时预览 + 执行信息
//
// 沙箱与业务代码解耦：编辑器里的代码是即时执行的，
// 每次执行都重建 Lua state，保证不残留全局变量。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'display_list.dart';
import 'display_list_renderer.dart';
import 'lua_loader.dart';
import 'lua_worker.dart';
import 'sandbox.dart';
import 'ui_tree.dart';
import 'ui_view.dart';

void main() {
  runApp(const StudioApp());
}

class StudioApp extends StatelessWidget {
  const StudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lua Canvas Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF4A9EFF),
        scaffoldBackgroundColor: const Color(0xFF0D0F14),
        dividerColor: const Color(0xFF262B38),
      ),
      home: const StudioPage(),
    );
  }
}

class StudioPage extends StatefulWidget {
  const StudioPage({super.key});

  @override
  State<StudioPage> createState() => _StudioPageState();
}

/// 两种互斥的产出模式。
///
/// 切模式会清空上一种的结果：两者的契约结构完全不同，
/// 留着旧结果只会让人以为「代码改了但画面没变」。
enum StudioMode { canvas, ui }

class _StudioPageState extends State<StudioPage> {
  late final TextEditingController _code;
  final DisplayListRenderer _renderer = DisplayListRenderer();
  final ScrollController _logScroll = ScrollController();

  StudioMode _mode = StudioMode.ui;  // TEMP

  /// Lua 在独立 isolate 里跑，UI 不受阻塞影响。
  final LuaWorker _worker = LuaWorker();
  final LuaLoader _loader = LuaLoader();

  /// 启动阶段：读 assets、落盘、拉起 worker。
  bool _booting = true;
  String? _bootError;

  DisplayList? _result;
  UiTree? _uiTree;

  /// UI 契约的交叉校验结果。空表示一切正常。
  List<String> _uiWarnings = const [];

  /// 事件分发中。用来避免连点时排队——
  /// 连点应该“最后一次生效”，而不是把每次点击都跑一遍。
  bool _dispatching = false;

  List<String> _logs = const [];
  String? _error;
  int _lastMicros = 0;

  Timer? _debounce;

  /// 画布容器的上次尺寸。变化时递增 [_canvasRevision]，
  /// 让 CustomPainter 知道缩放比例变了、必须重新 paint。
  double _lastW = -1;
  double _lastH = -1;
  int _canvasRevision = 0;

  /// 缩放倍数。1.0 = 1:1，一个逻辑像素对应一个物理像素。
  ///
  /// 画布默认就是原始逻辑尺寸——所见即所得。
  /// 放大只是看不清细节时的辅助手段，由用户拖滑条控制。
  double _zoom = 1.0;

  /// 是否画画布边界线。
  bool _showFrame = true;

  /// 缩放档位。滑条用这些离散值，方便对到整数倍率。
  static const _zoomSteps = <double>[
    0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0, 8.0,
  ];

  /// worker 未就绪时收到执行请求，先记下来就绪后补跑。
  ///
  /// 这是"第一次不稳定"的直接修复：启动约有 1 秒空窗
  /// （assets 落盘 234ms + 首启 FFI 绑定 831ms），
  /// 之前这段时间的编辑会被静默丢弃。
  bool _pendingRun = false;

  /// 递增的执行序号。用于丢弃过期结果——
  /// 用户连续编辑时，只有最后一次的结果该被采纳。
  int _runSeq = 0;

  // 预设示例。用户代码是一个返回显示列表的函数。
  static const _snippets = <String, String>{
    '基础图元': '''
local c = canvas.new({ width = 360, height = 200, background = "#0f1116" })

c:circle(70, 70, 40, { fill = "#4a9eff" })
c:rect(140, 40, 90, 60, { radius = 10, fill = "#30a46c" })
c:rect(255, 40, 90, 60, { radius = 10, stroke = "#f5a524", stroke_width = 2 })
c:line(30, 130, 330, 130, { stroke = "#2a2f3a" })
c:text(30, 165, "改左边代码，右边立刻变", { size = 14, color = "#e6e9ef" })

return json.encode(c:build())
''',

    '折线图': '''
local data = { 42, 55, 48, 71, 66, 84, 79, 95, 88, 102, 97, 110 }
local W, H, pad = 360, 200, 30

local lo, hi = data[1], data[1]
for _, v in ipairs(data) do lo, hi = math.min(lo, v), math.max(hi, v) end

local function to_x(i) return pad + (i - 1) * ((W - pad * 2) / (#data - 1)) end
local function to_y(v) return H - pad - (v - lo) / (hi - lo) * (H - pad * 2) end

local c = canvas.new({ width = W, height = H, background = "#0f1116" })

for i = 0, 4 do
  local y = pad + (H - pad * 2) * i / 4
  c:line(pad, y, W - pad, y, { stroke = "#2a2f3a", stroke_width = 0.5 })
end

local pts = {}
for i, v in ipairs(data) do pts[#pts + 1] = { x = to_x(i), y = to_y(v) } end
c:polygon(pts, { stroke = "#4a9eff", stroke_width = 2 })

for i, v in ipairs(data) do
  c:circle(to_x(i), to_y(v), 3, { fill = "#4a9eff" })
end

print("点数:", #data, "范围:", lo, "-", hi)
return json.encode(c:build())
''',

    '柱状图': '''
local bars = { 62, 88, 45, 73, 95, 58 }
local W, H, pad = 360, 200, 30

local c = canvas.new({ width = W, height = H, background = "#0f1116" })
local slot = (W - pad * 2) / #bars
local bw = slot * 0.6

for i, v in ipairs(bars) do
  local h = v / 100 * (H - pad * 2)
  local x = pad + (i - 1) * slot + (slot - bw) / 2
  local y = H - pad - h
  -- 业务规则：超过 80 转红
  local color = v > 80 and "#e5484d" or "#4a9eff"
  c:rect(x, y, bw, h, { radius = 4, fill = color })
  c:text(x + bw / 2, y - 6, tostring(v),
    { size = 10, color = "#8b93a3", align = "center" })
end

c:line(pad, H - pad, W - pad, H - pad, { stroke = "#2a2f3a" })
return json.encode(c:build())
''',

    '带参数的函数': '''
-- 函数可以带参数、也可以拆成多个复用。
--
-- 关键：**画布由外面传进来**，不要在函数里 canvas.new。
-- 每个 canvas.new 都是一块独立的画布，在函数里新建的话
-- 画的东西都进了那块临时画布，返回值又被丢弃——外面什么也没有。

local W, H = 300, 300

local function draw_dial(c, cx, cy, r, pct)
  -- 底盘
  c:circle(cx, cy, r, { stroke = "#2a2f3a", stroke_width = 8 })

  -- 进度弧（用多段小圆近似）
  local steps = 40
  local filled = math.floor(steps * pct)
  for i = 1, filled do
    local ang = -math.pi / 2 + (i - 1) / steps * math.pi * 2
    c:circle(cx + math.cos(ang) * r, cy + math.sin(ang) * r, 4,
      { fill = "#4a9eff" })
  end

  c:text(cx, cy + 8, tostring(math.floor(pct * 100)) .. "%",
    { size = 20, color = "#e6e9ef", align = "center" })
end

local c = canvas.new({ width = W, height = H, background = "#0f1116" })
draw_dial(c, 90, 150, 60, 0.75)
draw_dial(c, 210, 150, 60, 0.42)
return json.encode(c:build())
''',

    '会报错的样子': '''
local c = canvas.new({ width = 360, height = 200 })
-- 半径传了字符串，应该在 Lua 侧就报错
c:circle(100, 100, "big", { fill = "#4a9eff" })
return json.encode(c:build())
''',

    'print 调试': '''
print("开始绘制")
local c = canvas.new({ width = 360, height = 200, background = "#0f1116" })

for i = 1, 5 do
  print("第", i, "个圆，x =", i * 60)
  c:circle(i * 60, 100, 22, { fill = "#a78bfa" })
end

print("画完了，共 5 个圆")
return json.encode(c:build())
''',
  };

  // UI 模式的示例。同样是普通 Lua，只是产出 widget 树而不是绘制指令。
  static const _uiSnippets = <String, String>{
    '计数器': '''
-- UI 模式：用普通 Lua 语法描述 Flutter widget 树。
--
-- 三部分：
--   state    业务状态（宿主会在每次事件后把它送回来）
--   handlers 事件名 -> 处理函数
--   view     视图函数，收到 (builder, state)
--
-- 子节点是**语句式**的：回调里写的每一句自动成为子节点，
-- 不用 return，也不用手写数组。

local app = ui.app({
  title = "计数器",
  state = { count = 0, loud = false },

  handlers = {
    inc = function(s, ev) s.count = s.count + (ev.amount or 1) end,
    reset = function(s) s.count = 0 end,
    toggle = function(s) s.loud = not s.loud end,
  },

  view = function(b, s)
    b:column({ main = "center", align = "center", gap = 14 }, function(b)
      b:card({ color = "#14171F" }, function(b)
        b:column({ gap = 10 }, function(b)
          b:text("点了几下", { style = "label", color = "#6B7488" })
          b:text(tostring(s.count), { style = "display" })
          b:row({ main = "center", align = "center", gap = 8 }, function(b)
            b:button("-1", {
              on_tap = "inc", arg = { amount = -1 }, variant = "outlined",
            })
            b:button("+1", { on_tap = "inc", arg = { amount = 1 } })
            b:button("归零", { on_tap = "reset", variant = "text" })
          end)
        end)
      end)
      b:toggle({ value = s.loud, on_change = "toggle", label = "声音" })
      b:divider()
      b:text("Lua 只描述，rfw 负责渲染", { style = "caption", align = "center" })
    end)
  end,
})

return json.encode(app:build())
''',

    '列表与事件参数': '''
-- 同一个 handler 绑定到多个控件，靠事件参数区分。
-- on_tap = "pick" 的 arg 就是事件参数，宿主会原样传给 handler。

local fruits = { "苹果", "香蕉", "樱桃", "西瓜" }

local app = ui.app({
  state = { index = 1 },
  handlers = {
    pick = function(s, ev) s.index = ev.index end,
    next = function(s) s.index = s.index % #fruits + 1 end,
  },

  view = function(b, s)
    b:column({ gap = 10 }, function(b)
      b:text("水果", { style = "title" })

      b:row({ gap = 8 }, function(b)
        for i, name in ipairs(fruits) do
          b:button(name, {
            on_tap = "pick", arg = { index = i },
            variant = (i == s.index) and "elevated" or "text",
          })
        end
      end)

      b:card(function(b)
        b:row({ align = "center", gap = 12 }, function(b)
          b:icon("star", { size = 22, color = "#4A9EFF" })
          b:expand(function(b)
            b:text(fruits[s.index] .. "（第 " .. s.index .. " 个）", { style = "subtitle" })
          end)
          b:button("下一个", { on_tap = "next", variant = "text" })
        end)
      end)

      b:divider()
      b:kpi("已选", fruits[s.index], { accent = "#4A9EFF" })
    end)
  end,
})

return json.encode(app:build())
''',

    '自定义组件与滑条': '''
-- rfw 没有开关，滑动条也只是"只读展示"的语义。
-- 这两个控件由宿主以 studio.* 的名字注册（见 lib/ui_view.dart），
-- 所以 Lua 下发的内容不限于 Flutter 自带控件。

local app = ui.app({
  state = { volume = 40, enabled = true },
  handlers = {
    set_volume = function(s, ev) s.volume = ev.value end,
    flip = function(s) s.enabled = not s.enabled end,
  },

  view = function(b, s)
    b:scroll({ padding = 4 }, function(b)
      b:column({ gap = 14 }, function(b)
        b:row({ gap = 10 }, function(b)
          b:kpi("音量", tostring(s.volume), { accent = "#4A9EFF" })
          b:kpi("状态", s.enabled and "开" or "关", { accent = "#30A46C" })
        end)

        b:slider({
          value = s.volume, min = 0, max = 100, divisions = 10,
          on_change = "set_volume",
        })

        b:toggle({
          value = s.enabled, on_change = "flip",
          label = "启用（宿主自定义组件）",
        })

        b:progress({ value = s.volume / 100 })

        b:card(function(b)
          b:column({ gap = 6 }, function(b)
            b:text("事件是怎么回来的", { style = "label", color = "#6B7488" })
            b:text(
              "点击控件 -> rfw 报出事件名 -> 宿主把名字送回 Lua -> "
              .. "handler 改状态 -> 重新出一棵树",
              { style = "caption" })
          end)
        end)
      end)
    end)
  end,
})

return json.encode(app:build())
''',

    '本地状态（不回 Lua）': '''
-- 这个示例演示两种交互的差别。
--
--   展开 / +1  -> set_state，**rfw 客户端自己改**，不回 Lua。
--                  所以点完下面的日志面板**不会**多出任何一行。
--   提交        -> 业务事件，回 Lua 跑 handler，然后重出整棵树。
--                  日志面板会多一行「事件 submit(...)」。
--
-- 组件是本地状态的载体：状态挂在声明上，每个实例各有一份。

ui.component("Item", {
  state = { open = false, hits = 0 },

  view = function(b, s)
    b:card({ color = "#14171F" }, function(b)
      b:column({ gap = 8 }, function(b)
        b:row({ main = "between", align = "center" }, function(b)
          b:text("条目", { style = "title" })
          -- 注意这里：必须是 b:sref(...) 而不是 "x" .. s.hits。
          -- rfw 状态变化时只会**重新解析树里的引用**，
          -- Lua 在 build 时算出来的字面量它改不了。
          b:value(b:sref("hits"), { style = "subtitle" })
        end)

        -- 本地状态：点一下界面立刻变，不经过 Lua
        b:row({ gap = 8 }, function(b)
          b:button("展开", { on_tap = b:set_state("open", not s.open) })
          b:button("+1", { on_tap = b:set_state("hits", s.hits + 1) })
          b:button("收起", {
            on_tap = b:set_state("open", false),
            variant = s.open and "elevated" or "text",
          })
        end)

        if s.open then
          b:text("这段内容由 rfw 的本地状态控制显示，" ..
                 "点击没有产生任何事件，也没有回到 Lua。",
            { style = "caption" })
        end
      end)
    end)
  end,
})

local app = ui.app({
  title = "本地状态",
  state = { submitted = 0 },

  handlers = {
    submit = function(s) s.submitted = s.submitted + 1 end,
  },

  view = function(b, s)
    b:column({ main = "center", gap = 14 }, function(b)
      b:Item()

      b:divider()
      b:row({ gap = 10, align = "center" }, function(b)
        b:text("已提交 " .. s.submitted .. " 次", { style = "label" })
        b:expand(function(b)
          b:button("提交（会回 Lua）", { on_tap = "submit" })
        end)
      end)
    end)
  end,
})

return json.encode(app:build())
''',

    '会报错的样子': '''
local app = ui.app({
  state = {},
  handlers = {},
  view = function(b)
    -- 引用了没注册的事件名，Lua 侧就会报错并列出已注册的
    b:button("点了会炸", { on_tap = "不存在的处理器" })
  end,
})

return json.encode(app:build())
''',
  };

  /// 当前模式下的示例表。
  Map<String, String> get _snippetsForMode =>
      _mode == StudioMode.canvas ? _snippets : _uiSnippets;

  String _firstSnippet() =>
      _mode == StudioMode.ui ? _uiSnippets['本地状态（不回 Lua）']!
                              : _snippetsForMode.values.first;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: _firstSnippet());
    // 不再等一帧再启动——那样会让"启动中"的状态晚一拍才出现。
    unawaited(_boot());
  }

  /// 切换画布 / 组件模式。
  ///
  /// 两种模式用不同的示例与不同的产物，所以切模式时直接换成该模式的
  /// 第一个示例，而不是把上一模式的代码带过来（带过来必报错，没意义）。
  void _switchMode(StudioMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _code.text = _firstSnippet();
      _result = null;
      _uiTree = null;
      _uiWarnings = const [];
      _error = null;
    });
    _scheduleRun(immediate: true);
  }

  /// 启动流程：读 assets -> 落盘 -> 拉起 worker -> 补跑积压的编辑。
  Future<void> _boot() async {
    try {
      final root = await _loader.init();

      if (_loader.moduleCount == 0) {
        // assets 没打进来。列出尝试过的路径，避免只看到 module not found
        throw StateError(
          'assets 中未找到任何 Lua 模块。\n'
          '请确认 pubspec.yaml 的 assets 声明包含 assets/lua/manifest.txt，'
          '并重新构建。',
        );
      }

      await _worker.start(root);

      if (!mounted) return;
      setState(() => _booting = false);

      // 启动完成时必定执行一次最新代码——
      // 启动期间积压的编辑（[pendingRun] 记的就是这件事）也在这里被覆盖。
      _pendingRun = false;
      _scheduleRun(immediate: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _booting = false;
        _bootError = '$e';
      });
    }
  }

  /// 输入防抖：停止打字 400ms 后自动执行。
  void _onCodeChanged(String _) {
    _scheduleRun();
  }

  /// 安排一次执行。[immediate] 为真时跳过防抖。
  void _scheduleRun({bool immediate = false}) {
    _debounce?.cancel();
    if (immediate) {
      unawaited(_execute());
    } else {
      _debounce = Timer(
        const Duration(milliseconds: 400),
        () => unawaited(_execute()),
      );
    }
  }

  /// 执行用户代码。跑在 worker isolate 上，本 isolate 不阻塞。
  Future<void> _execute() async {
    // 启动还没完成时不能丢弃用户意图：记下来，等 _boot 完成后由它补跑。
    // 这直接修掉"第一次打开时自动运行没反应"——
    // 启动约有 1 秒空窗（assets 落盘 234ms + 首启 FFI 绑定 831ms）。
    if (_booting) {
      _pendingRun = true;
      return;
    }
    if (_bootError != null) return;

    final seq = ++_runSeq;
    setState(() => _error = null);

    // UI 模式的代码不是"返回函数"，而是一段立即执行的 chunk。
    // 两种写法由 sandbox 里的两个入口分别处理。
    final res = _mode == StudioMode.ui
        ? await _worker.runUi(_code.text)
        : await _worker.run(buildStudioSource(_code.text));

    // 期间用户又改了代码 —— 这次结果已过期，丢弃。
    // 不丢弃的话会看到"新代码配旧画面"，比延迟一拍更让人困惑。
    if (seq != _runSeq || !mounted) return;

    DisplayList? parsed;
    UiTree? uiTree;
    String? parseError;

    if (_mode == StudioMode.ui) {
      final uiJson = res.uiTreeJson;
      if (uiJson != null) {
        try {
          uiTree = UiTree.parse(uiJson);
        } catch (e) {
          parseError = 'UI 契约解析失败：$e';
        }
      }
    } else {
      final json = res.displayListJson;
      if (json != null) {
        try {
          parsed = DisplayList.fromJson(jsonDecode(json) as Map<String, dynamic>);
        } catch (e) {
          parseError = '显示列表解析失败：$e';
        }
      }
    }

    setState(() {
      _logs = res.logs;
      _error = res.error ?? parseError;
      _result = parsed;
      _uiTree = uiTree;
      _uiWarnings = uiTree?.validate() ?? const [];
      _lastMicros = res.elapsedMicros;
    });

    _scrollLogToEnd();
  }

  /// rfw 事件回调。把事件名送回 Lua，拿回新的一棵树。
  ///
  /// 为什么不在宿主侧直接改状态：
  /// 状态的唯一事实来源在 Lua 里（app.state）。宿主改一份副本的话，
  /// 下一次事件会被 Lua 重新执行时的状态覆盖，表现为「点一下归零」。
  ///
  /// 连点处理：分发中直接忽略新事件。编辑器场景下排队没有意义——
  /// 用户想要的是最后那一下的结果，不是把每次点击都跑一遍。
  Future<void> _onUiEvent(String name, Map<String, dynamic> args) async {
    if (_dispatching || _booting || _bootError != null) return;
    final current = _uiTree;
    if (current == null) return;

    setState(() => _dispatching = true);
    final sw = Stopwatch()..start();

    final res = await _worker.runUi(
      _code.text,
      stateJson: current.stateJson,
      eventName: name,
      eventArgsJson: jsonEncode(args),
    );
    sw.stop();

    if (!mounted) return;

    UiTree? next;
    String? parseError;
    final uiJson = res.uiTreeJson;
    if (uiJson != null) {
      try {
        next = UiTree.parse(uiJson);
      } catch (e) {
        parseError = 'UI 契约解析失败：$e';
      }
    }

    setState(() {
      _dispatching = false;
      // 出错时保留旧树，不要闪成空白。
      // 报错信息已经放到错误卡片里了，画面没必要跟着变。
      _uiTree = next ?? current;
      _uiWarnings = next?.validate() ?? const [];
      _error = res.error ?? parseError;
      _lastMicros = res.elapsedMicros;
      _logs = [
        if (res.error == null)
          '事件 ${describeUiEvent(name, args)} -> ${next?.actualNodeCount ?? 0} 节点'
              '（往返 ${sw.elapsedMilliseconds}ms）'
        else
          '事件 ${describeUiEvent(name, args)} 失败：${res.error!.split('\n').first}',
        ...res.logs,
      ];
    });
    _scrollLogToEnd();
  }

  void _scrollLogToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _logScroll.hasClients) {
        _logScroll.jumpTo(_logScroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _worker.dispose();
    _code.dispose();
    _logScroll.dispose();
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _toolbar(),
            const Divider(height: 1),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: _editorPane()),
                  const VerticalDivider(width: 1),
                  Expanded(flex: 6, child: _previewPane()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 工具栏 ----------

  Widget _toolbar() {
    final muted = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: const Color(0xFF14171F),
      child: Row(
        children: [
          const Icon(Icons.brush_outlined,
              size: 18, color: Color(0xFF4A9EFF)),
          const SizedBox(width: 10),
          Text('Lua Canvas Studio',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: muted)),
          const SizedBox(width: 22),
          _modeSwitch(),
          const SizedBox(width: 14),
          PopupMenuButton<String>(
            tooltip: '载入示例',
            onSelected: (key) {
              _code.text = _snippetsForMode[key]!;
              _scheduleRun(immediate: true);
            },
            itemBuilder: (_) => [
              for (final k in _snippetsForMode.keys)
                PopupMenuItem(value: k, child: Text(k)),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book_outlined, size: 15),
                const SizedBox(width: 6),
                Text('示例', style: TextStyle(fontSize: 12, color: muted)),
                const Icon(Icons.arrow_drop_down, size: 16),
              ],
            ),
          ),
          const Spacer(),
          _statusChip(),
          const SizedBox(width: 10),
          if (_result != null) _zoomControl(),
          const SizedBox(width: 6),
          // 画布边界开关
          Tooltip(
            message: _showFrame ? '隐藏画布边界' : '显示画布边界',
            child: IconButton(
              onPressed: () => setState(() => _showFrame = !_showFrame),
              icon: Icon(
                _showFrame ? Icons.crop_free : Icons.crop_free_outlined,
                size: 17,
              ),
              color: _showFrame
                  ? const Color(0xFF4A9EFF)
                  : const Color(0xFF6B7488),
            ),
          ),
          FilledButton.icon(
            onPressed: _booting ? null : () => _scheduleRun(immediate: true),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('运行'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4A9EFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- 模式切换 ----------

  /// 画布 / 组件两个模式。
  ///
  /// 两种的 Lua 产物结构不同（显示列表 vs widget 树），
  /// 所以切换时连代码一起换掉。
  Widget _modeSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F14),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF262B38)),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeButton(StudioMode.canvas, '画布', Icons.brush_outlined),
          _modeButton(StudioMode.ui, '组件', Icons.widgets_outlined),
        ],
      ),
    );
  }

  Widget _modeButton(StudioMode mode, String label, IconData icon) {
    final on = _mode == mode;
    return Tooltip(
      message: mode == StudioMode.canvas
          ? 'Lua 产出绘制指令，宿主用 CustomPaint 画'
          : 'Lua 产出 widget 树，宿主交给 rfw 渲染',
      child: InkWell(
        onTap: () => _switchMode(mode),
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: on ? const Color(0xFF4A9EFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14,
                  color: on ? Colors.white : const Color(0xFF6B7488)),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                  color: on ? Colors.white : const Color(0xFF98A1B3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- 缩放控制 ----------

  /// 缩放滑条。
  ///
  /// 默认 1:1 —— 画布就是 Lua 声明的原始逻辑尺寸。
  /// 放大只用于查看细节，拖这条滑条调整。
  Widget _zoomControl() {
    // 滑条位置映射到 [zoomSteps] 的下标
    final idx = _zoomSteps.indexOf(_zoom);
    final pos = idx >= 0 ? idx.toDouble() : 1.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _zoom > _zoomSteps.first
              ? () => setState(() => _zoom = _stepDown(_zoom))
              : null,
          icon: const Icon(Icons.remove, size: 16),
          tooltip: '缩小',
        ),
        SizedBox(
          width: 130,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: pos,
              min: 0,
              max: (_zoomSteps.length - 1).toDouble(),
              divisions: _zoomSteps.length - 1,
              onChanged: (v) {
                final i = v.round().clamp(0, _zoomSteps.length - 1);
                setState(() => _zoom = _zoomSteps[i]);
              },
            ),
          ),
        ),
        IconButton(
          onPressed: _zoom < _zoomSteps.last
              ? () => setState(() => _zoom = _stepUp(_zoom))
              : null,
          icon: const Icon(Icons.add, size: 16),
          tooltip: '放大',
        ),
        // 当前倍率。点一下回到 1:1
        InkWell(
          onTap: () => setState(() => _zoom = 1.0),
          child: Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF14171F),
              border: Border.all(color: const Color(0xFF262B38)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${(_zoom * 100).round()}%',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFE6E9EF),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 下一档缩放（放大方向）。
  double _stepUp(double current) {
    for (final z in _zoomSteps) {
      if (z > current) return z;
    }
    return current;
  }

  /// 上一档缩放（缩小方向）。
  double _stepDown(double current) {
    for (var i = _zoomSteps.length - 1; i >= 0; i--) {
      if (_zoomSteps[i] < current) return _zoomSteps[i];
    }
    return current;
  }

  // ---------- 状态指示 ----------

  /// 工具栏右侧的状态。启动中、执行中、耗时三态。
  Widget _statusChip() {
    if (_booting) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.6),
          ),
          const SizedBox(width: 7),
          Text(
            // 启动期间用户改过代码就说明一下，
            // 否则"画面没动"会让人以为编辑丢了
            _pendingRun ? '正在启动，编辑已排队' : '正在启动 Lua 运行时',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7488)),
          ),
        ],
      );
    }

    if (_worker.busy) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.6),
          ),
          SizedBox(width: 7),
          Text('执行中',
              style: TextStyle(fontSize: 11, color: Color(0xFF6B7488))),
        ],
      );
    }

    return Text(
      '${(_lastMicros / 1000).toStringAsFixed(1)} ms',
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF6B7488),
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }

  // ---------- 编辑器 ----------

  Widget _editorPane() {
    return Container(
      color: const Color(0xFF0D0F14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _paneHeader('Lua 代码', '停止输入 0.4 秒后自动运行'),
          Expanded(
            child: TextField(
              controller: _code,
              onChanged: _onCodeChanged,
              maxLines: null,
              expands: true,
              autocorrect: false,
              enableSuggestions: false,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontFamily: 'Menlo',
                fontFamilyFallback: ['SF Mono', 'Consolas'],
                fontSize: 13,
                height: 1.55,
                color: Color(0xFFE6E9EF),
              ),
              cursorColor: const Color(0xFF4A9EFF),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
            ),
          ),
          if (_logs.isNotEmpty) _logPanel(),
        ],
      ),
    );
  }

  Widget _paneHeader(String title, String note) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF262B38))),
      ),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(fontSize: 12, color: Color(0xFFE6E9EF))),
          const Spacer(),
          Text(note,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7488))),
        ],
      ),
    );
  }

  Widget _logPanel() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      decoration: const BoxDecoration(
        color: Color(0xFF14171F),
        border: Border(top: BorderSide(color: Color(0xFF262B38))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.centerLeft,
            child: Text('输出 (${_logs.length})',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7488))),
          ),
          Expanded(
            child: ListView.builder(
              controller: _logScroll,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              itemCount: _logs.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  _logs[i],
                  style: const TextStyle(
                    fontFamily: 'Menlo',
                    fontSize: 11.5,
                    color: Color(0xFF98A1B3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- 预览 ----------

  Widget _previewPane() {
    final isUi = _mode == StudioMode.ui;
    return Container(
      color: const Color(0xFF0D0F14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _paneHeader(
            isUi ? '预览' : '预览',
            isUi ? 'Lua 描述结构，rfw 渲染成真实 widget' : '宿主渲染显示列表',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_bootError != null) _errorCard(),
                  if (_bootError == null && _booting) _bootingState(),
                  if (_bootError == null && !_booting && _error != null)
                    _errorCard(),
                  if (_bootError == null && !_booting && _error == null)
                    if (isUi && _uiTree == null) _uiEmptyState(),
                    if (!isUi && _result == null) _emptyState(),
                  if (isUi && _uiTree != null) _uiView(),
                  if (isUi && _uiTree != null) const SizedBox(height: 14),
                  if (isUi && _uiTree != null) _uiStatsBar(),
                  if (!isUi && _result != null) _canvasView(),
                  if (!isUi && _result != null) const SizedBox(height: 14),
                  if (!isUi && _result != null) _statsBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- UI 预览 ----------

  /// 渲染 widget 树。
  ///
  /// 外面包一层 Material：rfw 的 ElevatedButton / Switch 等需要
  /// Theme 与 Directionality，而它们不在我们渲染的子树里。
  Widget _uiView() {
    final tree = _uiTree!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11141B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2430)),
      ),
      child: Material(
        color: Colors.transparent,
        child: LuaUiView(
          tree: tree,
          onEvent: (name, args) => unawaited(_onUiEvent(name, args)),
          onWarning: (msg) {
            // 诊断不致命，不打断界面，只在下方列出。
            // 累积而不是覆盖：一次可能报出多条（清单不对 + 节点数不对）。
            if (mounted) {
              setState(() => _uiWarnings = {..._uiWarnings, msg}.toList());
            }
          },
        ),
      ),
    );
  }

  Widget _uiEmptyState() {
    // 字面量直接写进 const 上下文：局部 const 变量在 const 表达式里
    // 仍然算运行时取值，analyzer 会要求 prefer_const。
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.widgets_outlined, size: 30, color: Color(0xFF98A1B3)),
          SizedBox(height: 12),
          Text('没有产出 widget 树',
              style: TextStyle(fontSize: 13, color: Color(0xFF98A1B3))),
          SizedBox(height: 6),
          Text(
            '代码需要声明一个应用并返回契约，例如\n'
            'local app = ui.app({ state = {}, handlers = {}, view = function(b, s) ... end })\n'
            'return json.encode(app:build())',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF6B7488), height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _uiStatsBar() {
    final tree = _uiTree!;
    final widgets = <String, int>{};
    for (final n in tree.root.walk()) {
      widgets[n.widget] = (widgets[n.widget] ?? 0) + 1;
    }
    final parts = widgets.entries.map((e) => '${e.key} ${e.value}').join('   ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('节点', '${tree.actualNodeCount}'),
            _chip('事件', tree.events.isEmpty ? '无' : tree.events.join(', ')),
            _chip('Lua', '$_lastMicros µs'),
            if (_dispatching) _chip('分发中', '…'),
            if (tree.fingerprint != null) _chip('指纹', tree.fingerprint!),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0F14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1E2430)),
          ),
          child: Text(parts,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF6B7488), height: 1.6)),
        ),
        if (_uiWarnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2113),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF5A524)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final w in _uiWarnings)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(w,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFF5C26B),
                            height: 1.6)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _errorCard() {
    final isBoot = _bootError != null;
    final message = isBoot ? _bootError! : _error!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1518),
        border: Border.all(color: const Color(0xFFE5484D)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, size: 15, color: Color(0xFFE5484D)),
              const SizedBox(width: 7),
              Text(
                isBoot ? '启动失败' : 'Lua 报错',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFFE5484D)),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Menlo',
              fontSize: 12,
              height: 1.55,
              color: Color(0xFFFFB4AB),
            ),
          ),
        ],
      ),
    );
  }

  /// 启动中。明确告诉用户"正在准备"，而不是留一片空白。
  Widget _bootingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 16),
          Text(
            _pendingRun ? '启动中，你刚才的修改已排队' : '正在启动 Lua 运行时',
            style: const TextStyle(fontSize: 13, color: Color(0xFF98A1B3)),
          ),
          const SizedBox(height: 6),
          const Text(
            '首次启动需要绑定符号，通常不到一秒',
            style: TextStyle(fontSize: 11, color: Color(0xFF6B7488)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.code_off_outlined, size: 30, color: muted),
          const SizedBox(height: 12),
          const Text('没有产出显示列表',
              style: TextStyle(fontSize: 13, color: Color(0xFF98A1B3))),
          const SizedBox(height: 6),
          const Text(
            '代码需要返回显示列表的 JSON，例如\n'
            'return json.encode(c:build())',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF6B7488)),
          ),
        ],
      ),
    );
  }

  Widget _canvasView() {
    final list = _result!;

    // 画布实际像素尺寸 = 逻辑尺寸 × 缩放。
    // 1:1 时就是 Lua 里声明的原始尺寸。
    final canvasW = (list.width * _zoom).round();
    final canvasH = (list.height * _zoom).round();

    // 视口尺寸变化时 bump revision，让 CustomPainter 重新 paint。
    // CustomPainter 拿不到容器尺寸，而缩放后的画布尺寸依赖它。
    return LayoutBuilder(
      builder: (context, constraints) {
        final availW = constraints.maxWidth;
        final availH = constraints.maxHeight;
        if (availW != _lastW || availH != _lastH) {
          _lastW = availW;
          _lastH = availH;
          _canvasRevision++;
        }

        // 画布比视口大时才需要滚动。1:1 且窗口够大时是静态的，
        // 符合"所见即所得"的预期。
        final needsScroll = canvasW > availW || canvasH > availH;

        final canvas = SizedBox(
          width: canvasW.toDouble(),
          height: canvasH.toDouble(),
          child: CustomPaint(
            painter: _DisplayListPainter(
              _renderer,
              list,
              revision: _canvasRevision,
              scale: _zoom,
              showFrame: _showFrame,
            ),
            size: Size(canvasW.toDouble(), canvasH.toDouble()),
          ),
        );

        if (!needsScroll) {
          // 画布装得下：居中显示，不提供平移
          return Center(child: canvas);
        }

        // 放大后画布超出视口：可拖动查看各部分。
        // alignment: topLeft 让左上角始终对齐（画布的直觉原点），
        // 而不是 InteractiveViewer 默认的居中——否则画布会"飘"。
        return InteractiveViewer(
          minScale: 1.0,
          maxScale: 1.0,
          panEnabled: true,
          scaleEnabled: false,
          alignment: Alignment.topLeft,
          boundaryMargin: const EdgeInsets.all(120),
          constrained: false,
          child: canvas,
        );
      },
    );
  }

  Widget _statsBar() {
    final list = _result!;
    final counts = <String, int>{};
    for (final op in list.ops) {
      counts[op.type.name] = (counts[op.type.name] ?? 0) + 1;
    }
    final parts = counts.entries.map((e) => '${e.key} ${e.value}').join('   ');

    // 1:1 时逻辑尺寸就是实际像素尺寸；放大后是逻辑尺寸 × 倍率
    final pxW = (list.width * _zoom).round();
    final pxH = (list.height * _zoom).round();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip('图元', '${list.ops.length}'),
        _chip('画布', '$pxW×$pxH px'),
        if (_zoom != 1.0)
          _chip('原始', '${list.width.toInt()}×${list.height.toInt()}'),
        _chip('缩放', '${(_zoom * 100).round()}%'),
        _chip('构成', parts),
        if (list.fingerprint != null) _chip('指纹', list.fingerprint!),
      ],
    );
  }

  Widget _chip(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF14171F),
        border: Border.all(color: const Color(0xFF262B38)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7488)),
          children: [
            TextSpan(text: '$k '),
            TextSpan(
              text: v,
              style: const TextStyle(color: Color(0xFFE6E9EF)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 把显示列表画到 Canvas。
///
/// 画布尺寸 = 显示列表逻辑尺寸 × [scale]。1:1 时每个逻辑像素
/// 对应一个物理像素，所见即所得；放大由用户拖滑条控制。
///
/// [revision] 由宿主持有：CustomPainter 拿不到容器尺寸，
/// 而缩放后的画布尺寸依赖它，尺寸变了必须重新 paint。
class _DisplayListPainter extends CustomPainter {
  _DisplayListPainter(
    this.renderer,
    this.list, {
    this.revision = 0,
    this.scale = 1.0,
    this.showFrame = true,
  });

  final DisplayListRenderer renderer;
  final DisplayList list;

  /// 宿主维护的修订号。画布容器尺寸变化时 +1。
  final int revision;

  /// 缩放倍数。1.0 为 1:1。
  final double scale;

  /// 是否画画布边界线。
  final bool showFrame;

  @override
  void paint(Canvas canvas, Size size) {
    renderer.render(canvas, size, list,
        scale: scale, drawFrame: showFrame);
  }

  @override
  bool shouldRepaint(covariant _DisplayListPainter old) {
    // 画布尺寸、缩放、边界开关任一变化都要重绘
    if (old.revision != revision) return true;
    if (old.scale != scale) return true;
    if (old.showFrame != showFrame) return true;

    // 内容变了要重绘。指纹可能缺失（老版本 Lua、被裁剪的库、解析失败），
    // 而 `null != null` 是 false 会让画面永远停在第一次，
    // 所以任一方缺指纹一律当作需要重绘。
    final a = old.list.fingerprint;
    final b = list.fingerprint;
    if (a == null || b == null) return true;
    return a != b;
  }
}
