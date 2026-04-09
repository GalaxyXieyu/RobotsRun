# Integrations

**Analysis Date:** 2026-04-08

## Core Integration Contracts

### Firmware ↔ Server

- The firmware side contains both `protocols/websocket_protocol.cc` and `protocols/mqtt_protocol.cc`.
- OTA/config handling in `main/ota.cc` reads `mqtt`, `websocket`, and `server_time` sections from server responses.
- The deploy layer publishes:
  - `/xiaozhi/v1/` for realtime WebSocket traffic
  - `/xiaozhi/ota/` for OTA/config delivery

### Server ↔ OpenClaw

- The OpenClaw plugin expects a bridge WebSocket endpoint and bridge token issued by the server.
- The CLI README and root README indicate token issuance via `POST /admin/openclaw/issue-bridge-token`.
- Sealos routing exposes:
  - `/openclaw/bridge/ws`
  - `/admin/openclaw/`

### Server Internal Composition

- `manager-api` assembles device report payloads that include WebSocket and MQTT configuration.
- `xiaozhi-server` hosts runtime WebSocket/HTTP services, tool/plugin execution, and bridge support.
- `manager-web` now carries the primary OpenClaw admin surface: channel setup, setup guide, inventory sync, unified Agent binding, direct chat, and clear session.
- `manager-mobile` remains a lightweight companion surface and does not duplicate the full OpenClaw control workspace.

### Deployment Truth ↔ Runtime Files

- `deploy/refresh-xiaozhi-hotfix.sh` injects selected Python files from `xiaozhi-esp32-server/main/xiaozhi-server/` into a ConfigMap-backed hotfix layer.
- The Sealos deployment command then copies these files into `/opt/xiaozhi-esp32-server/` inside the runtime container before startup.
- This hotfix overlay contract applies to `xiaozhi-server`, not to `xiaozhi-web`.
- `xiaozhi-web` production rollout now follows a different path: GitHub Actions builds `Dockerfile-web`, updates the deployment image, and forces `command: ["/start.sh"]`, which starts `/app/xiaozhi-esp32-api.jar`.

## External Dependencies

| Dependency | Purpose | Evidence |
|------------|---------|----------|
| MySQL | admin/config persistence | Sealos manifest provisions `xiaozhi-mysql` |
| Redis | cache/session/runtime support | Sealos manifest provisions `xiaozhi-redis` |
| OpenClaw Gateway | agent runtime and PM/Feishu bridge | plugin/CLI README + PM tooling |
| Nginx ingress | protocol fan-out and public surface | `deploy/xiaozhi-sealos.yaml` |

## Integration Drift Risks

- The server bridge contract lives across Python runtime code, deploy YAML, and OpenClaw plugin expectations.
- `xiaozhi-server` hotfix file copying means the effective runtime may differ from the upstream container image.
- `xiaozhi-web` no longer depends on PVC hotfix override as the normal production truth, but it can regress if rollout command patching is removed.
- Root-level docs were previously incomplete, making integration assumptions harder to audit.

## Immediate Verification Targets

1. Confirm deployed route mapping for `/xiaozhi/v1/`, `/xiaozhi/ota/`, `/openclaw/bridge/ws`, and `/admin/openclaw/`.
2. Confirm the bridge token issuance flow still matches the CLI expectations.
3. Confirm the hotfix file list in `deploy/refresh-xiaozhi-hotfix.sh` matches the files mounted by the Sealos deployment for `xiaozhi-server`.
4. Confirm `xiaozhi-web` deployment still rolls on `main/manager-api/**` changes and starts via `/start.sh`.

---

*Integration analysis: 2026-04-08*
