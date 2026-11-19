# Product Overview

> 最后更新：2026-11-19 | 当前版本：v0.30.35

## 项目简介
Willdeep 规则库：面向 AI 与开发者的通用工程规范及 Ruby 工具，支持按需上下文、并行协作和可验证交付；不绑定业务栈或 CI 平台。

## 核心能力
- 主题「硬约束 + 正文」，按画像生成 full / compact / index。
- 可叠加交付画像：工作区隔离、行为契约、集中分配版本、同候选门禁和按目标保护发布切换。
- 需求到验收与经验反馈规则，配套需求、任务、子系统、经验和发布契约模板；项目 AGENTS 默认索引，保留已有文件。
- `rake test` 校验规则、生成器和版本；tag 分发规则附件。

## 文档入口
| 子文档 | 何时读 |
|--------|--------|
| [docs/product/overview-details.md](docs/product/overview-details.md) | 能力与维护 |
| [delivery.md](delivery.md) | 并行高频交付 |
| [README.md](README.md) | 主题、模板与命令 |
| [ARCHITECTURE.md](ARCHITECTURE.md) | 工具与边界 |

## 限制
30–50 次日发版是业务流水线的容量目标，尚无试点实测；本仓库不提供业务发布调度器。
