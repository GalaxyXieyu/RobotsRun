# 智能喵喵 / RobotsRun

## What This Is

这是一个 brownfield 集成工作区，用来把 `xiaozhi-esp32` 设备固件、`xiaozhi-esp32-server` 服务端/管理端，以及 `openclaw-xiaozhi` OpenClaw 桥接插件组合成一个可部署、可演进的整体系统。根仓本身主要承载部署覆盖、架构梳理、任务/文档同步，而不是替代三个子仓的实现逻辑。

## Core Value

在不破坏各子仓独立演进的前提下，持续保持“设备 → 服务端 → OpenClaw Agent”这条集成链路可理解、可部署、可验证。

## Requirements

### Validated

- ✓ 设备端已具备音频交互、OTA、WebSocket/MQTT、设备侧 MCP 能力 —— 基于 `xiaozhi-esp32/` 现有实现推断。
- ✓ 服务端已包含 Python 运行时、Spring Boot 管理 API、Web 管理台、uni-app 移动端 —— 基于 `xiaozhi-esp32-server/main/` 现有结构推断。
- ✓ OpenClaw 桥接插件与安装 CLI 已存在，可通过服务端桥接接口接入 Agent 运行时 —— 基于 `openclaw-xiaozhi/` 现有实现推断。
- ✓ 根仓已具备 Sealos 部署能力，但运行时真相已按服务拆分：`xiaozhi-server` 仍依赖 hotfix overlay，`xiaozhi-web` 已切到镜像内 `/start.sh` 启动 —— 基于 `deploy/`、workflow 与 `docs/docker/start.sh` 现有实现推断。

### Active

- [ ] ARCH-01：为根仓建立可持续维护的 `.planning` / PM / 飞书架构真相文档。
- [ ] ARCH-02：明确三个子仓与 `deploy/` 的模块边界、依赖关系与集成契约。
- [ ] ARCH-03：给出后续集成治理的阶段路线图与当前阶段建议。

### Out of Scope

- 在本次初始化中重构任一子仓内部实现 —— 会干扰现有未提交改动与上游边界。
- 把三个子仓合并成单一 monorepo —— 当前真实结构就是 submodule 聚合，应先治理契约而非改组织方式。
- 处理大体积历史资产或做仓库瘦身 —— `REPO_SIZE_AUDIT.md` 已记录，但不属于本任务主线。

## Context

- 根仓 `README.md` 目前极简，架构知识主要分散在各子仓 README、部署清单和脚本里。
- `.pm/` 已完成 brownfield bootstrap，推荐动作明确为 `map-codebase`。
- `.planning/codebase/` 现在已补齐 deploy、bridge、统一 Agent 模型、管理面与语音打断契约文档，不再只有初始化骨架。
- `deploy/xiaozhi-sealos.yaml` 与 `deploy/refresh-xiaozhi-hotfix.sh` 仍是 `xiaozhi-server` runtime 的关键集成入口；但 `xiaozhi-web` 的生产真相已经改成镜像构建 + `/start.sh` 启动。
- `xiaozhi-esp32-server` 的后台与 runtime 侧已经形成 OpenClaw 管理闭环：`manager-web` 具备 channel 设置、setup guide、inventory 同步、统一 Agent 类型化绑定、direct chat 与 clear session；`manager-mobile` 仍保持轻量边界。

## Constraints

- **Compatibility**：必须尊重现有 submodule 组织方式 —— 根仓当前就是集成层，不应越界重写子仓架构。
- **Safety**：必须保留未提交改动 —— 当前 `xiaozhi-esp32`、`xiaozhi-esp32-server` 均为 dirty 状态。
- **Source of truth**：所有结论必须基于仓库真实内容 —— 不能假设不存在的统一构建链路或测试基线。
- **Documentation**：至少同步 `PROJECT` 与 `STATE` 到飞书 —— PM/doc 是该项目的长期叙事真相。

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| 根仓继续保持“集成工作区”定位 | 三个核心系统已独立成仓，根仓更适合承载部署与集成治理 | ✓ Good |
| 将 `deploy/` 视为一等模块边界 | `xiaozhi-server` 的生产运行时仍由 Sealos 清单与 hotfix 覆盖共同决定 | ✓ Good |
| 本次初始化仅写 `.planning/` 与 PM/飞书 | 既满足 GSD 架构初始化，又避免碰撞现有未提交改动 | ✓ Good |
| OpenClaw 前端控制面放在后续治理 phase，而不是混入 Phase 1 | 该问题依赖 deploy / bridge 契约稳定后再做产品化前端收口 | ✓ Good |
| `xiaozhi-web` 管理面改为镜像内 `/start.sh` 单一启动真相 | 避免生产继续运行 PVC 中的旧 jar，降低“镜像已更新但后台没变”的漂移风险 | ✓ Good |

---

*Last updated: 2026-04-08 after OpenClaw admin delivery and web deployment truth refresh*
