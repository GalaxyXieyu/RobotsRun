# RobotsRun AGENTS

## 1. 仓库定位

`RobotsRun` 是一个集成工作区，不是把所有逻辑重新做成单一 monorepo。

这个根仓的职责只有四类：

1. 说明三个子仓之间的边界和集成契约。
2. 维护部署真相和联调真相。
3. 提供根仓级 smoke / 联调脚本。
4. 记录禁止事项，避免后续继续走错误流程。

业务实现仍然分别在三个子仓里完成：

- `xiaozhi-esp32/`
  设备固件、板卡适配、设备侧 OTA / WebSocket / MQTT。
- `xiaozhi-esp32-server/`
  服务端主仓，包含：
  - `main/xiaozhi-server`：Python runtime，设备会话、语音链路、OpenClaw bridge hub
  - `main/manager-api`：Spring Boot 管理 API
  - `main/manager-web`：Vue 2 管理台
  - `main/manager-mobile`：uni-app 移动管理端
- `openclaw-xiaozhi/`
  OpenClaw xiaozhi channel 插件和安装 CLI。
- `deploy/`
  根仓保留的历史/辅助部署清单，只用于理解早期 Sealos 拓扑和做冷启动参考；不是日常发布入口。

## 2. 生产部署真相

### 2.1 唯一允许的发布方式

生产环境只允许：

1. 在对应子仓提交代码。
2. push 到 GitHub 远端分支。
3. 由 GitHub Actions 构建镜像并执行部署。

不允许继续使用任何“就地改容器内容”的方式。

### 2.2 触发仓库

当前生产发布的真实仓库是：

- `xiaozhi-esp32-server` 的 `galaxy/main`

当前生产发布**不**由根仓 `deploy/` 目录直接驱动，也**不**由 `openclaw-xiaozhi` 仓库自动替换线上服务端镜像。

### 2.3 GitHub Actions 触发规则

`xiaozhi-esp32-server/.github/workflows/deploy-xiaozhi-server-k8s.yml`

- push 到 `main`
- 且路径命中：
  - `main/xiaozhi-server/**`
  - `Dockerfile-server`
  - `.github/workflows/deploy-xiaozhi-server-k8s.yml`
- 且仓库变量 `AUTO_DEPLOY_XIAOZHI_SERVER == true`，或者手动 `workflow_dispatch`

`xiaozhi-esp32-server/.github/workflows/deploy-manager-web-k8s.yml`

- push 到 `main`
- 且路径命中：
  - `main/manager-api/**`
  - `main/manager-web/**`
  - `Dockerfile-web`
  - `docs/docker/start.sh`
  - `docs/docker/nginx.conf`
  - `.github/workflows/deploy-manager-web-k8s.yml`
- 且仓库变量 `AUTO_DEPLOY_MANAGER_WEB == true`，或者手动 `workflow_dispatch`

### 2.4 部署后的运行真相

- `xiaozhi-server`：容器直接执行镜像内 `python app.py`
- `manager-web / manager-api`：容器执行镜像内 `/start.sh`
- 线上不再允许依赖 PVC、ConfigMap 或 `kubectl cp` 去覆盖容器内代码

## 3. 禁止事项

### 3.1 禁止热更新

从现在开始，生产环境禁止以下行为：

- `kubectl cp` 把代码拷进运行中的 Pod
- 用 ConfigMap 挂载源码覆盖镜像内文件
- 手工改容器启动命令去执行临时脚本
- 保留“先热补丁，后补提交”的发布习惯

紧急修复也必须走：

1. 在对应仓库修代码
2. commit
3. push
4. 触发 GitHub Actions
5. 验证发布结果

### 3.2 根仓 deploy 的定位

`deploy/` 目录现在只保留两类价值：

- 冷启动/历史 Sealos 资源结构参考
- 早期拓扑、端口和资源关系说明

它不是日常发布入口，不应再被当成“线上手改入口”。

## 4. 本地联调标准流程

### 4.1 模式 A：快速联调

适合：

- 快速拉起整套服务
- UI 联调
- 回归验证
- 自动化 smoke 前预热环境

入口：

```bash
./scripts/dev-stack.sh quick-up
```

这会使用：

- `xiaozhi-esp32-server/main/xiaozhi-server/docker-compose_all.yml`

默认端口：

- `8000`：`xiaozhi-server` WebSocket
- `8002`：`manager-web + manager-api` 统一入口
- `8003`：`xiaozhi-server` HTTP

常用访问地址：

- 管理台：`http://127.0.0.1:8002`
- API 文档：`http://127.0.0.1:8002/xiaozhi/doc.html`
- WebSocket：`ws://127.0.0.1:8000/xiaozhi/v1/`

关闭：

```bash
./scripts/dev-stack.sh quick-down
```

### 4.2 模式 B：源码调试

适合：

- 单步调试
- 断点调试
- OpenClaw 问题定位
- 前后端本地联调

推荐做法：

1. 只用 Docker 起 MySQL 和 Redis

```bash
./scripts/dev-stack.sh db-up
```

2. 本地跑 `manager-api`

```bash
./scripts/dev-stack.sh run-api
```

要求：

- JDK 21
- Maven 3.8+

默认地址：

- `http://127.0.0.1:8002/xiaozhi/doc.html`

3. 本地跑 `manager-web`

```bash
./scripts/dev-stack.sh run-web
```

说明：

- 端口固定 `8001`
- `vue.config.js` 已把 `/xiaozhi` 代理到 `http://127.0.0.1:8002`
- 本地访问：`http://127.0.0.1:8001`

4. 本地跑 `xiaozhi-server`

先准备：

- 激活自己的 `conda` / `venv`
- 安装 `ffmpeg`
- 准备 `main/xiaozhi-server/data/.config.yaml`
- `manager-api.secret` 必须填智控台里的 `server.secret`

启动：

```bash
./scripts/dev-stack.sh run-server
```

默认端口：

- `8000`：WebSocket
- `8003`：HTTP / OpenClaw admin / bridge

5. 如果需要移动端 H5 调试

```bash
./scripts/dev-stack.sh run-mobile-h5
```

注意：

- `manager-mobile/env/.env.development` 里的 `VITE_SERVER_BASEURL` 要指向你的管理端，例如 `http://127.0.0.1:8002`

停止 DB / Redis：

```bash
./scripts/dev-stack.sh db-down
```

### 4.3 模式 C：OpenClaw 集成 smoke

#### 本地 Router smoke

用于验证：

- 本地 `~/.openclaw/openclaw.json`
- `defaultAgentId`
- peer 级别隔离
- channel account 下 agent inventory 是否正常

执行：

```bash
./scripts/dev-stack.sh smoke-router
```

实际调用的是：

- `scripts/openclaw-xiaozhi-router-smoke.mjs`

#### 直连 admin 接口 smoke

用于验证：

- `/admin/openclaw/inventory`
- `/admin/openclaw/connections`
- `/admin/openclaw/direct-chat`
- `/admin/openclaw/clear-session`

执行前先设置：

- `OPENCLAW_BASE_URL`
- `OPENCLAW_ADMIN_KEY`

然后执行：

```bash
./scripts/dev-stack.sh smoke-direct
```

## 5. OpenClaw 联调口径

### 5.1 服务端侧关键入口

OpenClaw 相关的服务端入口都在 `xiaozhi-server`：

- bridge websocket：`/openclaw/bridge/ws`
- issue bridge token：`/admin/openclaw/issue-bridge-token`
- inventory：`/admin/openclaw/inventory`

### 5.2 本地接入顺序

建议顺序固定为：

1. 本地起 `xiaozhi-server`
2. 本地起 `manager-api` / `manager-web`
3. 在智控台确认 OpenClaw channel 配置
4. 本地起 OpenClaw gateway
5. 执行 router smoke
6. 再做 direct chat / UI 验证

### 5.3 参数同步要求

全模块模式下至少确认这三个参数：

- `server.secret`
- `server.websocket`
- `server.ota`

如果 `xiaozhi-server/data/.config.yaml` 里的 `manager-api.secret` 不一致，OpenClaw 与设备 runtime 会一起漂移。

## 6. 推荐日常操作

### 6.1 做服务端改动时

1. 在 `xiaozhi-esp32-server` 内开发
2. 本地源码联调或快速联调
3. 跑 OpenClaw smoke
4. commit
5. push 到 `galaxy/main`
6. 看 GitHub Actions
7. 发布完成后做 UI / API 验证

### 6.2 做 OpenClaw 插件改动时

1. 在 `openclaw-xiaozhi` 内开发
2. 本地 `openclaw gateway restart`
3. 跑 `scripts/openclaw-xiaozhi-router-smoke.mjs`
4. 必要时再联动 `xiaozhi-server` 做桥接验证

### 6.3 做设备端改动时

1. 在 `xiaozhi-esp32` 内开发
2. 确认 `server.websocket` / `server.ota`
3. 做设备侧烧录或 OTA 验证

## 7. 统一入口

根仓统一入口脚本：

```bash
./scripts/dev-stack.sh help
./scripts/dev-stack.sh doctor
```

后续新增自动化测试、预检、smoke，优先继续收敛到这个脚本，不要再散落成新的临时脚本。
