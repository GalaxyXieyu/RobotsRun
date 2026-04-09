# OpenClaw 接口检查报告

检查日期：2026-04-09

## 1. 检查目标

本次检查覆盖三部分：

1. 生产环境前端到 OpenClaw 的主链路与关键接口。
2. 绕过平台时，如何直接检查 OpenClaw channel、agent 与对话连通性。
3. 本地 OpenClaw 的可见性、调试能力与会话隔离性。

## 2. 生产链路结论

前端生产环境 API 根路径是 `/xiaozhi`，OpenClaw 页面由 `manager-web` 调 `manager-api` 的 `/xiaozhi/openclaw-config/**`。

`manager-api` 再把请求代理到 runtime `baseUrl` 下的以下关键接口：

- `GET /inventory`
- `POST /direct-chat`
- `POST /clear-session`
- `GET /connections`
- `GET/POST /voice-interrupt`

结论：

- 平台内主调试入口不是直接打 OpenClaw plugin，而是先走 `manager-api`。
- 如果要绕过平台做直连测试，应该直接访问 `xiaozhi-server` 的 `/admin/openclaw/*` 接口。

## 3. 生产环境只读探测

已验证的线上入口：

- `https://dkyyznecfvae.sealoshzh.site/` 可访问，HTTP 200。
- `https://dkyyznecfvae.sealoshzh.site/xiaozhi/doc.html` 可访问，HTTP 200。

未带认证时的结果：

- `GET /xiaozhi/openclaw-config/channels` 返回 HTTP 200，但业务体为 `{"code":401,"msg":"Unauthorized","data":null}`。
- `GET /admin/openclaw/inventory` 返回 HTTP 401，业务体为 `{"ok":false,"message":"unauthorized"}`。

结论：

- 生产入口本身是活的。
- 平台侧接口需要 `manager-api` Bearer token。
- 直连 runtime 需要 `xiaozhi-server` 的 admin token。
- 当前无法在无凭证条件下完成线上 `inventory`、`connections`、`direct-chat`、`clear-session` 的完整实测。

## 4. 本地 OpenClaw 实测结果

本地环境已确认：

- 已安装 `openclaw` CLI。
- `Xiaozhi` channel 已启用。
- account 为 `default`。
- bridgeId 为 `bridge-b7ef0b1fb4ac`。
- 默认 agent 为 `smart-miaomiao`。

本地可见 agent 共 7 个：

1. `main`
2. `fufeng`
3. `img-producer`
4. `xhs-content`
5. `eggturtle-miniapp`
6. `smart-miaomiao`
7. `openclaw-pm-coder-kit`

实际 smoke 结论：

- `getInventory({ account: "default" })` 成功，能够拿到 bridge、default agent 与 agent 列表。
- 对 `peerA` 绑定 `smart-miaomiao` 后，`routeChat` 成功返回文本。
- 对 `peerB` 绑定 `main` 后，`routeChat` 成功返回文本。
- 对 `peerA` 执行 `clearPeerSession` 成功，清理后 override 消失。
- 清理 `peerA` 后再次对话仍命中 `smart-miaomiao`，原因是本地默认 agent 本来就是 `smart-miaomiao`，不是清理失效。

## 5. 隔离性判断

已实测成立：

- 同一 OpenClaw 实例内，不同 peer 的 agent 绑定是隔离的。
- 清理 `peerA` 不会影响 `peerB`。

当前只能部分确认，尚未完整实测：

- 本地 OpenClaw 与远端 OpenClaw 是否完全实例隔离。

原因：

- 远端 runtime admin token 缺失，无法对远端 bridge 做真实 `inventory/direct-chat/clear-session`。
- `ssh openclaw` 当前不能用于非交互自动化，连接后会被远端立即关闭。

基于现有代码与架构可以推断：

- channel/routing 以各自 runtime `baseUrl`、bridge 与 account 为边界。
- 只要本地和远端使用不同 runtime、不同 bridge 或不同 account，状态天然应当隔离。
- 但这部分仍应补一次真实双端 smoke，不能只停留在代码推断。

## 6. 当前发现的问题

### P1: 线上直连检查缺少 runtime admin token

影响：

- 无法直接验证远端 channel 的 `inventory` 返回。
- 无法列出远端 bridge 下实际有哪些 agent。
- 无法对远端 agent 做一条最小 `direct-chat` 验证。

建议：

- 从 `xiaozhi-server` 实例侧补充 admin token。
- 补齐后直接执行本仓库新增的 `scripts/openclaw-direct-smoke.sh`。

### P1: 远端 `ssh openclaw` 不适合自动化

影响：

- 不能靠无交互 SSH 自动拉取远端插件、channel 和 agent 详情。

建议：

- 调试通道统一改为 HTTP admin API。
- 如果必须保留 SSH 路径，需要在远端补可自动化的 shell 入口或专用调试脚本。

### P2: `openclaw status --all` 存在 scope 缺口

现象：

- 本地 `openclaw status --all` 提示 gateway 缺少 `operator.read` scope，因此部分 OpenClaw 总览状态不可用。

判断：

- 这是权限/运维问题，不应误判为 xiaozhi bridge 接口不可用。

## 7. 推荐调试方式

优先级建议：

1. 平台内链路排查：先看 `/xiaozhi/openclaw-config/**` 是否能正常返回。
2. 绕过平台直连排查：直接打 `/admin/openclaw/inventory`、`/connections`、`/direct-chat`、`/clear-session`。
3. 本地 agent/bridge 排查：用 `openclaw status --all`、`openclaw gateway status`，再配合本仓库脚本做 smoke。

本仓库已新增直连脚本：

- `scripts/openclaw-direct-smoke.sh`

脚本目标：

- 拉 inventory
- 拉 connections
- 自动挑一个 bridge 和 agent
- 发一条 direct-chat
- 再清掉当前 debug 会话

## 8. 下一步

要完成完整线上报告，还需要两项输入：

1. 远端 `xiaozhi-server` 的 admin token。
2. 一个可访问的远端 runtime `baseUrl`。

拿到后建议立刻补跑以下检查：

1. `inventory`，确认 bridge 与 agent 列表。
2. `connections`，确认当前在线设备与 session。
3. `direct-chat`，随机找一个 agent 发最小消息。
4. `clear-session`，确认会话可清理。
5. 再与本地实例做对比，补完跨实例隔离性结论。
