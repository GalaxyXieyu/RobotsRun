# 02-01 Summary

## Result

已完成 Phase 2 第一段契约梳理，并产出：

- `.planning/codebase/DEPLOY_OPENCLAW_RUNTIME_CONTRACT.md`

这份文档把 deploy、Nginx、runtime HTTP、hotfix overlay 的关系写成了单一 source-of-truth，不再需要从 Sealos yaml、刷新脚本和聊天记录里拼图。

## Key Findings

1. `deploy/xiaozhi-sealos.yaml` 不只是部署清单，它同时定义了 OpenClaw hub 配置、Nginx 暴露面和 runtime 启动时的 hotfix 覆盖行为。
2. `/openclaw/bridge/ws` 与 `/admin/openclaw/*` 当前都走 runtime HTTP 端口 `8003`，不是 manager-api 自己托管。
3. `refresh-xiaozhi-hotfix.sh` 与 deployment startup `cp` 清单目前是一致的，暂未发现明显漏项。
4. 真正的核心风险是 overlay 机制本身过于隐式，导致镜像版本、hotfix ConfigMap 和本地代码很容易漂移。

## Output Contract For 02-02

- `02-02` 不需要再重复解释 deploy overlay。
- 下一步应直接聚焦 bridge token、bridge websocket、runtime admin surface、manager-api 包装和 plugin RPC 的握手链路。
- 后续 smoke 验证要以 `DEPLOY_OPENCLAW_RUNTIME_CONTRACT.md` 的 readiness checklist 为 deploy 基线。

## Verification

- 文档包含 `OpenClaw Hub Config`
- 文档包含 `Route Map`
- 文档包含 `Runtime Ownership`
- 文档包含 `Hotfix Overlay`
- 文档包含 `Overlay File Matrix`
- 文档包含 `Drift Risks`
- 文档包含 `Readiness Checklist`
- 文档显式引用 `/openclaw/bridge/ws`、`/admin/openclaw/`、`refresh-xiaozhi-hotfix.sh`
