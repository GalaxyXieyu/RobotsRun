# Requirements: 智能喵喵 / RobotsRun

## Current Milestone

**v0.1 Architecture Baseline**

目标：把根仓从“仅靠人工记忆的集成仓”提升为“有清晰架构真相、可回写 PM/飞书、可继续进入 GSD 阶段规划的工作区”。

## v0.1 Requirements

### Integration Baseline

- [ ] **INTEG-01**：维护者能够从根仓文档快速理解 `xiaozhi-esp32`、`xiaozhi-esp32-server`、`openclaw-xiaozhi` 各自职责与边界。
- [ ] **INTEG-02**：维护者能够追踪“设备 → 服务端 → OpenClaw Agent”的主链路与对应部署入口。
- [ ] **INTEG-03**：维护者能够识别 `deploy/` 在生产拓扑中的作用，而不是把它视为普通附属脚本目录。

### Planning & Working Memory

- [ ] **PLAN-01**：根仓存在 `.planning/PROJECT.md`、`.planning/ROADMAP.md`、`.planning/STATE.md`，并可作为后续 GSD 工作流输入。
- [ ] **PLAN-02**：当前阶段、下一步建议、主要风险点能够从 `STATE.md` 直接读取。

### PM / Documentation Sync

- [ ] **DOC-01**：本次 brownfield 初始化结果能够同步到飞书 `PROJECT` 与 `STATE` 文档。
- [ ] **DOC-02**：T1 任务在执行过程中能收到阶段性进度回推，而不是只在结束时补结果。

### Admin Surface

- [ ] **ADM-01**：管理前端可查看并操作 OpenClaw 相关关键能力，而不是只停留在后台或部署侧配置。
- [ ] **ADM-02**：明确 `manager-web` 与 `manager-mobile` 在 OpenClaw 控制、MCP 暴露和调试能力上的边界，至少 Web 端具备完整控制面。
- [ ] **ADM-03**：后台模型需要以统一 `Agent` 作为顶层业务对象，并通过 `agent_type = native | openclaw` 区分实现来源，而不是把 OpenClaw 作为平行的第二套智能体管理流。
- [ ] **ADM-04**：管理前端需要复用统一 Agent 创建/编辑流程，共享名称、音色等公共配置，并按类型动态展示专属字段；`openclaw` 类型不应暴露本地 prompt 编辑心智，其 runtime/account/agent 选择应来自已绑定的 OpenClaw channel，而不是手工输入。

### Deployment Truth

- [ ] **OPS-WEB-01**：`xiaozhi-web` 生产部署必须以镜像内 `/start.sh` 为单一启动真相，不再依赖 PVC hotfix 覆盖旧 jar。
- [ ] **OPS-WEB-02**：当 `manager-api/**`、`manager-web/**`、`docs/docker/start.sh` 等后台管理面相关路径变更时，生产部署应自动重新构建并 rollout。

## Deferred / Next Milestone

- [ ] **OPS-01**：建立根仓级别的集成验证清单或 smoke 流程，覆盖 deploy overlay 与桥接路径。
- [ ] **OPS-02**：建立 submodule revision / hotfix 兼容性策略，降低版本漂移风险。
- [ ] **OPS-03**：补充根仓 README，让非 GSD 用户也能快速理解工作区结构。

## Out of Scope

- 重写服务端、固件或 OpenClaw 插件内部模块。
- 处理上游仓库历史大文件与资产治理。
- 在本任务中建立完整 CI/CD 或自动化测试体系。

## Traceability

| Requirement | Planned Phase | Status | Notes |
|-------------|---------------|--------|-------|
| INTEG-01 | Phase 1 | Planned | 架构摘要与模块边界 |
| INTEG-02 | Phase 2 | Planned | 主链路与桥接验证 |
| INTEG-03 | Phase 1 | Planned | deploy overlay 显式建模 |
| PLAN-01 | Phase 1 | Planned | GSD 核心资产初始化 |
| PLAN-02 | Phase 1 | Planned | STATE 持续维护 |
| DOC-01 | Phase 1 | Planned | 飞书同步 PROJECT / STATE |
| DOC-02 | Phase 1 | Planned | PM 评论阶段回推 |
| OPS-01 | Phase 2 | In progress | 已有 readiness checklist，但还缺根仓级 smoke 回归 |
| OPS-02 | Phase 2 | In progress | `xiaozhi-server` 仍有 overlay 漂移风险，`xiaozhi-web` 已切为镜像真相 |
| OPS-03 | Phase 1 | Planned | 可作为补充收尾 |
| ADM-03 | Phase 02.1 | Delivered | 已收口为统一 Agent + `native/openclaw` 类型模型 |
| ADM-04 | Phase 02.1 | Delivered | `roleConfig.vue` 已落地类型化字段与 inventory 下拉绑定 |
| ADM-01 | Phase 3 | Delivered | Web 已具备 channel、inventory、binding、direct chat、clear session |
| ADM-02 | Phase 3 | Delivered | Web 为主控面，Mobile 继续轻量边界 |
| OPS-WEB-01 | Phase 3 | Delivered | `xiaozhi-web` rollout 强制 `command: [\"/start.sh\"]` |
| OPS-WEB-02 | Phase 3 | Delivered | workflow 已覆盖 `main/manager-api/**` 等关键路径 |

---

*Last updated: 2026-04-08 after OpenClaw admin delivery and deployment workflow correction*
