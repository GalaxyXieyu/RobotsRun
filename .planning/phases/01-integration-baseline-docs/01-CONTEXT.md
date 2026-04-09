# Phase 1: Integration Baseline & Docs - Context

**Gathered:** 2026-04-07
**Status:** Ready for planning

<domain>
## Phase Boundary

本 phase 只处理根仓作为集成工作区的文档与工作记忆收口，让维护者能从根仓快速理解三子仓和 `deploy/` 的协作关系，并让后续 GSD 流程有稳定输入。

本 phase 不进入子仓实现修改，不提前做 deploy / bridge / OTA 的深度验证，也不建立完整 root-level smoke 流程；这些工作留到后续 phase。

</domain>

<decisions>
## Implementation Decisions

### Scope and execution posture
- **D-01:** 把 Phase 1 视为 brownfield bootstrap 的正式收口阶段，而不是重新做一轮 map-codebase。
- **D-02:** 所有执行内容限定在根仓文档、GSD 资产和状态同步层，避免触碰 dirty 的 `xiaozhi-esp32/` 与 `xiaozhi-esp32-server/`。
- **D-03:** Phase 1 的完成标志是“根仓文档可读、GSD 工件可继续推进”，不是“集成链路已验证”。

### Documentation surface
- **D-04:** 根仓 `README.md` 必须面向维护者/新接手者，优先回答“这个仓库为什么存在”“三个子仓分别负责什么”“deploy 为什么是一等模块”“下一步该看哪里”。
- **D-05:** `README.md` 作为入口页，负责导航；细节真相仍以下列文档为准：`.planning/PROJECT.md`、`.planning/ROADMAP.md`、`.planning/codebase/*.md`。
- **D-06:** README 不重复拷贝各子仓完整说明，而是提供角色摘要、入口路径和维护顺序。

### Planning and working memory
- **D-07:** Phase 1 规划产物必须把现有 bootstrap 成果转成标准 GSD 工件：`01-CONTEXT.md`、`01-01-PLAN.md`、`01-02-PLAN.md`。
- **D-08:** Phase 1 执行过程中要同步更新 `.planning/STATE.md` 与 `.planning/ROADMAP.md`，确保后续 `gsd-progress` 能读到真实位置和下一步动作。
- **D-09:** PM / 飞书同步基线以现有 `pm.json` 配置和已创建文档为证据，不在本 phase 里扩展新的同步能力。

### Risk containment and deferrals
- **D-10:** `deploy/xiaozhi-sealos.yaml` 与 `deploy/refresh-xiaozhi-hotfix.sh` 在本 phase 只作为架构说明依据，不做契约核对或脚本修复。
- **D-11:** root-level smoke / readiness checklist、bridge token 校验、hotfix 漂移治理都延后到 Phase 2。

### the agent's Discretion
- README 的章节结构、标题命名和信息密度
- `.planning` 文档之间的交叉引用方式
- 是否在 README 中加入简短的“安全修改边界”提醒

</decisions>

<specifics>
## Specific Ideas

- README 首屏就说明“根仓是集成工作区，不是把三个子仓合并后的单体项目”。
- 维护者入口要显式点出四个关键位置：`xiaozhi-esp32/`、`xiaozhi-esp32-server/`、`openclaw-xiaozhi/`、`deploy/`。
- 文档叙述顺序优先按“设备 -> 服务端 -> OpenClaw Agent -> deploy overlay”的主链路展开。
- Phase 1 完成后，下一跳要自然导向 Phase 2 的 deploy / bridge 契约验证，而不是继续停留在泛文档整理。

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project truth
- `.planning/PROJECT.md` — 根仓定位、约束、关键决策和 active requirements
- `.planning/REQUIREMENTS.md` — 当前 milestone 需求、Phase 1 追踪项、Deferred 范围
- `.planning/ROADMAP.md` — Phase 1 目标、success criteria 与 01-01 / 01-02 路线
- `.planning/STATE.md` — 当前阶段、blockers、最近活动和下一步建议

### Architecture and integration maps
- `.planning/codebase/ARCHITECTURE.md` — 根仓作为集成工作区的总体架构说明
- `.planning/codebase/STRUCTURE.md` — 根仓与三子仓的目录边界和职责划分
- `.planning/codebase/INTEGRATIONS.md` — 设备、服务端、OpenClaw、deploy overlay 的关键接口与验证目标
- `.planning/codebase/CONCERNS.md` — dirty submodule、README 缺失、hotfix 漂移等当前主要风险
- `.planning/codebase/STACK.md` — 各模块技术栈与 root repo 的 orchestration 属性

### Source-of-truth repo files
- `.gitmodules` — 三个子仓的边界与来源
- `deploy/xiaozhi-sealos.yaml` — 生产入口、路由与 hotfix 拷贝行为的部署真相
- `deploy/refresh-xiaozhi-hotfix.sh` — hotfix 文件列表与 rollout 流程
- `README.md` — 根仓当前入口页，现状极简，是 01-02 的主要修改对象
- `pm.json` — 飞书任务/文档同步基线与现有 doc 配置证据

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.planning/codebase/ARCHITECTURE.md`：已经具备高层架构摘要，可作为 README 的系统概览来源
- `.planning/codebase/STRUCTURE.md`：已经列出 top-level layout 和子仓边界，可直接转成维护者导航
- `.planning/codebase/INTEGRATIONS.md`：已经整理出主链路和 deploy 暴露面，可作为 README 与后续 Phase 2 的桥梁

### Established Patterns
- 根仓以文档、部署覆盖、状态同步为主，避免越界修改子仓实现
- `.planning/` 是 GSD 的长期工作记忆；README 只做入口，不复制全部细节
- 现有风险管理优先级很明确：先保护 dirty submodule，再治理部署/验证漂移

### Integration Points
- README 需要把 `.planning/`、`.gitmodules`、`deploy/` 和三子仓连接成同一条维护路径
- Phase 1 的计划文件需要承接已有 `.planning` 资产，并把下一步显式导向 Phase 2
- `pm.json` 是 PM / 飞书同步基线证据，但不应被 README 暴露敏感 token 细节

</code_context>

<deferred>
## Deferred Ideas

- 根仓级 smoke / readiness checklist — 留到 Phase 2
- hotfix 文件与部署清单的一致性审计 — 留到 Phase 2
- OpenClaw bridge token / 握手链路核验 — 留到 Phase 2
- 固件接入、OTA、reconnect 回归脚本 — 留到 Phase 4

</deferred>

---

*Phase: 01-integration-baseline-docs*
*Context gathered: 2026-04-07*
