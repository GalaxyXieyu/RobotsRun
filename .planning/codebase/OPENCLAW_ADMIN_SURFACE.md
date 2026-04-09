# OpenClaw Admin Surface

## Scope

本文件是 `Phase 3 / 03-01` 的基准审计文档，用来回答三件事：

1. 当前 OpenClaw 相关能力已经散落在哪些 Web、Mobile、manager-api、deploy 位置。
2. 现阶段真正缺的是什么，为什么 `FunctionDialog.vue` 不能被视为完整 OpenClaw 管理面。
3. `03-02` 在 Web 端落地时，入口、数据块、动作和 API 缺口应如何收口。

## Current Surfaces

### Web

| Surface | Current capability | Evidence | Assessment |
| --- | --- | --- | --- |
| `roleConfig.vue` | 智能体配置主页面，已有函数映射编辑入口，MCP 相关能力从这里间接进入 | `xiaozhi-esp32-server/main/manager-web/src/views/roleConfig.vue:233`, `xiaozhi-esp32-server/main/manager-web/src/views/roleConfig.vue:341`, `xiaozhi-esp32-server/main/manager-web/src/views/roleConfig.vue:856` | 是 OpenClaw 相关操作的当前宿主，但不是专属控制面 |
| `FunctionDialog.vue` | 展示 MCP 地址、工具列表、复制、刷新，以及插件参数编辑 | `xiaozhi-esp32-server/main/manager-web/src/components/FunctionDialog.vue:109`, `xiaozhi-esp32-server/main/manager-web/src/components/FunctionDialog.vue:313`, `xiaozhi-esp32-server/main/manager-web/src/components/FunctionDialog.vue:325` | 能力真实存在，但嵌在函数配置抽屉里，语义过底层 |
| `agent.js` | 已封装 `getAgentMcpAccessAddress`、`getAgentMcpToolsList` 等按 agentId 拉取 MCP 数据的方法 | `xiaozhi-esp32-server/main/manager-web/src/apis/module/agent.js:165`, `xiaozhi-esp32-server/main/manager-web/src/apis/module/agent.js:183` | Web 数据源已具备第一批基础能力 |
| `router/index.js` | 当前没有 OpenClaw 专属路径 | `xiaozhi-esp32-server/main/manager-web/src/router/index.js:15`, `xiaozhi-esp32-server/main/manager-web/src/router/index.js:36`, `xiaozhi-esp32-server/main/manager-web/src/router/index.js:114`, `xiaozhi-esp32-server/main/manager-web/src/router/index.js:189` | 缺少“可见、可达、可定位”的独立入口 |

### Mobile

| Surface | Current capability | Evidence | Assessment |
| --- | --- | --- | --- |
| `tools.vue` | 以当前 agent 为维度展示 MCP 地址、工具列表，并允许编辑函数参数 | `xiaozhi-esp32-server/main/manager-mobile/src/pages/agent/tools.vue:13`, `xiaozhi-esp32-server/main/manager-mobile/src/pages/agent/tools.vue:28`, `xiaozhi-esp32-server/main/manager-mobile/src/pages/agent/tools.vue:67`, `xiaozhi-esp32-server/main/manager-mobile/src/pages/agent/tools.vue:79` | Mobile 已有轻量查看和编辑能力，但页面语义仍偏 agent tools |
| `agent.ts` | 已封装 `getMcpAddress`、`getMcpTools` | `xiaozhi-esp32-server/main/manager-mobile/src/api/agent/agent.ts:129`, `xiaozhi-esp32-server/main/manager-mobile/src/api/agent/agent.ts:140` | 与 Web 共用同一后端能力模型 |
| `plugin.ts` | 用 store 持有当前 agentId 和插件映射 | `xiaozhi-esp32-server/main/manager-mobile/src/store/plugin.ts:15`, `xiaozhi-esp32-server/main/manager-mobile/src/store/plugin.ts:29` | 适合保留为轻量流转上下文，不适合扩成完整 OpenClaw 控制台 |

### Manager API

| Surface | Current capability | Evidence | Assessment |
| --- | --- | --- | --- |
| `AgentMcpAccessPointController.java` | 暴露 `/agent/mcp/address/{agentId}` 与 `/agent/mcp/tools/{agentId}`，并做权限校验 | `xiaozhi-esp32-server/main/manager-api/src/main/java/xiaozhi/modules/agent/controller/AgentMcpAccessPointController.java:30`, `xiaozhi-esp32-server/main/manager-api/src/main/java/xiaozhi/modules/agent/controller/AgentMcpAccessPointController.java:48` | 足够支撑第一批 Web 聚合页 |
| `AgentMcpAccessPointServiceImpl.java` | 基于系统参数生成 agent MCP 地址，并主动握手探测 tools 列表 | `xiaozhi-esp32-server/main/manager-api/src/main/java/xiaozhi/modules/agent/service/impl/AgentMcpAccessPointServiceImpl.java:28`, `xiaozhi-esp32-server/main/manager-api/src/main/java/xiaozhi/modules/agent/service/impl/AgentMcpAccessPointServiceImpl.java:47` | 后端目前偏“地址和工具探测”，缺少更高层 OpenClaw 状态聚合 |

### Deploy / Runtime

| Surface | Current capability | Evidence | Assessment |
| --- | --- | --- | --- |
| `openclaw_hub` config | 已配置 bridge websocket、持久化 state、默认 account 等 runtime 参数 | `deploy/xiaozhi-sealos.yaml:16`, `deploy/xiaozhi-sealos.yaml:18`, `deploy/xiaozhi-sealos.yaml:19` | OpenClaw runtime 已存在明确配置面 |
| Nginx routes | 已暴露 `/openclaw/bridge/ws` 与 `/admin/openclaw/` | `deploy/xiaozhi-sealos.yaml:106`, `deploy/xiaozhi-sealos.yaml:119` | 运行时路由存在，但前端未消费成管理入口 |
| Hotfix overlay | 启动时覆盖 `openclaw_admin_handler.py`、bridge 相关文件 | `deploy/xiaozhi-sealos.yaml:174`, `deploy/xiaozhi-sealos.yaml:179`, `deploy/xiaozhi-sealos.yaml:180` | 真实 runtime 能力部分依赖 overlay，契约稳定性仍受 Phase 2 影响 |

## Gap Matrix

| Gap | Current state | Why it matters | Phase ownership |
| --- | --- | --- | --- |
| 专属入口缺失 | Web 只有 `roleConfig -> FunctionDialog` 的间接路径，没有 OpenClaw 独立路由 | 维护者无法把 OpenClaw 视为一条独立工作流 | `03-02` |
| 控制语义缺失 | 当前页面强调“编辑函数”，不是“查看 OpenClaw 控制状态” | 容易把 MCP 地址和工具列表误判为附属信息 | `03-02` |
| 语音打断语义混淆 | runtime 已有 `/admin/openclaw/voice-interrupt`，但它当前控制的是 server-side speech interrupt，不等于整机唤醒/收音开关 | 如果 UI 直接写“语音打断总开关”，会把 runtime 行为和 firmware 行为混在一起 | `Phase 2` 契约先收口，`03-02` 仅按收口后语义展示 |
| 数据聚合缺失 | MCP 地址、tools、函数映射、后续调试指引不在同一视图 | 无法形成完整管理闭环 | `03-02` |
| Runtime 契约不透明 | deploy 已暴露 `/admin/openclaw/`，但 Web 没有对应消费说明 | 前后端边界不清，后续实现容易重复探路 | `03-01` 文档先澄清，`Phase 2` 稳定后再扩 API |
| API 仅提供基础探测 | manager-api 当前只有 address 和 tools | 如果要展示 bridge 状态、admin runtime 状态，可能还缺包装接口 | 依赖 `Phase 2` 后判断 |
| Web / Mobile 分工不清 | Mobile 已有 `tools.vue`，但边界没有文档化 | 两端容易各做一半、都不完整 | `03-01` 文档定义，`03-02` 按文档实现 |

当前 Web 能力是“散落的、低层的、可复用的”，不是“独立的 OpenClaw 管理路径”。`FunctionDialog.vue` 只能算底层函数/MCP 观察窗口，不能当作完整 OpenClaw 管理面。

## Target Web Control Surface

`03-02` 的目标不是复制一个更大的 `FunctionDialog`，而是新增一条围绕 `agentId` 组织的 OpenClaw Web 工作台，至少满足以下特征：

- 有明确的 OpenClaw 页面入口，维护者无需先猜到要打开函数配置抽屉。
- 在同一路径里同时看到 MCP 地址、工具列表、当前函数映射和后续操作建议。
- 把“查看状态”和“跳转到底层配置”区分开，避免页面继续被参数编辑逻辑主导。
- 明确提示哪些信息来自已稳定接口，哪些仍依赖 `Phase 2` 对 deploy / bridge 契约的校准。

## API Dependencies

### Already available

- `GET /agent/{agentId}`：已有 agent detail，可提供当前函数/插件映射的基础数据来源。
- `GET /agent/mcp/address/{agentId}`：可拉取 MCP 接入地址。
- `GET /agent/mcp/tools/{agentId}`：可拉取当前 agent 的 tools 列表。

### Not yet explicit

- OpenClaw bridge 当前连接状态是否可直接从 manager-api 获得。
- `/admin/openclaw/` 是否已有适合管理前端稳定消费的聚合接口。
- runtime 侧 bridge 绑定、最近错误、admin handler 状态是否存在已规范化响应。

这些空白不应在 `03-02` 里拍脑袋补齐。应先以现有 API 完成 Web 第一版聚合页，再把高阶状态接口作为 `Phase 2` 之后的补强项。

## Entry Path

推荐入口路径：

- 新增 Web 路由 `/openclaw-management`
- 通过 query 传递 `agentId`
- 在 `roleConfig.vue` 里提供显式按钮或跳转入口

原因：

- `roleConfig.vue` 已经是当前 agent 配置的事实入口，最容易形成自然跳转。
- 新路径能建立 OpenClaw 独立心智，而不是继续把相关能力藏在 drawer 中。
- `agentId` 已是现有 Web/Mobile/API 的共同主键，不需要引入新的页面状态模型。

## Web Data Blocks

`OpenClawManagement.vue` 第一版至少应包含以下数据块：

1. Agent 概览
   当前 agent 名称、agentId、返回配置页入口。
2. MCP Access
   地址展示、复制、刷新、异常提示。
3. Tool Surface
   当前可探测到的 tools 列表、空状态说明、刷新时间或重新探测动作。
4. Function / Plugin Mapping
   当前函数映射摘要，以及跳回 `roleConfig.vue` 或底层配置入口。
5. Runtime Notes
   明示 deploy 中存在 `/openclaw/bridge/ws`、`/admin/openclaw/` 路由，但相关高阶状态尚未被 Web 收口。

## Must-have Actions

- `refresh`
  重新加载 MCP 地址、tools 列表和 agent detail。
- `copy`
  复制 MCP 地址。
- `jump-to-config`
  回到 `roleConfig.vue`，进入底层函数/插件配置。
- `route-by-agent`
  页面必须以 `agentId` 为核心参数工作，不允许脱离 agent 维度构造伪全局页面。

## Mobile Boundary Decision

Mobile 在本 phase 保持轻量边界：

- 保留 `tools.vue` 作为 agent tools / MCP 的轻量查看与基础编辑入口。
- 不新增与 Web 同级的 OpenClaw 工作台。
- 不在 Mobile 端承担 deploy/runtime/admin 语义解释。
- 需要的只是和 Web 共享同一套 agentId、MCP address、tools 基础能力。

这能避免两个前端同时补半套 OpenClaw 管理面，最后都停在中间态。

## Backend Gaps

以下后端缺口应在 `03-02` 实现前显式认账：

| Gap | Current risk | Action |
| --- | --- | --- |
| 缺少 OpenClaw runtime 聚合接口 | Web 只能拼接基础信息，无法展示 bridge/admin 更高阶状态 | 第一版接受该限制，并在页面文案中明示 |
| `/admin/openclaw/` 契约未沉淀到 manager-api | 前端若直接猜测 runtime 返回结构，后续会被 deploy/hotfix 漂移击穿 | 等 `Phase 2` 校准后再决定是否补 manager-api 包装 |
| `voice-interrupt` 仍是全局开关 | 即使前端有开关，也不能准确表示“按机器维度控制喵伴是否会被打断” | 先以 `.planning/codebase/VOICE_INTERRUPT_CONTROL_CONTRACT.md` 为准，避免把 UI 做成错误承诺 |
| tools 探测依赖 runtime 握手 | 请求失败时前端只能拿到空列表或错误 | 页面需要区分“无工具”和“探测失败”两类状态 |

## Phase 2 Dependencies

`03-02` 可直接开始做 Web 聚合页，但以下部分仍依赖 `Phase 2`：

- deploy overlay 与实际 runtime OpenClaw admin handler 的一致性确认。
- `/admin/openclaw/` 是否形成稳定、可包装的后端契约。
- bridge token、握手和状态探测链路的稳定性验证。

因此，`03-02` 的正确姿势是先做“基于现有稳定接口的聚合控制面”，而不是直接承诺完整 runtime 控制台。
