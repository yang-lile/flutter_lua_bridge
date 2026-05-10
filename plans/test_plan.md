# Flutter Lua Bridge 测试计划

## 概述
为 `flutter_lua_bridge/lib/src/c_api/` 和 `flutter_lua_bridge/lib/src/aux_api/` 中的所有文件添加测试代码。

## 测试目录结构

```
flutter_lua_bridge/test/
├── c_api/
│   ├── stack_test.dart           # 栈操作测试
│   ├── push_operations_test.dart # 压栈操作测试
│   ├── table_operations_test.dart # 表操作测试
│   ├── type_check_test.dart      # 类型检查测试
│   ├── state_management_test.dart # 状态管理测试
│   ├── debugging_test.dart       # 调试测试
│   ├── function_calls_test.dart  # 函数调用测试
│   ├── garbage_collection_test.dart # 垃圾回收测试
│   ├── memory_management_test.dart # 内存管理测试
│   ├── metatable_operations_test.dart # 元表操作测试
│   ├── misc_operations_test.dart # 其他操作测试
│   └── value_conversion_test.dart # 值转换测试
└── aux_api/
    ├── buffer_test.dart          # 缓冲区操作测试
    ├── argument_check_test.dart  # 参数检查测试
    ├── error_test.dart           # 错误处理测试
    ├── table_test.dart           # 表和元表操作测试
    ├── library_test.dart         # 库管理测试
    ├── loading_test.dart         # 加载和执行测试
    ├── misc_test.dart            # 其他操作测试
    └── type_conversion_test.dart # 类型转换测试
```

## 测试文件详细内容

### 1. c_api/stack_test.dart - 栈操作测试

测试函数：
- `luaAbsindex` - 将可接受索引转换为绝对索引
- `luaGettop` - 获取栈顶索引
- `luaSettop` - 设置栈顶
- `luaPushvalue` - 将指定索引的值压栈
- `luaRemove` - 移除指定位置的元素
- `luaInsert` - 插入元素到指定位置
- `luaReplace` - 替换指定位置的元素
- `luaRotate` - 旋转栈元素
- `luaPop` - 弹出 n 个元素
- `luaXmove` - 在不同状态间移动值

### 2. c_api/push_operations_test.dart - 压栈操作测试

测试函数：
- `luaPushboolean` - 压入布尔值
- `luaPushcclosure` - 压入 C 闭包
- `luaPushcfunction` - 压入 C 函数
- `luaPushinteger` - 压入整数
- `luaPushlightuserdata` - 压入轻量用户数据
- `luaPushnil` - 压入 nil
- `luaPushnumber` - 压入数字
- `luaPushstring` - 压入字符串
- `luaPushthread` - 压入线程
- `luaPushglobaltable` - 压入全局表

### 3. c_api/table_operations_test.dart - 表操作测试

测试函数：
- `luaGetfield` - 获取字段
- `luaGetglobal` - 获取全局变量
- `luaGeti` - 获取数组元素
- `luaGettable` - 获取表元素
- `luaRawget` - 原始获取
- `luaRawgeti` - 原始获取数组元素
- `luaRawgetp` - 原始获取指针键元素
- `luaRawlen` - 获取原始长度
- `luaRawset` - 原始设置
- `luaRawseti` - 原始设置数组元素
- `luaRawsetp` - 原始设置指针键元素
- `luaSetfield` - 设置字段
- `luaSetglobal` - 设置全局变量
- `luaSeti` - 设置数组元素
- `luaSettable` - 设置表元素
- `luaNext` - 遍历表

### 4. c_api/type_check_test.dart - 类型检查测试

测试函数：
- `luaIsboolean` - 检查是否为布尔值
- `luaIscfunction` - 检查是否为 C 函数
- `luaIsfunction` - 检查是否为函数
- `luaIsinteger` - 检查是否为整数
- `luaIslightuserdata` - 检查是否为轻量用户数据
- `luaIsnil` - 检查是否为 nil
- `luaIsnone` - 检查是否无效
- `luaIsnoneornil` - 检查是否无效或 nil
- `luaIsnumber` - 检查是否为数字
- `luaIsstring` - 检查是否为字符串
- `luaIstable` - 检查是否为表
- `luaIsthread` - 检查是否为线程
- `luaIsuserdata` - 检查是否为用户数据
- `luaIsyieldable` - 检查是否可 yield

### 5. c_api/state_management_test.dart - 状态管理测试

测试函数：
- `luaNewstate` - 创建新状态
- `luaClose` - 关闭状态
- `luaStatus` - 获取状态
- `luaVersion` - 获取版本
- `luaCheckstack` - 检查栈空间
- `luaError` - 抛出错误
- `luaNewthread` - 创建新线程

### 6. c_api/debugging_test.dart - 调试测试

测试函数：
- `luaGethook` - 获取钩子函数
- `luaGethookcount` - 获取钩子计数
- `luaGethookmask` - 获取钩子掩码
- `luaGetinfo` - 获取调试信息
- `luaGetlocal` - 获取局部变量
- `luaGetstack` - 获取栈信息
- `luaSethook` - 设置钩子
- `luaSetlocal` - 设置局部变量
- `luaUpvalueid` - 获取上值 ID
- `luaUpvalueindex` - 获取上值索引
- `luaUpvaluejoin` - 连接上值
- `luaAtpanic` - 设置 panic 函数

### 7. c_api/function_calls_test.dart - 函数调用测试

测试函数：
- `luaCall` - 调用函数
- `luaCallk` - 调用函数（带 yield 支持）
- `luaPcall` - 保护调用
- `luaPcallk` - 保护调用（带 yield 支持）
- `luaResume` - 恢复协程
- `luaYield` - 让出协程
- `luaYieldk` - 让出协程（带 continuation）

### 8. c_api/garbage_collection_test.dart - 垃圾回收测试

测试函数：
- `luaGc` - 垃圾回收控制
- `luaCloseslot` - 关闭 to-be-closed 槽

### 9. c_api/memory_management_test.dart - 内存管理测试

测试函数：
- `luaGetallocf` - 获取分配函数
- `luaSetallocf` - 设置分配函数
- `luaGetextraspace` - 获取额外空间
- `luaNewuserdata` - 创建用户数据
- `luaNewuserdatauv` - 创建用户数据（带值）
- `luaGetuservalue` - 获取用户数据值
- `luaSetuservalue` - 设置用户数据值
- `luaGetiuservalue` - 获取用户数据值（索引）
- `luaSetiuservalue` - 设置用户数据值（索引）
- `luaClosethread` - 关闭线程

### 10. c_api/metatable_operations_test.dart - 元表操作测试

测试函数：
- `luaGetmetatable` - 获取元表
- `luaSetmetatable` - 设置元表

### 11. c_api/misc_operations_test.dart - 其他操作测试

测试函数：
- `luaArith` - 算术运算
- `luaCompare` - 比较
- `luaConcat` - 连接
- `luaCopy` - 复制
- `luaCreatetable` - 创建表
- `luaNewtable` - 创建新表
- `luaDump` - 转储函数
- `luaLen` - 获取长度
- `luaLoad` - 加载代码
- `luaNumbertocstring` - 数字转字符串
- `luaNumbertointeger` - 数字转整数
- `luaRawequal` - 原始比较
- `luaRegister` - 注册函数
- `luaResetthread` - 重置线程
- `luaSetwarnf` - 设置警告函数
- `luaStringtonumber` - 字符串转数字
- `luaToclose` - 设置 to-be-closed 槽
- `luaWarning` - 发出警告

### 12. c_api/value_conversion_test.dart - 值转换测试

测试函数：
- `luaToboolean` - 转换为布尔值
- `luaTocfunction` - 转换为 C 函数
- `luaTointeger` - 转换为整数
- `luaTointegerx` - 转换为整数（带状态）
- `luaTolstring` - 转换为字符串
- `luaTonumber` - 转换为数字
- `luaTonumberx` - 转换为数字（带状态）
- `luaTopointer` - 转换为指针
- `luaTostring` - 转换为字符串
- `luaTothread` - 转换为线程
- `luaTouserdata` - 转换为用户数据
- `luaType` - 获取类型
- `luaTypename` - 获取类型名称

### 13. aux_api/buffer_test.dart - 缓冲区操作测试

测试函数：
- `luaLibAddchar` - 添加字符
- `luaLibAddgsub` - 添加替换字符串
- `luaLibAddlstring` - 添加字符串（带长度）
- `luaLibAddsize` - 添加大小
- `luaLibAddstring` - 添加字符串
- `luaLibAddvalue` - 添加值
- `luaLibBuffaddr` - 获取缓冲区地址
- `luaLibBuffinit` - 初始化缓冲区
- `luaLibBuffinitsize` - 初始化缓冲区（指定大小）
- `luaLibBufflen` - 获取缓冲区长度
- `luaLibBuffsub` - 缓冲区子串
- `luaLibPrepbuffer` - 准备缓冲区
- `luaLibPrepbuffsize` - 准备缓冲区（指定大小）
- `luaLibPushresult` - 推入结果
- `luaLibPushresultsize` - 推入结果（指定大小）

### 14. aux_api/argument_check_test.dart - 参数检查测试

测试函数：
- `luaLibArgcheck` - 检查参数
- `luaLibArgerror` - 参数错误
- `luaLibArgexpected` - 期望参数类型
- `luaLibCheckany` - 检查任意类型
- `luaLibCheckinteger` - 检查整数
- `luaLibChecklstring` - 检查字符串（带长度）
- `luaLibChecknumber` - 检查数字
- `luaLibCheckoption` - 检查选项
- `luaLibCheckstack` - 检查栈空间
- `luaLibCheckstring` - 检查字符串
- `luaLibChecktype` - 检查类型
- `luaLibCheckudata` - 检查用户数据
- `luaLibCheckversion` - 检查版本
- `luaLibOptinteger` - 可选整数
- `luaLibOptlstring` - 可选字符串（带长度）
- `luaLibOptnumber` - 可选数字
- `luaLibOptstring` - 可选字符串

### 15. aux_api/error_test.dart - 错误处理测试

测试函数：
- `luaLibError` - 抛出错误
- `luaLibExecresult` - 执行结果
- `luaLibFileresult` - 文件操作结果
- `luaLibTraceback` - 追踪栈
- `luaLibWhere` - 错误位置
- `luaLibTypeerror` - 类型错误

### 16. aux_api/table_test.dart - 表和元表操作测试

测试函数：
- `luaLibCallmeta` - 调用元方法
- `luaLibGetmetafield` - 获取元表字段
- `luaLibGetmetatable` - 获取元表
- `luaLibGetsubtable` - 获取子表
- `luaLibGsub` - 全局替换
- `luaLibNewmetatable` - 创建新元表
- `luaLibSetmetatable` - 设置元表

### 17. aux_api/library_test.dart - 库管理测试

测试函数：
- `luaLibNewlib` - 创建新库
- `luaLibNewlibtable` - 创建库表
- `luaLibNewstate` - 创建新状态
- `luaLibOpenlibs` - 打开标准库
- `luaLibOpenselectedlibs` - 打开指定库
- `luaLibRequiref` - 需求模块
- `luaLibSetfuncs` - 设置函数

### 18. aux_api/loading_test.dart - 加载和执行测试

测试函数：
- `luaLibDofile` - 执行文件
- `luaLibDostring` - 执行字符串
- `luaLibLoadbuffer` - 加载缓冲区
- `luaLibLoadbufferx` - 加载缓冲区（指定模式）
- `luaLibLoadfile` - 加载文件
- `luaLibLoadfilex` - 加载文件（指定模式）
- `luaLibLoadstring` - 加载字符串

### 19. aux_api/misc_test.dart - 其他操作测试

测试函数：
- `luaLibAlloc` - 分配函数
- `luaLibMakeseed` - 生成种子
- `luaLibPushfail` - 推入失败值
- `luaLibRef` - 创建引用
- `luaLibTestudata` - 测试用户数据
- `luaLibUnref` - 释放引用

### 20. aux_api/type_conversion_test.dart - 类型转换测试

测试函数：
- `luaLibLen` - 获取长度
- `luaLibTolstring` - 转换为字符串
- `luaLibTypename` - 获取类型名称

## 测试注意事项

1. **Lua 状态管理**：每个测试组需要使用 `setUp` 和 `tearDown` 来管理 Lua 状态的生命周期

2. **测试辅助函数**：创建通用的测试辅助函数，如：
   - 创建 Lua 状态
   - 压入测试值
   - 验证栈状态
   - 清理资源

3. **跳过未实现的函数**：对于未实现或需要复杂设置的函数，使用 `skip` 标记

4. **错误处理测试**：为可能抛出错误的函数添加错误处理测试

5. **边界条件测试**：测试边界值和极端情况

6. **使用 Dart MCP 运行测试**：按照用户要求，使用 `mcp--dart--run_tests` 工具运行测试

## 测试执行流程

1. 创建测试目录结构
2. 为每个源文件创建对应的测试文件
3. 实现测试用例
4. 使用 Dart MCP 运行测试
5. 修复失败的测试
6. 确保所有测试通过

## 测试模板示例

```dart
import 'package:test/test.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

void main() {
  group('ModuleName Tests', () {
    late ffi.Pointer<gen.lua_State> L;

    setUp(() {
      // 初始化 Lua 状态
      L = luaLibNewstate();
      luaLibOpenlibs(L);
    });

    tearDown(() {
      // 清理 Lua 状态
      if (L != ffi.nullptr) {
        luaClose(L);
      }
    });

    test('functionName description', () {
      // 测试代码
    });
  });
}
```
