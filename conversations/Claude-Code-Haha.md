---
uid: Claude-Code-Haha
created: 2026-04-09
tags: [project, claude-code, TUI, tool-system]
related:
  - "[[2026-04-09]]"
---

# Claude Code Haha

> 基于 Claude Code 泄露源码修复的**本地可运行版本**

**项目位置**：`C:\Users\Administrator\.openclaw\workspace\claude-code-haha\claude-code-haha-main`

## 核心功能

- 完整的 Ink TUI 交互界面（与官方 Claude Code 一致）
- `--print` 无头模式（脚本/CI 场景）
- 支持 MCP 服务器、插件、Skills
- 支持自定义 API 端点和模型（如 MiniMax）
- 降级 Recovery CLI 模式

## 技术栈

| 类别 | 技术 |
|------|------|
| 运行时 | Bun |
| 语言 | TypeScript |
| 终端 UI | React + Ink |
| CLI 解析 | Commander.js |
| API | Anthropic SDK |
| 协议 | MCP, LSP |

## 架构概览

### 整体架构
- **CLI Entry** → **Init/Bootstrap** → 双通道
  - 左通道：UI/执行引擎（Terminal UI → Query Engine → Tool System → Agent）
  - 右通道：服务层（Services → State → Plugin/Skill → External Integrations）

### 主要模块
- **Tool System**：30+ 工具（文件读写、终端命令等）
- **Agent/Task**：多 Agent 协调
- **Services**：MCP、OAuth、Memory 管理
- **Plugin/Skill**：扩展系统

## 环境配置

```env
ANTHROPIC_API_KEY=sk-xxx          # 标准 API Key
ANTHROPIC_AUTH_TOKEN=sk-xxx       # Bearer Token（二选一）
ANTHROPIC_BASE_URL=https://api.minimaxi.com/anthropic  # 自定义端点
ANTHROPIC_MODEL=MiniMax-M2.7-highspeed
API_TIMEOUT_MS=3000000
DISABLE_TELEMETRY=1
```

## 快速开始

```bash
# 安装依赖
npm install

# 复制环境配置
cp .env.example .env
# 编辑 .env 填入 API Key

# 启动交互 TUI
./bin/claude-haha

# 无头模式
./bin/claude-haha -p "your prompt here"
```

## 相对于原始泄露源码的修复

| 问题 | 修复 |
|------|------|
| TUI 不启动 | 恢复走完整入口 cli.tsx |
| 启动卡死 | 创建 stub .md 文件 |
| --print 卡死 | 创建类型桩和资源桩文件 |
| Enter 键无响应 | try-catch 容错 |
| setup 被跳过 | 移除默认 LOCAL_RECOVERY=1 |

## 项目结构

```
bin/claude-haha          # 入口脚本
preload.ts               # Bun preload
src/
├── entrypoints/cli.tsx  # CLI 主入口
├── main.tsx             # TUI 主逻辑
├── screens/REPL.tsx     # 交互 REPL 界面
├── ink/                 # Ink 终端渲染引擎
├── components/          # UI 组件
├── tools/               # Agent 工具
├── commands/            # 斜杠命令
├── skills/              # Skill 系统
├── services/            # 服务层
└── utils/               # 工具函数
```

## 集成方案

### 架构：OpenClaw（主控）+ Claude Code Haha（编程执行）

```
用户 → OpenClaw（规划/记忆）→ Claude Code Haha（执行）
```

### 三种集成模式

| 模式 | 方式 | 优点 | 缺点 |
|------|------|------|------|
| CLI 管道 | `-p` 无头模式 | 简单直接 | 无状态 |
| MCP 协议 | 内置 @modelcontextprotocol/sdk | 有状态、可交互 | 需配置 |
| 子进程 | stdin/stdout 交互 | 保持上下文 | 需进程管理 |

### 待验证
- MCP 服务器模式是否可用
- 无头模式支持管道输入
- OpenClaw exec 调用方式

详见：`../Claude-Code-Haha-Integration.md`

## 参考价值

Claude Code Haha 的架构对 OpenClaw 有参考价值：
- **Tool System**：30+ 工具的设计模式
- **Agent/Task**：多 Agent 协调机制
- **Skill System**：插件化扩展
- **TUI + 无头双模式**：交互式 / 脚本两用

---

## 🔙 返回

- [[index|Vault 首页]]
- [[2026-04-09|今日对话]]
