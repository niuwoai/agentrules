<!-- GENERATED FILE — DO NOT EDIT.
     Source: Willdeep rule documents and scripts/generate_claude_md.rb -->

# GENERATED_CLAUDE.md

> 由 `scripts/generate_claude_md.rb` 生成；请修改规则源文件后重新生成。
> 规则画像：自定义选择
> 生成来源：Willdeep 规则库。
> 规范地址：`https://github.com/niuwoai/agentrules/blob/main/CLAUDE.md`
> 模式：对外发布概要索引（--index），规则正文在 GitHub 按需读取，不内嵌于本文件。

## 使用说明

- **本文件是概要索引**，不把各主题「硬约束」正文塞进系统提示；保持短，避免上下文膨胀。
- **规范全集地址**：https://github.com/niuwoai/agentrules/blob/main/CLAUDE.md（与本文件同源，随仓库发布更新）。
- **按需加载主题规则**：仅当任务命中时，再读取下方链接对应文件；不要因看到文件名列表就一次性拉取全部规则。
- **URL 推导**：主题规则默认位于同一仓库 `main` 分支根目录，模式为 `https://github.com/niuwoai/agentrules/blob/main/<文件名>`；索引未列出的主题也仅在任务相关时读取。
- **本地优先**：工作区已克隆 agentrules 或已 vendor 同名文件时优先读本地文件。
- **优先级**：系统 / 开发者 / 用户指令 > 目标仓库内更具体的 `AGENTS.md` / `CLAUDE.md` > 本索引。
- **按任务读取**：改代码先读 `ai-guardrails.md`、`programming.md`；提交或版本读 `version-control.md`；并行协作或交付读 `delivery.md`；发布读 `deployment.md`；UI 读 `design.md` / `frontend.md`。
- 不得输出或提交密钥、Token、凭据、个人隐私数据。

## 始终遵守（精简）

下文是跨任务底线；细则与例外见按需规则索引。

**协作与安全**

- 改文件优先 patch/编辑工具，禁止用 shell 覆写；破坏性操作先确认；禁止 force-push 共享分支；测试失败如实报，不宣称已完成。
- 不输出/提交密钥与凭据；不探测读取私钥、`.env`、token 文件。
- 不改 `GENERATED FILE — DO NOT EDIT` 产物，改源文件后重新生成；改动范围与任务一致。

**需求与界面**

- 不要把需求、验收、Prompt、实现参数当用户界面文案；实现行为由代码完成，界面少字、可点即懂。
- 用户可见文案走 i18n；新项目先落启动文档再大规模编码；关键决策写仓库文档，不单靠聊天记录。

**工程**

- SQL 参数化；核心逻辑有测；错误带上下文；单文件超过 3000 行必须拆分。
- 开发记录独立变更片段；发布阶段统一分配版本、归并 CHANGELOG 与版本文档。提交不等于发布，tag / 推送按授权执行，见 `version-control.md`。
- 并行任务隔离工作区并明确所有权；验证证据关联当前候选，见 `delivery.md`。
- 入口文档控体量：概览类 ≤300 行且 ≤20k 字符，产品/架构主文 ≤1k 字符，超限索引化到 `docs/`。
- Schema 迁移与回滚按 `database-migrations.md`；发布前置条件与流量切换按 `deployment.md`。
- 业务代码仓库维护 README、CHANGELOG、产品与架构入口；规则库仓库不强制业务四文档门禁，以 README、CHANGELOG 与校验为准，见 `version-control.md`。

## 按需规则索引
- [AI 协作红线](https://github.com/niuwoai/agentrules/blob/main/ai-guardrails.md)（`ai-guardrails.md`）：文件编辑方式、破坏性操作确认、需求文本与产品文案边界、界面要求与实现行为分离、共享分支保护和如实汇报
- [编程通用规范](https://github.com/niuwoai/agentrules/blob/main/programming.md)（`programming.md`）：代码风格、错误处理、测试、版本控制、安全和日志
- [多端产品设计规范](https://github.com/niuwoai/agentrules/blob/main/design.md)（`design.md`）：新项目启动门禁、界面呈现与实现行为分离、UI 规范方向和多端规范
- [前端规范](https://github.com/niuwoai/agentrules/blob/main/frontend.md)（`frontend.md`）：TypeScript、React、状态管理、CSS、性能、安全和测试
- [Go 规范](https://github.com/niuwoai/agentrules/blob/main/go.md)（`go.md`）：Go 项目结构、错误处理、并发、DI、测试、性能和 Go + React embed
- [Python 规范](https://github.com/niuwoai/agentrules/blob/main/python.md)（`python.md`）：Python 环境、类型、异步、数据库、测试和常用库
- [数据库迁移规范](https://github.com/niuwoai/agentrules/blob/main/database-migrations.md)（`database-migrations.md`）：迁移版本、建表、索引、启动迁移、回滚和 CI/CD
- [数据库查询规范](https://github.com/niuwoai/agentrules/blob/main/database-queries.md)（`database-queries.md`）：SQL 编写、索引、查询优化、EXPLAIN 和 ORM
- [数据库同步规范](https://github.com/niuwoai/agentrules/blob/main/database-sync.md)（`database-sync.md`）：全量、增量、实时同步、一致性、冲突解决和监控
- [高频交付与并行协作](https://github.com/niuwoai/agentrules/blob/main/delivery.md)（`delivery.md`）：任务与工作区所有权、行为契约、集成证据、分层验证和事故反馈
- [服务部署规范](https://github.com/niuwoai/agentrules/blob/main/deployment.md)（`deployment.md`）：发布检查、迁移、产物备份、健康检查、回滚和 CI/CD
- [Linux 服务器规范](https://github.com/niuwoai/agentrules/blob/main/linux-server.md)（`linux-server.md`）：安全基线、监控、备份、日志、性能调优、Docker 和应急响应
- [版本管理规范](https://github.com/niuwoai/agentrules/blob/main/version-control.md)（`version-control.md`）：分支策略、语义化版本、Build 号、CHANGELOG、.gitignore 和 Git 工作流
