# Unified Agent + OpenClaw Model

## Unified Agent Model

系统里的顶层业务对象仍然是统一的 `Agent`，不是并列维护一套本地智能体和一套 OpenClaw 智能体。差异通过 `agentType = native | openclaw` 表达。

当前实现已经按这个方向落地：

- `roleConfig.vue` 在同一表单里提供 `native/openclaw` 类型切换。
- `manager-api` 通过 `/openclaw-config/agents/{agentId}` 维护 OpenClaw 扩展绑定，而不是新建第二套 agent 主表。
- `OpenClawManagement.vue` 负责 channel 设置、inventory 同步、在线调试和会话清理，给 Agent 表单提供可选项，而不是替代 Agent 编辑入口。

这意味着：

- Agent 的公共身份和业务配置继续沿用原有 agent 管理流。
- OpenClaw 只是 Agent 的一种实现来源。
- OpenClaw runtime/account/agent 的选择结果，被看作 Agent 的扩展绑定信息。

## Shared Fields

以下字段仍应被视为统一 Agent 的公共字段，由原有 Agent 管理流负责：

- Agent 基本身份：名称、头像、描述、启用状态、所属用户/权限模型。
- 对外可见配置：音色、展示信息、设备端可消费的公共元数据。
- 原有 agent 生命周期：创建、编辑、删除、权限校验、列表展示。
- Agent 主体保存流程：仍然先保存 Agent 本体，再保存 OpenClaw 扩展绑定。

当前证据：

- `xiaozhi-esp32-server/main/manager-web/src/views/roleConfig.vue`
- `xiaozhi-esp32-server/main/manager-api/src/main/java/xiaozhi/modules/openclaw/controller/OpenClawConfigController.java`

## Native-only Fields

`native` 类型继续保留本地智能体心智，典型字段和能力包括：

- 本地 prompt 编辑。
- 本地 memory/context/model 等原生配置。
- 本地函数、知识库、插件映射等仅对 server-native agent 生效的配置。

这些能力仍然存在于统一 Agent 编辑流里，但只应在 `agentType = native` 时展示。

## OpenClaw-only Fields

`openclaw` 类型只暴露绑定所需字段，不暴露本地 prompt 编辑心智。当前实现中的专属字段包括：

- `channelId`
- `runtimeAccount`
- `runtimeAccountLabel`
- `openclawAgentId`
- `openclawAgentName`
- `syncStatus`
- `errorMessage`

这些字段的来源不是手工自由输入，而是：

1. 先在 OpenClaw channel 设置页保存 channel。
2. 通过 inventory 拉回 runtime/account、bridge、agent 列表。
3. 在 Agent 表单里以下拉选择完成绑定。

`openclaw` 类型不应暴露本地 prompt 编辑，这一点已经在 `roleConfig.vue` 中按类型收窄。

## Field Ownership Rules

当前字段归属应按下面的边界理解：

| 字段层 | Owner | 当前落点 | 说明 |
| --- | --- | --- | --- |
| Agent 公共字段 | 原有 agent 模块 | Agent API + `roleConfig.vue` | 所有类型共用 |
| Agent 类型 | OpenClaw 扩展绑定 | `/openclaw-config/agents/{agentId}` | 用于区分 `native/openclaw` |
| OpenClaw 绑定字段 | OpenClaw 扩展绑定 | `/openclaw-config/agents/{agentId}` | channel/runtime/account/agent 选择结果 |
| Channel 注册信息 | OpenClaw channel 配置 | `/openclaw-config/channels` | Web 设置页维护 |
| Inventory 运行态数据 | xiaozhi-server runtime | `/admin/openclaw/inventory` 经 manager-api 代理 | 不是前端本地真相 |

这里最重要的规则有两条：

- `openclaw` 类型的运行态选项必须来自 inventory，不允许重新退回到手工输入 runtime/account。
- runtime 状态、bridge 连接数、account-agent 映射等数据属于运行态只读信息，不应被保存成前端自维护状态。

## OpenClaw Channel Binding Flow

当前建议并已部分实现的绑定流如下：

1. 在 `/openclaw-management` 维护 channel 列表。
2. 保存 channel 时由 manager-api 自动补默认 `baseUrl`、`inventoryPath`、`accessToken` 等配置。
3. 通过 `/openclaw-config/channels/{channelId}/setup-guide` 生成可复制安装命令。
4. 在 OpenClaw 目录执行安装命令，让 bridge 主动接入 xiaozhi-server。
5. 回到管理台执行 inventory 同步。
6. Agent 表单消费该 channel 的 runtime/account、agent 下拉项完成绑定。

当前页面文案已经明确：用户主流程不再需要理解 `baseUrl / inventoryPath / accessToken`，而是以“保存 channel -> 执行命令 -> 同步 inventory -> 绑定 Agent”为主。

## Selection Flow

`openclaw` 类型 Agent 的选择流应固定为：

1. 在 Agent 表单把 `agentType` 切为 `openclaw`。
2. 选择 `channelId`。
3. 触发 `getChannelInventory(channelId)` 拉取 inventory。
4. 选择 `runtimeAccount`。
5. 选择 `openclawAgentId`。
6. 保存 Agent 主体，再保存 OpenClaw 扩展绑定。

当 inventory 缺失或 channel 未准备好时，表单应引导用户跳去 `/openclaw-management`，而不是放出原始文本输入框。

## Manager API Contract

当前 manager-api 已经形成一套可供二开的 OpenClaw 管理契约：

- `GET /openclaw-config/channels`
  读取 channel 列表。
- `PUT /openclaw-config/channels`
  保存 channel 列表，并补默认 server 侧配置。
- `GET /openclaw-config/channels/{channelId}/inventory`
  拉取 channel 对应的 inventory。
- `GET /openclaw-config/channels/{channelId}/setup-guide`
  生成安装命令和接入说明。
- `POST /openclaw-config/channels/{channelId}/direct-chat`
  直连 OpenClaw bridge 做在线调试。
- `POST /openclaw-config/channels/{channelId}/clear-session`
  清理调试会话。
- `GET /openclaw-config/agents/{agentId}`
  读取 Agent 的 OpenClaw 扩展绑定。
- `PUT /openclaw-config/agents/{agentId}`
  保存 Agent 的 OpenClaw 扩展绑定。

服务端实现表明：

- channel 和 binding 当前都通过系统参数持久化，先避免 DB migration。
- inventory、direct chat、clear session 本质上都是 manager-api 对 runtime admin 接口的包装，而不是前端直连 OpenClaw Gateway。

## Web Admin Flow

当前 Web 管理流的正确理解如下：

- `roleConfig.vue` 是统一 Agent 编辑入口。
- `OpenClawManagement.vue` 是 OpenClaw settings/integration workspace。
- `/openclaw-management` 负责维护 channel、同步 inventory、查看 bridge 状态、做在线调试、清理调试会话。
- Agent 表单只消费 channel 衍生出来的可选项，并展示必要的只读状态。

所以，OpenClaw 页面存在，但它不是“第二套智能体产品入口”，而是统一 Agent 流的配套设置页。

## Mobile Boundary

当前建议继续保持 Web 主控、Mobile 轻量边界：

- Web 负责 channel 管理、inventory 同步、调试、会话清理、类型化 Agent 编辑。
- Mobile 不复制完整 OpenClaw 控制台。
- Mobile 若后续接入 OpenClaw，只应消费已经稳定的 Agent 结果和轻量只读状态。

这样可以避免两个前端同时实现半套 OpenClaw 管理流。

## Current Risks

仍需明确记录的现实风险：

- inventory 真相当前来自 xiaozhi-server runtime 的 `/admin/openclaw/inventory` 聚合结果；如果 deploy hotfix 与运行代码漂移，前端看到的选项会失真。
- manager-api 当前用系统参数持久化 channel 和 binding，后续如果规模扩大，可能需要迁移到更稳定的数据模型。
- `openclaw` 类型虽然已经隐藏本地 prompt，但 `roleConfig.vue` 里仍保留部分 native 语义字段，后续是否继续裁剪要看产品口径。

## Evidence

- `xiaozhi-esp32-server/main/manager-web/src/views/roleConfig.vue`
- `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue`
- `xiaozhi-esp32-server/main/manager-web/src/apis/module/openclaw.js`
- `xiaozhi-esp32-server/main/manager-api/src/main/java/xiaozhi/modules/openclaw/controller/OpenClawConfigController.java`
- `xiaozhi-esp32-server/main/manager-api/src/main/java/xiaozhi/modules/openclaw/service/impl/OpenClawConfigServiceImpl.java`
- `xiaozhi-esp32-server/main/xiaozhi-server/core/api/openclaw_admin_handler.py`
