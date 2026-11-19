# 交付协议模板

这些模板是可选的结构参考，按任务复杂度取用，不由 AGENTS 脚手架自动写入每个业务仓库。已有 Issue、PR、任务系统或文档可承载同样内容，不必重复建文件。先读 [高频交付规则](../../delivery.md)。

| 模板 | 何时使用 | 建议放置 |
|------|----------|----------|
| [requirement.md](requirement.md) | 需求来源、范围、待澄清项或多条件验收需要追踪时 | 现有 Issue / 需求记录，可与任务合一 |
| [task.md](task.md) | 目标、接口或并行写入范围需要交接时 | Issue / PR / 任务记录 |
| [subsystem.md](subsystem.md) | 行为跨目录、跨仓库，反复需要定位时 | `docs/subsystems/` 或现有模块参考 |
| [lesson.md](lesson.md) | 重复缺陷、发布失败或漏检需要形成防线时 | Issue / 现有经验库 |
| [release-contract.md](release-contract.md) | 项目建立或调整发布链路时；每个发布单元一份 | `docs/delivery/` 或现有运行手册 |

需求流程见 [requirements.md](../../requirements.md)，经验生成与更新见 [delivery.md](../../delivery.md#经验记录如何生成与更新)，填写方式见 [需求到经验示例](../../docs/examples/requirements-to-lessons.md)。记录需填写实际来源和结果；模板不会自动收集外部反馈或生成经验文件。

发布契约由项目填写真实命令、目标与门禁；未填写的模板不构成可执行的流水线或发布授权。稳定事实只维护一处，模板中的占位说明不属于产品界面文案。版本、迁移、部署细则链接主题规则，不在每份记录中复制全文。
