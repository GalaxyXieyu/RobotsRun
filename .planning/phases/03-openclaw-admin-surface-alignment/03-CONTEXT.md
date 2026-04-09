# Phase 3: OpenClaw Admin Surface Alignment - Context

**Gathered:** 2026-04-08
**Status:** Updated for 03-03 replan after production smoke and IA correction

> Note: 该文档已经吸收 2026-04-08 的 production smoke 结论与用户最新产品决策。凡涉及顶层对象模型的地方，继续以 `../02.1-openclaw-agent/02.1-CONTEXT.md` 的“统一 Agent + native/openclaw 分型”决策为准；本文件只收敛 03-03 需要的 operator flow、页面结构和调试体验。

<domain>
## Phase Boundary

本 phase 仍然聚焦 `xiaozhi-esp32-server` 的 Web 管理面，目标不是另起一个独立 OpenClaw 产品，而是在统一 Agent 模型下把 `/openclaw-management` 收口成真正可用的 Channel 工作台。

`03-03` 的具体边界是两件事：

1. 修正 production 拓扑下的真实链路，确保 Channel inventory / binding / debug 走的是服务端可达路径，而不是浏览器直连内网 runtime。
2. 把当前长页重构成符合真实操作路径的界面：`Channel 卡片 -> Channel 详情 -> OpenClaw Agent -> 调试`。

本次不迁移运行时语音打断控制到新的承载页，只要求把它从 OpenClaw 主流程中移除，避免继续污染信息架构。

</domain>

<decisions>
## Implementation Decisions

### Product model and ownership
- **D-01:** 继续保留统一 Agent 模型，`roleConfig.vue` 仍是业务 Agent 的绑定编辑入口；`/openclaw-management` 不是第二套 Agent 产品，只是面向 Channel 和调试的工作台。
- **D-02:** `manager-web` 继续作为 OpenClaw 主控制面，`manager-mobile` 不在本 phase 内追求同级能力。
- **D-03:** `/openclaw-management` 的页面定位改为 “OpenClaw Channel 工作台”，不再强调“设备运行时控制台”。

### Primary operator journey
- **D-04:** 首页主视图必须是 Channel 卡片网格，而不是“左侧列表 + 长页 tab 工作台”。
- **D-05:** Channel 的主流程只围绕三步展开：找到 channel、确认目标 OpenClaw agent、开始调试。
- **D-06:** Channel 详情页的默认主对象是 OpenClaw agent 列表，不是 bridge 列表，也不是 runtime/account 原始面板。

### Channel list and CRUD
- **D-07:** Channel 首页卡片只显示用户真正需要扫读的信息：名称、启用状态、绑定摘要、inventory 健康摘要、备注。
- **D-08:** Channel 的增删改查采用“卡片 + 菜单”模式：卡片进入详情，新建按钮固定在列表页顶部，重命名/删除放在卡片菜单里。
- **D-09:** Channel 编辑表单保持轻量，基础字段默认可见，高级字段收进折叠区或轻量二级容器，不再占满主页面。

### Channel detail and bindings
- **D-10:** Channel 详情页默认只展示当前 runtime 范围下的 OpenClaw agents，以及每个 agent 对应的业务绑定关系。
- **D-11:** 业务绑定关系按 OpenClaw agent 聚合，默认用“折叠绑定列表”呈现，而不是整页平铺所有业务 Agent 卡片。
- **D-12:** 每张 OpenClaw agent 卡片至少提供两个动作：`查看绑定`、`开始调试`。
- **D-13:** 从绑定列表跳回 `roleConfig` 继续保留，但本页不负责修改业务 Agent 绑定逻辑。

### Runtime, bridge, and diagnostics exposure
- **D-14:** 如果 `runtimeAccounts` 只有 1 个，详情页和调试弹窗都不展示 runtime 选择器；直接按该 runtime 工作。
- **D-15:** 如果 `runtimeAccounts` 多于 1 个，只显示一个轻量 runtime 切换器；bridge 选择不应成为默认主流程控件。
- **D-16:** bridge、source URL、raw inventory、运维诊断信息必须降级到高级诊断区，默认折叠隐藏。
- **D-17:** `mac-mini`、`xiaozhi-default` 这类 bridge 名称不应继续作为页面一级对象暴露给普通用户。

### Debug workflow
- **D-18:** 在线调试继续复用现有大弹窗容器，但内部布局必须重做，风格和可读性要明显优于当前版本。
- **D-19:** 调试弹窗默认只呈现当前 Channel、当前 OpenClaw agent、聊天记录和输入区，不再默认展示大量步骤说明、数量统计和侧栏噪音。
- **D-20:** 调试上下文优先自动解析：从当前 Channel + runtime 选择推导 account，并自动挑选该 account 下在线 bridge；只有上下文无法唯一确定时才暴露轻量选择器。
- **D-21:** 调试历史保留，但降级为次级入口，不再作为弹窗主布局的大侧栏主体。

### De-scoped runtime controls
- **D-22:** 运行时语音打断控制从本页主流程移除，本次不再占据一级 tab。
- **D-23:** 运行时控制后续再考虑迁入 `/feature-management` 或其他系统能力页；这不是 03-03 的交付前置条件。

### Navigation and compatibility
- **D-24:** 顶部导航和页面标题必须改短，避免导航 pill 内文字换行。
- **D-25:** `roleConfig.vue` 进入 OpenClaw 工作台的跳转继续保留，并且深链参数 `channelId`、`runtimeAccount`、`openclawAgentId`、`entry=debug` 必须继续兼容。
- **D-26:** 默认复用现有 manager-api / runtime admin 契约，不以新增后端接口为前提；只有执行阶段发现前端无法在现有契约上完成目标时，才回补接口。

### the agent's Discretion
- 视觉语言采用何种“operations console / refined workbench”方向
- Channel 编辑容器到底用弹窗还是抽屉，只要保证轻量且不回到长页
- 高级诊断区放在详情页底部还是独立折叠块，只要默认不打扰主流程

</decisions>

<specifics>
## Specific Ideas

- 用户明确要求当前主流程收敛成：“哪个渠道，选哪个 agent，开始调试”。
- 用户明确反对把 bridge、runtime、inventory 原始信息默认平铺给普通使用者。
- 用户希望首页是 Channel 卡片墙，点进去后二级详情再看该 channel 下有哪些 agents、哪些业务 Agent 已经绑定。
- 用户希望调试弹窗复用现有“查看对话历史”的大弹窗思路，但视觉和可读性必须重做，不能继续保持“很丑、很简陋”的状态。
- 用户接受这次先把运行时控制从 OpenClaw 页移出，再考虑后续迁去系统功能配置页。
- production smoke 已经证明：如果继续围绕 bridge / runtime / debug 原始对象平铺页面，用户会持续搞不清“当前调试的是哪条真实链路”。

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project truth
- `.planning/PROJECT.md` — 根仓定位与 OpenClaw 管理面不应偏离统一 Agent 模型
- `.planning/REQUIREMENTS.md` — `ADM-01` / `ADM-02` / `INTEG-01` 约束
- `.planning/ROADMAP.md` — Phase 3 与 `03-03` 的路线位置
- `.planning/STATE.md` — 当前已进入“production connectivity + IA correction”阶段

### Prior phase contracts
- `.planning/phases/02.1-openclaw-agent/02.1-CONTEXT.md` — 统一 Agent + `native/openclaw` 类型边界
- `.planning/codebase/AGENT_ADMIN_TYPE_FLOW.md` — 现有 Web 管理流与 OpenClaw binding 的契约
- `.planning/codebase/OPENCLAW_ADMIN_SURFACE.md` — OpenClaw 管理面当前能力梳理
- `.planning/codebase/OPENCLAW_BRIDGE_HANDSHAKE.md` — bridge / runtime admin / manager-api 真正握手链路

### UX inputs
- `.planning/ui/2026-04-08-openclaw-runtime-console-ux-audit.md` — 当前长页问题与信息架构噪音审计
- `.planning/ui/2026-04-08-openclaw-runtime-console-wireframe.drawio` — 已有草图，可作为反例和演进参考

### Implementation surfaces
- `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue` — 当前页面，需做 IA 重构
- `xiaozhi-esp32-server/main/manager-web/src/components/OpenClawDebugDialog.vue` — 调试弹窗容器，需简化并美化
- `xiaozhi-esp32-server/main/manager-web/src/views/roleConfig.vue` — 业务 Agent binding 入口与深链来源
- `xiaozhi-esp32-server/main/manager-web/src/components/HeaderBar.vue` — 顶部 pill 换行问题
- `xiaozhi-esp32-server/main/manager-web/src/router/index.js` — 路由标题与旧别名兼容
- `xiaozhi-esp32-server/main/manager-web/src/apis/module/openclaw.js` — 前端现有 OpenClaw API 封装

### Backend/runtime truth
- `xiaozhi-esp32-server/main/manager-api/src/main/java/xiaozhi/modules/openclaw/controller/OpenClawConfigController.java` — Channel / inventory / bindings / debug Web API
- `xiaozhi-esp32-server/main/manager-api/src/main/java/xiaozhi/modules/openclaw/service/impl/OpenClawConfigServiceImpl.java` — manager-api 侧 inventory/binding 聚合与 route prefill 语义
- `xiaozhi-esp32-server/main/xiaozhi-server/core/api/openclaw_admin_handler.py` — runtime admin inventory / direct chat / clear session 真相

</canonical_refs>

<deferred>
## Deferred Ideas

- 把运行时语音打断控制正式迁移到 `/feature-management`
- 为 bridge 增加单独的删除、观测、诊断控制台
- Mobile 端做与 Web 等价的 Channel / debug 管理面
- 为 OpenClaw 调试加入更重的日志、trace、回放和实时推送

</deferred>

---

*Phase: 03-openclaw-admin-surface-alignment*
*Context refreshed: 2026-04-08 after production smoke and user-driven IA decisions*
