# 产品概览 · 详细说明

> 本文件由 `PRODUCT_OVERVIEW.md` 索引，按需加载  
> 最后更新：2026-11-19

## 核心内容（展开）

- **双层结构**：主题文档顶部「硬约束」，正文为背景与模板。
- **AI 协作红线**（`ai-guardrails.md`，required）：写文件优先级、破坏性操作确认、共享分支、如实汇报、需求文本与界面文案边界、嵌套 `AGENTS.md`、生成文件保护。
- **编程**（`programming.md`）：风格、错误处理、测试、安全、日志。
- **多端设计**（`design.md`）：启动门禁、确认清单、UI 体系、多语言、各端规范。
- **前端**（`frontend.md`）、**Go**（`go.md`）、**Python**（`python.md`）。
- **数据库**：迁移、查询、同步（见 `database-*.md`）；迁移默认幂等。
- **需求与验收**（`requirements.md`，未发布）：来源与归并、增量澄清、范围与优先级、状态条件、需求修订到验收证据的追踪；可复用已有 Issue / 任务记录，不增加必选主题。
- **交付**（`delivery.md`）：任务与行为契约、独立工作区、共享资源协调、分层验证、经验触发、生成 / 更新、归并和防线验证；需求、任务、子系统、经验和发布契约五类可选模板在 `templates/delivery/`，填写示例在 `docs/examples/`，由业务项目择需采用。
- **部署**（`deployment.md`）：同 SHA / 产物门禁、不可变分发、按目标保护切换与回滚；**版本控制**（`version-control.md`）：开发片段、发布阶段统一版本与 CHANGELOG、原子预留和幂等重试；**Linux 运维**（`linux-server.md`）。
- **容量目标**：支持每天 30–50 次发版的机制，实际吞吐需在业务试点验证；不迁入 Magpie 的技术栈、产物数量、固定复盘阈值或未核实的调度方式。
- **工具链**：`generate_claude_md.rb`（完整/compact/index）、`generate_project_agents.rb`（分层 AGENTS）、`verify_rules.rb` + `rake test`、tag 发布 `CLAUDE.md` / `AGENTS.md`。
- **上下文预算**：通用入口 ≤300 行且 ≤20k 字符；`PRODUCT_OVERVIEW.md` / `ARCHITECTURE.md` ≤1k 字符；详见 `ai-guardrails.md`。

## 使用方式（展开）

- 新项目：判断阶段 → 缺则生成 `AGENTS.md`、`CLAUDE.md`、`PRODUCT_OVERVIEW.md`、`ARCHITECTURE.md`（见 `design.md`）。
- 业务项目根目录维护 `ARCHITECTURE.md`，边界变更同步；纯规则 / 生成器仓库不强制业务四文档门禁，本库保留概览与架构用于索引和自检。
- 第一轮沟通 6–8 个高价值主题；选型先给建议再确认。
- UI 沉淀 `docs/design-system.md`、`docs/ui-tokens.md`；DB/部署按主题规则。
- 规则变更记录变更说明，发布准备时同步版本与 `CHANGELOG.md`；产品能力 / 架构改变时同步对应正文。本库采用源码显式版本，业务高频项目可使用 CI 注入和唯一发布索引。
- 叠加画像：`--profile go-api --profile delivery`，交付画像包含需求主题；可用 `--docs requirements` 单独选择。项目脚手架默认 index，离线可显式 compact；已有根 / 模块规则保持不变。
- 生成规则：`ruby scripts/generate_claude_md.rb --list`；项目脚手架 `--dry-run` 后实跑。
- 概览类文档按需读，不全量进每轮上下文。

## 维护规则

- 单文件 >2000 行考虑拆，>3000 行必拆；新规范独立成章再挂 README。
- 规则须可执行（MUST/MUST NOT）；高风险规则写清风险与处理。

## 已知问题 / 待办

- [ ] README 链接与行数自动化校验增强。
- [ ] 设计规范：新项目设计简报模板。
