# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(flutter_lua_bridge_library VERSION 0.0.1 LANGUAGES C)

add_library(flutter_lua_bridge SHARED
  "lua/src/lapi.c"
  "lua/src/lauxlib.c"
  "lua/src/lbaselib.c"
  "lua/src/lcode.c"
  "lua/src/lcorolib.c"
  "lua/src/lctype.c"
  "lua/src/ldblib.c"
  "lua/src/ldebug.c"
  "lua/src/ldo.c"
  "lua/src/ldump.c"
  "lua/src/lfunc.c"
  "lua/src/lgc.c"
  "lua/src/linit.c"
  "lua/src/liolib.c"
  "lua/src/llex.c"
  "lua/src/lmathlib.c"
  "lua/src/lmem.c"
  "lua/src/loadlib.c"
  "lua/src/lobject.c"
  "lua/src/lopcodes.c"
  "lua/src/loslib.c"
  "lua/src/lparser.c"
  "lua/src/lstate.c"
  "lua/src/lstring.c"
  "lua/src/lstrlib.c"
  "lua/src/ltable.c"
  "lua/src/ltablib.c"
  "lua/src/ltm.c"
  "lua/src/lua.c"
  "lua/src/lundump.c"
  "lua/src/lutf8lib.c"
  "lua/src/lvm.c"
  "lua/src/lzio.c"
)

set_target_properties(flutter_lua_bridge PROPERTIES
  PUBLIC_HEADER "lua/src/lapi.h;lua/src/lauxlib.h;lua/src/lbaselib.h;lua/src/lcode.h;lua/src/lcorolib.h;lua/src/lctype.h;lua/src/ldblib.h;lua/src/ldebug.h;lua/src/ldo.h;lua/src/ldump.h;lua/src/lfunc.h;lua/src/lgc.h;lua/src/linit.h;lua/src/liolib.h;lua/src/llex.h;lua/src/lmathlib.h;lua/src/lmem.h;lua/src/loadlib.h;lua/src/lobject.h;lua/src/lopcodes.h;lua/src/loslib.h;lua/src/lparser.h;lua/src/lprefix.h;lua/src/lstate.h;lua/src/lstring.h;lua/src/lstrlib.h;lua/src/ltable.h;lua/src/ltablib.h;lua/src/ltm.h;lua/src/lua.h;lua/src/luaconf.h;lua/src/lualib.h;lua/src/lundump.h;lua/src/lutf8lib.h;lua/src/lvm.h;lua/src/lzio.h"
  OUTPUT_NAME "flutter_lua_bridge"
)

target_compile_definitions(flutter_lua_bridge PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(flutter_lua_bridge PRIVATE "-Wl,-z,max-page-size=16384")
endif()
