# 本仓库架构 · 详细说明

> 本文件由 `ARCHITECTURE.md` 索引，按需加载  
> 最后更新：2026-09-30

## 模块与职责（完整表）

| 模块 | 职责 | 依赖 |
|------|------|------|
| 根目录主题文档 | 编程/设计/版本/部署/DB/前端等规范；硬约束 + 正文 | Markdown 交叉引用 |
| `PRODUCT_OVERVIEW.md` | 用途、能力摘要、子文档入口 | CHANGELOG、主题文档 |
| `ARCHITECTURE.md` | 边界与演进摘要、子文档入口 | README、脚本 |
| `CHANGELOG.md` | 按版本记录变更 | 发版时同步 |
| `scripts/generate_claude_md.rb` | 画像整合规则；`--compact` / `--index` | Ruby；可选 tty-prompt |
| `scripts/generate_project_agents.rb` | 扫描项目、模板化分层 `AGENTS.md`；不覆盖已有 | 生成器、ERB |
| `templates/agents/` | AGENTS 初始结构（Scope、Parent） | ERB |
| `scripts/verify_rules.rb` | 硬约束、版本、体量预算、生成产物、脚手架 | Ruby |
| `Rakefile` | `rake test` → verify `--no-report` | Rake |
| `.github/workflows/*` | PR 校验；tag 发布 Release 附件 | Actions |

## 数据与接口

- 数据载体为 Markdown；Git 追溯版本。
- 生成器读主题文件组合输出；脚手架只扫构建清单，不读业务数据、不暴露 API、不存凭据。

## 部署与运行

- 本地验证：`rake test`（stdout only，失败非零退出）。
- 发布：Git + tag；CI 校验后 tag 触发 Release 附 `CLAUDE.md` / `AGENTS.md`。
- Ruby 环境；`tty-prompt` 可选。

## 关键决策与演进

- 主题拆分 Markdown，按画像组合。
- 全局 Agent 索引模式，详细规范按需读。
- 分层 AGENTS：根基线 + 子级差异 + Parent 链；脚手架不覆盖。
- 根 `ARCHITECTURE.md` 为架构事实来源；细节在子目录 README / ADR / 本子文档。
- 新产品/架构变更必须更新架构文档；入口文档超预算索引化到 `docs/`。
