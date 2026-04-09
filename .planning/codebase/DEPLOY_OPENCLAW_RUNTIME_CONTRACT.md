# Deploy OpenClaw Runtime Contract

## Scope

本文件是 Phase 2 / `02-01` 的 source-of-truth，专门回答三个问题：

1. OpenClaw 相关运行时配置现在到底由谁定义。
2. `xiaozhi-server` 与 `xiaozhi-web` 这两个服务的生产启动真相分别是什么。
3. 本地代码、ConfigMap hotfix、Sealos 部署之间有哪些漂移风险，以及上线前最小检查项是什么。

这份文档只描述当前仓库里已经真实存在的 deploy/runtime 契约，不讨论新的产品方案。

## OpenClaw Hub Config

`deploy/xiaozhi-sealos.yaml` 里的 `.config.yaml` 当前就是 OpenClaw runtime 的第一层配置真相。关键字段包括：

- `openclaw_hub.enabled = true`
- `openclaw_hub.bridge_ws_path = /openclaw/bridge/ws`
- `openclaw_hub.store_file = /opt/xiaozhi-persistent/openclaw/bridges.json`
- `openclaw_hub.default_account = default`
- `openclaw_hub.relay_chat = true`
- `openclaw_hub.fallback_to_local_on_error = true`
- `openclaw_hub.chat_method = xiaozhi.chat`
- `openclaw_hub.bind_method = xiaozhi.bindPeerAgent`
- `openclaw_hub.session_started_method = xiaozhi.sessionStarted`
- `openclaw_hub.session_ended_method = xiaozhi.sessionEnded`

这些配置决定了三件事：

- OpenClaw bridge 入口默认挂在 `/openclaw/bridge/ws`。
- bridge state 会写到持久卷，而不是只放在内存里。
- runtime 和 OpenClaw 插件之间走的是固定 JSON-RPC 方法名，而不是前端或 manager-api 自己拼协议。

## Route Map

当前外部入口和内部 runtime 注册关系如下。

| Public path | Nginx upstream | Runtime handler | Purpose |
| --- | --- | --- | --- |
| `/xiaozhi/v1/` | `xiaozhi_runtime_ws` -> `xiaozhi-server:8000` | xiaozhi runtime websocket | 设备实时 WebSocket 主链路 |
| `/xiaozhi/ota/` | `xiaozhi_web` -> `xiaozhi-web:8002` | manager-web / manager-api side | OTA/config 下发 |
| `/mcp/vision/explain` | `xiaozhi_runtime_http` -> `xiaozhi-server:8003` | runtime HTTP | 视觉解释能力 |
| `/openclaw/bridge/ws` | `xiaozhi_runtime_http` -> `xiaozhi-server:8003` | `openclaw_hub.handle_websocket` | OpenClaw bridge WebSocket 接入 |
| `/admin/openclaw/` | `xiaozhi_runtime_http` -> `xiaozhi-server:8003` | `openclaw_admin_handler` 系列接口 | runtime admin surface |

需要特别注意：

- `/openclaw/bridge/ws` 与 `/admin/openclaw/*` 都经过 Nginx 转发到 runtime HTTP 端口 `8003`，不是 manager-api 自己处理。
- manager-api 在 OpenClaw 配置流里扮演的是“包装/代理 runtime admin”的角色，而不是 runtime 真正宿主。

## Service Split

当前生产部署不能再被笼统描述成“全都靠 hotfix 覆盖”。真实情况已经分成两类：

| Service | Production startup truth | Drift model |
| --- | --- | --- |
| `xiaozhi-server` | Sealos manifest + ConfigMap hotfix overlay + `python /opt/xiaozhi-esp32-server/app.py` | 高，运行代码可能领先或偏离镜像 |
| `xiaozhi-web` | container image + `/start.sh` + image 内 `/app/xiaozhi-esp32-api.jar` | 中，主要风险是 rollout 命令被改回旧启动方式 |

这一区分很重要，因为 OpenClaw 的 runtime admin 仍属于前者，而后台管理面与 manager-api 的生产部署已经被拉回后者。

## Runtime Ownership

当前 OpenClaw 运行态的职责分布非常明确：

| Layer | Owner | Responsibility |
| --- | --- | --- |
| Sealos ConfigMap | `deploy/xiaozhi-sealos.yaml` | 提供 `openclaw_hub` 配置、Nginx 暴露面、容器启动 cp 覆盖行为 |
| Runtime HTTP server | `core/http_server.py` | 把 `/admin/openclaw/*` 和 bridge websocket 注册到 aiohttp app |
| OpenClaw admin handler | `core/api/openclaw_admin_handler.py` | 提供 voice interrupt、inventory、bridge token、bridges、connections、push/chat、direct chat、clear session |
| OpenClaw hub | `core/openclaw/*` | 接收 bridge WebSocket、维护 bridge 状态、转发 RPC |
| Manager API | `OpenClawConfigController` + `OpenClawConfigServiceImpl` | 把 manager-web 的 channel/inventory/debug 请求包装到 runtime admin |

因此当前系统里“谁是 runtime 真相”的答案是：

- deploy 定义入口和覆盖方式；
- runtime Python 代码定义真实 handler；
- manager-api 不定义 runtime 行为，只包装并暴露管理端消费接口。

## xiaozhi-server Hotfix Overlay

部署时并不是直接运行镜像内原生代码，而是：

1. `xiaozhi-server-hotfix` ConfigMap 挂到 `/opt/xiaozhi-hotfix`
2. 容器启动时执行一组 `cp -f`，把 hotfix 文件覆盖到 `/opt/xiaozhi-esp32-server/...`
3. 然后再 `exec python /opt/xiaozhi-esp32-server/app.py`

这意味着 `xiaozhi-server` 生产实际运行代码 = 镜像内容 + ConfigMap 覆盖结果，而不是单纯等于镜像版本。

OpenClaw 相关 hotfix 目前至少覆盖：

- `core/openclaw/__init__.py`
- `core/openclaw/active_connections.py`
- `core/openclaw/bridge_client.py`
- `core/openclaw/bridge_store.py`
- `core/openclaw/bridge_hub.py`
- `core/openclaw/hub_session.py`
- `core/openclaw/spoken_text.py`
- `core/api/openclaw_admin_handler.py`
- `plugins_func/functions/openclaw_bind_peer_agent.py`

同时，OpenClaw 依赖的上游调用链也被一起覆盖，例如：

- `core/handle/abortHandle.py`
- `core/handle/receiveAudioHandle.py`
- `core/connection.py`
- `core/http_server.py`
- `core/websocket_server.py`

这解释了为什么 OpenClaw 问题不能只看一个文件。

## Overlay File Matrix

下面这张表只关注 `xiaozhi-sealos.yaml` 启动时 `cp` 的文件，以及 `refresh-xiaozhi-hotfix.sh` 重新打包 ConfigMap 的来源文件是否一一对应。

| Hotfix logical file | Deployment startup `cp` | Refresh script `--from-file` | Status |
| --- | --- | --- | --- |
| `app.py` | Yes | Yes | aligned |
| `config_loader.py` | Yes | Yes | aligned |
| `http_server.py` | Yes | Yes | aligned |
| `websocket_server.py` | Yes | Yes | aligned |
| `connection.py` | Yes | Yes | aligned |
| `abortHandle.py` | Yes | Yes | aligned |
| `intentHandler.py` | Yes | Yes | aligned |
| `reportHandle.py` | Yes | Yes | aligned |
| `receiveAudioHandle.py` | Yes | Yes | aligned |
| `plugin_executor.py` | Yes | Yes | aligned |
| `openclaw___init__.py` -> `core/openclaw/__init__.py` | Yes | Yes | aligned but name is non-obvious |
| `active_connections.py` | Yes | Yes | aligned |
| `bridge_client.py` | Yes | Yes | aligned |
| `bridge_store.py` | Yes | Yes | aligned |
| `bridge_hub.py` | Yes | Yes | aligned |
| `hub_session.py` | Yes | Yes | aligned |
| `spoken_text.py` | Yes | Yes | aligned |
| `openclaw_admin_handler.py` | Yes | Yes | aligned |
| `openclaw_bind_peer_agent.py` | Yes | Yes | aligned |

当前没有发现 `cp` 清单与 refresh 脚本明显缺项的地方。真正的风险不在“少文件”，而在“这套文件覆盖本身太隐式”。

## xiaozhi-web Image Startup Contract

`xiaozhi-web` 这一路径现在不应再被视为“运行时 hotfix 覆盖”的一部分。当前真相是：

1. GitHub Actions workflow `deploy-manager-web-k8s.yml` 构建并推送 `Dockerfile-web`
2. rollout 时先 `set image`
3. 再显式 patch deployment，把容器启动命令固定为 `command: ["/start.sh"]`
4. `/start.sh` 启动 `java -jar /app/xiaozhi-esp32-api.jar`，随后以前台 nginx 保持容器存活

这条链路的意义不是“换了一个脚本名”，而是把后台管理面的运行真相重新收敛到镜像本身，避免继续从 PVC 中的旧 jar 启动。

另外，workflow 的 `push.paths` 已覆盖：

- `main/manager-api/**`
- `main/manager-web/**`
- `docs/docker/start.sh`
- `docs/docker/nginx.conf`
- `.github/workflows/deploy-manager-web-k8s.yml`

这意味着 manager-api 的后台管理面改动也会触发 `xiaozhi-web` 重新构建与 rollout，不需要再手工补一次“前端部署”。

## Drift Risks

当前 deploy/runtime 契约的主要漂移风险有这些：

1. `xiaozhi-server` 镜像版本与 hotfix 文件版本漂移
   runtime 真正生效的是覆盖后的 Python 文件，不能只看镜像 tag。

2. `xiaozhi-server` 的 Sealos manifest 和 refresh 脚本双重维护
   现在 file list 在 yaml 和 shell 脚本里各维护一遍，后续有人只改一边就会出问题。

3. runtime 路由存在但 handler 能力漂移
   Nginx 暴露 `/admin/openclaw/` 不代表 runtime admin handler 当前实现和本地代码一致。

4. OpenClaw 依赖链跨多个目录
   即使 `openclaw_admin_handler.py` 对齐了，`active_connections.py`、`bridge_hub.py`、`receiveAudioHandle.py` 任何一个漂移，行为都会变。

5. `xiaozhi-web` 若回退到旧启动命令，仍会重新引入“镜像已更新但实际运行旧 jar”的问题
   这部分风险已经从“当前事实”降为“回归风险”，但不能忽略。

6. 本地子仓 revisions 已经领先于根仓记录
   当前根仓视角下 `xiaozhi-esp32-server`、`xiaozhi-esp32` 都是带本地偏移的 submodule；运维若只看根仓指针，可能误判实际运行基础。

## Readiness Checklist

后续每次声称“deploy 已与本地代码对齐”前，至少要过这份清单：

1. 确认 `deploy/xiaozhi-sealos.yaml` 里的 `openclaw_hub.bridge_ws_path` 仍是 `/openclaw/bridge/ws`，且与 runtime 注册一致。
2. 确认 Nginx 仍暴露 `/openclaw/bridge/ws` 与 `/admin/openclaw/`，并都指向 runtime HTTP upstream。
3. 确认 `refresh-xiaozhi-hotfix.sh` 与 deployment startup `cp` 的文件清单没有新增/缺失分叉。
4. 确认 `http_server.py` 仍注册 `voice-interrupt`、`inventory`、`issue-bridge-token`、`revoke-bridge-token`、`bridges`、`connections`、`push-text`、`chat`、`direct-chat`、`clear-session`。
5. 确认 `openclaw_admin_handler.py`、`bridge_hub.py`、`active_connections.py`、`receiveAudioHandle.py` 都在 hotfix 覆盖范围内。
6. 确认 rollout 后 runtime 实际使用的是新 ConfigMap，而不是旧 Pod。
7. 确认 manager-api 侧默认 `baseUrl` 仍然指向 `${serverOrigin}/admin/openclaw`，没有被改回错误的外部 Gateway 假设。
8. 确认 `deploy-manager-web-k8s.yml` 的触发路径仍覆盖 `main/manager-api/**`，且 rollout patch 仍强制 `command: ["/start.sh"]`。
9. 确认 `xiaozhi-web` 容器实际运行的是 `/app/xiaozhi-esp32-api.jar`，而不是旧的 PVC hotfix 路径。

## Follow-up For 02-02

`02-01` 解决的是“入口和覆盖真相在哪里”。下一步 `02-02` 要解决的是：

- bridge token 如何签发和撤销
- OpenClaw bridge 如何通过 `/openclaw/bridge/ws` 进入
- runtime admin、manager-api、OpenClaw RPC 方法如何拼成同一条握手链

也就是说，`02-01` 是 deploy/runtime 基线，`02-02` 才是桥接握手本身。

## Evidence

- `deploy/xiaozhi-sealos.yaml`
- `deploy/refresh-xiaozhi-hotfix.sh`
- `xiaozhi-esp32-server/.github/workflows/deploy-manager-web-k8s.yml`
- `xiaozhi-esp32-server/docs/docker/start.sh`
- `xiaozhi-esp32-server/main/xiaozhi-server/core/http_server.py`
- `xiaozhi-esp32-server/main/xiaozhi-server/core/api/openclaw_admin_handler.py`
- `xiaozhi-esp32-server/main/xiaozhi-server/core/openclaw/*`
