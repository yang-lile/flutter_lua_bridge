# 架构说明

一句话：**Lua 只描述，宿主负责"怎么做"。**

两条产出链路共用同一套约定：

```
画布模式：Lua → DisplayList → CustomPaint → 画面
组件模式：Lua → UiTree → RemoteWidgetLibrary → rfw → 画面
```

## 为什么不是"逐条调用"

假设 Lua 直接调 `canvas.circle(x, y, r)`：

- 每帧 60fps × 数百图元 = 数万次 FFI 跨界调用，开销无法接受
- 无法脱离 Flutter 做单元测试
- 无法缓存、无法 diff、无法回放

声明式显示列表（DisplayList）把这三点都解决了：

1. 每帧只有**一次**跨界调用（代码进、JSON 出）
2. 显示列表是纯数据，Lua 侧和 Dart 侧都能完整断言
3. 内容指纹可缓存、可 diff，宿主据此跳过无变化的重绘

## 关键文件

按重要性排序。画布链路前六个 + 组件链路四个。

### 1. `lib/sandbox.dart` — Lua 执行

把用户代码变成函数、取回返回值。

```lua
-- 用户写的
local c = canvas.new({ width = 360, height = 200 })
c:circle(70, 70, 40, { fill = "#4a9eff" })
return json.encode(c:build())
```

Dart 侧的流程：

```
doString(prelude)                      预置 host/canvas/json 全局
doString('local f = load(chunk)...')   加载成函数，取到 __studio_fn
doString('__studio_fn = canvas.wrap(...)')  装执行保护（可选）
getGlobal('__studio_fn') + _call()     调用，读返回值
```

每次执行都重建 `LuaState`、执行完立即销毁。理由是复用会导致全局变量泄漏，
出现"删了一行代码但行为没变"这类极难排查的问题。

**`buildStudioSource` 的两种写法**：写了 `return function` 就原样用，
没写就自动包一层——所以写片段和写完整文件都自然。

### 2. `lib/lua_worker.dart` — 独立 isolate 执行

Lua 通过 FFI 调用是**同步阻塞**的。跑在 UI isolate 上的话，
执行期间事件循环完全停摆——实测 20 万图元要 1105ms，
这段时间界面僵住，连防抖定时器都触发不了。写个 `while true do end`
窗口就永久冻结。

所以 Lua 跑在常驻 worker isolate 里：

```
主 isolate                    worker isolate
  │ 发代码 ────────────────────► │
  │                              │ FFI 调用（同步、阻塞）
  │                              ▼
  │ ◄──── 错误 / 显示列表 JSON ── │
```

实测：worker 就绪 4ms，首轮 437ms（含 FFI 绑定），之后每轮 1–2ms。

新编辑到达时会"取代"旧执行：旧请求立刻完成为「已被新的编辑取代」，
worker 重启。这是编辑器场景的正确语义——丢弃过时结果而非排队。

### 3. `assets/lua/canvas/init.lua` — 画布能力

产出声明式显示列表，含参数校验与内容指纹。

```lua
function Canvas:build()
  return {
    version = 1,
    width = self.w, height = self.h,
    background = self.bg,
    ops = self.ops,
    op_count = #self.ops,
    fingerprint = self:hash(),   -- 必须有，宿主靠它判断重绘
  }
end
```

**`fingerprint` 必须由 `build()` 自己输出。** 少了它，宿主拿到 null 后
`null != null` 为 false，画布永远停在第一次绘制，而界面看起来完全正常。
曾因此 bug 很久——因为测试替身手动补了这个字段，把问题掩盖了。

**协作式中断** `canvas_guard(fn, ms)` / `canvas_wrap(fn, ms)`：

```lua
local function wrap(fn, ms)  -- 返回包装函数，不执行
  return function(...)
    debug.sethook(function()
      if os.clock() - start > limit / 1000 then
        debug.sethook()
        error("执行超时...")
      end
    end, "", 10000000)
    local r = table.pack(pcall(fn, ...))
    debug.sethook()
    ...
  end
end
```

`isolate.kill()` **打断不了正在执行的 FFI 调用**——实测 kill 一个跑着
Lua 死循环的 isolate，它永远不会退出，进程也被拖住。所以死循环只能由
Lua 自己从内部抛错跳出。

### 4. `lib/display_list.dart` — 契约数据模型

纯数据，无任何 Flutter 类型。这让两侧测试都能脱离引擎运行。

`sameAs` 用**保守策略**：只有双方都有指纹且相等时才判定为未变化。
任一方缺指纹一律判定为变化——宁可多渲染一帧，也不能漏掉更新。

### 5. `lib/display_list_renderer.dart` — 批量渲染

唯一接触 Flutter 绘制 API 的文件。

```
画布实际尺寸 = 显示列表逻辑尺寸 × 缩放倍率（默认 1.0）
```

1:1 时一个逻辑像素对应一个物理像素。放大由用户拖滑条控制。
`CustomPaint` 的 `size` 用显式 `SizedBox` 表达，不能指望它自动撑开。

**不要在 `render()` 里做"内容没变就跳过绘制"的判断。** 早先的
`needsRepaint` 提前 return 就是窗口 resize 后图像消失的原因：
跳过*重绘决策*不等于跳过*绘制*——画布尺寸依赖运行时才知道的视口。

### 6. `lib/main.dart` — 编辑器 UI（画布 / 组件双模式）

左代码右预览。执行链路：

```
输入 → 400ms 防抖 → worker.run() → 解析 JSON → setState
```

启动期有约 1 秒空窗（assets 落盘 234ms + 首启 FFI 绑定 831ms）。
期间的编辑用 `_pendingRun` 记下，就绪后补跑——早期版本是静默丢弃，
表现为"自动运行没反应"。

`_runSeq` 递增序号用于丢弃过期结果：用户连续编辑时，
只有最后一次的结果该被采纳。

### 7. `lib/ui_tree.dart` — widget 树模型

纯数据，与 `display_list.dart` 同一套规矩（不含 Flutter 类型）。
额外做交叉校验：Lua 自报的节点数与 Dart 数出来的必须一致，
树里引用的事件必须已注册。

**空数组当空 map 处理**：Lua 的 JSON 编码器把空 table 编成 `[]`，
所以 `$args = {}` 到 Dart 手里是 `[]`。只放宽"空"这一种情况，
非空数组仍然报错（否则把 children 塞进 `$args` 就查不出来了）。

### 8. `lib/ui_rfw_ast.dart` — 树 -> rfw

只 import `package:rfw/formats.dart`。见下文「树 -> rfw 这一步刻意不用 Flutter」。

### 9. `lib/ui_view.dart` — rfw 渲染 + 自定义组件

唯一接触 Flutter 渲染 API 的 UI 文件。
注册三个本地库（widgets / material / studio）与 `RemoteWidget`。

**指纹相同就不 update**：`Runtime.update` 会 notifyListeners，
而 RemoteWidget 收到通知就整个重建 subtree。

### 10. `lib/driver_main.dart` — 带 driver 扩展的入口

正式入口不引 flutter_driver。要真实点击验证时用它。

## 能力契约层

`assets/lua/host/init.lua`。业务 Lua 不直接碰 io / os / 网络：

```lua
local host = require("host")
local json = host.require_cap("json", { reason = "解析远端配置" })
```

好处是依赖显式——启动时校验能力是否齐全，而不是运行到一半报 nil。
换 mock 宿主就能离线跑测试。

## 画布要当参数传

`canvas.new()` 每次返回**独立画布**。在辅助函数里新建画布，
画的东西全进那块临时画布，返回值一被丢弃外面就什么都没有：

```lua
-- 错
local function draw_dial(cx)
  local c = canvas.new({ width = 300, height = 300 })
  c:circle(cx, 150, 60)
  return c                    -- 被调用方忽略
end
local c = canvas.new({ width = 300, height = 300 })
draw_dial(90)                 -- c.op_count 仍是 0

-- 对
local function draw_dial(c, cx)
  c:circle(cx, 150, 60)
end
```

`make test-snippets` 会执行所有预设示例并断言 `op_count > 0`。

## 踩过的坑（都已修复，勿重犯）

| 坑 | 症状 | 根因 |
|---|---|---|
| `build()` 漏 `fingerprint` | 画面永远停在第一次，无报错 | `null != null` 为 false；测试替身手动补字段掩盖了 |
| `render()` 提前 return | 拖窗口图像消失 | 跳过重绘决策 ≠ 跳过绘制 |
| 棋盘底背景 | UI 拖死无响应 | 每帧 12500 次 `drawRect` |
| 辅助函数内 `canvas.new` | 跑通但画面空白 | 画布所有权错位 |
| 变量插值旁有全角括号 | `MODE?: unbound variable` | bash 把全角 `）` 当变量名一部分 |
| `isString` 对数字也返回 true | `return 123` 被当合法结果 | Lua 数字可转字符串，需再排除 number |
| Lua 空 table 编成 `[]` | Dart 端 `$args` 必须是 table | Lua 分不清空 table 和空数组 |
| JSON 里的整数被 rfw 静默丢弃 | `slider(max=100)` 变成 0..1 | `v<double>()` 是 `value is T ? value : null` |
| `x and nil or y` | 条件成立时也走进 `y` 分支 | `x and nil` 恒为假值 |
| `end` 作 table key | 语法错误 | `end` 是关键字，要写 `["end"]` |
| 子节点作用域收集栈写脏 | 后续渲染整个错位 | 回调抛错时必须还原收集栈 |

## 组件模式（UI）的几个关键决定

### 状态归 Lua，不归宿主

宿主只做两件事：把树喂给 rfw、把事件名送回去。

```
点击 → rfw EventHandler 触发 → onEvent(名字)
     → 宿主重跑用户代码 + ui.dispatch(名字, 参数)
     → handler 改 app.state → 重新 build() → 换树
```

`app.state` 声明的是**初始值**，宿主回传的状态优先。
反过来每次事件都会把状态拉回初始值，表现为「点一下归零」，
而且界面完全正常。

代价是每次事件都要重跑一次代码（实测 1–3ms，可接受）；
换来的是宿主没有任何需要和 Lua 同步的状态——不存在"两边不一致"的第三种情况。

### 事件是名字，不是回调

宿主每次执行都重建 LuaState，回调活不过一次执行。
契约里传的是 `{"$event": "inc"}`，Lua 侧查表找 handler。

### 树 -> rfw 这一步刻意不用 Flutter

`lib/ui_rfw_ast.dart` 只 import `package:rfw/formats.dart`（rfw 自己声明
不依赖 `dart:ui`），于是"真实 Lua 产出 -> 合法 rfw 远端库字节"这条链
能在纯 Dart VM 里跑完。rfw 官方的服务端就是这么用的。

需要引擎的只有 `RemoteWidget` 真正渲染那一步，留在 `lib/ui_view.dart`。

### 自定义本地库

rfw 没有 Switch。`createStudioWidgets()` 注册一个叫 `studio` 的
LocalWidgetLibrary，key 直接写全名（`studio.Toggle`）——
rfw 的 `LocalWidgetLibrary.findConstructor` 是按字符串直接查表，不拆前缀。

`kBuiltinWidgets` 是手抄的常量，启动时会和 `createCoreWidgets().widgets.keys`
对账，不一致就在界面上提示，免得 rfw 升级后满屏 ErrorWidget 才发现。

### 数值类型必须显式区分

**这条是跑真实界面才发现的**，单测全绿的时候它是坏的。

rfw 的 `DataSource.v<T>()` 实现是 `value is T ? value : null`：
类型不符就静默返回 null，参数被丢掉、控件用默认值，**画面照样正常**。

而纯 Lua 的 JSON 编码器用 `%.14g`，把 `40.0` 打成 `40`，
解析出来是整数 → 所有 `v<double>` 的参数（width / fontSize / padding /
min / max）全部失效。

表现是：`slider(min=0, max=100)` 的 max 被丢掉，
Flutter 那边成了 0..1，拖到最右事件里带的是 `0.9` 而不是 `90`。

修法两端都改：编码器给浮点补 `.0`；DSL 里 `num` 产出浮点、`int` 产出整数。
并加了两组断言（Lua 侧查 `math.type`，Dart 侧查 `runtimeType`）。

**教训：需要跨进程/跨语言时，"数值类型"和"字段名"一样是需要测的契约。**
只测"字段在不在"不够——rfw 这类解码器对类型不符是静默的。

### 诊断不能从 build 里回调出去

`LuaUiView` 的校验在 `initState` / `build` 里跑，而 `onWarning`
的实现方会 `setState`。在 build 期间 setState 会抛
`setState() or markNeedsBuild() called during build`，
而且报错位置指向**正在构建的子树**（rfw 的 DefaultTextStyle），
不是真正的罪魁祸首，极难定位。

所有诊断一律缓到 post-frame callback 再发出去。

## 性能：钱花在哪（`make bench` 实测）

先说结论：**损耗几乎全在 Lua 侧执行，跨 Dart 互操作本身几乎免费。**

```
从主 isolate 看一次 run 的总延迟        0.63 ms
  其中 worker 内部自报                 0.60 ms   <- 引导 + 执行 + 编码
  差额（isolate 调度 + 消息投递）      0.07 ms   <- 只占 11%
```

优化前后的规模扫描（单位 ms）：

| 产出规模 | 画布（图元） | 组件（节点） |
|---|---|---|
| 10 | 0.69 → 0.58 | 1.70 → 1.23 |
| 100 | 1.63 → 1.50 | 6.54 → 4.79 |
| 1 000 | 10.8 → 10.9 | **60.0 → 43.3** |
| 10 000 | 104 → 100 | **679 → 448** |
| 每次执行的固定成本 | 0.53 → **0.42** | 同左 |

### 1. 内容指纹（最大头，已优化）

早期 ui 的指纹为了保证 `pairs` 顺序无关，对**每一层 table 做一次 `table.sort`**。
在 6000 个节点的树上，这��项就 80ms，是 `app:build()` 总耗时（94ms）的大半。

改成顺序无关的累加（加法混合，不用异或——异或会让 `a^b^a == b`）：

```
逐层 table.sort        80.02 ms
顺序无关累积（无 sort） 39.13 ms    <- 减半
```

顺带修了一个自己引入的 bug：第一版把**全局**计数混进每个表，
导致同一棵树连续 build 两次指纹不同（`pairs` 顺序随机），
表现为宿主白白重绘。已改成每个表用自己的计数，并加了 2000 次求值稳定的断言。

### 2. 每次执行都在重新解析 Lua 源码（隐藏的大头）

沙箱每次执行都重建 `LuaState`（这是有意的：复用会导致全局变量泄漏）。
代价是**每次都要把全部模块重新 parse 一遍**：

```
解析源码      0.629 ms      <- 基本等于整条链路的固定成本
加载字节码    0.075 ms      <- 快 8 倍
```

所以加了一步**运行时预编译**：worker 启动前把打包模块 `string.dump` 成 `.luac`
写到临时目录，`package.path` 把 `?.luac` 排在 `?.lua` 前面。

**为什么必须在运行时 dump**：Lua 字节码与解释器版本绑定。生成它的工具链和
应用内嵌解释器可能随环境变化，旧字节码会直接报 bad header，所以只能由将要
加载它的解释器自己生成。

固定成本 0.53 → 0.42ms。剩下的 0.27ms 是**执行模块顶层代码**（建表、定义闭包），
这是"每次重建 state"架构的固有代价，要再降就得改架构了。

### 3. 选择性开标准库（**不是**性能优化，是兑现契约）

实测开全量库 0.015ms、只开引导集 0.010ms —— 省 0.005ms，可以忽略。

但仍然做了，因为 `host/init.lua` 一直声称"业务 Lua 不直接碰 io / os"，
而 `openLibs()` 把 io 也开了，契约只是一句空话。现在各模块通过
`perf.declare_libs()` 声明需求，宿主据此只开 `string/table/math/os/debug/package`。
用户代码里写 `io.write` 会直接报 `attempt to index a nil value (global 'io')` ——
**开了门就等于没锁**。

### 4. 跨 isolate 发什么，比序列化本身更贵

| 发送内容（1000 节点 / 73KB） | 耗时 |
|---|---|
| JSON 字符串 | 0.014 ms |
| `Uint8List` | 0.026 ms |
| `TransferableTypedData` | 0.027 ms |
| **Dart 对象树（Map/List 嵌套）** | **0.355 ms** |

所以"栈上解析成 Dart 对象树再发回去"这个最直观的方案反而最贵 ——
VM 拷贝对象图比拷贝一个 String 贵一个数量级。

## 热点策略注册表（`assets/lua/perf.lua`）

优化散落在三处很容易漏（canvas 和 ui 曾经各写了一份指纹）。
注册表把「每次执行都要跑的热点」集中起来：

```lua
perf.register("fingerprint", "fast", impl, { desc = "...", default = true })
perf.use("fingerprint", "canonical")     -- 可切换
perf.get("fingerprint")

perf.declare_libs("ui", { "string", "table", "math" })
local mask, names = perf.lib_mask()      -- 宿主据此开库
```

三件事挂在上面：内容指纹策略、JSON 数字策略、标准库需求声明。

`perf` 刻意**不 require host** —— `host/init.lua` 要用它登记库需求，
反过来就成循环依赖（Lua 直接报 "loop or previous error loading module"）。
保持 perf 是纯模块，由 host 在自己加载完后挂成能力。

## rfw 重建：组件化基本没用，原生状态是全部

`flutter run -t lib/bench_rebuild.dart` 的 2×2 矩阵（已扣掉 60Hz vsync
的 16.67ms 地板；每项 10 次取中位数）：

| 规模 | 换库·平铺（现状） | 换库·组件化 | 改 data·全读 | 改 data·1 个读 |
|---|---|---|---|---|
| 50 | 2.53 ms | 0.98 ms | <0.01 | 0.22 |
| 200 | 30.73 ms | 26.39 ms | 0.19 | 0.25 |
| 500 | 72.80 ms | 61.16 ms | <0.01 | <0.01 |
| 1000 | 135.09 ms | 132.27 ms | 0.14 | 0.88 |

（"改 data" 用的是 rfw 原生的按 key 订阅路径，与 `set state.x` 同一套机制。）

### 三个结论

**1. 组件化单独做几乎没用。** AST 节点数少了 6 倍，代价只降 14%（200 项）
到 2%（1000 项）。原因是换库的花费**不在 rfw 遍历 AST 上**——
`runtime.update` 清空所有 `_CurriedWidget` 缓存，N 个实例照样要重新
curry、重新 build。200 个 `Column`/`Row`/`ElevatedButton` 本身就很贵。

**2. 原生状态是决定性的。** 无论 50 还是 1000 项、无论有没有组件化，
改 data 都在测量分辨率以下（<1ms）。

**3. 所以正确的架构是「按变更路径选粒度」，不是「把树做小」：**

```
编辑时（防抖 0.4s）  runtime.update 全量重建   40–135ms   可以接受
交互时（点击）        rfw 原生 state / data    <1ms       必须走这条
```

**编辑**是低频且已被防抖合并的动作，135ms 只是偶尔卡一下；
**交互**是高频的，走换库就必然掉帧。

这条结论纠正了上一轮"组件化和原生状态必须一起做"的说法：
组件化不是必要条件，原生状态才是。想省事的话**只做原生状态**就够了。

### rfw 两条路径的粒度差异（源码）

```
换库：  runtime.update(lib)
        └─ _clearCache()      清空 _cachedConstructors + _widgets
        └─ notifyListeners()  RemoteWidget setState
        └─ 整棵子树重新绑定参数并重建      O(树大小)

原生：  DynamicContent.update(key, v)
        └─ 按 key 通知订阅者
        └─ 只有读了这个 key 的 _WidgetState.setState   O(订阅者数)
```

rfw 官方文档对这件事有明确说法：按钮按下态 "must react immediately
(in milliseconds) and cannot wait for logic that's possibly running on a
remote server"，为此提供 `widget Button { down: false }` + `set state.down`。
我们现在的设计（状态全推回 Lua、每次换整棵树）把这条路径整个绕开了。

## 旧：为什么组件化曾经看起来必要

`flutter run -t lib/bench_rebuild.dart` 的实测（已扣掉 60Hz vsync 的
16.67ms 地板 —— 不扣的话所有数字都被地板盖住）：

| 节点 | `runtime.update` | 改 data / state |
|---|---|---|
| 100 | 1.61 ms | <0.01 ms |
| 500 | 17.25 ms | <0.01 ms |
| 1000 | 28.87 ms | <0.01 ms |
| 2000 | 70.63 ms | <0.01 ms |

**根因在 rfw 源码里，两条路径的粒度完全不同：**

```
换库：  runtime.update(lib)
        └─ _clearCache()        清空 _cachedConstructors + _widgets
        └─ notifyListeners()    RemoteWidget 收到 -> setState
        └─ 整棵子树重新绑定参数      ← O(树大小)

原生：  DynamicContent.update(key, v)
        └─ 按 key 通知订阅者
        └─ 只有读了这个 key 的 _WidgetState.setState   ← O(订阅者数)
```

而 rfw 官方文档对这件事有明确的说法：按钮按下态"must react immediately
(in milliseconds) and cannot wait for logic that's possibly running on a
remote server"，所以它提供 `widget Button { down: false }` + `set state.down`。

**我们的设计把前者也做成了后者** —— 所有状态推回 Lua、所有更新换整棵树。
这就是 1000 节点要 43ms 的原因。

（这一节的结论已被上面那张 2×2 矩阵修正：组件化单独做只有 2–14% 的收益。）

## 方向验证：Lua 直接产出 rfw 文本（`assets/lua/ui/proto.lua`）

试了两件事，各有各的结论。

### 1. Lua -> rfw 文本：**可行，但更慢**

`tools/bench_text_vs_json.dart` 拿同一棵树走两条路，比产物与耗时：

| 规模 | 节点 | A: json（解码+转换） | B: parseLibraryFile | B/A |
|---|---|---|---|---|
| 25 | 176 | 0.43 ms | 2.63 ms | **6.1x** |
| 125 | 876 | 1.86 ms | 2.45 ms | **1.3x** |
| 500 | 3501 | 4.77 ms | 9.71 ms | **2.0x** |

**两条路线产出的库字节完全相同**（15237 vs 15237）——语义等价是确定的，
但 rfw 的文档早就说过文本格式比二进制慢十倍，`parseLibraryFile`
在客户端被明确不推荐。所以这条路**不能为性能走**。

`tools/verify_proto_text.dart` 验证了它**能跑通**（13 个用例）：
Lua 生成的文本，rfw 自己的 `parseLibraryFile` 解析、`encodeLibraryBlob`
编码，全都过。

如果哪天要走这条路，理由只能是**简化**而不是速度：能删掉
`ui_tree.dart`、`ui_rfw_ast.dart` 两个文件，以及 Lua 侧的 JSON 编码。
代价是丢掉"同样输入 -> 同样字节"的确定性，以及 Lua 里那个
`%.17g` 的类型保真问题要重新在文本上解决一遍。

顺带测了 rfw 解析器的报错质量：它给**行列号**
（`Unexpected ) at line 2 column 44`），比我们自己的校验器好。
但它**发现不了语义错**——`Colunm`（拼错的 widget 名）、未知的 widget，
它都照收不误，错误要到渲染时才以 ErrorWidget 的形式出现。
"可用属性表"这个校验只有我们自己做才提供。

### 1b. 生态调查：有没有现成的生成器

GitHub 从开发环境访问不到（HTML 与 API 都被挡），改从 pub.dev 全量搜：

| 包 | 版本 | 作用 | 判断 |
|---|---|---|---|
| `rfw_txt` | 0.0.2 | .rfw ↔ .rfwtxt | **已废弃**，被 `rfw_builder` 取代 |
| `rfw_builder` | 0.0.3 (2024-03) | 同上 | 老，没跟上 rfw 1.x |
| **`rfw_gen`** + `_builder` + `_preview` | **0.5.2 (2026-03)** | **Dart 函数 → rfwtxt**，带 MCP server 与预览 widget | 最成熟的一个 |
| `restage_codegen` | 2.0.0 (2026-09) | "写真正的 Flutter widget，编译成 RFW" | 同思路 |

**都不能直接用**：它们吃 **Dart AST**（`@RfwWidget` 注解 + build_runner），
我们要的是 Lua 吐 rfwtxt，没有 Lua 前端。

但 `rfw_gen` 的 `widget_registry.dart` 是一份**从 rfw 实际 API 推导出来的
63 个 widget 参数对照表**，比手写靠谱。拿它校验 proto 的 DSL，
发现缺 50 个（高频的有 ElevatedButton / TextButton / ListTile / Material /
Scaffold / Stack / Wrap / Spacer / GestureDetector / Flexible / Align /
ListView / InkWell / AppBar），已按它补齐到 23 个。

另两块可当规范：`expression_converter.dart`（`setState` / `event` /
`state.x` 的表达式转换）与 `rfw_icons.dart`（313 行图标码点，
我们手写了 20 个）。

**结论：官方没有、社区有但方向相反 → 自己写。**

### 2. 写起来像子程序：**可以做到**

见 `assets/lua/ui/proto.lua`：

```lua
local page = proto.page()
page:state { count = 0, on = true }
page:on("inc", function(s, ev) s.count = s.count + (ev.amount or 1) end)
page:body(function(ui, s)          -- 顶层也不用 return
  ui:column({ main = "center" }, function()
    ui:card(function()
      ui:text(tostring(s.count), { style = "w700", size = 32 })
      ui:button("+1", ui:event("inc", { amount = 1 }))
      ui:toggle(s.on, "on", "开关")                       -- 本地状态，不回 Lua
      ui:button("取反", ui:set("on", not s.on))          -- set state.on
    end)
  end)
end)
return page:emit()
```

和"填属性表"的差别：**每一行都是一句过程调用，从上到下读下来就是界面的结构**。
写错哪一步，报错直接指向那一步。

两个关键实现点：

- **顶层也不要求 `return`**。收集栈在 `page:body` 里同样接管，
  所以 body 里写 `ui:column(...)` 就够了。
  如果顶层还得写 return，那它跟填属性表没有本质区别。
- **数据字段一律带下划线前缀**（`_state` / `_handlers` / `_root`）。
  否则 `page.state` 会先命中实例上的数据表，`page:state{...}`
  就成了"对一张表调用冒号"——Lua 的 `__index` 只在字段不存在时才去找方法。

### 3. 交互是**两条路**，不是一条

之前表述成「交互尽量不回 Lua」容易被读成"业务交互也不回"。实际是分层：

```lua
ui:event("inc", {...})   -- 业务事件：回 Lua 执行业务逻辑 -> 换库重建
                         --   低频、已被 400ms 防抖合并，40–135ms 可接受
ui:set("on", not s.on)    -- 瞬时 UI 状态：rfw set state，当场生效不回 Lua
                         --   高频（按下/展开/选中），必须 <1ms
```

两者的分界是**「这个状态有没有业务含义」**：

* `inc`（计数 +1）要落库、要发请求 -> 业务事件，回 Lua
* `down`（按下态）只在这一次交互内成立 -> rfw 本地 state

两者的**产出路径不同**：业务事件回 Lua 后要重新 `emit()` 整棵树（换库）；
本地 state 由 rfw 自己改，之后没有任何跨界调用。

## 性能基准的自动化（`make bench`）

绝对值没有参考价值，所以：

- 基线记在 `tools/bench_baseline.json`
- 判定是**相对基线的劣化比例**，阈值按实测波动定（25% / 40%）
- 开跑前检查 loadavg 并提醒

那条提醒不是形式主义。实测：一个残留的 `flutter run`（占一个核）
让同样的代码慢 2 倍；一次 Android Studio 的 Java 进程让 loadavg 冲到 45，
所有数字虚高 60%。没有提醒的话，人会去追一个不存在的性能回归。

## 已知环境限制

- `flutter run` 时好时坏（VM service 的本地 socket）。debug 模式
  **构建**是好的，`open` 产物即可运行，只是没有热重载
- 换入口点（`-t lib/driver_main.dart`）后要 `hot_restart` 才生效，
  否则启动的还是旧 kernel
- 用 flutter_driver 做真实点击时，**窗口必须在最前**，否则指针注入一直超时
- `flutter test` 不可用（flutter_tester 需要本地 WebSocket）。
  用 `make test` 那组纯 Dart / Lua 脚本替代
- SPM 需要 `sandbox-exec`，受限环境报 `Operation not permitted`。
  `tools/fix_xcode_project.py` 会移除相关引用
- Xcode 27 最低支持 macOS 12.0，模板的 10.15 会失败 → 抬到 13.0
- `flutter_lua_bridge` 内置的是 **Lua 5.4**
