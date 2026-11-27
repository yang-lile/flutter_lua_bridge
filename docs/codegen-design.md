# 代码生成设计

本文记录 `flutter_lua_bridge_codegen` 的设计口径：开发者用 Dart 写接口，
Lua 侧（用 Teal 或 Lua）提供实现，互操作代码全部自动生成。

## 角色

| 语言 / 工具 | 作用 | 存在于 |
| --- | --- | --- |
| Dart | 定义契约（接口、数据类、枚举），调用 Lua，或为 Lua 提供实现 | 开发期 + 运行期 |
| Teal | 给 Lua 侧提供类型：契约的声明文件由生成器产出，业务实现可以用 Teal 写 | 仅开发期 |
| Lua | 唯一能和 Dart 桥接并执行的产物；也可以直接手写 | 开发期 + 运行期 |
| `build_runner` | 唯一的生成入口 | 仅开发期 |

Teal 只是一个单文件的 Lua 程序（`tl.lua`），随生成器包内置，用本库自带的
Lua 运行时执行。不使用 LuaRocks、Cyan 或系统 Lua，因此切换 Lua 版本时不存在
外部工具链的缓存问题。

## 两个方向

参照 pigeon 的 `@HostApi` / `@FlutterApi`，两个方向同时保留：

| 注解 | 谁实现 | 谁调用 | 典型用途 |
| --- | --- | --- | --- |
| `@LuaApi(module: ...)` | Lua / Teal | Dart | 业务逻辑、公式、可热更新的规则 |
| `@DartApi(module: ...)` | Dart | Lua | 回调、日志、存储、平台能力等宿主服务 |

和 pigeon 一样，接口整类导出，没有方法级的导出标注。`@LuaName` 只用来改
Lua 侧的名字。

接口可以 `implements` 不带注解的普通抽象接口并继承其方法。这样同一组方法
只声明一次，再按不同安全级别各绑定一次（示例中的 `BattleFormulas` 与
`FormulasO1Api`/`O2Api`/`O3Api`），O3 客户端同时实现这个基础接口。

生成的 `bindXxx` 会原地把实现表里的函数替换成包装函数，所以一张表只能绑定
到一个接口；再绑定到其他接口时直接报错，而不是悄悄复用前一档的包装。

## 目录

```text
<package>/
├── build.yaml                      # 把 lua/** 加入 build_runner 的输入
├── tlconfig.lua                    # 编辑器（Teal 语言服务）和 run 命令使用
├── lib/bridge/
│   ├── battle.dart                 # 手写：契约，含 part 'battle.g.dart';
│   └── battle.g.dart               # 生成
├── lua/
│   ├── src/                        # 手写：*.tl、*.lua
│   ├── test/                       # 手写：main.tl、*_test.tl，run 命令的入口
│   └── types/battle_bridge.d.tl    # 生成：Teal 声明
└── assets/lua/                     # 生成：最终的 Lua，作为 Flutter 资产打包
```

`tlconfig.lua` 放在包根目录：Teal 语言服务只读取编辑器所打开目录下的
`tlconfig.lua`，并以该目录为基准解析 `include_dir`，放在 `lua/` 里就找不到
`require("battle_bridge")` 的声明。

原则：手写和生成的文件不混在同一个目录里（Dart 的 `.g.dart` 例外，它遵循
Dart 社区惯例）；`lua/` 整个目录是开发期内容，只有 `assets/lua/` 进包。
四个目录都可以通过 `build.yaml` 的 `contracts`、`types`、`sources`、
`output` 选项修改。

`init` 可以直接在现有 Flutter 应用里运行。Lua 业务变多以后，建议把契约和
`lua/` 移到一个独立的 Flutter package：Lua 源码、生成物和 Lua 侧测试自成
一体，也不和应用的 `lib/` 混在一起。

生成器包自己的测试夹具 `test/fixtures/lua/` 也带一份 `tlconfig.lua`，单独
打开这个目录时编辑器同样能解析声明；从包根目录打开时用包根的那份。

## 生成内容

三个 Builder，一条命令 `dart run build_runner build`：

| Builder | 输入 | 输出 |
| --- | --- | --- |
| `bridge` | `lib/bridge/x.dart` | `x.g.dart`（经 `source_gen` 合并，可与 json_serializable 等共存） |
| `teal_types` | `lib/bridge/x.dart` | `lua/types/x_bridge.d.tl` |
| `teal` | `lua/src/*.tl`、`*.lua` | `assets/lua/*.lua`（Teal 编译，Lua 原样复制） |

`x.g.dart` 包含：

- `XxxClient`：`@LuaApi` 接口的调用端。`XxxClient(runtime:)` 绑定已加载的
  模块，`XxxClient.load(runtime:, source:)` 先加载再绑定。
- `registerXxx(Xxx? api, {required LuaRuntime runtime})`：注册 `@DartApi`
  的 Dart 实现，传 `null` 注销。
- 数据类和枚举的编解码。数据类就是用户自己写的类，生成器不重抄一份。
- 协议胶水 `x_bridge` 的 Lua 源码，以常量形式内嵌，客户端或注册函数首次
  使用时装入运行时。它不单独落盘，也不需要作为资产。

Lua 侧通过 `require("x_bridge")` 拿到 `bindXxx(impl)`（提交实现）和
`getXxx()`（取得 Dart 提供的接口），类型由 `x_bridge.d.tl` 描述。

## 安全级别

| 级别 | Lua 侧类型检查 | `pcall` | Dart 侧返回 |
| --- | --- | --- | --- |
| `O1`（默认） | 有 | 有 | `LuaCallResult<T>` |
| `O2` | 无 | 有 | `LuaCallResult<T>` |
| `O3` | 无 | 无 | `T`，失败抛 `LuaBridgeException`；客户端 `implements` 契约接口 |

默认级别来自 `build.yaml` 的 `optimization`，
`@LuaApi(optimization: LuaOptimization.o3)` 按接口覆盖。

说明：`flb` shim 下每次调用本身都是受保护的，Lua 错误不会让进程崩溃。所以
`O2` 与 `O3` 的实际差别是“错误以返回值呈现”还是“以异常呈现”，以及少一层
`pcall` 包装的开销。

## 不做的事

- **版本 / 指纹校验**：Dart 代码与下发的 Lua 是否匹配属于业务问题，不由工具
  库处理，已从运行时和生成器中移除。需要时应作为独立的包实现。业务侧可以
  这样分工：契约发生破坏性变化时改 Dart 接口并随 App 发版；只修 Lua 逻辑时
  下发一份完整的 Lua 快照，而不是在旧脚本上叠补丁；选择哪份脚本、回滚到
  哪份，也由业务决定。
- **Lua 的交付方式**：生成器只产出 `assets/lua/`。作为 Flutter 资产打包、
  远程下载还是放进其他制品，由应用决定；`LuaRuntime` 只加载最终的 Lua 源码。
- **独立的生成器命令行**：生成只走 `build_runner`。`init` 命令仅用于初始化
  目录、`build.yaml`、`tlconfig.lua` 和 `lua/test/main.tl`。

## 实现要点

- `build_runner` 的构建脚本不带 native assets，Builder 里不能直接创建
  `LuaRuntime`。Teal Builder 因此启动一个 `teal_worker` 子进程（整次构建
  共用一个），由它加载 `tl.lua` 并编译。这也使生成器包依赖运行时包；反过来
  运行时不依赖生成器。
- worker 使用应用所选的 Lua 版本，生成目标随之确定（5.4 及以上为 `5.4`，
  否则 `5.3`），`gen_compat` 关闭。
- Teal 的 `require` 在内存中解析：`lua/src` 与 `lua/types` 下的全部模块
  交给编译器，不访问文件系统的搜索路径。
- worker 的 stdout 上可能混有 `dart run` 的进度输出（不换行），协议行按
  标记 `FLB-TEAL:` 在行内查找，而不是要求它在行首。
- `build_runner` 默认不读取 `lua/` 目录，所以需要 `build.yaml` 里的
  `sources` 列表；`init` 会生成它。

## TODO

- 运行期在 App 内编译 Teal（把 `tl.lua` 作为资产装入 `LuaRuntime`）。可行，
  优先级不高；目前只下发编译后的 Lua。
- 异步宿主接口（`@DartApi` 方法返回 `Future`）。目前双向调用都是同步的。
