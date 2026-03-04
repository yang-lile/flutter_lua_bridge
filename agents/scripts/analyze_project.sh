#!/bin/bash
# 项目分析脚本
# 用法: ./agents/scripts/analyze_project.sh

set -e

echo "=========================================="
echo "   Flutter Lua Bridge 项目分析"
echo "=========================================="
echo ""

cd "$(dirname "$0")/../.."

echo "📍 项目路径: $(pwd)"
echo ""

# 检查 Dart SDK
echo "🔧 Dart SDK 版本:"
dart --version
echo ""

# 检查 Flutter SDK
echo "🔧 Flutter SDK 版本:"
flutter --version | head -1
echo ""

# 获取依赖
echo "📦 获取依赖..."
dart pub get > /dev/null 2>&1
echo "✅ 依赖已获取"
echo ""

# 代码分析
echo "🔍 运行代码分析..."
echo "------------------------------------------"
dart analyze --fatal-infos 2>&1 || true
echo ""

# 代码格式化检查
echo "🎨 检查代码格式化..."
dart format --output=none --set-exit-if-changed . 2>&1 || echo "⚠️  代码需要格式化: dart format ."
echo ""

# 运行测试
echo "🧪 运行测试..."
dart test 2>&1 || true
echo ""

# 项目统计
echo "📊 项目统计:"
echo "------------------------------------------"
echo "Dart 文件数: $(find lib test example -name '*.dart' 2>/dev/null | wc -l)"
echo "C 源文件数: $(find src -name '*.c' 2>/dev/null | wc -l)"
echo "测试文件数: $(find test -name '*_test.dart' 2>/dev/null | wc -l)"
echo ""

echo "=========================================="
echo "   分析完成"
echo "=========================================="
