# System Architecture

**Analysis Date:** 2026-04-07

## Architectural Summary

`RobotsRun` is a brownfield integration workspace that combines:

1. an ESP32 device firmware client,
2. a multi-service server/admin platform,
3. an OpenClaw bridge plugin,
4. and a deployment overlay that binds them into one runtime topology.

The root repo does not implement the business logic itself; it composes and deploys upstream systems.

## High-Level Flow

### Device Path

- `xiaozhi-esp32/` builds the device runtime.
- The firmware talks to the backend using WebSocket or MQTT+UDP, and consumes OTA/config data from the server side.

### Server Path

- `xiaozhi-esp32-server/main/xiaozhi-server/` is the realtime conversational/runtime hub.
- `main/manager-api/` exposes admin/device configuration APIs.
- `main/manager-web/` and `main/manager-mobile/` provide management surfaces for operators and users.

### Agent Bridge Path

- `openclaw-xiaozhi/packages/openclaw-xiaozhi/` registers an OpenClaw channel plugin and starts a bridge service.
- The plugin maintains an outbound WebSocket connection to the server bridge endpoint and maps peers to OpenClaw agents.
- The CLI package provisions config, issues bridge tokens through the server admin endpoint, and restarts the OpenClaw gateway.

### Deployment Path

- `deploy/xiaozhi-sealos.yaml` exposes WebSocket, OTA, vision HTTP, and OpenClaw bridge/admin routes via Nginx.
- `deploy/refresh-xiaozhi-hotfix.sh` copies selected Python runtime files into a ConfigMap-driven hotfix layer before rollout.

## Module Boundaries

| Boundary | Source of truth | Root repo responsibility |
|----------|-----------------|--------------------------|
| Firmware device logic | `xiaozhi-esp32/` | Pin version, document integration, validate endpoint contracts |
| Server/admin logic | `xiaozhi-esp32-server/` | Pin version, maintain deploy overlay, document cross-service contracts |
| OpenClaw bridge logic | `openclaw-xiaozhi/` | Pin version, document bridge setup and deployment expectations |
| Cluster/runtime topology | `deploy/` | Maintain the composed deployment contract |

## Current Architectural Pattern

- Pattern: federated submodules + root-level deploy overlay
- Strength: preserves upstream ownership and lets the root repo compose a product-specific deployment.
- Weakness: there is no single root-level verification pipeline proving that the three submodules still fit together after drift.

## Recommended Architectural Posture

- Keep the root repo thin and contract-driven.
- Treat deployment manifests, integration docs, and end-to-end verification as the main responsibilities of this workspace.
- Avoid moving feature work into the root repo unless it is truly integration-specific.

---

*Architecture analysis: 2026-04-07*
