# 数据库迁移最佳实践

## 硬约束

> 本节是 AI 必守清单，违反即错误；下文各节是背景、示例和细节，按需阅读。

- **MUST**：所有 DDL 变更走迁移文件，禁止手改数据库
- **MUST**：up/down 成对，down 必须实际测试过；删字段/删表的 down 先备份数据
- **MUST**：每张业务表有主键（自增 BIGINT 或 UUID）、`created_at`、`updated_at`
- **MUST**：所有外键列建索引；索引命名 `idx_<表>_<列>` / `uk_<表>_<列>`
- **MUST**：依赖新结构的代码承载流量前，必要迁移必须已成功且状态兼容；可由启动流程或受控迁移 Job 执行，失败阻断对应发布并输出迁移版本、文件名和错误上下文
- **MUST**：多实例或并行发布访问同一数据库时，迁移必须使用该数据库共享的锁（数据库锁 / 迁移工具自带锁 / 分布式锁），不能只在各自 CI job 内互斥
- **MUST**：滚动或并行发布的 Schema、数据与 API / 事件兼容窗口覆盖仍在运行及计划回滚的版本；破坏性收缩在旧读写者退出、回滚窗口结束后单独审批执行
- **MUST**：提供 `migrate up` / `migrate down --steps N` / `migrate status` CLI 子命令
- **MUST**：迁移必须尽可能幂等，可安全重复执行；只有目标数据库确实无法支持幂等实现时，才允许例外，并必须记录原因、前置条件、一次性执行保护与安全重试/恢复方案
- **MUST**：prod 迁移前确认最近备份可恢复
- **MUST**：高风险迁移（大表 DDL、不可逆数据变更、删字段/删表）人工审批，不随启动自动执行
- **MUST NOT**：修改已提交的迁移文件
- **MUST NOT**：一个迁移混多件事（加字段 + 建索引 + 改表名拆开写）
- **MUST NOT**：`migration down` 在未确认备份和影响范围前执行

## 迁移文件管理
- **版本化**：每个迁移文件有唯一递增版本号（时间戳或序号），不可修改已提交的迁移
- **up + down 成对**：每个迁移必须能回滚。`up` 创建的表，`down` 必须删掉。别留烂摊子
- **幂等性**：迁移必须可以安全重复执行，优先使用 `IF NOT EXISTS` / `IF EXISTS`、条件更新、唯一约束、迁移状态表或事务保护。只有目标数据库的语法或行为确实无法支持幂等实现时，才允许非幂等迁移；迁移文件或 ADR 必须写明无法幂等的数据库限制、执行前置条件、一次性执行保护、失败后的安全重试/恢复步骤，并在 prod 执行前人工审批。
- **禁止手改数据库**：所有 DDL 变更走迁移文件。别在 prod 上临时 `ALTER TABLE` 然后忘了

## 迁移内容规范
- **一个迁移做一件事**：别把"加字段 + 建索引 + 改表名"混一起
- **数据迁移和结构迁移分开**：先改表结构，确认无误后再跑数据迁移
- **大表变更要小心**：
  - `ALTER TABLE ... ADD COLUMN` 对千万级表 + 默认值可能锁表（MySQL 8.0+ instant DDL 好很多）
  - 大表加索引用 `ALGORITHM=INPLACE, LOCK=NONE`（MySQL）/ `CONCURRENTLY`（PostgreSQL）
  - 实在不行用 pt-online-schema-change 或 gh-ost
- **外键约束**：开发环境要，prod 看情况。高并发场景外键是性能杀手，用应用层保证一致性

## 建表规范

### 必须有的列
每张业务表必须包含：
```sql
created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
```
- **created_at**：记录创建时间，写入后不再修改
- **updated_at**：记录最后修改时间，每次 UPDATE 自动更新
- PostgreSQL 用 `TIMESTAMPTZ`，MySQL 用 `TIMESTAMP` 或 `DATETIME(3)`（毫秒精度）
- 别用 `datetime` 字符串，别靠应用层传时间

### 索引规范
- **主键必须有**：每张表一个自增 `BIGINT` 或 UUID 主键。别用业务字段当主键
- **外键建索引**：所有外键列必须建索引，不然 JOIN 和级联操作全表扫描
- **高频 WHERE 列建索引**：看查询最多的 5 条 SQL，WHERE 条件里的列都得有索引
- **联合索引按区分度排**：区分度高的列放最左。`status`（3 种值）和 `user_id`（百万种），`user_id` 放前面
- **唯一约束 = 唯一索引**：业务上不重复的字段直接建唯一索引，别靠应用层检查
- **软删除要带索引**：有 `deleted_at` 的表，查询索引要包含 `deleted_at IS NULL` 条件，或者联合索引把 deleted_at 放前面
- **别每个列都建索引**：写入慢、占磁盘。用 EXPLAIN 验证索引被实际用到再建
- **命名规范**：
  - 普通索引：`idx_<表名>_<列名>`，如 `idx_users_email`
  - 唯一索引：`uk_<表名>_<列名>`，如 `uk_users_phone`
  - 联合索引：`idx_<表名>_<col1>_<col2>`，如 `idx_orders_user_status`

### 建表示例
```sql
CREATE TABLE orders (
    id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id    BIGINT UNSIGNED NOT NULL,
    order_no   VARCHAR(32)     NOT NULL,
    status     TINYINT         NOT NULL DEFAULT 0,
    amount     DECIMAL(10,2)   NOT NULL,
    created_at TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_orders_order_no (order_no),
    INDEX      idx_orders_user_id (user_id),
    INDEX      idx_orders_status_created (status, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## 执行前检查
- **先跑 dry-run**：不管什么工具，先看生成的 SQL 长什么样
- **检查锁表风险**：`SHOW ENGINE INNODB STATUS` 了解当前锁情况
- **备份**：prod 迁移前至少确认最近一次备份可用。大变更备份当前表
- **错峰执行**：别在高峰期跑大表迁移
- **评估时间**：迁移脚本加上预估耗时注释。`-- estimated: ~30s on 5M rows`

## 启动与命令行
- **承载流量前完成必要迁移**：单机服务可在启动流程自动执行 `migration up`；编排平台可由受控 Job / 发布步骤执行，应用就绪检查确认所需结构兼容。执行方式由项目约定，不同时强制所有形态嵌入启动迁移。
- **失败阻断对应发布**：迁移失败时，依赖新结构的候选不得继续提供流量；日志包含迁移版本、文件名、数据库连接目标（脱敏后）和错误上下文。仍兼容当前结构的旧应用不必因新候选失败而停服。
- **提供 CLI 子命令**：服务或运维工具应提供 `migrate up`、`migrate down`、`migrate status` 等命令，至少支持按步数回滚，如 `migrate down --steps 1`
- **自动 up 要可观测**：每次启动迁移完成后记录执行结果、耗时、迁移前版本和迁移后版本，方便部署后复盘

## 回滚预案
- **down 脚本要测试过**：别只写了 up，down 从来没跑过
- **回滚不丢数据**：如果 down 要删字段，先备份该字段数据
- **灰度回滚**：出问题先停流量再回滚，别反过来
- **回滚说明要随部署输出**：每次部署后必须反馈本次可回滚到哪个应用版本、旧二进制备份路径、是否需要执行 `migrate down`、对应命令和风险提示

## 工具选择
- **Go 项目**：golang-migrate、goose
- **Python 项目**：Alembic（SQLAlchemy 生态）、Django migrations
- **Node 项目**：knex migrations、Prisma migrate、TypeORM migrations
- **通用**：Flyway（Java 生态但任何语言都能用）
- **K8s 里**：用 init container 或 Job 跑迁移，别嵌在应用启动逻辑里

## CI/CD 集成
- **迁移是部署的一部分**：由项目选定的启动流程或受控 Job 执行并记录结果；应用就绪条件包含所需 Schema 兼容。各执行器共享迁移状态与同数据库的锁，等待有超时、异常有恢复，不将互斥范围扩展到无关构建或测试。迁移安全重试还需核对已执行内容与预期结构，不能用 `IF NOT EXISTS` 掩盖不一致。
- **自动化检查**：CI 里校验迁移文件格式、检查 down 脚本存在、dry-run 验证
- **高风险 prod 迁移要审批**：大表 DDL、不可逆数据变更、删字段/删表等高风险迁移必须人工审批；普通幂等迁移可以随服务启动自动 up
- **迁移状态上报**：跑完通知到 Slack/钉钉，附上耗时和版本号

## 特殊场景
- **多实例部署**：用分布式锁确保只有一个实例跑迁移（或依赖迁移工具自带的锁机制）
- **滚动 / 蓝绿 / 并行发布**：采用 expand → migrate → contract。先新增兼容结构，部署能兼容旧数据的读写者，再按需幂等回填和切换；旧读写者全部退出、相关发布队列处理完且回滚窗口结束后，才在独立审批的后续版本删除旧结构。兼容窗口可能跨多个版本，不能只验证紧邻的两个版本。
- **并行迁移命名与执行**：使用工具支持的唯一迁移 ID；若采用顺序号，必须在集成时协调，禁止两个分支各取“当前最大号 +1”。执行仍由同数据库的共享锁协调；冲突处理不得改写已经提交的迁移，工具不支持安全并行时先排队再创建文件。
- **分库分表**：迁移脚本要考虑所有分片，逐个执行并验证
- **NoSQL（MongoDB 等）**：虽然 schema-less 但也需要迁移脚本管理索引、validator、数据清洗
