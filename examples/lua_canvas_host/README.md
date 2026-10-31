# Flutter 宿主 + Lua 编排

宿主提供渲染能力，Lua 编排业务逻辑。核心约定：**Lua 只描述，不负责"怎么做"**。

两条产出链路，同一套约定：

| 模式 | Lua 产出 | 宿主怎么用 | 产物 |
|---|---|---|---|
| **画布** | 绘制指令（显示列表） | `CustomPaint` 批量重绘 | `DisplayList` |
| **组件** | widget 树 | 交给 [rfw](https://pub.dev/packages/rfw) 渲染 | `UiTree` |

两条链路的共同点比差异更多：都只跨界一次（代码进、JSON 出），
都带内容指纹，都有参数校验与可读报错，都在独立 isolate 里跑。

## 为什么不用"逐条调用"

假设 Lua 直接调 `canvas.circle(x, y, r)`：

- 每帧 60fps × 数百图元 = 数万次 FFI 跨界调用，开销无法接受
- 无法脱离 Flutter 做单元测试
- 无法缓存、无法 diff、无法回放

声明式显示列表（DisplayList）把这三点都解决了：

1. 每帧只有**一次**跨界调用（JSON 进、JSON 出）
2. 显示列表是纯数据，Lua 侧和 Dart 侧都能完整断言
3. 内容指纹可缓存、可 diff，宿主据此跳过整帧渲染

## 分层

```
┌──────────────────────────────────────────────┐
│ render/*.lua   ui/init.lua     业务编排         │  ← 纯 Lua
├──────────────────────────────────────────────┤
│ canvas/init.lua  画布能力 + 参数校验            │  ← 纯 Lua
│ guard.lua        执行预算（canvas / ui 共用）  │
├──────────────────────────────────────────────┤
│ host/init.lua    能力契约层                     │
├──────────────────────────────────────────────┤
│ display_list.dart  显示列表模型                │  ← Dart，无 Flutter 类型
│ ui_tree.dart       widget 树模型               │
│ ui_rfw_ast.dart    树 -> rfw RemoteWidgetLibrary│  ← 只 import rfw/formats
├──────────────────────────────────────────────┤
│ display_list_renderer.dart  批量绘制           │  ← 接触 Flutter 绘制 API
│ ui_view.dart             rfw 渲染 + 自定义组件 │
├──────────────────────────────────────────────┤
│ sandbox.dart   lua_worker.dart   执行          │
│ lua_loader.dart                  assets 加载   │
│ main.dart / driver_main.dart     编辑器 UI      │
└──────────────────────────────────────────────┘
```

「模型层不含 Flutter 类型」这条规矩让两侧测试都能脱离引擎运行——
`flutter test` 在受限环境里不可用，全部验证都是纯 Dart / Lua 入口。

## 跑起来

**Makefile** 是入口：

```bash
make help          # 看全部命令
make run           # 构建并启动
make test          # 跑全部验证
make check         # analyze + test
```

macOS 构建由 `tools/build_macos.sh` 先生成 Flutter 配置，再直接构建
`Runner.xcodeproj`，不会触发 Web 构建。依赖已经解析好的环境可以用
`SKIP_PUB_GET=1 make build` 跳过依赖解析。

**本地调试**（日常用这个）：

```bash
cd examples/lua_canvas_host
bash tools/dev.sh
```

构建 debug 版并启动，约 30–60 秒。

```bash
bash tools/dev.sh --no-build   # 只启动，跳过构建（最快）
bash tools/dev.sh --release    # 用 release 模式（体积小、启动快）
```

**出包**（要给别人跑时用）：

```bash
bash tools/run.sh               # 构建 release + 启动
bash tools/run.sh --build-only  # 只构建
```

> **热重载一般不可用。** `flutter run` 需要连 VM service 的本地 socket，
> 这个环境里常常连不上（报 `Error waiting for a debug connection`）。
> debug 模式的**构建**是好的，直接 `open` 产物就能跑，只是没有热重载。
> 改完代码重跑 `dev.sh` 即可。
>
> 偶尔能连上时，本项目的调试价值很大——**真实点击能发现单测发现不了的 bug**
> （见下文「数值类型是个坑」）。

### 用 flutter_driver 驱动真实界面

`lib/driver_main.dart` 是带 driver 扩展的入口（正式入口不引 driver 相关依赖）：

```bash
flutter run -t lib/driver_main.dart
```

连上之后就能用真实点击验证整条链路（模式切换、示例切换、按钮、
自定义 Switch、滑条拖动）。三个环境事实，都实测过：

1. **窗口必须在前台**，否则指针注入会一直等到超时。
   日志里的 `Failed to foreground app; open returned 1` 就是信号，
   用 AppleScript 抬一下即可：

   ```bash
   osascript -e 'tell application "System Events" to set frontmost of \
     (first process whose unix id is <pid>) to true'
   ```

2. **换入口点后要 hot restart 才生效**。`flutter run -t lib/driver_main.dart`
   启动的仍是旧 kernel（日志照常打印 `lib/driver_main.dart`，但 driver 扩展没注册）。
   一次 `hot_restart` 就对了。

3. **不要在应用启动期间发 driver 命令**。第一条超时的命令会把扩展卡住，
   之后所有命令都超时——看起来像"工具坏了"，其实是上一条还在等。

> **改 Lua 必须重新构建。** Lua 代码通过 Flutter assets 打包进应用，
> 不是运行时从磁盘读，所以 `dev.sh --no-build` 拿不到新的 Lua。

左侧写 Lua，**停止输入 0.4 秒后自动执行**，右侧实时显示渲染结果。

工具栏左上角切换**画布 / 组件**两个模式，示例与产出都跟着换。

- **画布**：六个预设 —— 基础图元、折线图、柱状图、带参数的函数、会报错的样子、print 调试
- **组件**：四个预设 —— 计数器、列表与事件参数、自定义组件与滑条、会报错的样子

## 组件模式：用 Lua 描述 widget

切换到「组件」模式后，Lua 写的是 Flutter widget 树：

```lua
local app = ui.app({
  title = "计数器",
  state = { count = 0 },              -- 初始值

  handlers = {                        -- 事件名 -> 处理函数
    inc = function(s, ev) s.count = s.count + (ev.amount or 1) end,
  },

  view = function(b, s)               -- b 是 builder，s 是状态
    b:column({ main = "center" }, function(b)
      b:text(tostring(s.count), { style = "display" })
      b:button("加一", { on_tap = "inc", arg = { amount = 1 } })
    end)
  end,
})

return json.encode(app:build())
```

两条约定：

**参数顺序统一「属性在前、子节点在后」**，`b:column({...}, function(b) ... end)`。
只写子节点时可以省掉属性位：`b:column(function(b) ... end)`。

**子节点是语句式的** —— 回调里写的每一句自动成为子节点，
不用 `return`，也不用手写数组。

### 事件怎么回到 Lua

事件不是回调，而是**事件名**——宿主每次执行都重建 Lua state，回调活不过一次执行。

```
点击 → rfw 报出事件名 → 宿主把「名字 + 上轮状态」送回 Lua
     → ui.dispatch 找到 handler 改状态 → 重新出一棵树 → 宿主换树
```

所以 `app.state` 里声明的是**初始值**，宿主回传的状态优先于它。
（反过来的话每次点击都会把状态拉回初始值，表现为「点一下归零」，
而且界面看上去完全正常。）

实测往返 **1–3 毫秒**。

### 宿主自定义组件

rfw 内置的库没有 Switch，Slider 也只是「只读展示」的语义。
`lib/ui_view.dart` 注册了一个本地库 `studio`，树里写 `studio.Toggle` /
`studio.Slider` / `studio.Kpi` 就能用——**Lua 下发的内容不限于 Flutter 自带控件**。

### 数值类型是个坑（真的踩过）

rfw 的 `DataSource.v<T>()` 实现是 `value is T ? value : null`：
**类型不符就静默丢参数**，控件退回默认值，画面照样正常显示。

而纯 Lua 的 JSON 编码器用 `%.14g`，会把 `40.0` 打成 `40`，
解析出来就是整数，于是所有 `v<double>` 的参数（width / fontSize /
padding / min / max…）全部被丢弃。

这个 bug 是在真机上手动拖滑条才发现的：`slider(min=0, max=100)`
的 `max` 被丢掉，Flutter 那边成了 0..1，事件里带的是 `0.9` 而不是 `90`。
单测全绿——因为没有测试会去检查"参数有没有被对端接受"。

现在两端都修了（编码器保留 `.0`；DSL 里 `num` 产出浮点、`int` 产出整数），
并在 `ui_spec.lua` 与 `verify_ui_ast.dart` 里各加了一组类型断言。

## 两处不该手工处理的东西

**Lua SDK** —— 由 [flutter_lua_bridge](https://github.com/yang-lile/flutter_lua_bridge)
的 Dart hooks（code assets）自动构建并打包。不要手动编译 dylib、导出符号、
往 Frameworks 里拷文件，也不需要重签名。手写 FFI 绑定踩过的坑
（`lua_pcallk` 是 6 参、`size_t` 要 `IntPtr`、字符串长度必须是 UTF-8 字节数）
这个库都已经封装好了。

**Lua 代码** —— 通过 `pubspec.yaml` 的 `assets` 声明打包，运行时用
`rootBundle` 读取（见 `lua_loader.dart`）。不要手工往
`Contents/Resources` 里拷文件。

> `native/` 目录是早期手写 FFI 时代的遗留，**已不再使用**，保留仅为参考。

## Lua 模块清单机制

Flutter assets 不会递归列目录，所以模块索引靠
`assets/lua/manifest.txt`：

```
assets/lua/manifest.txt      # 清单，LuaLoader 消费
assets/lua/canvas/init.lua
assets/lua/host/cli.lua
...
```

两个脚本保证一致性：

```bash
bash tools/check_manifest.sh   # 校验清单与磁盘文件一致
bash tools/gen_assets.sh       # 从清单生成 pubspec 的 assets 声明
```

新增 Lua 模块时：加文件 → 更新 `manifest.txt` → 跑 `gen_assets.sh`。
漏掉的模块只会在运行时报 `require not found`，所以构建期校验是必要的。

## Lua 与 Dart 的数据契约

Lua 侧：

```lua
local c = canvas.new({ width = 900, height = 600, background = "#0f1116" })
c:rect(16, 76, 278, 246, { radius = 8, fill = "#1a1d24" })
c:text(30, 98, "gateway", { size = 14, color = "#e6e9ef" })

local list = c:build()   -- 已含 fingerprint，不用手动补
```

`fingerprint` 由 `build()` 自己算好，宿主靠它跳过无变化的重绘。
**不要在调用侧手动补这个字段** —— 曾经 `build()` 自己漏了它，
而调用方（`gen_gallery.lua`）手动补上，结果画廊正常、Studio 卡在第一帧。

Dart 侧：

```dart
final list = DisplayList.fromJson(json);
renderer.render(canvas, size, list);  // 内部比较指纹决定是否真画
```

图元类型：`circle` / `rect` / `line` / `text` / `polygon`。

### 组件模式的契约

Lua 侧产出一个信封：

```lua
return json.encode(app:build())
-- { version=1, widget="root", title=..., state={...}, events={...},
--   tree={ ["$widget"]="Column", ["$args"]={...} }, node_count=19,
--   fingerprint="97fb25fe00000000" }
```

树里只有三种值：

| Lua 产出 | 契约 | rfw |
|---|---|---|
| `{ ["$widget"]=..., ["$args"]=... }` | `UiNode` | `ConstructorCall` |
| `{ ["$event"]=..., ["$arg"]=... }` | `UiEvent` | `EventHandler` |
| 数字 / 字符串 / 布尔 / 数组 | 原样 | 参数值 |

用 `$` 前缀区分保留语义，普通数据 map 里就算有 `name` 之类的键也不会被误认成节点。

Dart 侧：

```dart
final tree = UiTree.parse(json);           // 纯数据模型
final library = buildUiLibrary(tree);      // -> RemoteWidgetLibrary
runtime.update(kRemoteLibrary, library);   // 交给 rfw 渲染
```

`UiTree.validate()` 做交叉校验：Lua 自报的节点数与 Dart 数出来的必须一致，
树里引用的事件必须已注册，注册了却没人触发的会提示。

## 沙箱语义

编辑器里每次执行都是**全新的 LuaState**，执行完立即销毁。理由：

> 复用会导致全局变量泄漏，出现"删了一行代码但行为没变"这类难排查的问题。

### 用户代码是返回显示列表的函数

```lua
local c = canvas.new({ width = 360, height = 200 })
c:circle(70, 70, 40, { fill = "#4a9eff" })
return json.encode(c:build())
```

Dart 侧的流程：`load` 成函数 → `getGlobal` 取到 → `call` 调用 → 读返回值。
用 Lua 原生的返回值语义，没有魔法全局变量。

也支持显式返回函数（能带参数、便于拆分复用）：

```lua
return function(scale)
  local c = canvas.new({ width = 300 * scale, height = 200 })
  -- ...
  return json.encode(c:build())
end
```

`buildStudioSource` 会检测用户是否写了 `return function`：
写了就原样用，没写就自动包一层——所以写片段和写完整文件都自然。

### 组件模式的用户代码是一段立即执行的 chunk

同一个沙箱里第二个入口 `runUi`。差别只有一个：**不包函数**，直接执行——
因为 `ui.app` 执行时就把 app 登记到模块级槽位，事件分发不必重跑视图。

```
构建阶段：load(chunk) → 调用 → 返回值就是契约信封
事件阶段：load(chunk) → 调用（注册 app）→ ui.dispatch(名字, 参数) → 新信封
```

状态注入在两步之间：`ui.seed_state(__studio_state)`。
**漏掉这一步的表现是「每次点按钮状态都回到初始值」，界面看上去完全正常。**

`print` 输出由沙箱在 Lua 侧收集后随执行结束回传，不需要在 Dart 侧
注册 C 回调（那会引入 FFI 回调指针在 state 销毁后变野指针的风险）。

### 执行在独立 isolate 里

Lua 通过 FFI 调用是**同步阻塞**的。如果跑在 UI isolate 上，
执行期间事件循环完全停摆——实测 20 万图元要 1105ms，
这段时间界面僵住，连防抖定时器都触发不了。写个 `while true do end`
窗口就永久冻结。

所以 `lib/lua_worker.dart` 把 Lua 放进常驻 worker isolate：

```
主 isolate                    worker isolate
  │ 发代码 ────────────────────► │
  │                              │ FFI 调用（同步、阻塞）
  │                              ▼
  │ ◄──── 错误 / 显示列表 JSON ── │
```

实测：worker 就绪 4ms，首轮 437ms（含 FFI 绑定），之后每轮 1–2ms。

### 死循环由 Lua 自己中断

`isolate.kill()` **打断不了正在执行的 FFI 调用**——实测 kill 一个跑着
Lua 死循环的 isolate，它永远不会退出。所以保护必须由 Lua 侧完成：

`canvas.wrap(fn, ms)` 用 `debug.sethook` 的计数模式，每 1000 万条指令
查一次时钟，超预算就抛错跳出。宿主在 `__studio_fn` 就位后调它装上保护。

**必须在 Lua 侧装，不能在 Dart 侧包一层。** 实测从 Dart 侧调
`doString('__studio_fn = canvas.wrap(...)')` 会导致执行挂起——
`doString` 底层是 `luaL_loadstring`（含 pcall），与 `wrap` 内部的
pcall 冲突。所以 `studioGuardSetup` 是一个独立的 Lua chunk。

实测：死循环 300ms 预算下在 604ms 返回，worker 保持健康无需重启；
主 isolate 的 300ms 定时器实际只延迟 302ms（未被阻塞）。

业务代码也可以手动用：

```lua
local guard = require("canvas").guard
return guard(function()
  -- 绘制逻辑
end, 1000)  -- 1000ms 预算
```

## 常用 API

| 类别 | 方法 |
|---|---|
| 创建 | `canvas.new{width, height, background}` |
| 图元 | `c:circle(x,y,r,style)` `c:rect(x,y,w,h,style)` `c:line(x1,y1,x2,y2,style)` `c:polygon(points,style)` `c:text(x,y,str,style)` |
| 输出 | `c:build()` 产显示列表、`c:hash()` 内容指纹、`c:clear()` 清空 |
| 保护 | `guard(fn, ms)` 在时间预算内执行并抛错中断 |
| 样式 | `fill` `stroke`（`#rgb`/`#rrggbb`/`#aarrggbb`）、`stroke_width`、`radius`、`size`、`align` |

完整说明见 `gallery.html`（浏览器打开，左代码右结果 + API 参考表）。

### 组件模式的 API

| 类别 | 方法 |
|---|---|
| 应用 | `ui.app{state, handlers, view}`、`app:build()`、`ui.dispatch(name, args)` |
| 布局 | `b:column(props, kids)` `b:row` `b:box` `b:pad` `b:center` `b:expand` `b:spacer` `b:scroll` |
| 内容 | `b:text(str, props)` `b:icon(name, props)` `b:button(label, props)` `b:card` `b:divider` `b:progress` |
| 交互 | `b:toggle` `b:slider`（宿主自定义组件 `studio.*`） |
| 自定义 | `b:kpi(label, value, props)` 演示「一个 Lua 函数 = 一个组件」 |
| 样式 | `display` `title` `subtitle` `body` `label` `caption` `mono`，可被 `color` / `style` 覆盖 |

属性名在 Lua 侧就校验，拼错会列出该控件支持的全部属性
（`ui: column 不支持属性 'gapp'。可用: align, gap, main, size`）。


### 画布要当参数传

`canvas.new()` 每次返回**一块独立画布**。在辅助函数里新建画布，
画的东西全进那块临时画布，返回值一被丢弃外面就什么都没有——
表现为「代码跑通了但画面空白」。

```lua
-- 错：函数内新建，画完就丢
local function draw_dial(cx)
  local c = canvas.new({ width = 300, height = 300 })
  c:circle(cx, 150, 60)
  return c          -- 这个 c 被调用方忽略，外层画布是空的
end

local canvas1 = canvas.new({ width = 300, height = 300 })
draw_dial(90)       -- 外层 op_count 仍是 0

-- 对：把画布传进去
local function draw_dial(c, cx)
  c:circle(cx, 150, 60)
end

local canvas1 = canvas.new({ width = 300, height = 300 })
draw_dial(canvas1, 90)
draw_dial(canvas1, 210)
```

编辑器里的「带参数的函数」示例踩过这个坑，已修正。
`tools/verify_snippets.dart` 会执行所有示例并断言 `op_count > 0`，
这类问题以后会被立刻拦下。

## 性能

`make bench` 跑流水线基准（冷启动 / 规模扫描 / 事件往返 / 长期稳定性），
并与 `tools/bench_baseline.json` 里的基线**相对比较**。

绝对值在这个环境里没有意义（换台机器就差几倍），所以判定标准是
「相对基线劣化超过阈值」，阈值按**实测波动**定的：

```
同一台机器连跑三次的波动：
  fixed.bootstrap    0.569 / 0.493 / 0.582 ms    ±8%
  scale.canvas.1000  15.9 / 12.8 / 16.4  ms     ±13%
  scale.ui.1000      60.1 / 53.5 / 60.9  ms     ±7%
=> 阈值取 25%（固定成本/规模）、40%（冷启动）
```

基准会在开跑前检查机器负载并提醒 —— 实测有残留进程时同样的代码
**能虚高 2 倍**，不提醒的话会让人去追一个不存在的性能回归。

```bash
make bench                          # 跑并与基线比较
dart run tools/bench_pipeline.dart --update   # 换机器 / 环境变了就更新基线
```

### rfw 的重建成本（`flutter run -t lib/bench_rebuild.dart`）

扣掉 60Hz 的 vsync 地板（16.67ms）后的 2×2 矩阵，每项 10 次取中位数：

| 规模 | 换库·平铺（现状） | 换库·组件化 | 改 data·全读 | 改 data·1 个读 |
|---|---|---|---|---|
| 50 | 2.53 ms | 0.98 ms | <0.01 | 0.22 |
| 200 | 30.73 ms | 26.39 ms | 0.19 | 0.25 |
| 500 | 72.80 ms | 61.16 ms | <0.01 | <0.01 |
| 1000 | 135.09 ms | 132.27 ms | 0.14 | 0.88 |

**结论：组件化单独做几乎没用（2–14%），原生状态是全部（<1ms）。**

换库的花费不在 rfw 遍历 AST 上 —— `runtime.update` 清空所有
`_CurriedWidget` 缓存，N 个实例照样要重新 curry、重新 build，
200 个 `Column`/`Row`/`ElevatedButton` 本身就很贵。AST 小 6 倍只换来 14%。

所以架构应该**按变更路径选粒度**，不是「把树做小」：

```
编辑时（防抖 0.4s）  runtime.update 全量重建   40–135ms   可以接受
交互时（点击）        rfw 原生 state / data    <1ms       必须走这条
```

> 测量方法：用 data 变更代理 state 变更。两者最终都落到
> `_WidgetState.updateData` → `setState`，是同一套订阅机制。
> 不直接触发 state 写入是因为它只能由交互控件在 build 期间调用
> `source.voidHandler`，而这里没有 `flutter_test` 的 TestGesture。


关键结论：

- **跨 Dart 互操作几乎免费**：isolate 调度 + 消息投递只占单次执行的 11%
- **钱在 Lua 侧**：每次执行都要重建 LuaState、重新解析模块、跑用户代码
- 组件模式每节点比画布贵 5–6 倍（已优化，从 61µs/节点降到 43µs/节点）
- 1000 节点以上会顶爆 60fps 的 16ms 预算，这是真正的瓶颈
- 2000 次执行漂移在 ±2% 内，重建 LuaState 不累积劣化

三处主要优化（细节见 ARCHITECTURE.md「性能」一节）：

1. **内容指纹去掉逐层 `table.sort`** —— 6000 节点树上 80ms → 39ms
2. **运行时预编译字节码** —— 每次执行省下 0.55ms 的重复解析。
   必须在运行时 dump：字节码与解释器版本绑定，生成它的工具链和应用内嵌
   解释器可能随环境变化，运行时生成可以避免加载旧产物
3. **只开声明过的标准库** —— 省下的时间可忽略，但它让"业务代码不碰 io"
   从一句空话变成真的做不到

## 验证

`make test` 汇总所有检查。

```bash
lua  assets/lua/spec/canvas_spec.lua    # 画布 Lua 侧 46 个用例
lua  assets/lua/spec/ui_spec.lua        # 组件 Lua 侧 72 个用例
lua  assets/lua/spec/perf_spec.lua      # 热点策略注册表 49 个用例
python3 tools/verify_contract.py       # 跨语言契约 15 项（含重绘决策）
dart run tools/verify_return.dart      # return 语义 20 个用例
dart run tools/verify_worker.dart      # worker isolate 29 个用例
dart run tools/verify_guard.dart       # 执行预算 10 个用例
dart run tools/verify_snippets.dart    # 画布预设示例 17 个用例
dart run tools/verify_ui_snippets.dart # 组件预设示例 25 个用例
dart run tools/verify_ui_ast.dart      # UI 契约 -> rfw blob 54 个用例
dart run tools/verify_bytecode.dart    # 字节码预编译 15 个用例
dart run tools/verify_change_detect.dart # 内容变化检测 71 个用例
flutter analyze                        # 静态检查
```

`make test` 把它们串起来（**354 个用例**），也可以按 `make test-ui` /
`make test-bytecode` 单独跑某一部分。

`verify_bytecode.dart` 的验证手法值得一提：它把 `.lua` 源码**全部改名**，
只留 `.luac` 再跑一遍 —— 能跑通就说明执行时确实走了字节码。
只断言"字节码文件存在"是不够的：版本不匹配、路径模板写错、
magic byte 校验失败，Lua 都会**静默跳过字节码**改用源码，
那种情况下文件照样在，跑的却还是源码。

`verify_contract.py` 用**真实 Lua 产出**的数据校验 Dart 侧解析，
任何一侧改了字段名都会立刻失败。其中一项专门验证
`shouldRepaint` 的判定逻辑——`fingerprint` 缺失时必须保守重绘，
否则画面会静默停在第一次（这个 bug 真实发生过）。

### 为什么 UI 那两个脚本能在没有引擎的情况下跑

rfw 把「格式层」拆成了**不依赖 `dart:ui`** 的 `package:rfw/formats.dart`
（它自己的注释说这是给服务端生成 library blob 用的）。
`lib/ui_rfw_ast.dart` 只 import 它，于是

```
真实 Lua → 契约解析 → RemoteWidgetLibrary → encodeLibraryBlob → decodeLibraryBlob
```

整条链都能在纯 Dart VM 里跑完，`verify_ui_ast.dart` 就是这么做的：
它证明产出的字节是**合法的 rfw 远端库**，也就是真实场景里服务端能直接发出去的那份。
唯一需要引擎的 `RemoteWidget` 渲染，留在 `lib/ui_view.dart` 由应用本身验证。

## 尺寸与缩放

显示列表的坐标就是**像素坐标**。Lua 写 `canvas.new({width = 900, height = 600})`，
画布就是 900×600 像素。

**默认 1:1**，一个逻辑像素对应一个物理像素，所见即所得：

```
画布实际尺寸 = 显示列表逻辑尺寸 × 缩放倍率
```

缩放倍率由工具栏的滑条控制（25% ~ 800%，10 档），
配 `-` `+` 按钮和倍率显示，点倍率数字回到 100%。

画布比视口大时可**拖动查看**各部分（`InteractiveViewer`，
左上角锚定）。装得下时就是静态居中，不提供无意义的平移。

统计栏显示 `画布 900×600 px`（缩放后的实际像素）、
`缩放 100%`，放大时额外显示 `原始 900×600`。

旁边还有个边界开关（`crop_free` 图标），控制是否画一圈画布边框。
**不用棋盘底**——每帧几千个 `drawRect` 会把 UI 拖死，
边框线已经足够说明画布范围。

> **不要在 `render()` 里做"内容没变就跳过绘制"的判断。**
> 早先的 `needsRepaint` 提前 return 就是窗口 resize 后图像消失的原因：
> 跳过*重绘决策*不等于跳过*绘制*——画布尺寸依赖运行时才知道的视口。
>
> `CustomPainter` 拿不到容器尺寸，所以用 `LayoutBuilder` 监听变化并递增
> `revision`，`shouldRepaint` 比较它。

## 内容变化检测

判断"内容变了没有"用的是**两段式**：

1. **指纹相同 → 直接相同**（O(1)，Lua 侧算的哈希当快路径）
2. 指纹不同或缺失 → **结构比较**（`lib/deep_equality.dart`，权威）

以前只有第 1 步，而指纹是**哈希**——会碰撞。碰撞的表现是
**静默漏更新**：画面停住不刷新，界面上完全没有报错。
早期的内容指纹就漏过字段，而单测全绿。

`verify_change_detect.dart` 逐字段改动验证（几何、颜色、字号、
圆角、多边形顶点、事件名、事件参数……），因为"漏更新"这种 bug
靠跑一遍看看是发现不了的 —— 它在绝大多数时候都对。

比较发生在**原始 JSON** 上而不是解析后的对象上：`DisplayList` 里的
`DrawOp` 用 `dart:ui`，纯 Dart VM 跑不起来，而这个项目的测试全靠
纯 Dart 入口。顺带也避免了"两套解析规则不一致"的风险。

## 已知边界

- `json` 是纯 Lua 实现，生产环境应换成 cjson之类的 C 实现
- 字体由系统提供，跨平台渲染有细微差异；需要像素级一致得内嵌字体
- `flutter_lua_bridge` 内置的是 **Lua 5.4**，
  `debug.sethook` 与 `os.clock` 都可用
- 死循环靠 Lua 侧的 `canvas_guard` 中断，**不能靠 `isolate.kill`**——
  实测 kill 打断不了正在执行的 FFI 调用，被 kill 的 isolate 永不退出
- 诊断时 Flutter 会警告 `flutter_lua_bridge` 的 code asset 在不同架构下
  framework 命名不一致，这是上游包的 build hook 问题，不影响运行
