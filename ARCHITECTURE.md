# Architecture

> 最后更新：2026-03-22 | 当前版本：v0.28.32

## 架构概览

Markdown 规则库 + Ruby 生成/校验；无运行时服务。可读主题、生成 `CLAUDE.md`/`AGENTS.md` 包，或脚手架分层 `AGENTS.md`。

## 上下文（摘要）
人/AI → 主题 md → 画像整合（full/compact/index）；脚手架 → 根+模块 `AGENTS.md`。

## 文档入口
| 子文档 | 何时读 |
|--------|--------|
| [docs/architecture/repository.md](docs/architecture/repository.md) | 模块表、CI、部署、关键决策 |
| [PRODUCT_OVERVIEW.md](PRODUCT_OVERVIEW.md) | 能力与版本 |

## 约束
本文件主文 ≤1k 字符；细节在 `docs/architecture/`，按需 `read_file`。
