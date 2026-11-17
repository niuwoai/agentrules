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
- **URL 推导**：主题规则默认位于同一仓库 `main` 分支根目录，模式为 `https://github.com/niuwoai/agentrules/blob/main/<文件名>`。例如 `ai-guardrails.md` → `https://github.com/niuwoai/agentrules/blob/main/ai-guardrails.md`；索引未列出的其它 `.md` 规则（若存在）按同模式推导，仅在与任务相关时读取。
- **本地优先**：若工作区已克隆 [niuwoai/agentrules](https://github.com/niuwoai/agentrules) 或已 vendor 同名文件，优先读本地文件，与远程内容冲突时以**目标业务仓库**内更具体的 `AGENTS.md` / `CLAUDE.md` 为准。
- **优先级**：系统 / 开发者 / 用户指令 > 目标仓库内更具体的 `AGENTS.md` / `CLAUDE.md` > 本索引。
- **最低必读（涉及改代码时）**：先读 `ai-guardrails.md`、`programming.md`；提交、发版、打 tag 再读 `version-control.md`；UI 相关再读 `design.md` / `frontend.md`。
- 不得输出或提交密钥、Token、凭据、个人隐私数据。

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
- [服务部署规范](https://github.com/niuwoai/agentrules/blob/main/deployment.md)（`deployment.md`）：发布检查、迁移、产物备份、健康检查、回滚和 CI/CD
- [Linux 服务器规范](https://github.com/niuwoai/agentrules/blob/main/linux-server.md)（`linux-server.md`）：安全基线、监控、备份、日志、性能调优、Docker 和应急响应
- [版本管理规范](https://github.com/niuwoai/agentrules/blob/main/version-control.md)（`version-control.md`）：分支策略、语义化版本、Build 号、CHANGELOG、.gitignore 和 Git 工作流
