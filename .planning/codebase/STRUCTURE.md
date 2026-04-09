# Repository Structure

**Analysis Date:** 2026-04-07

## Top-Level Layout

| Path | Role | Notes |
|------|------|-------|
| `README.md` | Root landing page | Currently minimal; does not explain workspace architecture. |
| `.gitmodules` | Submodule manifest | Declares the three upstream codebases. |
| `.planning/` | GSD planning assets | Previously partial; architecture bootstrap is filling gaps. |
| `.pm/` | PM context cache | Generated task/doc context and bootstrap metadata. |
| `deploy/` | Environment overlay | Sealos manifests and hotfix rollout scripts. |
| `xiaozhi-esp32/` | Device firmware submodule | ESP32 client/device runtime. |
| `xiaozhi-esp32-server/` | Backend/admin submodule | Python runtime + Java API + web/mobile consoles. |
| `openclaw-xiaozhi/` | OpenClaw bridge submodule | Plugin and installer CLI for bridge mode. |

## Submodule Boundaries

### `xiaozhi-esp32/`

- `main/` contains application runtime, protocols, MCP server, audio, OTA, board abstractions.
- `docs/` contains firmware protocol and hardware guides.
- `scripts/` contains asset/build helper scripts.

### `xiaozhi-esp32-server/`

- `main/xiaozhi-server/` is the Python conversational runtime and integration surface.
- `main/manager-api/` is the Spring Boot admin/backend API.
- `main/manager-web/` is the browser management console.
- `main/manager-mobile/` is the uni-app mobile/multi-platform console.
- `docs/` and Docker files support deployment, integration, and onboarding.

### `openclaw-xiaozhi/`

- `packages/openclaw-xiaozhi/` contains the plugin entry and bridge runtime.
- `packages/openclaw-xiaozhi-cli/` contains the install/status/unbind CLI.
- `scripts/prepare-publish.mjs` prepares publish metadata.

## Integration-Specific Root Assets

- `deploy/xiaozhi-sealos.yaml` wires Nginx, Python runtime, web/admin runtime, MySQL, and Redis.
- `deploy/refresh-xiaozhi-hotfix.sh` rebuilds a ConfigMap from selected hotfix files under `xiaozhi-esp32-server/main/xiaozhi-server/` and restarts workloads.
- `REPO_SIZE_AUDIT.md` captures repository size concerns for the server submodule; it is analysis-only and not part of the runtime path.

## Structural Assessment

- The root repo is best treated as an integration workspace with submodule pinning, deploy overlay, and architecture docs.
- Ownership boundaries should stay explicit: implementation changes belong in the submodules; root-level work should focus on orchestration, deployment, verification, and documentation.

---

*Structure analysis: 2026-04-07*
