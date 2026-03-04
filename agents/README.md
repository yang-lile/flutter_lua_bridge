# Agents 目录

此目录用于存放 AI 助手（Agent）相关的脚本、文档和配置文件。

## 目录结构

```
agents/
├── README.md              # 本文件
├── scripts/               # 自动化脚本
│   ├── mcp_client.dart    # MCP 服务器交互客户端
│   └── analyze_project.sh # 项目分析脚本
└── docs/                  # 文档
    └── project_status.md  # 项目状态报告
```

## 脚本说明

### MCP 客户端 (`scripts/mcp_client.dart`)

用于与 Dart/Flutter MCP 服务器交互，获取项目信息。

**用法:**
```bash
dart agents/scripts/mcp_client.dart
```

**功能:**
- 连接 MCP 服务器
- 列出可用工具
- 执行代码分析
- 获取项目信息

### 项目分析脚本 (`scripts/analyze_project.sh`)

运行项目质量检查。

**用法:**
```bash
./agents/scripts/analyze_project.sh
```

**功能:**
- 检查 SDK 版本
- 运行代码分析
- 检查代码格式化
- 运行测试
- 项目统计

## 添加新脚本

1. 将脚本放入 `scripts/` 目录
2. 添加可执行权限: `chmod +x scripts/your_script.sh`
3. 在此 README 中更新脚本说明
4. 在脚本开头添加注释说明用途和用法

## 添加新文档

1. 将文档放入 `docs/` 目录
2. 使用 Markdown 格式
3. 在文件名中包含日期或版本信息（如需要）
