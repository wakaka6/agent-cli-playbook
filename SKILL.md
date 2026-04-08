---
name: agent-cli-design
version: "2.0"
description: Agent-first CLI 设计方法论。教你为 LLM Agent 设计、评审、重构命令行工具——覆盖输出格式、错误处理、发现机制、安全操作等核心原则。适用于任何领域。
user-invocable: true
activation:
  keywords:
    - "CLI 设计"
    - "agent CLI"
    - "命令行设计"
    - "agent-first"
    - "CLI 规范"
    - "设计 CLI"
    - "CLI review"
    - "CLI 评审"
    - "tool design"
    - "工具设计"
  patterns:
    - "(?i)\\b(design|设计|写|build|构建)\\b.*\\b(cli|命令行|command.?line)\\b"
    - "(?i)\\b(cli|命令行)\\b.*\\b(规范|原则|best.?practice|pattern)\\b"
    - "(?i)\\bagent.?first\\b.*\\b(cli|tool)\\b"
  tags:
    - "cli-design"
    - "agent-tooling"
    - "methodology"
    - "developer-experience"
  max_context_tokens: 4000
metadata:
  openclaw:
    requires:
      bins: []
      env: []
    emoji: "🏗️"
---

# agent-cli-design — Agent-First CLI 设计方法论

**定位：通用方法论技能，适用于任何领域。** 当你需要为 LLM Agent 设计、评审、重构 CLI 工具时——无论是 DevOps、数据管道、SaaS API 还是安全运维——遵循这里的原则和检查清单。

## 适用场景

- **设计新 CLI** — 从零开始为一个 API/设备/服务构建 Agent 友好的命令行工具
- **评审现有 CLI** — 检查一个 CLI 是否对 Agent 友好，给出改进建议
- **重构 CLI 输出** — 把面向人类的 CLI 改造成 Agent 可消费的格式
- **编写 Agent 工具文档** — 为已有 CLI 撰写 Agent 可消费的结构化文档（system prompt、tool spec 等）
- **选型对比** — 评估多个 CLI 工具的 Agent 友好度

## 核心认知：Agent ≠ 人类

| 维度 | 人类用户 | LLM Agent |
|------|---------|-----------|
| 发现能力 | 读文档、Google、问同事 | 只读 `--help` 和工具文档 |
| 解析输出 | 看表格、看颜色高亮 | `JSON.parse(stdout)` |
| 错误恢复 | 读 Stack Overflow | 读结构化错误中的修复建议，执行修复命令 |
| 重试行为 | 手动改参数重跑 | 自动重试，需要幂等保证 |
| 上下文窗口 | 无限（可翻页、可搜索） | 有限 token，每个字段都有成本 |
| 批处理 | 写 shell 脚本 | 逐条调用，需要流式/分页 |

> **设计口诀：输出即接口，错误即指令，help 即目录。**

## 设计原则速查

设计或评审 CLI 时，逐条对照：

### 第一层：可发现性（Agent 怎么知道你能做什么）

| # | 原则 | 一句话 | 学谁 |
|---|------|--------|------|
| 1 | CLI 即文档 | `--help` 列全部命令+参数+示例，一次调用发现全部能力 | cloudflared |
| 2 | 文档即接口 | 三层金字塔：`--help`(发现) → Agent 工具文档(知识) → JSON 输出(数据) | Cloudflare llms.txt |

**说明：** "Agent 工具文档" 可以是 MCP tool spec、OpenAPI schema、system prompt 附带的工具说明，或任何 Agent 运行时能读取的结构化描述。形式不限，关键是 `--help` 中的命令名/参数名必须与文档一致。

### 第二层：输出格式（Agent 怎么读你的结果）

| # | 原则 | 一句话 | 学谁 |
|---|------|--------|------|
| 3 | 双通道输出 | JSON→stdout, 日志→stderr, 成功失败统一格式 | cloudflared |
| 4 | 字段精选 | 按需选字段减少 token 消耗，显式请求全量 | GitHub CLI `gh` |
| 5 | 流式分页 | 大结果集 NDJSON，默认分页，结尾统计行 | ripgrep |
| 6 | 输出自包含 | 一次输出足够决策，不需要二次查询补充上下文 | — |

### 第三层：错误与安全（Agent 出错了怎么办）

| # | 原则 | 一句话 | 学谁 |
|---|------|--------|------|
| 7 | 可操作错误 | 每个错误必须告诉 Agent 下一步该做什么 | cloudflared |
| 8 | 早校验快失败 | 先验参数再调 API，凭据缺失立即报错 | cloudflared |
| 9 | 凭据安全 | 日志脱敏，输出不含凭据，密钥不入库 | cloudflared |

### 第四层：操作安全（Agent 做写操作时怎么保护）

| # | 原则 | 一句话 | 学谁 |
|---|------|--------|------|
| 10 | 安全试运行 | 写操作 `--dry-run`，破坏性操作拆 preview→confirm | kubectl, Terraform |
| 11 | 幂等操作 | 重复执行同一命令结果不变，非幂等显式标注 | kubectl `apply` |
| 12 | 异步等待 | 异步任务返回 task_id，提供 `wait` 子命令 | AWS CLI Waiter |

### 第五层：工程约定（一致性与可组合性）

| # | 原则 | 一句话 | 学谁 |
|---|------|--------|------|
| 13 | 命令无歧义 | 命令名、子命令名、flag 名在上下文中有唯一解读 | POSIX, kubectl |
| 14 | 命令正交 | 按动词语义组织，不按 API 端点组织 | — |
| 15 | 配置优先级 | Flag > Env > File，三层合成 | cloudflared |
| 16 | 最短路径 | 发现一步到位，一条命令一个意图，输出足够决策 | — |

### 原则 13 展开：命令无歧义（Unambiguous Naming）

Agent 不会猜测你的意图。命令名、子命令名、参数名必须在上下文中只有一种解读方式。

**命令与子命令：**

```bash
# ❌ 前缀冲突：list vs listen，Agent 简写时出错
mytool list
mytool listen

# ✅ 语义分离，不共享前缀
mytool list
mytool watch
```

```bash
# ❌ 近义歧义：remove vs delete，Agent 不知道该用哪个
mytool remove <id>
mytool delete <id>

# ✅ 一个概念一个命令
mytool delete <id>
```

**Flag 命名：**

```bash
# ❌ --name 在不同子命令中含义不同
mytool create --name "my-server"    # 资源名称
mytool search --name "pattern"      # 搜索关键词

# ✅ 用明确的 flag 名消除歧义
mytool create --name "my-server"
mytool search --query "pattern"
```

```bash
# ❌ 布尔 flag 默认值不直觉
mytool list --no-cache     # 否定式，Agent 要推断"不加 flag 就是有 cache"

# ✅ 正向命名，或提供成对 flag
mytool list --cache=false
mytool list --skip-cache
```

**位置参数 vs 命名参数：**

```bash
# ❌ 两个位置参数，顺序依赖上下文
mytool copy source.txt dest.txt     # Agent 可能搞反

# ✅ 方案 A：用 flag 显式命名
mytool copy --from source.txt --to dest.txt

# ✅ 方案 B：只保留一个位置参数，其余用 flag
mytool copy source.txt --to dest.txt
```

**检查规则：**
- 同一 CLI 内不存在前缀冲突的子命令对
- 同一 flag 名在所有子命令中含义一致
- 位置参数最多 1 个；2 个以上改用命名 flag
- 避免否定式 flag（`--no-X`），优先用 `--X=false` 或正向反义词

## 推荐输出模式

Agent 消费 CLI 输出的核心需求：**一次 `JSON.parse(stdout)` 就能判断成功/失败并提取数据。** 以下是推荐的信封模式（团队可按需调整字段名）：

```jsonc
// 成功
{
  "success": true,
  "data": { ... },
  "meta": { "total": 42, "page": 1, "took_ms": 120 }  // 可选
}

// 失败
{
  "success": false,
  "error": {
    "code": "INVALID_ARG",       // 机器可读的枚举值
    "message": "Invalid value for --region: us-east-99 is not a valid region"
  },
  "suggestion": "Run `mytool regions list` to see available regions"
}
```

**关键约束（无论信封格式怎么变）：**
- 有一个布尔字段让 Agent 判断成功/失败（`success`、`ok`、`status == "ok"` 均可）
- 错误有机器可读的分类码（`error.code`），Agent 可 switch-case
- 错误有 Agent 可直接执行的修复建议（`suggestion`），不只是解释原因

**替代方案：** 如果 CLI 同时服务人类和 Agent，可参考 `gh` 的模式——默认人类友好输出，`--json <fields>` 切换到 JSON 模式。但要确保 JSON 模式覆盖全部命令，而非只有部分命令支持。

### 通用错误码分类

不同项目可自定义错误码，但建议覆盖以下类别：

| 类别 | 示例码 | 含义 | suggestion 方向 |
|------|--------|------|----------------|
| 参数错误 | `MISSING_ARG`, `INVALID_ARG` | 调用方式不对 | 指向 `--help` 或列出合法值 |
| 认证错误 | `AUTH_FAILED`, `AUTH_EXPIRED` | 凭据无效或过期 | 指向认证/登录命令 |
| 配置错误 | `CONFIG_ERROR` | 必需配置缺失 | 列出需要的配置项和设置方式 |
| 上游错误 | `API_ERROR`, `TIMEOUT` | 被调用服务出错 | 包含原始状态码，建议缩小范围或重试 |
| 资源错误 | `NOT_FOUND`, `CONFLICT` | 目标资源状态不对 | 检查 ID 或当前状态 |
| 限流 | `RATE_LIMITED` | 超出调用频率 | 给出等待时间 |

## Help 文本设计原则

Agent 通过一次 `--help` 调用发现 CLI 的全部能力。以下是关键要求：

1. **顶层 help 列出全部子命令 + 关键参数 + 至少 2 个示例**
2. **每个子命令一行说明**，包含必填参数和常用可选参数
3. **Common flags 区块**列出跨命令通用的 flag

```
mytool — Manage cloud resources

Commands:
  list   [--type TYPE] [--region REGION]     List resources
  get    <id> [--fields f1,f2]               Get resource details
  create <name> --type TYPE [--dry-run]      Create a resource
  delete <id> [--dry-run] [--force]          Delete a resource
  wait   <task-id> [--timeout N]             Wait for async task
  health                                     Check connectivity

Common flags:
  --json              Force JSON output (override TTY detection)
  --fields <f1,f2>    Return only specified fields
  --pretty            Pretty-print JSON output
  --dry-run           Preview without executing
  --limit N           Limit results (default: 50)
  --cursor <token>    Pagination cursor
  --timeout N         Timeout in seconds
  --help              Show this help

Examples:
  mytool health
  mytool list --type vm --region us-east-1
  mytool create my-server --type vm --dry-run
```

## 设计工作流

### 场景一：从零设计新 CLI

1. **明确受众** — 主要调用者是 Agent 还是人？如果是 Agent，遵循本方法论。
2. **列意图清单** — 列出 Agent 需要通过这个 CLI 完成的所有意图（不是 API 端点）。
3. **映射到动词** — 每个意图对应一个子命令，优先复用标准动词：

| 动词 | 语义 | 适用场景 |
|------|------|---------|
| `health` | 连通性检查 | 所有 CLI 必备 |
| `login` / `auth` | 认证/重新认证 | 有 session/token 的 CLI |
| `list` | 列出资源 | 几乎所有 CLI |
| `get` / `show` | 获取单个资源详情 | 几乎所有 CLI |
| `create` | 创建资源 | 写操作 |
| `update` / `set` | 修改资源 | 写操作 |
| `delete` / `remove` | 删除资源 | 写操作（破坏性） |
| `search` / `query` | 复杂条件查询 | 有搜索需求的 CLI |
| `status` | 查看运行状态/概览 | 仪表盘/监控类 |
| `wait` | 等待异步任务完成 | 有异步操作的 CLI |
| `watch` | 持续监听变更 | 实时流/事件类 |
| `export` / `import` | 批量导入导出 | 数据迁移场景 |

4. **设计输出** — 每个命令的 JSON 输出应包含 Agent 做下一步决策所需的全部信息。
5. **设计错误** — 列出每个命令可能的失败场景，为每个 error 写 suggestion。
6. **写 `--help`** — 确保顶层 help 列出全部命令+参数+示例。
7. **写 Agent 工具文档** — 确保命令表完整、示例可直接执行。
8. **用检查清单验收** — 逐条对照下方检查清单。

### 场景二：评审现有 CLI 的 Agent 友好度

运行以下检查：

```bash
# 1. help 是否自包含？（一次 --help 能否知道调什么）
<tool> --help

# 2. 输出是否是 JSON？
<tool> <some-command> 2>/dev/null | python3 -c "import sys,json; json.load(sys.stdin); print('✅ Valid JSON')"

# 3. 错误输出是否也是 JSON？
<tool> --nonexistent 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print('✅' if 'error' in d else '❌ no error field')"

# 4. 是否有修复建议？
<tool> --nonexistent 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print('✅' if 'suggestion' in d or 'hint' in d else '❌ no suggestion')"

# 5. 退出码是否有意义？
<tool> health; echo "exit: $?"
<tool> --nonexistent; echo "exit: $?"
```

### 场景三：把人类 CLI 改造为 Agent 友好

**改造步骤：**
1. 所有 stdout 包裹进统一 JSON 信封（成功/失败同一格式）
2. 日志、进度条、提示语全部改走 stderr
3. 所有 catch 块输出结构化错误（code + message + suggestion）
4. 添加 `--json` 或 `--output json` flag（如果要保留人类默认模式）
5. 添加 `--fields` flag 控制输出字段范围

## 设计检查清单

完成 CLI 设计后，逐条验证：

**可发现性**
- [ ] `--help` 一次列出全部命令+参数+示例
- [ ] 未知命令输出完整 help 而非只报错
- [ ] 空结果有引导（建议调整查询条件等）

**输出格式**
- [ ] stdout 全部是可 `JSON.parse()` 的（或有 `--json` flag 切换）
- [ ] 成功和失败用统一信封格式
- [ ] 日志/进度只写 stderr
- [ ] 支持按需选择输出字段
- [ ] 大结果集有分页（`--limit` + `--cursor`）

**错误处理**
- [ ] 每个 error 有机器可读分类码 + 人可读描述 + 修复建议
- [ ] 参数校验在发 HTTP 请求之前完成
- [ ] 凭据/配置缺失时立即报错并列出需要的项
- [ ] 退出码有意义（0=成功，非 0=失败，可细分）

**操作安全**
- [ ] 写操作支持 `--dry-run`
- [ ] 破坏性操作（delete/purge 等）有确认机制
- [ ] 写操作默认幂等（非幂等操作显式标注）
- [ ] 异步操作有 `wait` 子命令或 `--wait` flag

**凭据安全**
- [ ] stderr 日志中 token/password/key 已脱敏
- [ ] JSON 输出不含凭据
- [ ] 密钥文件不入版本控制

**文档一致性**
- [ ] `--help` 命令名 = 工具文档中的命令名 = JSON 输出字段名
- [ ] 文档中的命令表覆盖全部子命令
- [ ] 文档中的示例可直接 copy-paste 执行

## 反模式清单

| 反模式 | 问题 | 正确做法 |
|--------|------|---------|
| 默认输出表格/彩色文本 | Agent 无法解析 | 默认 JSON，或 `--json` 切换 |
| 错误输出纯文本 | Agent 无法分支处理 | 错误也是结构化 JSON |
| 只说 "Error: failed" | Agent 不知如何修复 | 必须有 code + suggestion |
| 列表只返回 ID | Agent 需要逐个二次查询 | 内联关键字段 |
| 嵌套 3 层 help | Agent 发现成本高 | 顶层 help 列全部命令+参数 |
| 写操作无预览 | 误操作不可逆 | `--dry-run` 先看后做 |
| 非幂等且不标注 | Agent 重试导致重复副作用 | 默认幂等，非幂等显式标注 |
| 一次返回 10 万条 | 撑爆上下文窗口 | 分页 + NDJSON 流式 |
| 凭据出现在 stdout | 泄漏到 Agent 上下文/日志 | 凭据只在认证阶段用，不输出 |
| API 端点当命令名 | `/api/v2/users/list` → `users-list` | 按意图命名：`list users` |

## 学习来源

本方法论综合以下顶级 CLI 的设计精华（均已通过官方文档验证）：

| CLI | 核心贡献 | 值得研究的命令 |
|-----|---------|---------------|
| **cloudflared** | 双通道输出、可操作错误、配置三层合成 | `cloudflared tunnel --help` |
| **GitHub CLI (`gh`)** | `--json fields` 字段精选、`--jq` 内置 JSON 过滤 | `gh pr list --json number,title` |
| **kubectl** | `--dry-run=client\|server`、声明式 `apply` 幂等操作、`-o jsonpath` | `kubectl apply --dry-run=server` |
| **Terraform** | `plan`→`apply` 两阶段分离、`-json` 机器可读 NDJSON 变更流 | `terraform plan -json` |
| **AWS CLI v2** | Waiter 模式（阻塞等待异步操作）、JMESPath `--query`、多格式输出（json/yaml/text/table 等 6 种） | `aws ec2 wait instance-running` |
| **ripgrep** | `--json` NDJSON 流式输出（JSON Lines 格式，每行一个结构化结果） | `rg --json "pattern"` |

> **关键点：** 不要照搬任何单个 CLI 的全部设计。每个 CLI 解决不同问题，取其精华组合。cloudflared 的错误处理 + gh 的字段精选 + kubectl 的 dry-run + AWS 的 waiter + ripgrep 的流式输出 = Agent 最佳体验。

## 约束

1. 本技能是通用设计方法论，不绑定任何特定项目、语言或运行时
2. 原则是方向性指导，具体实现需要根据项目技术栈和约束调整
3. 不是所有原则都必须一次性实现——按优先级递进：先做输出格式（原则 3）和错误处理（原则 7），再补充其他
