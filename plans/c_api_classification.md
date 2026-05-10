# Lua C API 分类方案

本文档定义了 Lua C API 的分类结构，用于在 `flutter_lua_bridge/lib/src/` 目录下组织 wrapper 文件。

## 目录结构

```
flutter_lua_bridge/lib/src/
├── c_api/                        # 核心 C API
│   ├── types.dart                # 类型定义
│   ├── stack.dart                # 栈操作
│   ├── type_check.dart           # 类型检查
│   ├── value_conversion.dart     # 值转换
│   ├── push_operations.dart      # 压栈操作
│   ├── table_operations.dart     # 表操作
│   ├── metatable_operations.dart # 元表操作
│   ├── function_calls.dart       # 函数调用
│   ├── state_management.dart     # 状态管理
│   ├── memory_management.dart    # 内存管理
│   ├── garbage_collection.dart   # 垃圾回收
│   ├── debugging.dart            # 调试
│   └── misc_operations.dart      # 其他操作
└── aux_api/                      # 辅助库 API
    ├── buffer.dart               # 缓冲区操作
    ├── argument_check.dart       # 参数检查
    ├── loading.dart              # 加载执行
    ├── error.dart                # 错误处理
    ├── table.dart                # 表元表操作
    ├── library.dart              # 库管理
    ├── type_conversion.dart      # 类型转换
    └── misc.dart                 # 其他操作
```

**注意**：所有模块最终通过 `flutter_lua_bridge/lib/flutter_lua_bridge.dart` 统一导出。

## C API (capi) 分类详情

### 1. types.dart - 类型定义

**类型定义和枚举：**
- `lua_Alloc` -> `LuaAlloc`
- `lua_CFunction` -> `LuaCFunction`
- `lua_Debug` -> `LuaDebug`
- `lua_Hook` -> `LuaHook`
- `lua_Integer` -> `LuaInteger`
- `lua_KContext` -> `LuaKContext`
- `lua_KFunction` -> `LuaKFunction`
- `lua_Number` -> `LuaNumber`
- `lua_Reader` -> `LuaReader`
- `lua_State` -> `LuaState`
- `lua_Unsigned` -> `LuaUnsigned`
- `lua_WarnFunction` -> `LuaWarnFunction`
- `lua_Writer` -> `LuaWriter`

**枚举类型：**
- `FlbType` -> `LuaType`
  - `FLB_TNONE` -> `LuaType.none`
  - `FLB_TNIL` -> `LuaType.nil`
  - `FLB_TBOOLEAN` -> `LuaType.boolean`
  - `FLB_TLIGHTUSERDATA` -> `LuaType.lightUserdata`
  - `FLB_TNUMBER` -> `LuaType.number`
  - `FLB_TSTRING` -> `LuaType.string`
  - `FLB_TTABLE` -> `LuaType.table`
  - `FLB_TFUNCTION` -> `LuaType.function`
  - `FLB_TUSERDATA` -> `LuaType.userdata`
  - `FLB_TTHREAD` -> `LuaType.thread`
- `FlbStatus` -> `LuaStatus`
  - `FLB_OK` -> `LuaStatus.ok`
  - `FLB_YIELD` -> `LuaStatus.yield`
  - `FLB_ERRRUN` -> `LuaStatus.errRun`
  - `FLB_ERRSYNTAX` -> `LuaStatus.errSyntax`
  - `FLB_ERRMEM` -> `LuaStatus.errMem`
  - `FLB_ERRGCMM` -> `LuaStatus.errGcmm`
  - `FLB_ERRERR` -> `LuaStatus.errErr`
- `FlbGC` -> `LuaGC`
  - `FLB_GC_STOP` -> `LuaGC.stop`
  - `FLB_GC_RESTART` -> `LuaGC.restart`
  - `FLB_GC_COLLECT` -> `LuaGC.collect`
  - `FLB_GC_COUNT` -> `LuaGC.count`
  - `FLB_GC_COUNTB` -> `LuaGC.countB`
  - `FLB_GC_STEP` -> `LuaGC.step`
  - `FLB_GC_SETPAUSE` -> `LuaGC.setPause`
  - `FLB_GC_SETSTEPMUL` -> `LuaGC.setStepMul`
  - `FLB_GC_ISRUNNING` -> `LuaGC.isRunning`
- `FlbArith` -> `LuaArith`
  - `FLB_OPADD` -> `LuaArith.add`
  - `FLB_OPSUB` -> `LuaArith.sub`
  - `FLB_OPMUL` -> `LuaArith.mul`
  - `FLB_OPDIV` -> `LuaArith.div`
  - `FLB_OPMOD` -> `LuaArith.mod`
  - `FLB_OPPOW` -> `LuaArith.pow`
  - `FLB_OPUNM` -> `LuaArith.unm`
  - `FLB_OPBAND` -> `LuaArith.band`
  - `FLB_OPBOR` -> `LuaArith.bor`
  - `FLB_OPBXOR` -> `LuaArith.bxor`
  - `FLB_OPSHL` -> `LuaArith.shl`
  - `FLB_OPSHR` -> `LuaArith.shr`
  - `FLB_OPBNOT` -> `LuaArith.bnot`
- `FlbCompare` -> `LuaCompare`
  - `FLB_OPEQ` -> `LuaCompare.eq`
  - `FLB_OPLT` -> `LuaCompare.lt`
  - `FLB_OPLE` -> `LuaCompare.le`

---

### 2. stack.dart - 栈操作

**栈索引和操作：**
- `lua_absindex` -> `luaAbsindex`
- `lua_gettop` -> `luaGettop`
- `lua_settop` -> `luaSettop`
- `lua_pushvalue` -> `luaPushvalue`
- `lua_remove` -> `luaRemove`
- `lua_insert` -> `luaInsert`
- `lua_replace` -> `luaReplace`
- `lua_rotate` -> `luaRotate`
- `lua_pop` -> `luaPop`
- `lua_xmove` -> `luaXmove`

---

### 3. type_check.dart - 类型检查

**类型检查函数：**
- `lua_isboolean` -> `luaIsboolean`
- `lua_iscfunction` -> `luaIscfunction`
- `lua_isfunction` -> `luaIsfunction`
- `lua_isinteger` -> `luaIsinteger`
- `lua_islightuserdata` -> `luaIslightuserdata`
- `lua_isnil` -> `luaIsnil`
- `lua_isnone` -> `luaIsnone`
- `lua_isnoneornil` -> `luaIsnoneornil`
- `lua_isnumber` -> `luaIsnumber`
- `lua_isstring` -> `luaIsstring`
- `lua_istable` -> `luaIstable`
- `lua_isthread` -> `luaIsthread`
- `lua_isuserdata` -> `luaIsuserdata`
- `lua_isyieldable` -> `luaIsyieldable`

---

### 4. value_conversion.dart - 值转换

**值转换函数：**
- `lua_toboolean` -> `luaToboolean`
- `lua_tocfunction` -> `luaTocfunction`
- `lua_tointeger` -> `luaTointeger`
- `lua_tointegerx` -> `luaTointegerx`
- `lua_tolstring` -> `luaTolstring`
- `lua_tonumber` -> `luaTonumber`
- `lua_tonumberx` -> `luaTonumberx`
- `lua_topointer` -> `luaTopointer`
- `lua_tostring` -> `luaTostring`
- `lua_tothread` -> `luaTothread`
- `lua_touserdata` -> `luaTouserdata`
- `lua_type` -> `luaType`
- `lua_typename` -> `luaTypename`

---

### 5. push_operations.dart - 压栈操作

**压栈函数：**
- `lua_pushboolean` -> `luaPushboolean`
- `lua_pushcclosure` -> `luaPushcclosure`
- `lua_pushcfunction` -> `luaPushcfunction`
- `lua_pushexternalstring` -> `luaPushexternalstring`
- `lua_pushfstring` -> `luaPushfstring`
- `lua_pushglobaltable` -> `luaPushglobaltable`
- `lua_pushinteger` -> `luaPushinteger`
- `lua_pushlightuserdata` -> `luaPushlightuserdata`
- `lua_pushliteral` -> `luaPushliteral`
- `lua_pushlstring` -> `luaPushlstring`
- `lua_pushnil` -> `luaPushnil`
- `lua_pushnumber` -> `luaPushnumber`
- `lua_pushstring` -> `luaPushstring`
- `lua_pushthread` -> `luaPushthread`
- `lua_pushvfstring` -> `luaPushvfstring`

---

### 6. table_operations.dart - 表操作

**表访问函数：**
- `lua_getfield` -> `luaGetfield`
- `lua_getglobal` -> `luaGetglobal`
- `lua_geti` -> `luaGeti`
- `lua_gettable` -> `luaGettable`
- `lua_rawget` -> `luaRawget`
- `lua_rawgeti` -> `luaRawgeti`
- `lua_rawgetp` -> `luaRawgetp`
- `lua_rawlen` -> `luaRawlen`
- `lua_rawset` -> `luaRawset`
- `lua_rawseti` -> `luaRawseti`
- `lua_rawsetp` -> `luaRawsetp`
- `lua_setfield` -> `luaSetfield`
- `lua_setglobal` -> `luaSetglobal`
- `lua_seti` -> `luaSeti`
- `lua_settable` -> `luaSettable`
- `lua_next` -> `luaNext`

---

### 7. metatable_operations.dart - 元表操作

**元表函数：**
- `lua_getmetatable` -> `luaGetmetatable`
- `lua_setmetatable` -> `luaSetmetatable`

---

### 8. function_calls.dart - 函数调用

**函数调用函数：**
- `lua_call` -> `luaCall`
- `lua_callk` -> `luaCallk`
- `lua_pcall` -> `luaPcall`
- `lua_pcallk` -> `luaPcallk`
- `lua_resume` -> `luaResume`
- `lua_yield` -> `luaYield`
- `lua_yieldk` -> `luaYieldk`

---

### 9. state_management.dart - 状态管理

**状态管理函数：**
- `lua_newstate` -> `luaNewstate`
- `lua_close` -> `luaClose`
- `lua_status` -> `luaStatus`
- `lua_version` -> `luaVersion`
- `lua_checkstack` -> `luaCheckstack`
- `lua_error` -> `luaError`
- `lua_newthread` -> `luaNewthread`

---

### 10. memory_management.dart - 内存管理

**内存管理函数：**
- `lua_getallocf` -> `luaGetallocf`
- `lua_setallocf` -> `luaSetallocf`
- `lua_getextraspace` -> `luaGetextraspace`
- `lua_newuserdata` -> `luaNewuserdata`
- `lua_newuserdatauv` -> `luaNewuserdatauv`
- `lua_getuservalue` -> `luaGetuservalue`
- `lua_setuservalue` -> `luaSetuservalue`
- `lua_getiuservalue` -> `luaGetiuservalue`
- `lua_setiuservalue` -> `luaSetiuservalue`
- `lua_closethread` -> `luaClosethread`

---

### 11. garbage_collection.dart - 垃圾回收

**垃圾回收函数：**
- `lua_gc` -> `luaGc`
- `lua_closeslot` -> `luaCloseslot`

---

### 12. debugging.dart - 调试

**调试函数：**
- `lua_gethook` -> `luaGethook`
- `lua_gethookcount` -> `luaGethookcount`
- `lua_gethookmask` -> `luaGethookmask`
- `lua_getinfo` -> `luaGetinfo`
- `lua_getlocal` -> `luaGetlocal`
- `lua_getstack` -> `luaGetstack`
- `lua_sethook` -> `luaSethook`
- `lua_setlocal` -> `luaSetlocal`
- `lua_upvalueid` -> `luaUpvalueid`
- `lua_upvalueindex` -> `luaUpvalueindex`
- `lua_upvaluejoin` -> `luaUpvaluejoin`
- `lua_atpanic` -> `luaAtpanic`

---

### 13. misc_operations.dart - 其他操作

**其他操作函数：**
- `lua_arith` -> `luaArith`
- `lua_compare` -> `luaCompare`
- `lua_concat` -> `luaConcat`
- `lua_copy` -> `luaCopy`
- `lua_createtable` -> `luaCreatetable`
- `lua_newtable` -> `luaNewtable`
- `lua_dump` -> `luaDump`
- `lua_len` -> `luaLen`
- `lua_load` -> `luaLoad`
- `lua_numbertocstring` -> `luaNumbertocstring`
- `lua_numbertointeger` -> `luaNumbertointeger`
- `lua_rawequal` -> `luaRawequal`
- `lua_register` -> `luaRegister`
- `lua_resetthread` -> `luaResetthread`
- `lua_setwarnf` -> `luaSetwarnf`
- `lua_stringtonumber` -> `luaStringtonumber`
- `lua_toclose` -> `luaToclose`
- `lua_warning` -> `luaWarning`

---

## 辅助库 (auxlib) 分类详情

### 14. buffer.dart - 辅助库缓冲区操作

**缓冲区操作函数：**
- `luaL_Buffer` -> `LuaLibBuffer`
- `luaL_addchar` -> `luaLibAddchar`
- `luaL_addgsub` -> `luaLibAddgsub`
- `luaL_addlstring` -> `luaLibAddlstring`
- `luaL_addsize` -> `luaLibAddsize`
- `luaL_addstring` -> `luaLibAddstring`
- `luaL_addvalue` -> `luaLibAddvalue`
- `luaL_buffaddr` -> `luaLibBuffaddr`
- `luaL_buffinit` -> `luaLibBuffinit`
- `luaL_buffinitsize` -> `luaLibBuffinitsize`
- `luaL_bufflen` -> `luaLibBufflen`
- `luaL_buffsub` -> `luaLibBuffsub`
- `luaL_prepbuffer` -> `luaLibPrepbuffer`
- `luaL_prepbuffsize` -> `luaLibPrepbuffsize`
- `luaL_pushresult` -> `luaLibPushresult`
- `luaL_pushresultsize` -> `luaLibPushresultsize`

---

### 15. argument_check.dart - 辅助库参数检查

**参数检查函数：**
- `luaL_argcheck` -> `luaLibArgcheck`
- `luaL_argerror` -> `luaLibArgerror`
- `luaL_argexpected` -> `luaLibArgexpected`
- `luaL_checkany` -> `luaLibCheckany`
- `luaL_checkinteger` -> `luaLibCheckinteger`
- `luaL_checklstring` -> `luaLibChecklstring`
- `luaL_checknumber` -> `luaLibChecknumber`
- `luaL_checkoption` -> `luaLibCheckoption`
- `luaL_checkstack` -> `luaLibCheckstack`
- `luaL_checkstring` -> `luaLibCheckstring`
- `luaL_checktype` -> `luaLibChecktype`
- `luaL_checkudata` -> `luaLibCheckudata`
- `luaL_checkversion` -> `luaLibCheckversion`
- `luaL_optinteger` -> `luaLibOptinteger`
- `luaL_optlstring` -> `luaLibOptlstring`
- `luaL_optnumber` -> `luaLibOptnumber`
- `luaL_optstring` -> `luaLibOptstring`

---

### 16. loading.dart - 辅助库加载执行

**加载执行函数：**
- `luaL_dofile` -> `luaLibDofile`
- `luaL_dostring` -> `luaLibDostring`
- `luaL_loadbuffer` -> `luaLibLoadbuffer`
- `luaL_loadbufferx` -> `luaLibLoadbufferx`
- `luaL_loadfile` -> `luaLibLoadfile`
- `luaL_loadfilex` -> `luaLibLoadfilex`
- `luaL_loadstring` -> `luaLibLoadstring`

---

### 17. error.dart - 辅助库错误处理

**错误处理函数：**
- `luaL_error` -> `luaLibError`
- `luaL_execresult` -> `luaLibExecresult`
- `luaL_fileresult` -> `luaLibFileresult`
- `luaL_traceback` -> `luaLibTraceback`
- `luaL_where` -> `luaLibWhere`
- `luaL_typeerror` -> `luaLibTypeerror`

---

### 18. table.dart - 辅助库表元表操作

**表和元表操作函数：**
- `luaL_callmeta` -> `luaLibCallmeta`
- `luaL_getmetafield` -> `luaLibGetmetafield`
- `luaL_getmetatable` -> `luaLibGetmetatable`
- `luaL_getsubtable` -> `luaLibGetsubtable`
- `luaL_gsub` -> `luaLibGsub`
- `luaL_newmetatable` -> `luaLibNewmetatable`
- `luaL_setmetatable` -> `luaLibSetmetatable`

---

### 19. library.dart - 辅助库库管理

**库管理函数：**
- `luaL_Reg` -> `LuaLibReg`
- `luaL_newlib` -> `luaLibNewlib`
- `luaL_newlibtable` -> `luaLibNewlibtable`
- `luaL_openlibs` -> `luaLibOpenlibs`
- `luaL_openselectedlibs` -> `luaLibOpenselectedlibs`
- `luaL_requiref` -> `luaLibRequiref`
- `luaL_setfuncs` -> `luaLibSetfuncs`

---

### 20. type_conversion.dart - 辅助库类型转换

**类型转换函数：**
- `luaL_len` -> `luaLibLen`
- `luaL_tolstring` -> `luaLibTolstring`
- `luaL_typename` -> `luaLibTypename`

---

### 21. misc.dart - 辅助库其他操作

**其他操作函数：**
- `luaL_Stream` -> `LuaLibStream`
- `luaL_alloc` -> `luaLibAlloc`
- `luaL_makeseed` -> `luaLibMakeseed`
- `luaL_newstate` -> `luaLibNewstate`
- `luaL_pushfail` -> `luaLibPushfail`
- `luaL_ref` -> `luaLibRef`
- `luaL_testudata` -> `luaLibTestudata`
- `luaL_unref` -> `luaLibUnref`

---

## 设计原则

1. **单一职责**：每个文件只包含相关功能的 API
2. **易于维护**：清晰的分类使查找和修改更容易
3. **可扩展性**：新增 API 可以轻松添加到相应分类
4. **命名一致性**：使用一致的命名约定
5. **文档完整**：每个 API 都应有清晰的文档注释

## API 命名约定

### C 层命名（保持不变）
- 使用 `flutter_lua_bridge_` 前缀
- 例如：`flutter_lua_bridge_absindex`, `flutter_lua_bridgeL_addchar`

### Dart 层命名
- 使用小驼峰命名法（lowerCamelCase）
- 以 `lua` 开头，保留原始 Lua API 名称
- 辅助库的 `L` 转换为 `Lib`
- 类型使用大驼峰命名法（UpperCamelCase）

**命名转换示例：**

| C API | Dart 函数 | Dart 类型 |
|-------|-----------|-----------|
| `lua_absindex` | `luaAbsindex` | - |
| `lua_gettop` | `luaGettop` | - |
| `luaL_addchar` | `luaLibAddchar` | - |
| `lua_State` | - | `LuaState` |
| `lua_CFunction` | - | `LuaCFunction` |
| `luaL_Buffer` | - | `LuaLibBuffer` |
| `lua_Debug` | - | `LuaDebug` |
| `lua_Hook` | - | `LuaHook` |
| `lua_Integer` | - | `LuaInteger` |
| `lua_Number` | - | `LuaNumber` |
| `lua_Reader` | - | `LuaReader` |
| `lua_Writer` | - | `LuaWriter` |
| `lua_KContext` | - | `LuaKContext` |
| `lua_KFunction` | - | `LuaKFunction` |
| `lua_Unsigned` | - | `LuaUnsigned` |
| `lua_WarnFunction` | - | `LuaWarnFunction` |
| `luaL_Reg` | - | `LuaLibReg` |
| `luaL_Stream` | - | `LuaLibStream` |

**枚举类型命名：**

| C 枚举 | Dart 枚举 |
|--------|-----------|
| `FlbType` | `LuaType` |
| `FlbStatus` | `LuaStatus` |
| `FlbGC` | `LuaGC` |
| `FlbArith` | `LuaArith` |
| `FlbCompare` | `LuaCompare` |

**枚举值命名：**

| C 值 | Dart 值 |
|------|---------|
| `FLB_TNIL` | `LuaType.nil` |
| `FLB_TBOOLEAN` | `LuaType.boolean` |
| `FLB_OK` | `LuaStatus.ok` |
| `FLB_YIELD` | `LuaStatus.yield` |
| `FLB_GC_COLLECT` | `LuaGC.collect` |
| `FLB_OPADD` | `LuaArith.add` |
| `FLB_OPEQ` | `LuaCompare.eq` |
