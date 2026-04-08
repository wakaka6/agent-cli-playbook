# agent-cli-playbook

为 LLM Agent 设计命令行工具的方法论。

## 这是什么

一份结构化的设计原则集，帮你构建**Agent 能正确调用**的 CLI 工具。不限语言、不限领域——DevOps、数据管道、SaaS API、安全运维都适用。

## 核心认知

Agent 消费 CLI 的方式和人类完全不同：

- Agent 通过 `--help` 发现能力，不读 Markdown 文档
- Agent 用 `JSON.parse(stdout)` 解析输出，不看表格和颜色
- Agent 靠错误中的 `suggestion` 字段自动修复，不读 Stack Overflow
- Agent 会重试，需要幂等保证

## 16 条设计原则

| 层 | 原则 | 学谁 |
|----|------|------|
| **可发现** | CLI 即文档、文档即接口 | cloudflared, Cloudflare llms.txt |
| **输出** | 双通道输出、字段精选、流式分页、输出自包含 | cloudflared, GitHub CLI, ripgrep |
| **错误** | 可操作错误、早校验快失败、凭据安全 | cloudflared |
| **操作安全** | 安全试运行、幂等操作、异步等待 | kubectl, Terraform, AWS CLI |
| **工程** | 命令无歧义、命令正交、配置优先级、最短路径 | POSIX, kubectl, cloudflared |

每条原则均已通过官方文档验证来源。详见 [SKILL.md](./SKILL.md)。

## 用法

### 作为 Agent Skill

将本仓库作为 Agent 技能加载。当 Agent 需要设计、评审或重构 CLI 时，自动激活。

### 作为设计参考

阅读 [SKILL.md](./SKILL.md) 中的：
- **设计原则速查** — 16 条原则分 5 层，逐条对照
- **推荐输出模式** — JSON 信封格式、错误码分类
- **设计检查清单** — 完成后逐条打勾
- **反模式清单** — 10 个常见陷阱

## 学习来源

综合以下顶级 CLI 的设计精华：

| CLI | 核心贡献 |
|-----|---------|
| cloudflared | 双通道输出、可操作错误、配置三层合成 |
| GitHub CLI (`gh`) | `--json fields` 字段精选、`--jq` 内置过滤 |
| kubectl | `--dry-run=client\|server`、声明式 `apply` 幂等 |
| Terraform | `plan`→`apply` 分离、`-json` NDJSON 变更流 |
| AWS CLI v2 | Waiter 模式、JMESPath `--query` |
| ripgrep | `--json` NDJSON 流式输出 |

## License

MIT
