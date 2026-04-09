# Agent Admin Type Flow

## Current Flow

当前 Web 端的真实能力已经不是“没有 OpenClaw 管理面”，而是分成两块：

- `roleConfig.vue`：统一 Agent 创建/编辑入口，负责 `native/openclaw` 类型切换和最终绑定保存。
- `OpenClawManagement.vue`：OpenClaw settings workspace，负责 channel、inventory、在线调试和会话清理。

需要明确区分两件事：

- 旧的“把 standalone OpenClaw page 当成独立产品入口”心智已经过时。
- 现在的 `/openclaw-management` 路由不是废页，而是统一 Agent 流依赖的 settings/workspace。

所以当前 Web capability 的真实状态是：能力分布在统一 Agent 表单和一个被重定义过的 OpenClaw 设置页之间，而不是继续沿用旧版 summary 里那种“独立 OpenClaw 控制台”口径。

## Gap Matrix

| 项目 | 已有能力 | 当前缺口 | 影响 |
| --- | --- | --- | --- |
| 统一 Agent 入口 | `roleConfig.vue` 已支持 `native/openclaw` | 仍需持续收敛页面文案和字段边界 | 二开时容易把 OpenClaw 当第二套模型 |
| Channel 设置页 | `OpenClawManagement.vue` 已可维护 channel、拉 inventory、生成命令 | 页面仍偏运维/集成视角，需要继续产品化说明 | 新同学第一次看不易理解主线 |
| Inventory 供给 | manager-api 已提供 channel inventory 接口 | 仍依赖 runtime `/admin/openclaw/inventory` 稳定性 | deploy/hotfix 漂移会直接影响前端 |
| 在线调试 | 已支持 direct chat | 仍需真实环境回归 bridge/account/agent 组合 | 线上调试可能受 bridge 状态影响 |
| 会话清理 | 已支持 clear session | 仍依赖 runtime connection registry 和 clear RPC | 清理目标匹配可能受运行时会话变化影响 |
| Mobile 边界 | 当前未复制完整控制台 | 还没有单独文档给移动端维护者 | 容易重复建设 |

## Target Web Flow

当前应该把目标 Web 流理解为下面这条链路：

1. 先进入 `/openclaw-management` 维护 channel。
2. 保存 channel 后生成安装命令。
3. 在 OpenClaw runtime 所在目录执行命令，让 bridge 接入 xiaozhi-server。
4. 回管理页同步 inventory，确认 runtime/account、bridge、agent 已可见。
5. 回到 `roleConfig.vue`，把 Agent 切成 `openclaw` 并完成下拉绑定。
6. 如需验证，回到 `/openclaw-management` 做 direct chat 和 clear session。

这条流里，真正的产品入口还是 Agent 编辑流；OpenClaw 页面承担的是设置、发现、验证和诊断。

## Settings Entry

Settings 入口当前应放在两个位置：

- 统一 Agent 编辑页中的显式入口按钮。
- Web 路由 `/openclaw-management`，允许带 `agentId/channelId/runtimeAccount/openclawAgentId` query 进入。

这样做的原因是：

- 维护者可以从 Agent 任务上下文直接跳去补齐 channel/inventory。
- OpenClaw 设置页也可以独立打开，承担安装、同步和调试职责。

## API Dependencies

当前 Flow 依赖的核心接口已经基本成型：

- `OpenClawConfigController.java`
  - `/openclaw-config/channels`
  - `/openclaw-config/channels/{channelId}/inventory`
  - `/openclaw-config/channels/{channelId}/setup-guide`
  - `/openclaw-config/channels/{channelId}/direct-chat`
  - `/openclaw-config/channels/{channelId}/clear-session`
  - `/openclaw-config/agents/{agentId}`
- `AgentMcpAccessPointController.java`
  - 继续提供原有 agent MCP 地址/工具类能力

其中要特别注意：

- OpenClaw 专属控制流现在主要走 `/openclaw-config/*`。
- `AgentMcpAccessPointController.java` 不再是 OpenClaw 管理流的主入口，而是统一 Agent 衍生能力的一部分。

## Type-aware Agent Form

`roleConfig.vue` 当前已经具备类型感知表单的雏形，后续二开应坚持以下约束：

- 所有类型共用一个 Agent 表单，不拆第二套创建页。
- `native` 类型继续展示本地语义字段。
- `openclaw` 类型只展示 channel/runtime/account/openclaw agent 等绑定项。
- `openclaw` 类型下隐藏本地 prompt 编辑。
- 保存时保持“Agent 主体 + OpenClaw binding”双写，不让表单只落一半。

## Dropdown Sources

下拉数据来源应固定，避免后续再退回手工填值：

- `channel`：来自 `GET /openclaw-config/channels`
- `runtime/account`：来自 `GET /openclaw-config/channels/{channelId}/inventory`
- `openclaw agent`：来自同一个 inventory 响应
- `bridge`：来自 inventory 的 `bridges`
- `accountAgents`：来自 inventory 的按 account 分组结果
- 当前 Agent 的已有绑定：来自 `GET /openclaw-config/agents/{agentId}`

也就是说，Agent 表单本身不是 source of truth；它只消费由 channel workspace 和 runtime 聚合出来的数据。

## Read-only Status Panels

当前实现里，以下信息更适合保持只读状态展示，而不是做成可编辑字段：

- inventory `sourceUrl`
- inventory 健康状态
- `connectedBridgeCount`
- bridge 在线/离线状态
- 当前绑定的 runtime/account label
- 当前绑定的 OpenClaw agent name
- runtime admin 返回的错误信息

这些内容用于帮助维护者判断“绑定是否真的生效”，不应和保存表单混在一起。

## Mobile Boundary Decision

当前边界建议维持不变：

- `manager-web` 负责 OpenClaw channel、inventory、调试、会话清理和绑定收口。
- `manager-mobile` 不复制 `/openclaw-management`。
- 移动端最多消费轻量只读能力，或沿用现有 agent tools/MCP 入口。

如果未来要补移动端，也应优先复用统一 Agent 结果，而不是重新发明一套 OpenClaw runtime 管理流。

## Backend Gaps

当前仍需认账的后端缺口有三类：

- runtime `/admin/openclaw/*` 契约虽然已经可用，但仍依赖 deploy hotfix 覆盖，Phase 2 之前不宜假设它完全稳定。
- channel 和 binding 通过系统参数持久化，规模增大后可能出现治理压力。
- direct chat / clear session 都依赖 OpenClaw hub、bridge 在线状态和 runtime connection registry，前端需要继续把失败态暴露清楚。

## Implementation Notes For Next Iteration

下一轮如果继续二开，优先级建议是：

1. 先补 runtime/admin 契约稳定性和 deploy 对齐，不要先继续堆前端控件。
2. 再决定 `openclaw` 类型是否继续收窄 `roleConfig.vue` 中保留的 native 字段。
3. 最后才考虑 Mobile 是否需要补只读态或调试态入口。

## Evidence

- `xiaozhi-esp32-server/main/manager-web/src/views/roleConfig.vue`
- `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue`
- `xiaozhi-esp32-server/main/manager-web/src/router/index.js`
- `xiaozhi-esp32-server/main/manager-web/src/apis/module/openclaw.js`
- `xiaozhi-esp32-server/main/manager-api/src/main/java/xiaozhi/modules/openclaw/controller/OpenClawConfigController.java`
- `xiaozhi-esp32-server/main/manager-api/src/main/java/xiaozhi/modules/agent/controller/AgentMcpAccessPointController.java`
- `xiaozhi-esp32-server/main/xiaozhi-server/core/api/openclaw_admin_handler.py`
