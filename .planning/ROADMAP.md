# Roadmap: 智能喵喵 / RobotsRun

## Overview

这是一个 brownfield 集成工作区，路线图先解决架构可见性、集成契约和验证基线，再进入更高风险的桥接强化与设备回归工作。到 2026-04-08 为止，Phase 2 / 02.1 已完成；Phase 3 虽然已有交付，但 production smoke 暴露出连通性与信息架构问题，因此追加一轮收口计划后才进入设备侧回归。

## Phases

**Phase Numbering:**
- 整数 phase 表示主线治理阶段
- 如后续出现高优先级插单，可在整数之间插入小数 phase

- [ ] **Phase 1: Integration Baseline & Docs** - 固化根仓架构真相、GSD 资产和 PM/飞书同步机制
- [x] **Phase 2: Deploy & Bridge Contract Hardening** - 校准 deploy overlay、OpenClaw bridge、运行时入口的一致性
- [x] **Phase 02.1: Agent 统一模型与 OpenClaw 类型化重定义** - 先定义统一 Agent 模型、`native/openclaw` 类型分流与后台映射关系，再进入前端实现
- [ ] **Phase 3: Agent Admin Surface Alignment** - 基于统一 Agent 模型，把 OpenClaw 类型智能体收敛进现有前端管理流，并厘清 Web / Mobile 分工
- [ ] **Phase 4: Device Onboarding & OTA Validation** - 回到设备端，验证固件接入、OTA 与协议链路的闭环

## Phase Details

### Phase 1: Integration Baseline & Docs
**Goal**: 根仓具备可复用的架构真相文档、GSD 核心资产与 PM/飞书同步基线
**Depends on**: Nothing (first phase)
**Requirements**: [INTEG-01, INTEG-03, PLAN-01, PLAN-02, DOC-01, DOC-02, OPS-03]
**Success Criteria** (what must be TRUE):
  1. 维护者能从 `.planning/` 读懂根仓为何存在、三子仓如何协作、`deploy/` 扮演什么角色
  2. `PROJECT` 与 `STATE` 已同步到飞书，T1 留下阶段性回推记录
  3. 后续 GSD 工作流能以这些文档为输入继续规划
**Plans**: 3 plans

Plans:
- [x] 01-01: 完成 brownfield map-codebase 文档与 `.planning` 核心资产初始化
- [ ] 01-02: 补根仓 README / 维护者入口说明（可在本 phase 内择机完成）

### Phase 2: Deploy & Bridge Contract Hardening
**Goal**: 明确 deploy overlay、服务端桥接接口和 OpenClaw 插件的契约，降低版本漂移风险
**Depends on**: Phase 1
**Requirements**: [INTEG-02, OPS-01, OPS-02]
**Success Criteria** (what must be TRUE):
  1. `/xiaozhi/v1/`、`/xiaozhi/ota/`、`/openclaw/bridge/ws`、`/admin/openclaw/` 的入口映射被验证
  2. hotfix 文件列表与实际部署拷贝路径一致
  3. 根仓拥有一份集成 smoke / readiness checklist
**Plans**: 2 plans

Plans:
- [x] 02-01: 审计 Sealos 清单与 hotfix 刷新脚本的一致性
- [x] 02-02: 验证 OpenClaw bridge token 与桥接握手链路

### Phase 02.1: Agent 统一模型与 OpenClaw 类型化重定义 (INSERTED)

**Goal**: 在进入前端实现前，先定义统一 Agent 模型与 `native/openclaw` 类型分流，明确哪些字段是公共配置、哪些差异由类型决定，以及 OpenClaw 映射关系如何作为后台实现细节存在
**Requirements**: [ADM-01, ADM-03, ADM-04]
**Depends on:** Phase 2
**Success Criteria** (what must be TRUE):
  1. 团队明确系统中的顶层业务对象是统一的 `Agent`，而不是并列维护一套 server agent 和一套 OpenClaw agent 控制台
  2. `native` 与 `openclaw` 类型的公共字段、专属字段、可编辑边界都已定义清楚
  3. OpenClaw 映射关系、状态同步与工具暴露被定位为后台实现细节，并为前端下一阶段提供明确 manager-api 契约输入
**Plans:** 1 plan

Plans:
- [x] 02.1-01: 定义统一 Agent 模型、OpenClaw channel 接入流与前后端契约

### Phase 3: Agent Admin Surface Alignment
**Goal**: 基于 02.1 定义的统一 Agent 模型，把 OpenClaw 类型智能体收敛进现有前端管理流，并明确 manager-api / manager-web / manager-mobile 的分工
**Depends on**: Phase 02.1
**Requirements**: [INTEG-01, ADM-01, ADM-02]
**Success Criteria** (what must be TRUE):
  1. 维护者能说明 OpenClaw 配置当前落在 runtime / deploy / admin API 的哪些位置，以及前端缺了哪一层控制面
  2. `manager-web` 至少具备一条基于统一 Agent 创建/编辑流程的可操作管理路径，能根据 `native/openclaw` 类型动态展示配置项
  3. `manager-mobile` 与 `manager-web` 的 OpenClaw 能力边界清晰，避免两个前端都做一半
**Plans**: 2 plans

Plans:
- [x] 03-01: 审计现有 agent 创建/编辑流与 OpenClaw channel/type contract gap
- [x] 03-02: 实现 OpenClaw channel 设置页与统一 Agent 类型化编辑流，明确 Mobile 端是否只读/延后
- [ ] 03-03: 修复 OpenClaw production 连通性并重构 Channel → Agent 调试信息架构

### Phase 4: Device Onboarding & OTA Validation
**Goal**: 回到固件与设备链路，验证从接入到 OTA 的闭环
**Depends on**: Phase 3
**Requirements**: [INTEG-02]
**Success Criteria** (what must be TRUE):
  1. 设备协议入口、配置下发与 OTA 流程有明确验证步骤
  2. 设备接入链路与服务端/部署侧契约保持一致
**Plans**: 2 plans

Plans:
- [ ] 04-01: 梳理 firmware 连接配置与 server 返回字段映射
- [ ] 04-02: 制定 OTA / reconnect / protocol regression checklist

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Integration Baseline & Docs | 1/2 | In progress | 01-01 complete |
| 2. Deploy & Bridge Contract Hardening | 2/2 | Completed | 2026-04-08 |
| 02.1. Agent 统一模型与 OpenClaw 类型化重定义 | 1/1 | Completed | 2026-04-08 |
| 3. Agent Admin Surface Alignment | 2/3 | In progress | 03-01 / 03-02 complete; 03-03 pending |
| 4. Device Onboarding & OTA Validation | 0/2 | Not started | - |

---

*Last updated: 2026-04-08 after reopening Phase 3 for production smoke failures and IA correction*
