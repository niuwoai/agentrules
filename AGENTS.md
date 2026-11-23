<!-- SCAFFOLDED FILE — REVIEW AND CUSTOMIZE.
     Created by Willdeep scripts/generate_project_agents.rb; the generator will never overwrite it. -->

# agentrules — Agent Instructions

> **Scope:** 仓库根目录及全部子目录。
> **Template:** `generic`；子目录 `AGENTS.md` 只补充局部规则；系统 / 开发者 / 用户指令优先于仓库规则，局部规则仅覆盖父级冲突条目。

## 项目上下文

- 按任务读取已有入口：产品行为与范围查 `PRODUCT_OVERVIEW.md`，模块边界与数据流查 `ARCHITECTURE.md`，开发运行查 `README.md` 和当前目录构建清单。
- 只沿相关入口补读需要的子文档；这些参考文档不要求每轮全部读取，缺失时先核对仓库实际结构。
- 持久规则与行为契约更新所属仓库文档，不把聊天记录当作唯一事实来源。

## 常用命令

- 按根目录规则运行相关测试；不要凭空猜测命令。

## Willdeep 规则基线

- 索引模式下，修改代码前先读取 `ai-guardrails.md`、`programming.md`；提交或处理版本时读取 `version-control.md`。
- 需求收集、澄清与验收读 `requirements.md`；并行协作与经验记录读 `delivery.md`；发布、界面任务分别按需读取 `deployment.md`、`design.md` / `frontend.md`，不一次性加载全部主题。
- 优先读本地 vendor 规则，否则使用下方链接；未列出的相关主题按同一链接根路径定位。compact 已嵌入所选硬约束，背景细则按需补读。

## 按需规则索引
- [编程通用规范](https://github.com/niuwoai/agentrules/blob/main/programming.md)（`programming.md`）：代码风格、错误处理、测试、版本控制、安全和日志
- [多端产品设计规范](https://github.com/niuwoai/agentrules/blob/main/design.md)（`design.md`）：新项目启动门禁、界面呈现与实现行为分离、UI 规范方向和多端规范
- [版本管理规范](https://github.com/niuwoai/agentrules/blob/main/version-control.md)（`version-control.md`）：分支策略、语义化版本、Build 号、CHANGELOG、.gitignore 和 Git 工作流
- [AI 协作红线](https://github.com/niuwoai/agentrules/blob/main/ai-guardrails.md)（`ai-guardrails.md`）：文件编辑方式、破坏性操作确认、需求文本与产品文案边界、界面要求与实现行为分离、共享分支保护和如实汇报
