# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-08)

**Core value:** 在不破坏各子仓独立演进的前提下，持续保持“设备 → 服务端 → OpenClaw Agent”集成链路可理解、可部署、可验证。
**Current focus:** reopen Phase 3 for production connectivity recovery and Channel-first IA correction before Phase 4 device validation

## Current Position

Current Phase: 3
Current Phase Name: Agent Admin Surface Alignment
Total Phases: 5
Current Plan: `03-03` channel-first workbench replan with refreshed discuss context
Total Plans in Phase: 3
Status: 02-01 / 02-02 / 02.1-01 / 03-01 / 03-02 已落地，但 03 production smoke 失败，现追加 03-03 修复真实链路与信息架构
Last Activity: 2026-04-08 — refreshed Phase 3 context and rewrote 03-03 execute plan
Last Activity Description: 已将最新用户决策写入 GSD 文档：`/openclaw-management` 改为 Channel 卡片首页 + Channel 详情，详情默认看 OpenClaw Agent 列表与折叠业务绑定，调试弹窗改为简洁大弹窗，运行时语音打断从本页主流程移除
Progress: 78%

## Performance Metrics

**Velocity:**
- Total plans completed: 5
- Average duration: -
- Total execution time: -

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 | 0 | - | - |
| 2 | 2 | - | - |
| 02.1 | 1 | - | - |
| 3 | 3 | - | - |

**Recent Trend:**
- Last 5 plans: 02-02 completed, 02.1-01 completed, 03-01 completed, 03-02 completed, 03-03 opened
- Trend: OpenClaw 管理面进入“交付后回收真实 smoke 缺口”阶段，先修 production connectivity 和 operator flow，再进入设备侧回归

## Decisions Made

| Phase | Summary | Rationale |
|-------|---------|-----------|
| 1 | 根仓保持集成工作区定位 | 保留 submodule 边界，避免在初始化任务中越界修改子仓 |
| 1 | 将 `deploy/` 视为一等模块边界 | 实际生产拓扑由 Sealos 清单与 hotfix 覆盖共同决定 |
| 1 | 本次初始化仅写 `.planning/` 与 PM/飞书 | 在完成架构初始化的同时保护现有未提交改动 |
| 1 | Phase 1 先做文档治理收口，再进入契约验证 | 避免把 deploy / bridge 验证提前混入 bootstrap 收尾 |
| 1 | OpenClaw 前端控制需求收口到 Phase 3 | 该能力依赖 Phase 2 的契约稳定，不应插入到当前 Phase 1 执行中 |
| 1 | Phase 3 以 Web 为主控制面，Mobile 保持轻量边界 | 避免两个前端同时做完整 OpenClaw 控制台而失焦 |
| 02.1 | 先统一 Agent 模型，再定义 OpenClaw 类型化边界 | 比起独立 OpenClaw 控制台，统一 Agent 创建/编辑流更符合业务心智，也更容易复用现有字段与页面 |
| 02.1 | `openclaw` 类型固定为“先绑定 channel，再下拉选择 runtime/account/agent” | 避免 runtime/account 回退成手工输入，减少错误配置面 |
| 3 | `/openclaw-management` 被收敛为 settings workspace，而非第二套 Agent 产品入口 | 保持统一 Agent 产品心智，避免管理入口再次分叉 |
| 3 | inventory 真相收口到 xiaozhi-server runtime `/admin/openclaw/inventory` | 真实 OpenClaw Gateway 不是稳定的 manager-api 直连 inventory HTTP 服务 |
| 3 | runtime inventory 真相虽然在 xiaozhi-server，但浏览器不得直接访问该地址 | production 环境中 runtime 常位于集群内网，必须经由 manager-api 等服务端代理收口 |
| 3 | Web 端补 direct chat 和 clear session | 提高二开验证与线上排障效率，减少依赖真实设备在线调试 |
| 3 | `xiaozhi-web` 生产启动固定为镜像内 `/start.sh` | 避免继续从 PVC hotfix 覆盖旧 jar，降低“镜像已更新但后台仍运行旧代码”的漂移风险 |
| 3 | `/openclaw-management` 的默认操作路径收敛为 `Channel -> OpenClaw Agent -> Debug` | 用户真正关心的是选渠道、选目标 agent、验证调试回复，而不是先读 bridge / runtime 基础设施细节 |
| 3 | Channel 详情默认看 OpenClaw Agent 列表，业务绑定以折叠列表挂在 agent 下 | 这样既保留绑定可观测性，又避免把页面重新堆成长页式标签墙 |
| 3 | 运行时语音打断从 OpenClaw 页面主流程移除，后续再迁移到系统功能配置 | 当前最优先的是修正 production 可达链路和页面信息架构，不应再让运行时控制污染该页 |
| 2 | Phase 2 先拆成 deploy/runtime overlay 审计和 bridge handshake 审计两段 | 这两块依赖关系不同，混成一个 plan 容易丢失 source-of-truth 边界 |
| 4 | `xiaozhi-esp32` 当前有本地触摸过滤补丁尚未纳入正式 phase | 设备侧也在演进，但仍缺完整 OTA / reconnect / protocol 回归闭环 |

## Accumulated Context

### Roadmap Evolution

- 2026-04-07: inserted Phase 02.1 after Phase 2 — 先重定义 OpenClaw 相关产品模型，再进入实现
- 2026-04-07: confirmed the product model should be one unified `Agent` with `native/openclaw` types, not a separate OpenClaw console object
- 2026-04-07: existing Phase 3 is now treated as implementation follow-up to 02.1 and must be replanned around unified Agent flows
- 2026-04-07: fixed OpenClaw source-of-truth flow as “bind channel in settings first, then select runtime/account/agent from dropdowns in Agent form”
- 2026-04-07: Phase 02.1 now has an executable plan and Phase 3 plans were rewritten away from the standalone OpenClaw page direction
- 2026-04-08: confirmed `xiaozhi-esp32-server` current `HEAD` is `6e5bddf`, including channel management, web debug console, and session clearing
- 2026-04-08: confirmed current Web flow is already split into `roleConfig.vue` + `OpenClawManagement.vue`, so `.planning` must document actual implementation rather than only future intent
- 2026-04-08: confirmed `xiaozhi-esp32` has local `esp_vocat.cc` touch filtering patch (valid point check + tap duration guard), but device-side validation phase is still open
- 2026-04-08: created Phase 2 context and split Phase 2 into `02-01` deploy/hotfix contract audit and `02-02` bridge handshake contract audit
- 2026-04-08: completed `02-01` and documented current deploy/runtime overlay truth in `.planning/codebase/DEPLOY_OPENCLAW_RUNTIME_CONTRACT.md`
- 2026-04-08: completed `02-02` and documented bridge token, websocket, runtime admin, manager-api, and plugin RPC handshake truth in `.planning/codebase/OPENCLAW_BRIDGE_HANDSHAKE.md`
- 2026-04-08: fixed OpenClaw binding persistence/read path in `xiaozhi-esp32-server` (`3175c7b`, `3c9b4f2`, `4f250b8`), eliminating the main stale-param binding bug
- 2026-04-08: corrected `xiaozhi-web` production deploy workflow so `main/manager-api/**` changes also trigger rollout, and the deployment now forces `command: ["/start.sh"]`
- 2026-04-08: confirmed production `xiaozhi-web` runtime should execute `java -jar /app/xiaozhi-esp32-api.jar`, not `/uploadfile/openclaw-web-hotfix/api/xiaozhi-esp32-api.jar`
- 2026-04-08: production smoke exposed that `OpenClawManagement.vue` still uses browser-side `fetch(baseUrl + /admin/openclaw/*)` for inventory sync, which fails when `baseUrl` is a cluster-internal runtime address
- 2026-04-08: user feedback clarified the desired operator flow should be `Channel cards -> channel detail -> runtime/account/OpenClaw agents/business-agent bindings -> debug`, not a mixed long-form workspace
- 2026-04-08: Phase 3 discuss context was refreshed to lock the following IA decisions: card-based Channel home, OpenClaw Agent-first detail view, folded binding lists, beautified debug modal, and runtime-control removal from the page

### Delivered OpenClaw Work

- manager-web 已具备 OpenClaw channel 设置、setup guide / install command、inventory 同步、bridge 状态展示、在线调试和会话清理，但其中 inventory 仍有一条错误的浏览器直连 runtime 路径待修复。
- manager-web 的统一 Agent 编辑页已支持 `native/openclaw` 类型切换和 OpenClaw binding。
- manager-api 已具备 `/openclaw-config/*` 契约，并通过系统参数持久化 channel 与 binding。
- xiaozhi-server runtime 已提供 `/admin/openclaw/inventory`、direct chat、clear session 等 admin 能力。
- OpenClaw binding 的持久化、读取与缓存绕过问题已修复，前端绑定不再依赖旧参数形态。
- `xiaozhi-web` 当前生产部署已改成镜像真相，deploy / hotfix 主要风险收缩到 `xiaozhi-server` runtime 一侧。

## Blockers

- `xiaozhi-esp32`、`xiaozhi-esp32-server` 当前为 dirty 状态，后续执行必须继续避开无关修改
- `xiaozhi-server` deploy hotfix 仍采用运行时拷贝文件，存在镜像与实际运行代码漂移风险
- 根仓仍缺少统一 E2E / smoke 验证基线
- runtime `/admin/openclaw/*` 在真实 bridge / account / agent 数据上的回归验证还没形成长期基线
- Phase 3 当前页面的信息架构不匹配真实运维流程，用户难以从 channel 视角理解 inventory、binding 与调试关系
- PM / 飞书同步基线已建立，执行阶段以 `pm.json` 为配置依据，不额外扩展同步能力

## Session

Last Date: 2026-04-08 20:10 CST
Stopped At: 已完成 03-03 的 GSD re-discuss 和 execute plan 重写；下一步应按新计划执行前端 IA 重构、调试弹窗简化和 production smoke
Resume File: .planning/phases/03-openclaw-admin-surface-alignment/03-03-PLAN.md
