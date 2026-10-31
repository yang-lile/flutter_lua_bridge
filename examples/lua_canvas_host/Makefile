LUA ?= lua
FLUTTER ?= flutter
DART ?= dart

.PHONY: help deps test test-lua test-dart test-worker test-guard \
        test-snippets test-ui test-ui-ast test-bytecode test-change-detect \
        test-proto-text test-ui-native-state test-contract analyze check run build clean

help:
	@echo "make run             构建并启动（本地调试）"
	@echo "make build           构建 release 包但不启动"
	@echo ""
	@echo "make test            跑全部验证"
	@echo "  make test-lua        Lua 侧单元测试（canvas + ui）"
	@echo "  make test-dart       跨语言契约（用真实 Lua 产出校验 Dart 解析）"
	@echo "  make test-worker     worker isolate 行为"
	@echo "  make test-guard      Lua 执行预算"
	@echo "  make test-snippets   画布预设示例能真实跑出图元"
	@echo "  make test-ui         UI 预设示例能真实跑出 widget 树"
	@echo "  make test-ui-ast     UI 契约 -> rfw blob 端到端"
	@echo "  make test-bytecode   字节码预编译（删源码仍能跑）"
	@echo "  make test-change-detect  内容变化检测（逐字段）"
	@echo "  make test-proto-text  Lua 直出 rfw 文本（原型可行性）"
	@echo "  make test-ui-native-state  交互分层（本地状态 vs 业务事件）"
	@echo ""
	@echo "make bench          流水线性能基准（冷启动/规模扫描/事件往返）"
	@echo ""
	@echo "make analyze         静态检查"
	@echo "make check           analyze + test"
	@echo "make gallery         重新生成浏览器对照页数据"
	@echo "make clean           清理生成物"

# ---------- 常用 ----------

run:
	@bash tools/dev.sh

build:
	@bash tools/run.sh --build-only

# 同步 pubspec 的 assets 声明。改过 Lua 模块后必须跑，否则
# 打包时新模块进不去，且只在运行时暴露为 "module not found"。
deps:
	@bash tools/check_manifest.sh
	@bash tools/gen_assets.sh

# ---------- 验证 ----------

test: test-lua test-dart test-worker test-guard test-snippets test-ui test-ui-ast \
     test-bytecode test-change-detect test-proto-text test-ui-native-state

# 测试文件自己反推 assets/lua 路径，从任意工作目录都能跑
test-lua:
	@$(LUA) assets/lua/spec/canvas_spec.lua
	@$(LUA) assets/lua/spec/ui_spec.lua

test-dart: gallery
	@python3 tools/verify_contract.py

test-worker:
	@$(DART) --suppress-analytics run tools/verify_worker.dart

test-guard:
	@$(DART) --suppress-analytics run tools/verify_guard.dart

test-snippets:
	@$(DART) --suppress-analytics run tools/verify_snippets.dart

# UI 链路：预设示例
test-ui:
	@$(DART) --suppress-analytics run tools/verify_ui_snippets.dart

# UI 链路：契约 -> rfw blob 的端到端校验
test-ui-ast:
	@$(DART) --suppress-analytics run tools/verify_ui_ast.dart

# 字节码预编译：证明执行时真的走了字节码（删掉源码仍能跑）
test-bytecode:
	@$(DART) --suppress-analytics run tools/verify_bytecode.dart

# 内容变化检测：漏更新的表现是静默的，必须逐字段验
test-change-detect:
	@$(DART) --suppress-analytics run tools/verify_change_detect.dart

# 原型：Lua 直接产出 rfw 文本，且 rfw 自己的解析器认它
test-proto-text:
	@$(DART) --suppress-analytics run tools/verify_proto_text.dart

# 交互分层：本地状态必须编成 SetStateHandler（不回 Lua），业务事件才是 EventHandler
test-ui-native-state:
	@$(DART) --suppress-analytics run tools/verify_ui_native_state.dart

# 性能基准（不进 make test，结果随机器波动，只在需要时手动跑）
bench:
	@$(DART) --suppress-analytics run tools/bench_pipeline.dart

# 注意：flutter test 在受限环境下不可用（flutter_tester 需要与
# 工具建立本地 WebSocket，会被拦）。上面这组是等价替代——
# 都是纯 Dart / Lua 入口，不依赖 Flutter 引擎。
#
# display_list.dart 因为用了 dart:ui 的 Color/Offset，无法在纯 Dart
# VM 下测试；它的 parseColor / sameAs 逻辑由 verify_contract.py
# 从契约层面间接覆盖（原 test/display_list_test.dart 已归档）。
analyze:
	@$(FLUTTER) analyze

check: analyze test

# ---------- 浏览器对照页 ----------

gallery:
	@$(LUA) tools/gen_gallery.lua

serve: gallery
	@echo "打开 http://127.0.0.1:8899/gallery.html"
	@python3 -m http.server 8899 --bind 127.0.0.1

# ---------- 清理 ----------

clean:
	@rm -rf assets/lua/out
	@echo "已清理生成物（build/ 与 .dart_tool/ 用 flutter clean）"
