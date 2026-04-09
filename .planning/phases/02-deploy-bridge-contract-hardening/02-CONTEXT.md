# Phase 2: Deploy & Bridge Contract Hardening - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning

<domain>
## Phase Boundary

本 phase 的目标不是继续扩前端能力，而是把 OpenClaw 集成链路中最容易漂移的契约单独收口成 source-of-truth。

当前系统已经具备：

- `manager-web` 的 OpenClaw channel / inventory / debug / clear-session 能力
- `manager-api` 的 `/openclaw-config/*` 包装接口
- `xiaozhi-server` runtime 的 `/admin/openclaw/*` admin handler
- `openclaw-xiaozhi` 对 `xiaozhi.chat`、`xiaozhi.bindPeerAgent`、`xiaozhi.inventory`、`xiaozhi.clearPeerSession` 的 bridge RPC

但这些能力跨了四层：

1. `deploy/xiaozhi-sealos.yaml`
2. `deploy/refresh-xiaozhi-hotfix.sh`
3. `xiaozhi-esp32-server/main/xiaozhi-server/*`
4. `openclaw-xiaozhi/*`

只要其中任意一层漂移，前端看到的“可用能力”就可能和实际生产运行态不一致。

因此 Phase 2 只做两件事：

1. 固化 deploy overlay 与 hotfix 刷新链路的契约真相。
2. 固化 bridge token、bridge websocket、runtime admin、manager-api 包装、OpenClaw RPC 之间的握手链路。

本 phase 不负责：

- 新增前端页面
- 重新设计统一 Agent 模型
- 做设备端 OTA / reconnect 回归

</domain>

<decisions>
## Implementation Decisions

### Locked decisions

- **D-01:** OpenClaw inventory 的真相应优先收口到 `xiaozhi-server` runtime `/admin/openclaw/inventory`，而不是假设 manager-api 可以直接访问 OpenClaw Gateway 本机 HTTP `/inventory`。
- **D-02:** `deploy/xiaozhi-sealos.yaml` 与 `deploy/refresh-xiaozhi-hotfix.sh` 必须被当成运行时契约的一部分，而不只是部署辅助脚本。
- **D-03:** Phase 2 的核心产出应先是文档化的契约图和核对清单，再考虑后续补 smoke / readiness 自动化。
- **D-04:** `manager-api` 的 `OpenClawConfigServiceImpl` 当前默认把 channel `baseUrl` 指向 `${serverOrigin}/admin/openclaw`，这在产品上是合理的，但必须被显式记录，否则后续很容易又退回“直连 OpenClaw Gateway”的错误假设。
- **D-05:** OpenClaw bridge 的真实方向是 OpenClaw 主机主动连 `xiaozhi-server` 的 `/openclaw/bridge/ws`，不是服务端反向连到 Gateway。
- **D-06:** Web 调试与会话清理依赖 runtime admin handler、OpenClaw hub 与 active connection registry 三层同时可用，不能只盯前端页面是否有按钮。

### the agent's Discretion

- Phase 2 的 codebase artifact 最终拆成 1 份还是 2 份文档。
- 是先生成 smoke checklist，再生成更细的 handshake 文档，还是反过来。
- readiness checklist 最终放在 codebase map 里，还是单独作为 ops 文档。

</decisions>

<specifics>
## Specific Ideas

- `deploy/xiaozhi-sealos.yaml` 目前同时定义了 `openclaw_hub` config、Nginx 路由和热修复 cp 覆盖列表，这说明 deploy 本身就是 runtime 真相的一部分。
- `refresh-xiaozhi-hotfix.sh` 负责把本地 runtime 关键文件重新打进 ConfigMap，再重启 deployment；如果脚本与 yaml 的 cp 列表不一致，生产行为会和本地代码分叉。
- `OpenClawConfigServiceImpl` 的默认 `baseUrl = ${serverOrigin}/admin/openclaw`，意味着 manager-api 是按“服务端代理 runtime admin”来设计的，而不是按“直连 OpenClaw Gateway”设计的。
- `openclaw_admin_handler.py` 已经提供 voice interrupt toggle、bridge token 签发/撤销、inventory 聚合、connection 列表、push/chat、direct chat、clear session，这些接口组合起来才是当前 OpenClaw runtime admin surface。
- `openclaw-xiaozhi` bridge client 已经声明支持 `xiaozhi.chat`、`xiaozhi.bindPeerAgent`、`xiaozhi.inventory`、`xiaozhi.clearPeerSession`，所以 Phase 2 需要核对的不是“有没有方法”，而是“这些方法是否被 deploy/runtime/manager-api 串成同一条链”。

</specifics>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` — Phase 2 的目标与 success criteria
- `.planning/STATE.md` — 当前 focus 与 OpenClaw 实现超前于 planning 的现状
- `.planning/codebase/INTEGRATIONS.md` — 根仓级系统链路
- `.planning/codebase/CONCERNS.md` — 当前已知风险
- `.planning/codebase/UNIFIED_AGENT_OPENCLAW_MODEL.md` — 上一阶段确认的统一 Agent + OpenClaw 类型化模型
- `.planning/codebase/AGENT_ADMIN_TYPE_FLOW.md` — 当前 Web 管理流与 runtime 依赖关系
- `deploy/xiaozhi-sealos.yaml` — Sealos 配置、Nginx 路由、hotfix overlay、PVC
- `deploy/refresh-xiaozhi-hotfix.sh` — 热修复 ConfigMap 刷新入口
- `xiaozhi-esp32-server/main/xiaozhi-server/core/api/openclaw_admin_handler.py` — runtime admin 入口
- `xiaozhi-esp32-server/main/manager-api/src/main/java/xiaozhi/modules/openclaw/controller/OpenClawConfigController.java`
- `xiaozhi-esp32-server/main/manager-api/src/main/java/xiaozhi/modules/openclaw/service/impl/OpenClawConfigServiceImpl.java`
- `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js`
- `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/router/agent-router.js`
- `.pm/current-context.json` — 已有真实联调结论与验证记录

</canonical_refs>

<code_context>
## Existing Code Insights

### Deploy / overlay truth
- `xiaozhi-sealos.yaml` 既定义 `openclaw_hub` 参数，也在容器启动时把 hotfix 文件 `cp` 到 runtime 目录。
- `refresh-xiaozhi-hotfix.sh` 重新生成 `xiaozhi-server-hotfix` ConfigMap，并滚动重启 deployment。

### Runtime admin truth
- `openclaw_admin_handler.py` 当前不只是 inventory handler，还承担 bridge token、connection list、push/chat、direct chat、clear session、voice interrupt 开关。
- admin handler 的多个方法依赖 `openclaw_hub`、`websocket_server`、`active connection registry`。

### Manager API truth
- `OpenClawConfigController` 已经是 manager-web 与 runtime admin 之间的稳定 Web 后端包装层。
- `OpenClawConfigServiceImpl` 通过 `buildDefaultBaseUrl(serverOrigin) + "/admin/openclaw"` 推导默认 runtime admin 地址。

### Bridge plugin truth
- `openclaw-xiaozhi` 的 bridge client 已经显式支持 `xiaozhi.inventory` 和 `xiaozhi.clearPeerSession`。
- 这使得 inventory / clear session 可以通过同一条 bridge RPC 路径闭环，不需要额外引入 SSH 或手工读配置。

</code_context>

<deferred>
## Deferred Ideas

- 自动化 smoke / readiness script
- bridge 连接健康度长期监控
- deploy 与 hotfix 清单自动 diff 检查
- 把系统参数持久化迁移为更稳定的数据层

</deferred>

---

*Phase: 02-deploy-bridge-contract-hardening*
*Context gathered: 2026-04-08*
