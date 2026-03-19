# Flutter Lua Bridge 项目概述

## 📖 项目简介

**flutter_lua_bridge** 是一个 Dart FFI 绑定库，用于在 Dart/Flutter 应用中无缝集成 Lua 脚本引擎。该项目将 Lua 5.4/5.5 源码直接打包，通过 Dart Native Assets 机制自动编译为各平台的原生库。

### 核心特点

| 特性 | 说明 |
|------|------|
| 🔄 源码编译 | Lua C 源码随库分发，易于定制修改 |
| 🚀 零外部依赖 | 不依赖系统 Lua 库，开箱即用 |
| 📱 全平台支持 | macOS, Linux, Windows, Android, iOS |
| 🎯 三层 API | 简化版、原始 C API、Dart 风格 API |
| 🏗️ 自动构建 | 通过 Dart Hook 自动编译 native 库 |

---

## 🎯 项目目标

### 1. 技术目标

- **跨平台 Lua 运行时**: 让 Flutter/Dart 应用能够在所有支持的平台运行 Lua 脚本
- **无缝 FFI 集成**: 提供类型安全、内存安全的 Dart FFI 绑定
- **灵活定制能力**: 通过源码分发，允许开发者修改 Lua 核心或添加自定义模块
- **高性能通信**: 实现 Dart 与 Lua 之间高效的数据交换

### 2. 应用场景

- **游戏开发**: 游戏逻辑热更新、配置表解析、AI 行为脚本
- **配置系统**: 复杂业务规则的可配置化
- **插件系统**: 应用扩展和第三方脚本支持
- **快速原型**: 动态执行脚本进行测试验证

---

## 📊 Git 提交历史分析

### 开发路线图

```
初始化阶段 (33bea6d - 03f567f)
├── 🎉 init: init project
├── ✨ feat: 为 android 平台添加适配
├── ✨ feat: 添加 mac 的适配
├── ✨ feat: 完善 example，添加辅助功能
└── 🎉 init: 0.0.1 release

构建系统重构 (f2017b5 - de524a9)
├── refactor: refactor build flow by dart hook
└── 🐞 fix: ignore gen file lint

开发体验增强 (902da96 - 31524ad)
├── feat: add lua interactive shell for testing

核心功能实现 (1472b06 - cb4362a)
├── feat: 添加 LuaState 封装和 FFI 基础架构
├── feat: 添加抽卡战斗游戏 Demo
└── fix: 修复 Android native asset 配置

文档与工程化 (75fd14d - 0fae1f2)
├── docs: 重构文档结构
└── chore: 添加开发辅助 agents 目录

API 设计优化 (9efeeb9 - 0b2658d)
├── refactor: split flutter_lua_bridge into two API styles
└── refactor: split flutter_lua_bridge into two API styles (#5)

版本升级 (f36e6f4)
└── feat: update lua source code to 5.5.0
```

### 关键里程碑

| 里程碑 | Commit | 说明 |
|--------|--------|------|
| **项目启动** | `33bea6d` | 初始项目结构搭建 |
| **首个版本** | `03f567f` | 0.0.1 发布，基础 FFI 绑定 |
| **Hook 重构** | `de524a9` | 采用 Dart Hook 构建，简化配置 |
| **Shell 支持** | `31524ad` | 添加交互式 Lua Shell |
| **核心封装** | `1472b06` | LuaState 面向对象封装 |
| **游戏 Demo** | `cb4362a` | 完整抽卡战斗游戏验证框架 |
| **API 分层** | `0b2658d` | 三种 API 风格正式确立 |
| **Lua 升级** | `f36e6f4` | 升级至 Lua 5.5.0 |

---

## 🏗️ 架构设计

### 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Dart/Flutter 应用层                       │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  简化版 API   │  │ Dart 风格 API│  │ 原始 C API   │      │
│  │ lua_simple_  │  │ lua_dart_api │  │ lua_raw_api  │      │
│  │ api.dart     │  │ .dart        │  │ .dart        │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
├─────────────────────────────────────────────────────────────┤
│                    FFI 绑定层 (ffigen)                       │
│              lib/src/gen/flutter_lua_bridge.g.dart          │
├─────────────────────────────────────────────────────────────┤
│                   Native Assets 构建层                       │
│              hook/build.dart + native_toolchain_c           │
├─────────────────────────────────────────────────────────────┤
│                    Lua C 源码层                              │
│              src/lua/src/*.c (Lua 5.5.0)                    │
└─────────────────────────────────────────────────────────────┘
```

### 模块说明

| 模块 | 路径 | 职责 |
|------|------|------|
| **简化版 API** | [`lib/lua_simple_api.dart`](lib/lua_simple_api.dart) | 最简单的使用方式，一行代码执行 Lua |
| **Dart 风格 API** | [`lib/lua_dart_api.dart`](lib/lua_dart_api.dart) | 面向对象的 LuaState 类 |
| **原始 C API** | [`lib/lua_raw_api.dart`](lib/lua_raw_api.dart) | 保持 C 语言命名风格 |
| **FFI 生成代码** | [`lib/src/gen/flutter_lua_bridge.g.dart`](lib/src/gen/flutter_lua_bridge.g.dart) | ffigen 生成的底层绑定 |
| **构建钩子** | [`hook/build.dart`](hook/build.dart) | 自动编译 Lua 源码为 native 库 |
| **Lua 源码** | [`src/lua/src/`](src/lua/src/) | Lua 5.5.0 完整 C 源码 |

---

## 🎮 游戏 Demo 详解

项目包含一个完整的**抽卡战斗游戏 Demo**，用于验证框架的实际能力：

### 验证功能点

| 功能 | 验证目标 | 状态 |
|------|----------|------|
| Lua 配置加载 | 从 assets 加载 Lua 文件 | ✅ |
| Lua 表解析 | 递归解析 Lua 表为 Dart Map | ✅ |
| Lua 函数调用 | 战斗公式在 Lua 中计算 | ✅ |
| 双向数据传递 | Dart 属性 → Lua → 伤害结果 | ✅ |
| 复杂数据结构 | 嵌套表、函数、元数据 | ✅ |
| 资源管理 | 正确管理指针生命周期 | ✅ |

### 游戏特性

- **卡牌系统**: 战士、法师、治疗、刺客四种职业
- **战斗系统**: 回合制，物理/法术双伤害类型
- **技能系统**: 普攻 + 冷却技能 + 被动技能
- **Lua 配置**: 所有卡牌数据、战斗公式均由 Lua 脚本配置

---

## 📁 项目结构

```
flutter_lua_bridge/
├── lib/                          # Dart 代码
│   ├── flutter_lua_bridge.dart   # 主入口（导出所有 API）
│   ├── lua_simple_api.dart       # 简化版 API
│   ├── lua_dart_api.dart         # Dart 风格 API
│   ├── lua_raw_api.dart          # 原始 C API
│   └── src/
│       ├── core/                 # 核心功能
│       │   ├── lua_state.dart    # LuaState 类
│       │   └── lua_constants.dart# Lua 常量
│       ├── gen/                  # 生成代码
│       │   └── flutter_lua_bridge.g.dart
│       └── utils/                # 工具类
├── src/                          # C/C++ 源码
│   └── lua/src/                  # Lua 5.5.0 源码
├── hook/                         # Native Assets 钩子
│   └── build.dart                # 自动构建脚本
├── example/                      # 示例应用
│   ├── assets/game/              # 游戏 Lua 配置
│   └── lib/game/                 # 游戏 Demo 代码
├── test/                         # 单元测试
├── agents/                       # 开发辅助
│   ├── scripts/                  # 分析脚本
│   └── docs/                     # 状态文档
└── docs/                         # 项目文档
    ├── DEVELOPMENT.md            # 开发指南
    └── lua_apis.md               # Lua API 文档
```

---

## 🔧 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Dart | ^3.10.0 | 主要开发语言 |
| FFI | ^2.1.3 | 外部函数接口 |
| native_toolchain_c | ^0.17.4 | C 代码编译 |
| hooks | ^1.0.1 | Native Assets 钩子 |
| ffigen | ^20.1.1 | FFI 绑定生成 |
| Lua | 5.5.0 | 脚本引擎 |

---

## 📈 当前状态

### 版本信息
- **当前版本**: 0.0.1
- **Lua 版本**: 5.5.0
- **Dart SDK**: ^3.10.0

### 测试覆盖
| 测试套件 | 通过数 |
|---------|--------|
| lua_state_test.dart | 26 |
| lua_constants_test.dart | 17 |
| type_convert_helper_test.dart | 13 |
| flutter_lua_bridge.g_test.dart | 1 |
| **总计** | **57** |

### 已知问题
- 生成的 FFI 代码中有 150+ 未使用元素警告（不影响功能）

---

## 🚀 快速开始

```dart
// 推荐：使用简化版 API
import 'package:flutter_lua_bridge/lua_simple_api.dart';

void main() {
  final result = lua.eval('return 1 + 1');
  print(result); // 2
}
```

更多用法参见 [README.md](README.md) 和 [example/](example/) 目录。

---

## 📝 总结

flutter_lua_bridge 项目旨在为 Flutter/Dart 生态提供一个**完整、灵活、易用**的 Lua 集成方案。通过源码分发和 Native Assets 机制，实现了跨平台、零依赖的 Lua 运行时环境。项目通过游戏 Demo 充分验证了框架的实用性和稳定性。

**最新进展**: 已完成 Lua 5.5.0 升级，API 设计定型，具备生产环境使用条件。
