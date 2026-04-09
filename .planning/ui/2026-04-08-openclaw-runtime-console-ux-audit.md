# OpenClaw Runtime Console UI/UX Audit

日期：2026-04-08

## 结论

当前“设备运行时控制台”最大的设计问题不是配色，而是信息架构失焦：一个页面同时承载了 4 条复杂任务流，导致首屏信息噪音大、核心操作埋得深、阅读顺序反复跳变。

建议把页面重构为“左侧 Channel 工作区 + 右侧分段控制台”，默认落到“运行时控制”标签页，把 Channel 接入、Inventory 校验、在线调试降为同级二级工作区，而不是全部堆在一个长页里。

## 主要问题

### 1. 顶部导航 pill 可读性差

- 当前导航按钮固定高度 `30px`，但文本允许换行，且文本最大宽度只有 `80px`，直接导致“设备运行时控制”在 pill 内换成两行，视觉上像被挤压变形。
- 相关实现：
  - `xiaozhi-esp32-server/main/manager-web/src/components/HeaderBar.vue:693`
  - `xiaozhi-esp32-server/main/manager-web/src/components/HeaderBar.vue:710`
  - `xiaozhi-esp32-server/main/manager-web/src/components/HeaderBar.vue:864`

### 2. 首屏被 Hero 说明占满，但不提供真实决策支持

- 页面标题、Hero 标题、Hero 描述表达的是同一件事，内容重复。
- 首屏右侧状态 pill 只给出结果，不告诉用户下一步该做什么。
- 相关实现：
  - `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue:5`
  - `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue:26`
  - `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue:1427`

### 3. 一页混合 4 条任务流，滚动成本过高

- 当前页面把以下流程连续堆叠：
  1. Channel 管理
  2. Inventory 校验
  3. 运行时语音打断
  4. 在线调试
- 用户必须在“创建配置”“同步状态”“运行时控制”“调试验证”之间上下跳读。
- 相关实现：
  - `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue:50`
  - `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue:183`
  - `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue:251`
  - `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue:440`

### 4. 页面宣称“优先控制运行时”，但真正的运行时面板被放在中后段

- Hero 文案明确说“优先控制设备播报打断”，但真正的打断控制块在 Inventory 后面。
- 这会形成叙事与操作位置的错位。
- 相关实现：
  - `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue:29`
  - `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue:251`

### 5. Channel 编辑卡片过长，且操作阶段没有被折叠

- 一个卡片里同时包含：
  - 步骤说明
  - 基础表单
  - 主操作按钮
  - 安装命令
  - 高级配置
- 这会导致首屏下面立刻进入大段表单区，难以扫读。
- 相关实现：
  - `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue:80`
  - `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue:94`
  - `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue:126`
  - `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue:165`

### 6. 按钮层级失衡，用户不知道当前最应该点哪个

- “保存 Channel 配置”“复制安装命令”“测试并拉取 Inventory”都出现在同一组按钮里，但它们属于不同阶段。
- 没有“你现在处于第几步”的显式反馈。
- 相关实现：
  - `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue:119`

### 7. Inventory 与在线调试信息展示过满，默认视图不够克制

- Inventory 把 bridge、runtime/account、agent、source url、绑定策略全部摊开。
- 在线调试默认展示完整控制条、会话栏、双栏对话区域，体量接近独立工具页。
- 它们适合二级工作区，不适合在主任务流中默认展开。
- 相关实现：
  - `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue:183`
  - `xiaozhi-esp32-server/main/manager-web/src/views/OpenClawManagement.vue:440`

## 改版方向

### 信息架构

建议改成两栏工作台：

- 左栏：Channel 工作区
  - 当前选中 channel
  - channel 列表
  - 接入进度 checklist
- 右栏：主控制台
  - 顶部状态摘要条
  - 标签页：
    - `运行时控制`
    - `Channel 接入`
    - `Inventory 校验`
    - `在线调试`

### 交互原则

- 默认落在 `运行时控制`
- 没有选中 channel 时，右栏显示轻量的阻断提示，而不是让用户自己去长页里找入口
- `Channel 接入` 只展示当前阶段必需字段，其余通过折叠区或抽屉进入
- `Inventory 校验` 默认先看健康状态和最近同步结果，详细项二次展开
- `在线调试` 独立成标签页，避免拖垮主页面长度

### 视觉方向

建议采用更偏 “control room / operations console” 的风格，而不是当前这种“营销 Hero + 通用卡片堆叠”。

关键词：

- 更短的标题区
- 更强的状态条
- 更清晰的阶段边界
- 更少但更明确的主按钮
- 更稳定的左右布局

## 低风险优化优先级

### P0

- 修复顶部导航 pill 换行
- 删除或压缩 Hero，改成状态摘要条
- 把运行时控制提升到默认首屏

### P1

- 把长页切成标签页工作区
- 把 Channel 编辑重构为“基础配置 + 命令安装 + 高级配置”分段
- 增加当前进度提示

### P2

- 重做在线调试区的排版和消息层级
- 为 Inventory 增加更明确的健康检查反馈样式

## 草图文件

- `.planning/ui/2026-04-08-openclaw-runtime-console-wireframe.drawio`

## 文本预览

```text
+--------------------------------------------------------------------------------------+
| Header / Global Nav                                   [设备运行时控制]               |
+--------------------------------------------------------------------------------------+
| 设备运行时控制台                                             [返回] [新建] [刷新]    |
| 优先管理运行时打断；Channel / Inventory / 在线调试做成分段工作区                    |
+-----------------------------------+--------------------------------------------------+
| 左栏：Channel 工作区              | 右栏：主控制台                                   |
|                                   |                                                  |
| 当前 Channel                      | [当前 Channel] [Inventory] [在线设备] [打断状态] |
| 生产 Runtime / prod-runtime       |                                                  |
|                                   | [运行时控制] [Channel 接入] [Inventory 校验]     |
| Channel 列表                      | [在线调试]                                       |
| - 生产 Runtime                    |                                                  |
| - 灰度 Runtime                    | 运行时控制                                       |
|                                   | +----------------+ +----------------+            |
| 接入进度                          | | 全局默认值      | | 按设备控制      |            |
| 1. 保存 Channel                   | +----------------+ +----------------+            |
| 2. 执行安装命令                   | | 作用范围说明 / 风险提示               |         |
| 3. 同步 Inventory                 | +--------------------------------------+         |
|                                   |                                                  |
|                                   | 在线设备列表 / 表格 / 快捷操作                    |
+-----------------------------------+--------------------------------------------------+
```
