# 2026-04-13 Production Capture

## Scope

本文件记录 2026-04-13 针对生产环境 OpenClaw 管理与调试界面的截图留档。

目标不是做本地 mock 展示，而是确认以下页面已经在真实生产入口可访问、可截图、可用于对外展示：

- Channel 卡片首页
- Channel 详情工作台
- OpenClaw 调试弹窗
- 带真实调试回复的调试弹窗

## Production Entry

- 域名：`https://dkyyznecfvae.sealoshzh.site`
- 页面路由：`#/openclaw-management`

## Evidence Files

- `production/production-channel-registry.png`
  - 生产版 Channel 卡片页
  - 展示 Channel-first 首屏与卡片摘要
- `production/production-channel-detail.png`
  - 生产版 Channel 详情工作台
  - 展示真实 inventory 拉通后的 Agent 列表和操作入口
- `production/production-debug-dialog-runtime-openclaw.png`
  - 生产版调试弹窗
  - runtime 已切到在线的 `openclaw`
- `production/production-debug-dialog-with-reply.png`
  - 生产版调试弹窗
  - 展示真实消息提交后的用户提问与 AI 回复

## Capture Notes

- 本次截图使用真实生产环境，而不是本地开发环境。
- 为了完成截图，临时创建了一个仅用于拍摄的 production Channel；截图完成后已删除该 Channel，避免把展示配置残留在线上。
- 截图过程中验证了：
  - 生产路由可访问
  - 普通登录用户可进入 OpenClaw 工作台路由
  - 生产 inventory 可返回 runtime / agent / delivery channel / bridge 数据
  - 生产 direct chat 可真实受理并返回调试回复

## Residual Cleanup

- 本次为进入生产页面拍摄，临时注册了一个普通用户账号用于截图。
- 该账号本身不会影响截图归档，但如果后续要严格收口生产测试痕迹，建议由超级管理员在用户管理里做账号清理。
