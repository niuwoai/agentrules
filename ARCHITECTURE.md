# Architecture

> 最后更新：2026-11-19 | 当前版本：v0.30.36

## 架构概览
Markdown 规则源 + Ruby 生成 / 校验，无运行时服务、数据库或业务发布调度器。

## 模块与数据流
主题规则 → 画像选择与去重 → full / compact / index；项目清单 → 根与模块 AGENTS。交付画像叠加需求与验收主题；需求、任务及经验记录由项目选用，不自动收集反馈或生成整套文档。项目 AGENTS 默认索引；已存在规则不覆盖。

## 交付边界
版本与 CHANGELOG 在发布阶段收口；构建可并行，共享目标的切换需保护顺序。业务系统实现自己的分配器、检查门禁、部署锁与恢复机制；本库只校验规则和工具行为。

## 文档入口
| 子文档 | 何时读 |
|--------|--------|
| [docs/architecture/repository.md](docs/architecture/repository.md) | 生成器、验证与 CI |
| [delivery.md](delivery.md) | 通用协作协议 |
| [PRODUCT_OVERVIEW.md](PRODUCT_OVERVIEW.md) | 能力与版本 |

## 约束
本主文 ≤1,000 字符，细节按需读取。
