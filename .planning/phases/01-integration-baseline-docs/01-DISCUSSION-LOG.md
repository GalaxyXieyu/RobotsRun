# Phase 1: Integration Baseline & Docs - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-07
**Phase:** 01-integration-baseline-docs
**Areas discussed:** phase posture, documentation surface, working-memory scope, deferred verification

---

## Phase posture

| Option | Description | Selected |
|--------|-------------|----------|
| Re-run bootstrap | 重新 map codebase 并重建 `.planning` | |
| Bootstrap closeout | 承认现有 bootstrap 成果，转为正式 GSD phase 工件 | ✓ |
| Jump to Phase 2 | 不做 Phase 1 收口，直接做 deploy / bridge 契约验证 | |

**User's choice:** 自动采用推荐方案：先把 Phase 1 作为 bootstrap closeout，补齐正式 `CONTEXT` / `PLAN`。
**Notes:** 当前 `.planning` 已有大量资产，但流程层面尚未形成 phase 目录与计划文件。

---

## Documentation surface

| Option | Description | Selected |
|--------|-------------|----------|
| README as landing page | README 提供系统概览、维护顺序和文档入口 | ✓ |
| New maintainer doc only | 新建独立维护者文档，README 保持极简 | |
| Duplicate submodule docs | 在根仓 README 大量复制各子仓说明 | |

**User's choice:** 自动采用推荐方案：README 作为维护者入口页，细节继续落在 `.planning` 与子仓文档。
**Notes:** 这样既能补齐入口缺口，也不会制造多份难以维护的重复说明。

---

## Working-memory scope

| Option | Description | Selected |
|--------|-------------|----------|
| Root docs only | 只在根仓 `.planning` 和 README 层收口 | ✓ |
| Modify submodules | 顺手修子仓里的说明或实现 | |
| Add full validation | 在 Phase 1 顺带做 smoke / bridge 验证 | |

**User's choice:** 自动采用推荐方案：所有变更限定在根仓文档和 GSD 工件。
**Notes:** `xiaozhi-esp32/`、`xiaozhi-esp32-server/` 当前是 dirty 状态，不适合在 Phase 1 混入实现层修改。

---

## Deferred verification

| Option | Description | Selected |
|--------|-------------|----------|
| Verify now | 在 Phase 1 里开始 deploy / bridge 路由核对 | |
| Defer to Phase 2 | 把入口映射、hotfix 一致性、bridge token 留到 Phase 2 | ✓ |
| Fold into README | 只在 README 里简单写到，不形成后续计划 | |

**User's choice:** 自动采用推荐方案：验证工作显式递延到 Phase 2。
**Notes:** Phase 1 只负责把维护者带到正确入口和上下文，不提前做高风险验证。

---

## the agent's Discretion

- README 的具体章节顺序和篇幅
- 是否在 README 里加入简短“安全编辑边界”提醒
- 状态文档里用于描述“已规划、待执行”的措辞

## Deferred Ideas

- 根仓级 smoke checklist
- hotfix 兼容性策略
- OpenClaw bridge token / 握手核验

---

*Phase: 01-integration-baseline-docs*
*Discussion log generated: 2026-04-07*
