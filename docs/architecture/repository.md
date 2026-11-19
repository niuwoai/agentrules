# 本仓库架构 · 详细说明

> 本文件由 `ARCHITECTURE.md` 索引，按需加载  
> 最后更新：2026-11-19

## 模块与职责（完整表）

| 模块 | 职责 | 依赖 |
|------|------|------|
| 根目录主题文档 | 编程/设计/版本/部署/DB/前端等规范；硬约束 + 正文 | Markdown 交叉引用 |
| `PRODUCT_OVERVIEW.md` | 用途、能力摘要、子文档入口 | CHANGELOG、主题文档 |
| `ARCHITECTURE.md` | 边界与演进摘要、子文档入口 | README、脚本 |
| `CHANGELOG.md` | 按版本记录变更 | 发版时同步 |
| `scripts/generate_claude_md.rb` | 画像叠加与主题去重；full / compact / index；交付画像可选 | Ruby；可选 tty-prompt |
| `scripts/generate_project_agents.rb` | 扫描项目、分层 `AGENTS.md`；默认索引，显式 compact；不覆盖已有 | 生成器、ERB |
| `templates/agents/` | AGENTS 初始结构（Scope、Parent、按需入口） | ERB |
| `requirements.md`、`delivery.md`、`templates/delivery/` | 需求到验收与经验反馈协议、五类可选模板；复用现有记录，不自动收集或生成 | 主题规则链接 |
| `docs/examples/requirements-to-lessons.md` | 从来源到验收及经验更新的虚构示例，不作为真实验证证据 | 需求 / 交付规则、模板 |
| `scripts/verify_rules.rb` | 硬约束、版本、体量预算、画像组合、生成产物、脚手架、发布步骤回归 | Ruby |
| `tests/release_workflow_test.rb` | 隔离执行真实发布 shell；假的 gh 模拟远端状态与失败 | Minitest、YAML |
| `Rakefile` | `rake test` → verify `--no-report` | Rake |
| `.github/workflows/*` | PR 校验；tag 发布 Release 附件 | Actions |

## 数据与接口

- 数据载体为 Markdown；Git 追溯版本。
- 生成器读主题文件组合输出；脚手架只扫构建清单，不读业务数据、不暴露 API、不存凭据。

## 部署与运行

- 本地验证：`rake test`（stdout only，失败非零退出）。
- 发布：默认分支上的 tag 触发，在该 SHA 执行验证，再生成规则附件；先建草稿，仅上传缺失附件，下载逐文件核对后公开。已有同内容附件复用，不覆盖；公开版本缺附件或内容冲突时失败并保留现场。同 tag 互斥，不同 tag 可并行，不推进共享 Latest。
- 发布回归用假的 gh 操作系统临时目录，覆盖新建、重试、部分上传、摘要内容冲突及网络失败；不访问 GitHub，不执行生产部署。在线 Actions、权限和真实网络行为仍需实际运行核实。
- Ruby 环境；`tty-prompt` 可选。

## 关键决策与演进

- 主题拆分 Markdown，按画像组合；需求主题可单独选择或随交付画像叠加（未发布），required 仍是协作红线、编程和版本三项。已有 Issue / 需求 / 经验正文是各自事实来源，模板不另建平行台账。
- 全局 Agent 索引模式，详细规范按需读。
- 分层 AGENTS：根索引 + 子级差异 + Parent 链；画像可叠加，按主题 key 去重；脚手架不覆盖。fragment 不重复常驻说明，交付模板按需取用而非扫描即创建。
- 协议边界：开发与构建并行，版本由发布单元集中预留，共享目标的切换需防过期写入；具体机制由业务项目实现，本库不增加调度服务。
- 根 `ARCHITECTURE.md` 为架构事实来源；细节在子目录 README / ADR / 本子文档。
- 新产品/架构变更必须更新架构文档；入口文档超预算索引化到 `docs/`。
