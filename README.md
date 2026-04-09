<h1 align="center">Agent CLI Playbook</h1>

<p align="center">
  为 LLM Agent 设计命令行工具的方法论。<br/>
  16 条设计原则，综合 6 个顶级 CLI 的实战经验——不限语言，不限领域。
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="License"/></a>
  <a href="SKILL.md"><img src="https://img.shields.io/badge/version-2.0-brightgreen" alt="Version"/></a>
  <a href="https://agentskills.io"><img src="https://img.shields.io/badge/Agent%20Skills-compatible-blueviolet" alt="Agent Skills"/></a>
</p>

---

## 痛点

AI Agent 调用 CLI 时遇到的典型灾难：

```bash
# Agent 跑了一条命令
$ mytool list-servers

# 拿到一堆彩色表格文本...
NAME          STATUS    CPU    MEMORY
web-01        running   45%    2.1GB
db-master     running   78%    8.3GB

# Agent 的内心：我怎么 JSON.parse 这坨东西？？？
```

```bash
# Agent 删错了东西
$ mytool delete web-01

# Error: Operation failed.

# Agent 的内心：失败了，但我该怎么修？不知道，再来一次吧。
# （于是无限重试...）
```

**根本原因：** 绝大多数 CLI 是给人用的——表格输出、彩色高亮、模糊错误信息。Agent 需要的是完全不同的接口契约。

## 装上之后有什么变化

| 维度 | 没有这套原则 | 用了之后 |
|------|-------------|---------|
| 输出 | 表格/彩色文本，Agent 无法解析 | JSON→stdout，`JSON.parse()` 一步到位 |
| 错误 | `"Error: failed"`，Agent 不知如何修复 | 结构化错误 + `suggestion` 字段，Agent 自动修复 |
| 发现 | 读文档、猜参数、反复试错 | 一次 `--help` 拿到全部命令+参数+示例 |
| 安全 | 写操作直接执行，删错不可逆 | `--dry-run` 预览 → 确认 → 执行 |
| 重试 | 重复调用导致重复副作用 | 幂等设计，重试无副作用 |
| 上下文 | 返回 10 万条撑爆 token 窗口 | 分页 + 字段精选，按需获取 |

## 16 条原则一览

分 5 层，从"Agent 怎么发现你"到"怎么安全操作"：

| 层 | 原则 | 一句话 | 学谁 |
|----|------|--------|------|
| **可发现** | CLI 即文档 | `--help` 列出全部能力 | cloudflared |
| | 文档即接口 | `--help` → 工具文档 → JSON 三层金字塔 | Cloudflare llms.txt |
| **输出** | 双通道输出 | JSON→stdout，日志→stderr | cloudflared |
| | 字段精选 | `--fields` 按需选字段，省 token | GitHub CLI `gh` |
| | 流式分页 | 大结果集 NDJSON + 分页 | ripgrep |
| | 输出自包含 | 一次输出足够决策 | — |
| **错误** | 可操作错误 | 每个 error 带 suggestion | cloudflared |
| | 早校验快失败 | 先验参数再调 API | cloudflared |
| | 凭据安全 | 日志脱敏，输出不含密钥 | cloudflared |
| **操作安全** | 安全试运行 | `--dry-run` 先看后做 | kubectl, Terraform |
| | 幂等操作 | 重复执行结果不变 | kubectl `apply` |
| | 异步等待 | 返回 task_id + `wait` 子命令 | AWS CLI Waiter |
| **工程** | 命令无歧义 | 命令名/flag 无歧义 | POSIX, kubectl |
| | 命令正交 | 按意图组织，不按 API 端点 | — |
| | 配置优先级 | Flag > Env > File | cloudflared |
| | 最短路径 | 发现→调用→决策步数最少 | — |

> 所有技术声明均通过官方文档验证。详见 [SKILL.md](./SKILL.md) 中的「学习来源」。

## 安装

### 给 Agent 的安装指令

> **如果你是 AI Agent 正在读这段文字**，按你的运行平台执行对应的一条命令即可完成安装：

```bash
# Claude Code — 全局安装
git clone https://github.com/wakaka6/agent-cli-playbook.git ~/.claude/skills/agent-cli-playbook

# OpenAI Codex / Gemini CLI / 通用 Agent
git clone https://github.com/wakaka6/agent-cli-playbook.git ~/.agents/skills/agent-cli-playbook

# 项目级安装（当前项目内生效）
git clone https://github.com/wakaka6/agent-cli-playbook.git .claude/skills/agent-cli-playbook
```

安装后无需额外配置。提到"CLI 设计"、"agent CLI"、"命令行规范"等关键词时自动激活。

---

### 一键安装（推荐）

克隆仓库后运行 `install.sh`，自动检测已安装的 AI 平台并创建 symlink：

```bash
git clone https://github.com/wakaka6/agent-cli-playbook.git
cd agent-cli-playbook
./install.sh            # 自动 symlink 到所有检测到的平台
./install.sh --dry-run  # 预览但不执行
./install.sh --uninstall  # 移除所有 symlink
```

支持平台：Claude Code · Gemini CLI · Goose · OpenCode · GitHub Copilot

---

### 手动安装

<details>
<summary><b>Claude Code</b></summary>

```bash
# 全局安装（所有项目可用）
git clone https://github.com/wakaka6/agent-cli-playbook.git ~/.claude/skills/agent-cli-playbook

# 项目级安装
git clone https://github.com/wakaka6/agent-cli-playbook.git .claude/skills/agent-cli-playbook
```

Claude Code 自动发现 `SKILL.md`，当你提到"CLI 设计"、"agent CLI"、"命令行规范"等关键词时激活。
</details>

<details>
<summary><b>OpenAI Codex</b></summary>

```bash
# 用户级安装
git clone https://github.com/wakaka6/agent-cli-playbook.git ~/.agents/skills/agent-cli-playbook

# 项目级安装
git clone https://github.com/wakaka6/agent-cli-playbook.git .agents/skills/agent-cli-playbook
```
</details>

<details>
<summary><b>Cursor</b></summary>

创建 `.cursor/rules/agent-cli-playbook.mdc`：

```markdown
---
description: Agent-first CLI 设计方法论
globs: "**/cli/**"
---
设计、评审或重构 CLI 时，遵循 `agent-cli-playbook/SKILL.md` 中的 16 条原则和检查清单。
```

或直接将 `SKILL.md` 内容粘贴到 **Settings → Rules for AI**。
</details>

<details>
<summary><b>GitHub Copilot</b></summary>

添加到 `.github/copilot-instructions.md`：

```markdown
## CLI 设计
设计或评审 CLI 工具时，遵循 `agent-cli-playbook/SKILL.md` 中的原则。
重点关注：JSON 输出、可操作错误、--dry-run、幂等性。
```
</details>

<details>
<summary><b>Windsurf</b></summary>

创建 `.windsurf/rules/agent-cli-playbook.md`：

```markdown
设计或评审 CLI 时，遵循 `agent-cli-playbook/SKILL.md` 中的 16 条原则。
```
</details>

<details>
<summary><b>Gemini CLI</b></summary>

添加到项目根目录 `GEMINI.md`：

```markdown
## CLI 设计方法论
设计 CLI 工具时，遵循 `agent-cli-playbook/SKILL.md` 中的原则和检查清单。
```
</details>

<details>
<summary><b>其他工具</b></summary>

它就是 Markdown。克隆到项目中，然后在你的 AI 工具配置里指向 `SKILL.md`。
</details>

## 快速体验

安装后，直接和 AI 助手对话：

**设计新 CLI：**
```
帮我设计一个管理 Kubernetes 集群的 CLI，主要给 Agent 调用
```

**评审现有 CLI：**
```
评审一下这个 CLI 的 Agent 友好度：`aws s3 ls`
```

**重构输出格式：**
```
把这个命令的表格输出改成 Agent 友好的 JSON 格式
```

Agent 会自动加载 SKILL.md，按 16 条原则给出设计方案或改进建议。

## SKILL.md 里有什么

| 区块 | 内容 | 什么时候看 |
|------|------|-----------|
| **核心认知** | Agent vs 人类的 6 个差异 | 理解为什么需要不同设计 |
| **16 条原则速查** | 分 5 层逐条展开，附学习来源 | 设计或评审时逐条对照 |
| **命令无歧义展开** | 前缀冲突、flag 歧义、位置参数规范 | 命名子命令和参数时 |
| **推荐输出模式** | JSON 信封格式 + 错误码分类表 | 定义输出格式时 |
| **Help 文本设计** | 模板 + 3 条关键要求 | 写 `--help` 输出时 |
| **设计工作流** | 3 种场景的 step-by-step 流程 | 新建 / 评审 / 重构时 |
| **设计检查清单** | 20+ 项逐条打勾 | 设计完成后验收 |
| **反模式清单** | 10 个常见陷阱 + 正确做法 | 快速排雷 |
| **学习来源** | 6 个顶级 CLI 的核心贡献 + 推荐命令 | 深入学习时 |

## 学习来源

综合 6 个顶级 CLI 的设计精华，每条声明均已通过官方文档验证：

| CLI | 核心贡献 | 值得研究的命令 |
|-----|---------|---------------|
| **cloudflared** | 双通道输出、可操作错误、配置三层合成 | `cloudflared tunnel --help` |
| **GitHub CLI (`gh`)** | `--json fields` 字段精选、`--jq` 内置过滤 | `gh pr list --json number,title` |
| **kubectl** | `--dry-run=client\|server`、声明式 `apply` 幂等 | `kubectl apply --dry-run=server` |
| **Terraform** | `plan`→`apply` 分离、`-json` NDJSON 变更流 | `terraform plan -json` |
| **AWS CLI v2** | Waiter 模式、JMESPath `--query`、6 种输出格式 | `aws ec2 wait instance-running` |
| **ripgrep** | `--json` NDJSON 流式输出（JSON Lines） | `rg --json "pattern"` |

> **不要照搬任何单个 CLI。** 取 cloudflared 的错误处理 + gh 的字段精选 + kubectl 的 dry-run + AWS 的 waiter + ripgrep 的流式输出 = Agent 最佳体验。

## 文件结构

```
agent-cli-playbook/
├── SKILL.md              # 核心内容：16 条原则 + 检查清单 + 反模式
├── install.sh            # 一键安装：自动检测已安装平台并 symlink
├── agents/
│   └── openai.yaml       # OpenAI Codex 平台适配配置
├── README.md             # 本文件
├── LICENSE               # MIT
└── .gitignore
```

> `SKILL.md` 是唯一的知识文件，`install.sh` 负责自动部署到所有检测到的 AI 平台。

## 适用场景

- ✅ 从零设计 Agent 调用的 CLI 工具
- ✅ 评审现有 CLI 的 Agent 友好度
- ✅ 把面向人类的 CLI 改造成 Agent 可消费的格式
- ✅ 为已有 CLI 编写 Agent 工具文档
- ✅ 任何语言、任何领域（DevOps / 数据 / SaaS / 安全 / IoT）

- ❌ 不是 CLI 框架（不生成代码脚手架）
- ❌ 不绑定特定语言或运行时

## Contributing

欢迎 PR，尤其是：

- **新的设计原则** — 从其他优秀 CLI 中提炼的 Agent 友好模式
- **实战案例** — 用这套原则改造了某个 CLI？分享 before/after
- **新平台适配** — 其他 AI 工具的安装说明
- **错误修正** — 发现某条声明与官方文档不符？请指出

提 PR 时请确保技术声明有官方文档来源支撑。

## License

[MIT](./LICENSE)
