# Phase 3: OpenClaw Admin Surface Alignment - Discussion Log

> **Audit trail only.** Do not use as input to planning or execution agents.
> Locked decisions are recorded in `03-CONTEXT.md`. This file preserves the alternatives and user choices that led to the latest 03-03 replan.

**Phase:** 03-openclaw-admin-surface-alignment

---

## 2026-04-07 baseline discussion

### Surface ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Web primary | `manager-web` 做完整 OpenClaw 控制面，Mobile 只保留轻量能力 | ✓ |
| Dual build | Web 和 Mobile 同时做完整控制面 | |
| Mobile primary | 优先把 Mobile 作为主要入口 | |

**Choice:** Web 做主控制面，Mobile 只保留轻量能力。  
**Notes:** 现有 Web 管理台更适合承担复杂配置与调试收口。

### Reuse strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse existing agent/MCP surfaces | 基于 `roleConfig`、`FunctionDialog`、`/agent/mcp/*` 扩展 | ✓ |
| Build from scratch | 另起新的前端模块，不复用现有能力 | |
| Deploy-only console | 只暴露 deploy/runtime 层配置，不复用 agent 维度 | |

**Choice:** 在现有 agent/plugin/MCP 能力之上收口。  
**Notes:** 减少重复开发，也更符合统一 Agent 模型。

### Web / Mobile boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Web full, Mobile light | Web 完整控制，Mobile 只读或轻操作 | ✓ |
| Same capability | 两端做同一套能力 | |
| Web docs only | Web 只做文档和跳转，不做真正控制 | |

**Choice:** Web 完整控制，Mobile 不追求同级覆盖。

### Control-surface expectations

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated workspace | 有专属页面/路径，聚合状态、工具、映射、操作入口 | ✓ |
| Keep hidden in dialog | 继续放在底层抽屉里 | |
| Pure documentation | 只写说明，不做可操作界面 | |

**Choice:** 做专属控制面，而不是继续隐藏在低层对话框里。

---

## 2026-04-08 production smoke re-discuss

### Page structure

| Option | Description | Selected |
|--------|-------------|----------|
| 频道为主 | 首页只看 Channel 卡片，点进二级详情后看 agent 与调试 | ✓ |
| 单页重排 | 仍保留一个页面，但默认只露出 Channel 和 agent | |
| 三栏工作台 | 左侧 Channel，中间 agent，右侧调试常驻同屏 | |

**Choice:** Channel 首页卡片化，进入二级详情再看 agent 与调试。  
**Why it changed:** production smoke 和用户实测都表明当前长页混合流程太重，用户真正需要的是更短的路径。

### Primary detail object

| Option | Description | Selected |
|--------|-------------|----------|
| 业务 Agent 卡片 | 默认先看业务 Agent，再看它绑了哪个 OpenClaw agent | |
| OpenClaw Agent 列表 | 默认先看 OpenClaw inventory 返回的 agent 列表 | ✓ |
| 双列表并列 | 业务 Agent 与 OpenClaw Agent 同屏并列 | |

**Choice:** Channel 详情默认看 OpenClaw Agent 列表。  
**Notes:** 业务绑定作为每个 OpenClaw agent 的二级展开关系出现。

### Binding presentation

| Option | Description | Selected |
|--------|-------------|----------|
| 折叠绑定列表 | 卡片只显示绑定数量，点开后再看哪些业务 Agent 绑到了它 | ✓ |
| 直接显示标签 | 卡片上直接铺开所有业务 Agent 标签 | |
| 完全隐藏 | 默认不展示业务 Agent，只保留调试入口 | |

**Choice:** 业务绑定采用折叠列表展示。  
**Notes:** 保留可观测性，但不再让默认界面被标签墙淹没。

### Debug container

| Option | Description | Selected |
|--------|-------------|----------|
| 复用弹窗 | 沿用大弹窗容器，但内容重做为简洁调试台 | ✓ |
| 右侧抽屉 | 从右侧拉出调试台 | |
| 详情内嵌 | 在详情页下半部分展开调试区 | |

**Choice:** 复用现有大弹窗容器。  
**User note:** “要尽量美化一下，现在好丑。”

### Channel CRUD pattern

| Option | Description | Selected |
|--------|-------------|----------|
| 卡片 + 菜单 | 卡片进入详情，右上角菜单负责重命名和删除 | ✓ |
| 列表 + 侧边编辑 | 延续旧的左侧列表 + 右侧表单 | |
| 独立设置页 | 查看调试和编辑配置彻底拆成两个页面 | |

**Choice:** Channel CRUD 采用卡片 + 菜单。

### Runtime control placement

| Option | Description | Selected |
|--------|-------------|----------|
| 降级到高级区 | 仍留在页内，但弱化为折叠区 | |
| 独立路由 / 系统页 | 从 OpenClaw 主流程里拿掉，后续再迁到系统功能配置 | ✓ |
| 保留同页标签 | 继续放在当前页 tab 里 | |

**Choice:** 本次先从 OpenClaw 页移除。  
**User note:** “放到系统功能配置页面吧。”  
**Implementation note:** 03-03 先负责移除和去耦，不把迁移作为本次交付前置。

### Infra exposure

| Option | Description | Selected |
|--------|-------------|----------|
| 默认隐藏 | bridge/source/raw inventory 只进高级诊断区 | ✓ |
| 默认展示 | 保持当前 bridge/runtime/source 平铺 | |
| 单独运维页 | 彻底拆成单独 bridge console | |

**Choice:** 默认隐藏到高级诊断区。  
**Notes:** 用户明确认为当前 bridge 名称和链路信息“太乱、太奇怪”，不应继续作为一级界面对象。

---

## Deferred ideas

- 将运行时语音打断正式迁入 `/feature-management`
- 做单独的 bridge 删除 / 观测 / 诊断控制台
- 给调试台补实时日志、trace、回放能力
- Mobile 端做等价的 Channel / debug 面板

---

*Discussion log refreshed: 2026-04-08 after user IA decisions*
