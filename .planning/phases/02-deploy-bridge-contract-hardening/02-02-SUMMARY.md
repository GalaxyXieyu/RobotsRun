# 02-02 Summary

## Result

已完成 Phase 2 第二段契约梳理，并产出：

- `.planning/codebase/OPENCLAW_BRIDGE_HANDSHAKE.md`

这份文档把 bridge token、`/openclaw/bridge/ws`、runtime admin、manager-api 包装层和 `openclaw-xiaozhi` RPC 方法串成了一条完整握手链。

## Key Findings

1. 真实 bridge 方向是 OpenClaw 插件作为客户端，主动连接 xiaozhi-server 的 `/openclaw/bridge/ws`。
2. manager-api 当前的正确心智是“包装 runtime admin surface”，不是“直连 Gateway inventory”。
3. runtime `/admin/openclaw/*` 当前已经不仅有 inventory，还包括 token、bridges、connections、push/chat、direct-chat、clear-session、voice-interrupt。
4. `direct-chat` 和 `clear-session` 的底层都依赖 OpenClaw hub JSON-RPC，而不是普通 HTTP 控制台逻辑。

## Output Contract

- 后续如果做 smoke，必须按 `issue-bridge-token -> websocket -> bridges -> inventory -> direct-chat -> clear-session` 的顺序验证。
- 后续如果再有人讨论 “baseUrl 指向哪里”，应直接以 `${serverOrigin}/admin/openclaw` 为当前 manager-api 约定。
- 后续如果前端再报 inventory/debug 问题，应先检查 runtime bridge 和 RPC 是否在线，而不是先怀疑页面。

## Verification

- 文档包含 `Handshake Flow`
- 文档包含 `Bridge Token`
- 文档包含 `WebSocket Entry`
- 文档包含 `Runtime Admin Surface`
- 文档包含 `Plugin RPC Methods`
- 文档包含 `Manager API Assumptions`
- 文档包含 `False Assumptions To Avoid`
- 文档包含 `Failure Modes`
- 文档包含 `Smoke Gaps`
- 文档显式引用 `/openclaw/bridge/ws`、`/admin/openclaw`、`xiaozhi.inventory`、`xiaozhi.clearPeerSession`
