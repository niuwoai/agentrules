# Changelog

## [0.28.00031] - 2026-03-22

### Changed
- `CLAUDE.md` **「始终遵守（精简）」** 增补：Schema 变更须有 `up`/`down` 迁移；业务仓库维护 README / CHANGELOG / PRODUCT_OVERVIEW / ARCHITECTURE。
- 主 `CHANGELOG.md` 超出 300 行预算，将 `0.28.00028` 至 `0.1.0` 归档至 `docs/changelog/v0.27-and-earlier.md`。
- 规则库版本提升到 0.28.00031。

### Verification
- `rake test`：PASS

## [0.28.00030] - 2026-03-22

### Changed
- `CLAUDE.md` 在概要索引中新增 **「始终遵守（精简）」**：常驻协作/安全、需求与界面、工程底线；主题规则仍按需从 GitHub 加载。
- 规则库版本提升到 0.28.00030。

### Verification
- `rake test`：PASS

## [0.28.00029] - 2026-03-22

### Changed
- `CLAUDE.md` / `GENERATED_CLAUDE.md` 改为 **`--all --index` 概要索引**：标明规范地址 `https://github.com/niuwoai/agentrules/blob/main/CLAUDE.md`，主题规则链至 `niuwoai/agentrules` 默认分支，Agent 按任务推导并加载 `ai-guardrails.md` 等，不再内嵌硬约束正文以控制提示长度。
- `scripts/generate_claude_md.rb`：默认仓库 URL 改为 niuwoai；为 `CLAUDE.md` 输出增强索引说明（URL 推导、本地优先）。
- `scripts/verify_rules.rb`、`release-claude.yml`、`README.md` 与发布流程对齐索引版 CLAUDE。
- 规则库版本提升到 0.28.00029。

### Verification
- `rake test`：PASS

## 历史归档

- [v0.27 及更早版本](docs/changelog/v0.27-and-earlier.md)（含 0.28.00028 至 0.1.0）

