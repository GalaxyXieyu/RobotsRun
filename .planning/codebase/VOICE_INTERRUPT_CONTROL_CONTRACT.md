# Voice Interrupt Control Contract

## Scope

本文件是 Phase 2 的补充契约文档，用来回答四个容易混淆的问题：

1. 后台修改“语音打断”为什么会对在线设备立刻生效。
2. 当前 `/admin/openclaw/voice-interrupt` 到底控制的是哪一层，不控制哪一层。
3. 如果产品要求“按机器维度控制喵伴会不会被语音打断”，现有实现差哪一层。
4. 如果要让后台修改对离线重连后的设备仍然生效，持久化和连接注入点应放在哪里。

这份文档只基于仓库当前代码给出现状与契约建议，不假设尚未实现的控制面已经存在。

## Current Truth

当前系统里“语音打断”并不是一个单一概念，而是至少包含三层语义：

| Layer | Current owner | Current behavior | Can backend toggle now |
| --- | --- | --- | --- |
| runtime speech interrupt | `xiaozhi-server` runtime | 设备正在播报时，服务端是否因新语音输入而触发 abort | Yes |
| device wake-word interrupt | `xiaozhi-esp32` firmware | 设备正在 speaking / listening 时，本地唤醒词是否会重新打断并进入监听 | No |
| audio upload lifecycle | `xiaozhi-esp32` firmware + protocol | 设备何时打开音频通道并向 server 发送音频 | No |

因此，当前后台开关真正控制的是第一层：`runtime speech interrupt`。

## Runtime Control Path

### Admin surface

runtime HTTP 当前已注册：

- `GET /admin/openclaw/voice-interrupt`
- `POST /admin/openclaw/voice-interrupt`

`POST` 行为分三步：

1. 更新 runtime 全局配置 `self.config["enable_voice_interrupt"]`
2. 同步 `websocket_server.config["enable_voice_interrupt"]`
3. 遍历当前活跃连接，直接改写每个 `conn.config["enable_voice_interrupt"]`

这意味着它不是“写配置等下次连接生效”，而是“直接改在线连接的运行时值”。

### Enforcement path

服务端真正决定要不要打断时，每次都读取连接级配置：

- `abortHandle.py` 通过 `is_voice_interrupt_enabled(conn)` 判断是否允许处理 abort
- `receiveAudioHandle.py` 在设备正在播报时，如果检测到新语音：
  - 开启打断：触发 `handleAbortMessage(conn)`
  - 关闭打断：忽略本次说话，继续当前播报

因此，对在线设备来说，后台改动的生效保证来自“下一次判断时读取的是已被改写的 `conn.config`”，而不是来自设备端固件重载。

## Current Limits

### Limit 1: current scope is global, not per device

当前 `set_voice_interrupt_enabled(enabled)` 会遍历所有在线 session 批量更新。

这意味着当前后台开关的控制粒度是：

- 有 selector 吗：没有
- 作用对象：全部在线连接
- 对离线设备生效吗：不会立即生效

虽然底层判断是在 `conn` 维度做的，但后台控制面目前还没有把这个能力暴露成“按 `deviceId` / `sessionId` 控制”的契约。

### Limit 2: backend switch does not cover device-side wake-word preemption

如果产品语义里的“语音打断”包含：

- 设备正在播报时，被本地唤醒词再次叫醒
- 设备从 speaking 状态直接切回 listening

那么当前后台开关并不能完全覆盖。

设备侧当前状态机是：

- `idle` 时关闭 voice processing，开启 wake word detection
- `speaking` 时若不是 realtime 模式，会关闭 voice processing，但仍可能保留 AFE wake-word detection
- 当 speaking / listening 状态检测到 wake word 时，设备本地会先执行 `AbortSpeaking(...)` 或重进 listening 流程

所以，如果用户说的“不会被语音打断”指的是整机体验，而不只是 runtime abort，那么还需要单独治理 firmware 侧的唤醒打断策略。

### Limit 3: backend switch does not mean always-on audio streaming

当前 ESP32 不是一直把音频上传给 server。

真实行为是：

- `idle`：本地待机，做唤醒词检测
- 检测到 wake word：必要时先打开 audio channel
- `listening`：发送 `SendStartListening(...)` 并开启 voice processing
- 有待发送音频包时：通过 `protocol_->SendAudio(...)` 发到 WebSocket

所以，“后台要动态控制语音打断”与“设备是否一直上传音频”是两个不同问题，不能混成一个开关。

## Why Current Backend Changes Take Effect

当前后台修改对在线设备有效，是因为它满足了三个条件：

1. 控制面和执行面都在 runtime 内
   admin handler 与 abort / receiveAudio 判断都在同一服务端进程。
2. 修改落到了 live connection object
   不是只改全局配置，而是改当前 `conn.config`。
3. 判断发生在事件路径上
   新语音到达或收到 abort 时，会重新读取当前连接配置。

这套保证只覆盖“当前在线连接”。对于离线设备，系统里根本没有在线 `conn` 可改。

## Hardened Contract For Device-Level Control

如果下一步要把产品语义提升为“按机器维度控制喵伴会不会被语音打断”，建议把契约拆成两层，而不是继续复用一个模糊布尔值。

### Control model

建议明确区分两个开关：

| Key | Layer | Meaning |
| --- | --- | --- |
| `runtimeVoiceInterruptEnabled` | server runtime | 设备播报时，服务端是否因新语音触发 abort |
| `deviceWakeInterruptEnabled` | firmware behavior | 设备 speaking / listening 时，本地唤醒词是否允许打断当前流程 |

可选的第三个状态值：

| Key | Layer | Meaning |
| --- | --- | --- |
| `idleWakeWordEnabled` | firmware behavior | 空闲态是否启用本地唤醒词 |

Phase 2 当前应先把第一层契约硬化；第二层如果要做，需要进入 OTA / device config 范畴。

### API shape

为保持兼容，建议保留现有路径，但扩展 payload：

`POST /admin/openclaw/voice-interrupt`

请求体建议支持：

```json
{
  "enabled": true,
  "deviceId": "AA:BB:CC:DD:EE:FF",
  "sessionId": "",
  "persist": true
}
```

契约建议如下：

- 未传 `deviceId` / `sessionId`
  保持现状，执行全局批量更新。
- 传 `deviceId`
  解析到当前设备连接，只改该设备。
- 传 `sessionId`
  只改当前这次连接，优先级高于 `deviceId`。
- `persist = true`
  除了在线连接即时更新，还把设备级策略写入持久层。

响应建议至少返回：

- `scope`: `global | device | session`
- `enabled`
- `updatedConnections`
- `persisted`
- `deviceId`
- `sessionId`

### Persistence model

如果希望后台修改对离线后重连仍生效，就必须引入设备级持久化真相。

建议最小契约为：

1. 设备策略以 `deviceId` 为主键保存
2. 连接建立时读取该设备策略
3. 在 `ConnectionHandler` 初始化阶段，把设备策略注入 `conn.config`
4. 未命中设备策略时，回退到当前全局默认值

这样可以得到明确语义：

- 在线设备：立即生效
- 离线设备：下次连接生效
- 未配置单机策略：走全局默认

### Runtime integration point

当前 registry 已支持按 `session_id` / `device_id` 定位连接，因此单机控制不需要重做连接模型，只需要补一层定向写入方法，例如：

- `set_voice_interrupt_for_connection(session_id=None, device_id=None, enabled=True)`

连接启动时的配置注入点，应放在 runtime 创建 `conn` 并组装 `conn.config` 的阶段，而不是放到前端或 OpenClaw bridge 层。

## UI / Product Naming Guardrail

后续如果 Web 或后台要暴露这个开关，当前阶段必须避免把它命名成：

- “设备语音打断总开关”
- “整机不会被语音打断”

更准确的命名应该是：

- “运行时语音打断”
- “播报时语音插话”
- “server-side voice interrupt”

否则前端会误导用户，以为它同时关闭了本地唤醒打断和设备收音。

## Backward Compatibility

建议保持以下兼容策略：

1. 旧客户端和旧前端继续只传 `enabled`
   维持现有全局行为。
2. 新控制面在需要单机控制时再补 `deviceId` / `sessionId`
3. 未实现持久化前，不承诺“离线后仍生效”
4. 未实现 firmware 配置前，不承诺“整机永不被语音打断”

## Recommended Next Steps

1. 在 runtime admin handler 和 active connection registry 上补“按设备/连接定向更新”的接口契约。
2. 明确设备级配置的持久化落点，再把该值注入连接初始化。
3. 如果产品真的要求“整机不会被语音打断”，新增 firmware 侧唤醒打断配置，不要继续复用 runtime 开关。
4. Web / manager-api 文案统一改成“运行时语音打断”，避免产品语义漂移。

## Evidence

- `xiaozhi-esp32-server/main/xiaozhi-server/core/http_server.py`
- `xiaozhi-esp32-server/main/xiaozhi-server/core/api/openclaw_admin_handler.py`
- `xiaozhi-esp32-server/main/xiaozhi-server/core/openclaw/active_connections.py`
- `xiaozhi-esp32-server/main/xiaozhi-server/core/handle/abortHandle.py`
- `xiaozhi-esp32-server/main/xiaozhi-server/core/handle/receiveAudioHandle.py`
- `xiaozhi-esp32/main/protocols/websocket_protocol.cc`
- `xiaozhi-esp32/main/application.cc`
