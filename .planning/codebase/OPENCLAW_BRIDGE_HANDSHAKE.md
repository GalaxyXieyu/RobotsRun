# OpenClaw Bridge Handshake

## Scope

本文件是 Phase 2 / `02-02` 的 source-of-truth，用来回答下面这些问题：

1. OpenClaw bridge token 是谁签发、谁消费、怎么进入 WebSocket 握手。
2. `/openclaw/bridge/ws` 和 `/admin/openclaw/*` 各自属于哪一层。
3. manager-api 的 inventory / direct chat / clear session 为什么本质上是 runtime admin 包装，而不是直连 Gateway。
4. `openclaw-xiaozhi` 插件实际支持哪些 RPC 方法，以及这些方法如何被 runtime 调用。

这份文档只描述当前仓库里已经存在的链路，不扩展新的控制面设计。

## Handshake Flow

当前 bridge handshake 的真实方向如下：

1. runtime 暴露 `/admin/openclaw/issue-bridge-token` 和 `/openclaw/bridge/ws`。
2. OpenClaw 侧拿到 bridge token 与 server URL 后，构造 WebSocket URL。
3. OpenClaw 插件作为客户端主动连接 `wss://<server>/openclaw/bridge/ws?token=...`。
4. runtime `openclaw_hub` 接受这条连接并维护 bridge 状态。
5. runtime 通过 bridge JSON-RPC 调用插件侧的 `xiaozhi.inventory`、`xiaozhi.bindPeerAgent`、`xiaozhi.chat`、`xiaozhi.clearPeerSession`。
6. manager-api 不直接参与 WebSocket 握手；它只通过 HTTP 访问 runtime admin surface，再把结果包装给 manager-web。

这条流最容易被误解的地方是第 3 步。真实方向是 OpenClaw 主机向 xiaozhi-server 出站连接，不是 manager-api 或 xiaozhi-server 反向去连 OpenClaw Gateway。

## Bridge Token

bridge token 的职责只有一个：授权 OpenClaw bridge 接入 runtime websocket。

当前 runtime admin handler 已提供：

- `POST /admin/openclaw/issue-bridge-token`
- `POST /admin/openclaw/revoke-bridge-token`

其行为是：

- 校验 admin key。
- 调 `openclaw_hub.issue_bridge_token(...)` 或 `openclaw_hub.revoke_bridge(...)`。
- 返回 `bridge` 元数据、`token` 和 `bridgeWebSocketUrl`。

因此 bridge token 的宿主是 runtime，不是 manager-api，也不是 OpenClaw 插件本地自造。

## WebSocket Entry

bridge websocket 入口由两层共同定义：

- deploy 层在 `xiaozhi-sealos.yaml` 把 `/openclaw/bridge/ws` 暴露到 runtime HTTP upstream。
- runtime 层在 `http_server.py` 里把 `bridge_ws_path` 绑定到 `openclaw_hub.handle_websocket`。

这意味着：

- `/openclaw/bridge/ws` 是 OpenClaw 插件进入 xiaozhi runtime 的唯一正式 bridge 入口。
- 这条链路是 WebSocket，不是 HTTP inventory 接口。
- manager-api 不应该试图“代替 bridge 客户端”去走这条链。

## Runtime Admin Surface

当前 runtime admin surface 由 `openclaw_admin_handler.py` + `http_server.py` 一起定义。已注册的关键 HTTP 入口包括：

- `GET /admin/openclaw/voice-interrupt`
- `POST /admin/openclaw/voice-interrupt`
- `GET /admin/openclaw/inventory`
- `POST /admin/openclaw/issue-bridge-token`
- `POST /admin/openclaw/revoke-bridge-token`
- `GET /admin/openclaw/bridges`
- `GET /admin/openclaw/connections`
- `POST /admin/openclaw/push-text`
- `POST /admin/openclaw/chat`
- `POST /admin/openclaw/direct-chat`
- `POST /admin/openclaw/clear-session`

这些接口的职责分别是：

- `voice-interrupt`
  读取/切换运行时语音打断开关，并同步到当前连接。
- `inventory`
  调 OpenClaw bridge 的 `xiaozhi.inventory`，聚合出 runtimeAccounts、agents、bridges、accountAgents。
- `bridges`
  列出当前 bridge 与 `bridgeWebSocketPath`。
- `connections`
  列出当前 xiaozhi 设备连接。
- `push-text` / `chat`
  走 active connection registry，对在线设备代发文本或聊天。
- `direct-chat`
  不依赖在线设备，直接通过 OpenClaw hub RPC 调 `bindPeerAgent + chat`。
- `clear-session`
  通过 OpenClaw hub RPC 调 `xiaozhi.clearPeerSession` 清理桥接会话。

所以 runtime admin surface 不是一个单一 inventory 接口，而是一整套 bridge 管理面。

## Manager API Assumptions

manager-api 当前对 OpenClaw 的关键假设有三条：

1. channel 的默认 `baseUrl` 应指向 `${serverOrigin}/admin/openclaw`
2. inventory 地址是 `baseUrl + inventoryPath`
3. debug / clear session 地址是 `baseUrl + /direct-chat`、`baseUrl + /clear-session`

这套设计体现在 `OpenClawConfigServiceImpl`：

- `buildDefaultBaseUrl(serverOrigin) -> ${serverOrigin}/admin/openclaw`
- `buildInventoryUrl(channel)`
- `buildChannelApiUrl(channel, path)`
- `requestChannelApi(...)`

也就是说，manager-api 当前不是设计成去读 OpenClaw Gateway 本机的控制台 HTTP，而是显式包在 xiaozhi runtime admin surface 外面。

## Manager API Wrapper Flow

manager-api 对 runtime admin 的包装方式可以分成三类：

1. settings / bootstrap
   - `GET /openclaw-config/channels/{channelId}/setup-guide`
   - 负责返回 install command、server URL、default agent 等引导信息。

2. inventory / binding
   - `GET /openclaw-config/channels/{channelId}/inventory`
   - `GET|PUT /openclaw-config/agents/{agentId}`
   - 负责把 runtime inventory 转成 manager-web 可消费的 channel 绑定流。

3. debug / cleanup
   - `POST /openclaw-config/channels/{channelId}/direct-chat`
   - `POST /openclaw-config/channels/{channelId}/clear-session`
   - 负责把 manager-web 的调试请求转发到 runtime admin。

所以 manager-api 的角色是“带权限与产品语义的包装层”，不是 bridge 协议终点。

## Plugin RPC Methods

`openclaw-xiaozhi` bridge client 当前明确支持以下 JSON-RPC 方法：

- `xiaozhi.sessionStarted`
- `xiaozhi.sessionEnded`
- `xiaozhi.chat`
- `xiaozhi.bindPeerAgent`
- `xiaozhi.inventory`
- `xiaozhi.clearPeerSession`

它们在插件侧的落点是：

- `xiaozhi.bindPeerAgent` -> `router.bindPeerAgent(params)`
- `xiaozhi.inventory` -> `router.getInventory(params)`
- `xiaozhi.clearPeerSession` -> `router.clearPeerSession(params)`
- `xiaozhi.chat` -> `router.routeChat(params)`

因此 runtime inventory / direct chat / clear session 并不是凭空实现出来的，它们最终都依赖这组 RPC。

## HTTP vs WebSocket Boundary

当前链路里 HTTP 和 WebSocket 的边界应这样理解：

| Boundary | Protocol | Owner |
| --- | --- | --- |
| manager-web -> manager-api | HTTP | Spring Boot manager-api |
| manager-api -> runtime admin | HTTP | aiohttp runtime admin surface |
| OpenClaw plugin -> runtime bridge | WebSocket + JSON-RPC | `openclaw_hub` + `openclaw-xiaozhi` |
| runtime -> plugin inventory/chat/bind/clear | JSON-RPC over bridge websocket | runtime hub + plugin bridge client |

这也是为什么“HTTP inventory”和“bridge websocket”必须分开看。

## False Assumptions To Avoid

当前必须避免继续传播的错误假设有这些：

1. manager-api 可以稳定直连 OpenClaw Gateway 本机 `/inventory`
   实际联调已经证明真实 Gateway 常常只绑定 loopback，且 `/inventory` 不一定返回预期 JSON。

2. `/admin/openclaw/` 是 manager-api 提供的接口
   实际它属于 runtime aiohttp handler，经 Nginx 转发暴露。

3. OpenClaw 页面能工作就说明 bridge 握手没问题
   页面只是 manager-api 包装结果；真正的 bridge 可用性还取决于 token、WebSocket、hub、plugin RPC 和 active connection registry。

4. direct chat 依赖在线设备
   当前 `direct-chat` 明确是为了不依赖在线设备做 bridge 调试。

## Failure Modes

当前这条握手链最可能出问题的点有：

1. token 正常签发，但 OpenClaw 插件没有成功连上 `/openclaw/bridge/ws`
   结果：`bridges` 看不到在线连接，inventory 只能返回空或错误。

2. bridge 在线，但 `xiaozhi.inventory` 返回结构不符合预期
   结果：runtime inventory 聚合报 `inventory 响应格式无效` 或 manager-api 兼容解析失败。

3. manager-api channel `baseUrl` 被错误改成真实 Gateway 地址
   结果：inventory/debug/clear session 会打到错误 HTTP 目标。

4. direct chat 指定的 account / bridge / agent 不匹配
   结果：bind 成功但 chat 失败，或 chat 命中错误 agent。

5. clear session 缺失 `sessionId/deviceId/peerId`
   结果：只能依赖 `allowLatest` 从 connection registry 猜最后一个连接，行为有不确定性。

6. runtime admin route 存在，但 deploy hotfix 与本地代码漂移
   结果：文档、源码、生产行为三者不一致。

## Smoke Gaps

虽然契约已经能从代码里说清，但下面这些仍需要真实环境 smoke 才能算闭环：

- `issue-bridge-token` 返回的 `bridgeWebSocketUrl` 是否可被真实 OpenClaw 主机成功连接
- `/openclaw/bridge/ws` 在生产域名与 Nginx 转发下是否稳定
- `/admin/openclaw/inventory` 在真实 bridge 在线时是否返回正确 account/agent 列表
- `direct-chat` 在真实 account / bridge / agent 组合下是否能稳定收到回复
- `clear-session` 对 sessionId / deviceId / peerId 的匹配是否符合预期
- `voice-interrupt` 改动是否真的同步到活动连接

## Recommended Smoke Order

如果下一步继续做真实环境验证，建议顺序如下：

1. 先验证 `issue-bridge-token`
2. 再验证 bridge 是否连上 `/openclaw/bridge/ws`
3. 再看 `/admin/openclaw/bridges`
4. 再测 `/admin/openclaw/inventory`
5. 然后测 `direct-chat`
6. 最后测 `clear-session` 和 `voice-interrupt`

这样排的原因是：前面的环节不通，后面的功能一定是假阳性或无法稳定复现。

## Evidence

- `deploy/xiaozhi-sealos.yaml`
- `xiaozhi-esp32-server/main/xiaozhi-server/core/http_server.py`
- `xiaozhi-esp32-server/main/xiaozhi-server/core/api/openclaw_admin_handler.py`
- `xiaozhi-esp32-server/main/manager-api/src/main/java/xiaozhi/modules/openclaw/controller/OpenClawConfigController.java`
- `xiaozhi-esp32-server/main/manager-api/src/main/java/xiaozhi/modules/openclaw/service/impl/OpenClawConfigServiceImpl.java`
- `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js`
- `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/router/agent-router.js`
- `.pm/current-context.json`
