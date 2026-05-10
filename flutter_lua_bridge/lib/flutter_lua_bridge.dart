/// Flutter Lua Bridge
///
/// Flutter Lua 的 FFI 绑定，提供对 Lua C API 的访问。
library;

export 'src/gen/flutter_lua_bridge.g.dart' show
  FlbType,
  FlbStatus,
  FlbGC,
  FlbArith,
  FlbCompare,
  kLuaVersionReleaseNum,
  kLuaRegistryIndex;

// ============================================================================
// 核心 C API (capi)
// ============================================================================

export 'src/c_api/types.dart' show
  LuaType,
  LuaStatus,
  LuaGC,
  LuaArith,
  LuaCompare,
  LuaState,
  LuaCFunction,
  LuaDebug,
  LuaHook,
  LuaInteger,
  LuaKContext,
  LuaKFunction,
  LuaNumber,
  LuaReader,
  LuaUnsigned,
  LuaWarnFunction,
  LuaWriter,
  LuaAlloc,
  LuaLibBuffer,
  LuaLibReg,
  LuaLibStream;

export 'src/c_api/stack.dart' show
  luaAbsindex,
  luaGettop,
  luaSettop,
  luaPushvalue,
  luaRemove,
  luaInsert,
  luaReplace,
  luaRotate,
  luaPop,
  luaXmove;

export 'src/c_api/type_check.dart' show
  luaIsboolean,
  luaIscfunction,
  luaIsfunction,
  luaIsinteger,
  luaIslightuserdata,
  luaIsnil,
  luaIsnone,
  luaIsnoneornil,
  luaIsnumber,
  luaIsstring,
  luaIstable,
  luaIsthread,
  luaIsuserdata,
  luaIsyieldable;

export 'src/c_api/value_conversion.dart' show
  luaToboolean,
  luaTocfunction,
  luaTointeger,
  luaTointegerx,
  luaTolstring,
  luaTonumber,
  luaTonumberx,
  luaTopointer,
  luaTostring,
  luaTothread,
  luaTouserdata,
  luaType,
  luaTypename;

export 'src/c_api/push_operations.dart' show
  luaPushboolean,
  luaPushcclosure,
  luaPushcfunction,
  luaPushexternalstring,
  luaPushfstring,
  luaPushglobaltable,
  luaPushinteger,
  luaPushlightuserdata,
  luaPushliteral,
  luaPushlstring,
  luaPushnil,
  luaPushnumber,
  luaPushstring,
  luaPushthread,
  luaPushvfstring;

export 'src/c_api/table_operations.dart' show
  luaGetfield,
  luaGetglobal,
  luaGeti,
  luaGettable,
  luaRawget,
  luaRawgeti,
  luaRawgetp,
  luaRawlen,
  luaRawset,
  luaRawseti,
  luaRawsetp,
  luaSetfield,
  luaSetglobal,
  luaSeti,
  luaSettable,
  luaNext;

export 'src/c_api/metatable_operations.dart' show
  luaGetmetatable,
  luaSetmetatable;

export 'src/c_api/function_calls.dart' show
  luaCall,
  luaCallk,
  luaPcall,
  luaPcallk,
  luaResume,
  luaYield,
  luaYieldk;

export 'src/c_api/state_management.dart' show
  luaNewstate,
  luaClose,
  luaStatus,
  luaVersion,
  luaCheckstack,
  luaError,
  luaNewthread;

export 'src/c_api/memory_management.dart' show
  luaGetallocf,
  luaSetallocf,
  luaGetextraspace,
  luaNewuserdata,
  luaNewuserdatauv,
  luaGetuservalue,
  luaSetuservalue,
  luaGetiuservalue,
  luaSetiuservalue,
  luaClosethread;

export 'src/c_api/garbage_collection.dart' show
  luaGc,
  luaCloseslot;

export 'src/c_api/debugging.dart' show
  luaGethook,
  luaGethookcount,
  luaGethookmask,
  luaGetinfo,
  luaGetlocal,
  luaGetstack,
  luaSethook,
  luaSetlocal,
  luaUpvalueid,
  luaUpvalueindex,
  luaUpvaluejoin,
  luaAtpanic;

export 'src/c_api/misc_operations.dart' show
  luaArith,
  luaCompare,
  luaConcat,
  luaCopy,
  luaCreatetable,
  luaNewtable,
  luaDump,
  luaLen,
  luaLoad,
  luaNumbertocstring,
  luaNumbertointeger,
  luaRawequal,
  luaRegister,
  luaResetthread,
  luaSetwarnf,
  luaStringtonumber,
  luaToclose,
  luaWarning;

// ============================================================================
// 辅助库 API (auxlib)
// ============================================================================

export 'src/aux_api/buffer.dart' show
  luaLibAddchar,
  luaLibAddgsub,
  luaLibAddlstring,
  luaLibAddsize,
  luaLibAddstring,
  luaLibAddvalue,
  luaLibBuffaddr,
  luaLibBuffinit,
  luaLibBuffinitsize,
  luaLibBufflen,
  luaLibBuffsub,
  luaLibPrepbuffer,
  luaLibPrepbuffsize,
  luaLibPushresult,
  luaLibPushresultsize;

export 'src/aux_api/argument_check.dart' show
  luaLibArgcheck,
  luaLibArgerror,
  luaLibArgexpected,
  luaLibCheckany,
  luaLibCheckinteger,
  luaLibChecklstring,
  luaLibChecknumber,
  luaLibCheckoption,
  luaLibCheckstack,
  luaLibCheckstring,
  luaLibChecktype,
  luaLibCheckudata,
  luaLibCheckversion,
  luaLibOptinteger,
  luaLibOptlstring,
  luaLibOptnumber,
  luaLibOptstring;

export 'src/aux_api/loading.dart' show
  luaLibDofile,
  luaLibDostring,
  luaLibLoadbuffer,
  luaLibLoadbufferx,
  luaLibLoadfile,
  luaLibLoadfilex,
  luaLibLoadstring;

export 'src/aux_api/error.dart' show
  luaLibError,
  luaLibExecresult,
  luaLibFileresult,
  luaLibTraceback,
  luaLibWhere,
  luaLibTypeerror;

export 'src/aux_api/table.dart' show
  luaLibCallmeta,
  luaLibGetmetafield,
  luaLibGetmetatable,
  luaLibGetsubtable,
  luaLibGsub,
  luaLibNewmetatable,
  luaLibSetmetatable;

export 'src/aux_api/library.dart' show
  luaLibNewlib,
  luaLibNewlibtable,
  luaLibNewstate,
  luaLibOpenlibs,
  luaLibOpenselectedlibs,
  luaLibRequiref,
  luaLibSetfuncs;

export 'src/aux_api/type_conversion.dart' show
  luaLibLen,
  luaLibTolstring,
  luaLibTypename;

export 'src/aux_api/misc.dart' show
  luaLibAlloc,
  luaLibMakeseed,
  luaLibPushfail,
  luaLibRef,
  luaLibTestudata,
  luaLibUnref;
