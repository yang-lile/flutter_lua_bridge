# Flutter Lua Bridge 代码生成 Makefile
# 用于生成 FFI 绑定和 Dart 接口文件

.PHONY: all gen ffigen lua_interfaces clean

# 默认目标：生成所有文件
all: gen

# 生成所有代码
gen: ffigen lua_interfaces
	@echo "所有代码生成完成！"

# ============================================
# ffigen 生成的 FFI 绑定
# ============================================
FFIGEN_OUTPUT = lib/src/gen/flutter_lua_bridge.g.dart
FFIGEN_TOOL = tool/ffigen.dart

ffigen: $(FFIGEN_OUTPUT)

$(FFIGEN_OUTPUT): $(FFIGEN_TOOL)
	@echo "正在生成 FFI 绑定: $@"
	dart run $(FFIGEN_TOOL)
	@echo "FFI 绑定生成完成！"

# ============================================
# Lua 脚本生成的 Dart 接口
# ============================================
LUA_SCRIPT = scripts/generate_dart_interfaces.lua
LUA_C_API_OUTPUT = lib/src/gen/lua_c_api.dart
LUA_AUX_API_OUTPUT = lib/src/gen/lua_aux_api.dart

lua_interfaces: $(LUA_C_API_OUTPUT) $(LUA_AUX_API_OUTPUT)

$(LUA_C_API_OUTPUT) $(LUA_AUX_API_OUTPUT): $(LUA_SCRIPT)
	@echo "正在生成 Lua C API Dart 接口..."
	lua $(LUA_SCRIPT)
	@echo "Lua C API Dart 接口生成完成！"

# 单独生成 lua_c_api.dart
lua_c_api: $(LUA_SCRIPT)
	@echo "正在生成 lua_c_api.dart..."
	lua $(LUA_SCRIPT)

# 单独生成 lua_aux_api.dart
lua_aux_api: $(LUA_SCRIPT)
	@echo "正在生成 lua_aux_api.dart..."
	lua $(LUA_SCRIPT)

# ============================================
# 清理生成的文件
# ============================================
clean:
	@echo "清理生成的文件..."
	rm -f $(FFIGEN_OUTPUT)
	rm -f $(LUA_C_API_OUTPUT)
	rm -f $(LUA_AUX_API_OUTPUT)
	@echo "清理完成！"

# ============================================
# 帮助信息
# ============================================
help:
	@echo "Flutter Lua Bridge 代码生成工具"
	@echo "================================"
	@echo ""
	@echo "可用目标:"
	@echo "  make all           - 生成所有代码（默认）"
	@echo "  make gen           - 生成所有代码"
	@echo "  make ffigen        - 仅生成 flutter_lua_bridge.g.dart"
	@echo "  make lua_interfaces - 生成 lua_c_api.dart 和 lua_aux_api.dart"
	@echo "  make clean         - 删除所有生成的文件"
	@echo "  make help          - 显示此帮助信息"
	@echo ""
	@echo "生成的文件:"
	@echo "  - $(FFIGEN_OUTPUT)"
	@echo "  - $(LUA_C_API_OUTPUT)"
	@echo "  - $(LUA_AUX_API_OUTPUT)"
