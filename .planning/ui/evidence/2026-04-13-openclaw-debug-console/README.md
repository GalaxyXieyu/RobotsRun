# 2026-04-13 OpenClaw Debug Console Evidence

## Scope

本目录保存 `03-03` 执行阶段的 OpenClaw 调试台 UI 证据，用于证明本轮不是只停留在蓝图，而是已经把 Channel-first 工作台和新的 debug workbench 做到真实页面层。

## Files

- `channel-registry.png`
  - Channel 首页卡片视图
  - 为真实页面状态截图
- `channel-detail-agent-workbench.png`
  - Channel 详情页的 agent-first 工作台
  - 由于本地 `LocalTestChannel` 当时未连通，使用页面内注入的 mock inventory / binding 数据拍摄
- `debug-dialog-workbench.png`
  - 新的 Task / Trace / Playback 调试弹窗
  - 使用页面内注入的 mock debug state 拍摄
- `debug-dialog-density-v2.png`
  - 第一轮真实历史数据截图
  - 重点验证调试弹窗的密度、字号和关键回复展示
- `debug-dialog-reading-flow-v3.png`
  - 第二轮真实历史数据截图
  - 重点验证“左侧选任务，右侧按 1 → 2 → 3 阅读详情”的阅读流
- `production/production-channel-registry.png`
  - 生产版 Channel 卡片页
  - 用于展示真实线上首屏卡片状态
- `production/production-channel-detail.png`
  - 生产版 Channel 详情工作台
  - 用于展示真实线上 Agent 工作台
- `production/production-debug-dialog-runtime-openclaw.png`
  - 生产版调试弹窗
  - runtime 已切到在线的 `openclaw`
- `production/production-debug-dialog-with-reply.png`
  - 生产版调试弹窗
  - 含真实消息提交后的 AI 回复
- `production-capture-2026-04-13.md`
  - 生产截图说明
  - 记录生产入口、截图范围和清理说明

## Capture Notes

- 截图日期：2026-04-13
- 页面入口：`http://localhost:8001/#/openclaw-management`
- `channel registry` 截图对应真实页面数据
- `debug-dialog-density-v2.png` 与 `debug-dialog-reading-flow-v3.png` 基于真实历史任务数据拍摄，用于证明真实链路回归后 UI 已继续收敛
- 同日已补生产环境截图，详见 `production-capture-2026-04-13.md`

## Follow-up

后续如果继续做 server UI 改动验收或 deploy 后回归，应在同目录继续补：

- 真实 trace 中携带 `taskId` 的截图
- 真实设备队列出现 `device_push_enqueued` 的截图
- 新一轮 deploy 后的 UI/UX 回归截图
