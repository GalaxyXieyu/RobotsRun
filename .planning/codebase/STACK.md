# Technology Stack

**Analysis Date:** 2026-04-07

## Workspace Shape

- Root repository `RobotsRun` is an orchestration workspace, not a conventional single-app repo.
- `.gitmodules` binds three source-of-truth submodules: `xiaozhi-esp32/`, `xiaozhi-esp32-server/`, and `openclaw-xiaozhi/`.
- `deploy/` adds environment-specific deployment and hotfix overlay logic for the combined system.

## Primary Stacks By Module

### `xiaozhi-esp32/` Firmware

- Language: C/C++
- Build: ESP-IDF + CMake via `CMakeLists.txt`
- Protocol modules visible in `main/protocols/` include WebSocket and MQTT.
- Runtime capabilities include OTA, MCP server, audio pipeline, display/LED/device abstractions.

### `xiaozhi-esp32-server/` Runtime + Admin

- `main/xiaozhi-server/`: Python runtime server with `requirements.txt`, WebSocket/HTTP entrypoints, plugin/tool integrations, local models/assets.
- `main/manager-api/`: Java 21 + Spring Boot 3.4 + Maven admin API.
- `main/manager-web/`: Web admin frontend with Node/npm toolchain.
- `main/manager-mobile/`: Vue 3 + uni-app + TypeScript + pnpm mobile/admin client.
- Deployment images are described with `Dockerfile-server`, `Dockerfile-web`, and Docker compose files.

### `openclaw-xiaozhi/` Agent Bridge

- Language: Node.js ESM
- Package manager: pnpm workspace
- Packages:
  - `@galaxyxieyu/openclaw-xiaozhi`: OpenClaw channel plugin
  - `@galaxyxieyu/openclaw-xiaozhi-cli`: Installer/registration CLI
- Validation baseline is `npm run check`, implemented with `node --check` over key entry files.

### `deploy/` Integration Overlay

- Kubernetes manifests for Sealos deployment
- Bash-based hotfix refresh script that mounts selected server files into runtime containers
- Nginx routing and runtime config are embedded as ConfigMaps

## Runtime Dependencies

- MySQL and Redis are provisioned by `deploy/xiaozhi-sealos.yaml` for the server/admin stack.
- OpenClaw Gateway is an external runtime dependency for the bridge plugin and PM/Feishu automation.
- The Python server integrates model/tool providers, plugin functions, and bridge storage under `main/xiaozhi-server/`.

## Tooling Observations

- There is no root-level package manager, test runner, or build manifest.
- Validation is fragmented by submodule and technology boundary.
- The root repo currently serves as a coordination and deployment surface more than a unified build surface.

---

*Stack analysis: 2026-04-07*
