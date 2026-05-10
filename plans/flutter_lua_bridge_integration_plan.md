# Flutter Lua Bridge 整合计划

## 概述

将 `legacy/flutter_lua_shim` 和 `legacy/flutter_lua_bridge` 两个实验库整合到新的 `flutter_lua_bridge` 库中。

## 关键设计决策

### 1. 命名空间

所有 C 代码使用 `flutter_lua_bridge_` 前缀（替代 shim 的 `dart_lua_shim_`）。

### 2. API 版本支持策略

**与 shim 的区别**：
- **shim**: 所有 API 都有声明，不支持的返回 `Result<T, E>` 类型错误
- **新库**: 所有 API 都有声明，但不支持的版本**函数体为空**，返回对逻辑无影响的"零值"

### 3. 类型命名

使用 `Flb` 前缀（替代 shim 的 `lua_shim_*`），枚举值使用 Lua 原始定义：

| Shim 类型 | 新库类型 |
|-----------|---------|
| `lua_shim_type_t` | `FlbType` |
| `lua_shim_status_t` | `FlbStatus` |
| `lua_shim_gc_t` | `FlbGC` |
| `lua_shim_arith_t` | `FlbArith` |
| `lua_shim_compare_t` | `FlbCompare` |

枚举值使用 Lua 原始定义（如 `LUA_TNIL`、`LUA_OK`、`LUA_OPADD` 等），这些是 Lua C 层的标准常量，Dart 层通过 ffigen 重命名。

### 4. 文档注释

从 `legacy/flutter_lua_bridge/lib/src/raw/lua_c_api.dart` 和 `lua_aux_api.dart` 复制详细的 API 文档。

**注意**：
- 如果找不到文档，可以去 Lua 官方 manual.html 文件中查看。
- 文档注释使用常规的 `/* */` 格式。
- API 按照 a-z 顺序排列，与 `docs/api_support.md` 保持一致。
- 从 Lua 官方 manual.html 提取文档（优先参考 `legacy/flutter_lua_bridge/lib/src/raw/lua_c_api.dart` 和 `lua_aux_api.dart`）。
- 项目中包含 Lua 5.3/5.4/5.5 的文档，如果找不到，可以去 Lua 官方文档查看。

### 5. 文档注释来源

从 Lua 官方 manual.html 提取文档（优先参考 `legacy/flutter_lua_bridge/lib/src/raw/lua_c_api.dart` 和 `lua_aux_api.dart`）。

**注意**：如果找不到文档，可以去 Lua 官方 manual.html 文件中查看。

## 文件结构

```
flutter_lua_bridge/
├── src/
│   ├── flutter_lua_bridge.h    # 头文件（包含所有 API 声明和文档）
│   └── flutter_lua_bridge.c    # 实现文件
├── hook/
│   └── build.dart             # 构建脚本（使用 shim 版本）
├── tool/
│   └── ffigen.dart           # FFI 生成脚本（使用 shim 版本）
└── lib/
    └── flutter_lua_bridge_bindings_generated.dart  # 自动生成
```

## API 版本支持矩阵

参考 `docs/api_support.md`，使用以下宏控制：

```c
#if LUA_VERSION_NUM >= 503  // Lua 5.3+
#if LUA_VERSION_NUM >= 504  // Lua 5.4+
#if LUA_VERSION_NUM >= 505  // Lua 5.5+
```

### 不支持的 API 示例

| API | Lua 5.3 | Lua 5.4 | Lua 5.5 |
|-----|---------|---------|---------|
| `lua_closeslot` | ❌ 不定义 | ✅ | ✅ |
| `lua_closethread` | ❌ 不定义 | ❌ 不定义 | ✅ |
| `lua_warning` | ❌ 不定义 | ✅ | ✅ |
| `lua_pushexternalstring` | ❌ 不定义 | ❌ 不定义 | ✅ |

## 实现步骤

### 步骤 1: 创建头文件结构

```c
#ifndef FLUTTER_LUA_BRIDGE_H
#define FLUTTER_LUA_BRIDGE_H

#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// 版本号
extern const int kLuaVersionReleaseNum;

// 类型枚举
typedef enum FlbType { ... } FlbType;
typedef enum FlbStatus { ... } FlbStatus;
// ...

// C API 函数声明
// ...

// Auxlib API 函数声明
// ...

#ifdef __cplusplus
}
#endif

#endif // FLUTTER_LUA_BRIDGE_H
```

### 步骤 2: 定义类型枚举

```c
typedef enum FlbType {
    FLB_TNONE          = -1,
    FLB_TNIL           = 0,
    FLB_TBOOLEAN       = 1,
    // ...
} FlbType;
```

### 步骤 3: 定义 API 函数（带文档）

从 Lua 官方 manual.html 提取文档：

```c
/// lua_absindex
///
/// Stack: [-0, +0, –]
///
/// Converts the acceptable index idx into an equivalent absolute index
/// (that is, one that does not depend on the stack size).
int flutter_lua_bridge_absindex(lua_State* L, int idx);
```

### 步骤 4: 实现文件

```c
#include "flutter_lua_bridge.h"
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

const int kLuaVersionReleaseNum = LUA_VERSION_RELEASE_NUM;

// 版本控制的 API 实现
int flutter_lua_bridge_closeslot(lua_State* L, int idx) {
#if LUA_VERSION_NUM >= 504
    lua_closeslot(L, idx);
    return 0;
#else
    // 此版本不支持，函数体为空
    return 0;
#endif
}
```

### 步骤 5: 更新构建脚本

使用 shim 的 `hook/build.dart`，修改：
- `name: packageName` → `name: 'flutter_lua_bridge'`
- `assetName` → `'flutter_lua_bridge.dart'`
- `sources` → `['src/flutter_lua_bridge.c']`

**注意**：不使用 `ffigen.yaml` 文件，完全使用 `ffigen.dart` 来生成。

### 步骤 6: 创建 ffigen 生成脚本

使用 shim 的 `ffigen.dart`，修改：
- `name: FlutterLuaBridgeBindings`
- `entry-points: ['src/flutter_lua_bridge.h']`
- 类型重命名：`flutter_lua_bridge_*` → `Flutter*`

**注意**：不使用 `ffigen.yaml` 文件。

### 步骤 7: Dart 层使用方式

Dart 层使用包函数，命名缩短到最简单：

```dart
import 'package:flutter_lua_bridge/flutter_lua_bridge_bindings_generated.dart';

// C API 函数
void luaCloseslot(LuaState L, int idx) {
    if (kLuaVersionReleaseNum >= 504) {
        flutterLuaBridgeCloseslot(L, idx);
    }
}

// Auxlib API 函数（luaLib 前缀）
void luaLibToNumberX(LuaState L, int idx, Pointer<Int> isNum) {
    if (kLuaVersionReleaseNum >= 503) {
        return flutterLuaBridgeLibToNumberX(L, idx, isNum);
    }
}
```

## 已完成的工作

### ✅ 已完成的任务

1. **分析现有代码结构** - 分析了 shim 和 legacy bridge 的实现
2. **创建头文件结构** - 创建了 `flutter_lua_bridge.h`，包含所有 API 声明
3. **定义类型枚举** - 使用 `Flb` 前缀定义了所有类型枚举
4. **修复枚举问题** - 修复了 `FlbArith` 枚举的重复定义问题
5. **修复语法错误** - 修复了实现文件中的多个语法错误
6. **修复类型不匹配** - 修复了头文件和实现文件之间的类型不匹配问题
7. **更新构建脚本** - 创建了 `hook/build.dart`，支持 Lua 5.3/5.4/5.5
8. **创建 ffigen 脚本** - 创建了 `tool/ffigen.dart`，用于生成 Dart 绑定
9. **生成 Dart 绑定** - 使用 ffigen 生成了 `flutter_lua_bridge_bindings_generated.dart`
10. **验证编译** - 通过 Dart analyze 验证了编译

### ⏳ 待完成的任务

1. **添加 C API 文档注释** - 从 legacy bridge 提取文档注释到头文件
2. **添加 Auxlib API 文档注释** - 从 legacy bridge 提取文档注释到头文件

## 注意事项

1. **不使用 result.h**：新库不依赖 `result.h`，不支持的 API 函数体为空
2. **类型命名**：严格使用 `Flb*` 前缀
3. **文档完整性**：每个 API 都要有文档注释
4. **版本宏**：使用 `LUA_VERSION_NUM` 而非自定义宏
5. **命名空间**：所有函数使用 `flutter_lua_bridge_` 前缀
6. **API 顺序**：按照 a-z 顺序排列，与 `docs/api_support.md` 保持一致
7. **不使用 ffigen.yaml**：完全使用 `ffigen.dart` 来生成
8. **生成文件位置**：`lib/flutter_lua_bridge_bindings_generated.dart`（使用 `.g.dart` 结尾）

## 技术细节

### 特殊函数处理

1. **lua_newstate** - Lua 5.3/5.4 只有两个参数（f, ud），不需要 seed 参数
2. **lua_pushliteral** - 使用 `lua_pushstring(L, s)` 替代，因为 `lua_pushliteral` 是宏
3. **lua_pushvfstring** - 使用可变参数 `...` 和 `va_list` 来正确处理
4. **lua_sethook** - 返回类型为 `void`，不是 `int`

### 版本控制示例

```c
// Lua 5.4+ 支持的 API
int flutter_lua_bridge_closeslot(lua_State* L, int idx) {
#if LUA_VERSION_NUM >= 504
    return lua_closeslot(L, idx);
#else
    (void)L;
    (void)idx;
    return 0;
#endif
}

// Lua 5.5 支持的 API
const char* flutter_lua_bridge_pushexternalstring(lua_State* L, const char* s, size_t len, void* falloc, void* ud) {
#if LUA_VERSION_NUM >= 505
    return lua_pushexternalstring(L, s, len, (lua_Alloc)falloc, ud);
#else
    (void)L;
    (void)s;
    (void)len;
    (void)falloc;
    (void)ud;
    return NULL;
#endif
}
```

## 构建配置

### 用户定义选项

```dart
final userDefines = input.userDefines;
final luaVersion = (userDefines['lua_version'] as String?)?.trim() ?? '5.4';
final luaSourceUrl = (userDefines['lua_source_url'] as String?)?.trim();
```

### 支持的 Lua 版本

- **5.3** - Lua 5.3.6
- **5.4** - Lua 5.4.7
- **5.5** - Lua 5.5.0

## 测试

测试文件位于 `test/flutter_lua_bridge_test.dart`，包含：
- 版本号测试
- 类型枚举测试
- 枚举值测试

## 示例

示例应用位于 `example/lib/main.dart`，展示：
- Lua 版本显示
- 类型枚举展示
- 状态枚举展示
