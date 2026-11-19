# Willdeep 规则库

这些是我日常工作中积累的最佳实践，写代码/做技术决策时可以参考。

每个主题文档顶部有「**硬约束**」小节——只含 MUST / MUST NOT 的 AI 必守清单；正文是背景、模板和细节，按需阅读。对外发布的 **`CLAUDE.md`** 为概要索引（含 [规范地址](https://github.com/niuwoai/agentrules/blob/main/CLAUDE.md) 与主题链接），Agent 按任务按需加载 `ai-guardrails.md` 等，避免系统提示过长。本地离线集成可用 `--compact` 内嵌硬约束；`AGENTS.md` 用 `--index` 生成同类索引。

## 通用
| 文件 | 内容 |
|------|------|
| [ai-guardrails.md](ai-guardrails.md) | AI 协作红线：文件编辑方式、破坏性操作确认、共享分支保护、如实汇报、需求文本与产品文案边界、界面要求与实现行为分离、长文档索引化与上下文预算 |
| [programming.md](programming.md) | 编程：代码风格、错误处理、测试、设计原则、安全、日志 |
| [delivery.md](delivery.md) | 高频交付：任务与行为契约、worktree 所有权、分层验证、并发边界、事故反馈 |
| [design.md](design.md) | 多端设计：新项目启动门禁、第一轮确认清单、启动文档模板、UI 体系、多端规范 |
| [version-control.md](version-control.md) | 版本管理：分支策略、语义化版本、CHANGELOG、Product Overview、Architecture 文档、Git 工作流 |
| [deployment.md](deployment.md) | 服务部署：发布检查、迁移、产物备份、健康检查、回滚、CI/CD |
| [database-migrations.md](database-migrations.md) | 数据库迁移：版本管理、执行规范、回滚、工具选择、CI/CD 集成 |
| [database-queries.md](database-queries.md) | 数据库查询：SQL 规范、索引设计、查询优化、EXPLAIN、ORM |
| [database-sync.md](database-sync.md) | 数据库同步：同步策略、增量设计、一致性、冲突解决、工具选型 |
| [linux-server.md](linux-server.md) | Linux 服务器：安全基线、监控、备份、日志、性能调优、Docker、应急响应 |

## 语言/平台
| 文件 | 内容 |
|------|------|
| [go.md](go.md) | Go：项目结构、命名、错误处理、并发、DI、测试、性能、常用库 |
| [python.md](python.md) | Python：环境、风格、类型注解、异步、SQLAlchemy、FastAPI、测试 |
| [frontend.md](frontend.md) | 前端：TypeScript、React、状态管理、CSS、性能、Vite、安全 |

## 项目文档
| 文件 | 内容 |
|------|------|
| [CHANGELOG.md](CHANGELOG.md) | 规则库变更记录 |
| [PRODUCT_OVERVIEW.md](PRODUCT_OVERVIEW.md) | 规则库当前状态、适用范围和维护说明 |
| [ARCHITECTURE.md](ARCHITECTURE.md) | 规则库架构、文档边界和维护方式 |
| [Magpie agent 开发方式研究](docs/research/magpie-agent-development-2026-11-19.md) | 文档与协作协议、自动化链路、交付统计及证据边界 |

## 工具脚本
| 文件 | 内容 |
|------|------|
| [scripts/generate_claude_md.rb](scripts/generate_claude_md.rb) | 交互选择规则文档并生成 AI 协作规则；`--compact` 输出硬约束精简版，`--index` 输出不含主题正文的按需索引版 |
| [scripts/generate_project_agents.rb](scripts/generate_project_agents.rb) | 扫描目标项目并生成分层 `AGENTS.md`：支持通用、React、Go API、Go + React 模板；已有文件一律跳过，不覆盖人工规则 |
| [templates/agents/](templates/agents/) | 根目录与模块级 `AGENTS.md` 的可维护 ERB 模板 |
| [templates/delivery/](templates/delivery/) | 可选任务、子系统、经验和发布契约模板，复用既有 Issue / PR / 文档即可 |
| [tests/release_workflow_test.rb](tests/release_workflow_test.rb) | 隔离执行实际附件发布步骤，使用假的 gh 覆盖重试、内容冲突、部分上传和网络失败，不访问 GitHub |
| [scripts/verify_rules.rb](scripts/verify_rules.rb) | 校验规则结构、必选规则、版本一致性、入口文档体量预算、生成产物和嵌套 AGENTS 上溯链，并集成测试项目脚手架的重复执行安全性；输出 JSON + Markdown 报告，加 `--no-report` 则只打印到 stdout 不落盘 |
| [Rakefile](Rakefile) | 本地验证入口：`rake test`（也是默认任务）执行 `ruby scripts/verify_rules.rb --no-report`，报告只打印到 stdout，不生成 `tmp/` 报告、不改动工作区；校验失败时 rake 以非零退出码结束 |
| [.github/workflows/verify-rules.yml](.github/workflows/verify-rules.yml) | 在 PR、合并队列与分支推送时执行规则校验，并上传报告 |
| [.github/workflows/release-claude.yml](.github/workflows/release-claude.yml) | 校验默认分支 tag 的实际 SHA，草稿准备 `CLAUDE.md` / `AGENTS.md` 并下载核对后公开；同 tag 重试互斥、附件不覆盖，不推进共享 Latest |

## 本地验证

```bash
rake test
```

`rake test` 就是 `ruby scripts/verify_rules.rb --no-report`：报告打到 stdout、不落盘，跑完工作区保持不变；不带参数的 `rake` 默认也是这个任务。失败时命令以非零退出码结束。系统 Ruby + Rake 即可，不需要 bundler。

## 生成全局精简索引

```bash
ruby scripts/generate_claude_md.rb --all --index --output AGENTS.md --force
```

索引版只保留使用说明、优先级和主题链接。AI 应按任务读取直接相关的源规则，不应在开工时批量加载整个规则库。
需要生成离线目录内的相对链接时，增加 `--index-base .`。

## 支持每天 30–50 次小步发版

从 [delivery.md](delivery.md) 开始，为项目定义发布单元与 [发布契约](templates/delivery/release-contract.md)：开发、审查和打包可并行，版本统一分配，共享目标的切换有序且拒绝过期任务。具体版本、产物、部署与迁移要求分别由对应主题维护。

先落地一个可验证、可恢复的发布单元，再测队列等待、检查耗时、发布失败 / 回滚率，逐步增加并行度。30–50 次是容量目标，本规则库尚未提供业务流水线的吞吐实测，也不提供通用发布调度器。

交付画像可叠加技术画像，不必在所有项目常驻加载完整主题：

```bash
ruby scripts/generate_claude_md.rb --profile go-api --profile delivery --index --output AGENTS.md
```

[四类模板](templates/delivery/README.md) 按需取用；简单任务写在现有 Issue / PR 即可，不强制每次交付新建文档。Magpie 的技术栈、固定产物数、复盘天数和业务规则不迁入通用要求。

## 为项目生成分层 AGENTS.md

先预览生成计划：

```bash
ruby scripts/generate_project_agents.rb --target /path/to/project --dry-run
```

确认后生成：

```bash
ruby scripts/generate_project_agents.rb --target /path/to/project
```

脚本会自动识别通用、React、Go API 或 Go + React 项目，也可用 `--template` 明确指定。根规则默认 `--rules-mode index`；离线使用可选 `--rules-mode compact`。使用可重复的 `--profile` 叠加画像，例如：

```bash
ruby scripts/generate_project_agents.rb --target /path/to/project --profile delivery --dry-run
```

脚本只创建缺失的 `AGENTS.md`，已有根 / 模块文件均报告为 `skipped`；不会创建交付模板或覆盖已有规则。已有项目升级需审阅后合入索引 / 规则补丁，重新运行脚手架不会自动更新旧文件。可通过 `--json-output` 和 `--markdown-output` 保存审计报告。

> 这些不是教条，是我踩过坑之后总结的。有不同意见随时改。
