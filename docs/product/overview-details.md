# 产品概览 · 详细说明

> 本文件由 `PRODUCT_OVERVIEW.md` 索引，按需加载  
> 最后更新：2026-09-30

## 核心内容（展开）

- **双层结构**：主题文档顶部「硬约束」，正文为背景与模板。
- **AI 协作红线**（`ai-guardrails.md`，required）：写文件优先级、破坏性操作确认、共享分支、如实汇报、需求文本与界面文案边界、嵌套 `AGENTS.md`、生成文件保护。
- **编程**（`programming.md`）：风格、错误处理、测试、安全、日志。
- **多端设计**（`design.md`）：启动门禁、确认清单、UI 体系、多语言、各端规范。
- **前端**（`frontend.md`）、**Go**（`go.md`）、**Python**（`python.md`）。
- **数据库**：迁移、查询、同步（见 `database-*.md`）；迁移默认幂等。
- **部署**（`deployment.md`）、**版本控制**（`version-control.md`）、**Linux 运维**（`linux-server.md`）。
- **工具链**：`generate_claude_md.rb`（完整/compact/index）、`generate_project_agents.rb`（分层 AGENTS）、`verify_rules.rb` + `rake test`、tag 发布 `CLAUDE.md` / `AGENTS.md`。
- **上下文预算**：通用入口 ≤300 行且 ≤20k 字符；`PRODUCT_OVERVIEW.md` / `ARCHITECTURE.md` ≤1k 字符；详见 `ai-guardrails.md`。

## 使用方式（展开）

- 新项目：判断阶段 → 缺则生成 `AGENTS.md`、`CLAUDE.md`、`PRODUCT_OVERVIEW.md`、`ARCHITECTURE.md`（见 `design.md`）。
- 根目录必须有 `ARCHITECTURE.md`；边界变更须同步。
- 第一轮沟通 6–8 个高价值主题；选型先给建议再确认。
- UI 沉淀 `docs/design-system.md`、`docs/ui-tokens.md`；DB/部署按主题规则。
- 规则变更同步 `CHANGELOG.md` 与 `PRODUCT_OVERVIEW.md` 摘要。
- 生成规则：`ruby scripts/generate_claude_md.rb --list`；项目脚手架 `--dry-run` 后实跑。
- 概览类文档按需读，不全量进每轮上下文。

## 维护规则

- 单文件 >2000 行考虑拆，>3000 行必拆；新规范独立成章再挂 README。
- 规则须可执行（MUST/MUST NOT）；高风险规则写清风险与处理。

## 已知问题 / 待办

- [ ] README 链接与行数自动化校验增强。
- [ ] 设计规范：新项目设计简报模板。
