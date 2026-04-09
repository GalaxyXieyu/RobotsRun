# Coding Conventions

**Analysis Date:** 2026-04-07

## Naming Patterns

**Files:**
- Use kebab-case for module and executable filenames in the active Node workspace under `openclaw-xiaozhi/`, for example `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/channel/xiaozhi-channel.js`, `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/router/agent-router.js`, `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/store/runtime-overrides.js`, and `openclaw-xiaozhi/scripts/prepare-publish.mjs`.
- Keep package directories aligned to the publishable unit defined in `openclaw-xiaozhi/pnpm-workspace.yaml` and `openclaw-xiaozhi/package.json`: `openclaw-xiaozhi/packages/openclaw-xiaozhi/` for the plugin and `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/` for the installer CLI.

**Functions:**
- Use camelCase for helpers and command handlers, as shown by `parseArgs`, `normalizeScope`, `buildRepoFields`, `resolveTargetAgent`, `issueBridgeToken`, `installCommand`, and `statusCommand` in `openclaw-xiaozhi/scripts/prepare-publish.mjs`, `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/router/agent-router.js`, and `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js`.

**Variables:**
- Use camelCase for locals and params, and UPPER_SNAKE_CASE for process-wide constants such as `DEFAULT_AGENT_ID`, `RECONNECT_MIN_MS`, `RECONNECT_MAX_MS`, `SUPPORTED_METHODS`, and `DEFAULT_PLUGIN_SPEC` in `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/router/agent-router.js`, `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js`, and `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js`.

**Types:**
- TypeScript types and interfaces are not detected. Use runtime guards and normalization helpers instead, as in `isObject` in `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/router/agent-router.js` and `normalizeObjectBindings` / `normalizeArrayBindings` in `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/store/static-bindings.js`.

## Code Style

**Formatting:**
- A formatter config is not detected under `openclaw-xiaozhi/` (`.prettierrc*`, `biome.json`, `eslint.config.*`, `.eslintrc*` are absent from the visible tree).
- Match the existing handwritten style in `openclaw-xiaozhi/packages/openclaw-xiaozhi/index.js`, `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js`, and `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js`: ESM modules, two-space indentation, double quotes, no semicolons, and compact object literals unless a multiline layout improves readability.

**Linting:**
- A lint runner is not detected. Treat the curated syntax gate in `openclaw-xiaozhi/package.json` as the current quality baseline.
- When adding a new maintained entry file under `openclaw-xiaozhi/packages/`, extend the `check` script in `openclaw-xiaozhi/package.json` so the file is covered by `node --check` in local and CI flows.

## Import Organization

**Order:**
1. Node built-ins first in scripts and CLIs, as in `openclaw-xiaozhi/scripts/prepare-publish.mjs` and `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js`.
2. External packages next, as in `openclaw-xiaozhi/packages/openclaw-xiaozhi/index.js` and `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js`.
3. Relative workspace modules last, separated by a blank line, as in `openclaw-xiaozhi/packages/openclaw-xiaozhi/index.js` and `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js`.

**Path Aliases:**
- Path aliases are not detected. Use explicit relative ESM imports with the `.js` extension, for example `./src/channel/xiaozhi-channel.js` in `openclaw-xiaozhi/packages/openclaw-xiaozhi/index.js` and `../store/runtime-overrides.js` in `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js`.

## Error Handling

**Patterns:**
- Throw plain `Error` objects for argument validation and command failures in scripts and CLI code, as in `openclaw-xiaozhi/scripts/prepare-publish.mjs` and `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js`.
- Catch at the process boundary and convert failure into `stderr` plus `process.exitCode`, as in `openclaw-xiaozhi/scripts/prepare-publish.mjs` and `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js`.
- In long-lived plugin runtime code, normalize errors into JSON-RPC responses or structured log messages instead of letting socket callbacks crash the process, as in `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js`.

## Logging

**Framework:** `api.logger` inside the plugin runtime in `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js`; `console.log` / `console.error` in the installer CLI at `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js`.

**Patterns:**
- Prefix runtime log lines with `[xiaozhi]` and include account or bridge context, as in `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js`.
- Keep CLI output short and operational, for example `安装完成`, `已解绑 account=...`, and the `Usage:` block in `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js`.

## Comments

**When to Comment:**
- Comments are sparse. Add a comment only when documenting environment-specific behavior or a non-obvious workaround, matching the terminal note near `AbortSignal.timeout(...)` in `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js`.

**JSDoc/TSDoc:**
- JSDoc and TSDoc blocks are not detected in the active workspace under `openclaw-xiaozhi/packages/` or `openclaw-xiaozhi/scripts/`.

## Function Design

**Size:**
- Keep pure helpers small and single-purpose, as in `hasText`, `buildBridgeUrl`, `normalizeScope`, and `resolveStaticBinding` inside `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/channel/xiaozhi-channel.js`, `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js`, `openclaw-xiaozhi/scripts/prepare-publish.mjs`, and `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/store/static-bindings.js`.
- Put orchestration in clearly named async functions or classes, such as `installCommand`, `runLoop`, and `XiaozhiAgentRouter` in `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js`, `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js`, and `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/router/agent-router.js`.

**Parameters:**
- Prefer object parameters when async flows need several named inputs, for example `issueBridgeToken({ serverUrl, adminKey, accountId, defaultAgentId, name, bridgeId })` in `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js` and the constructor object passed to `XiaozhiBridgeClient` in `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js`.

**Return Values:**
- Return serializable POJOs for config inspection and RPC responses, as in `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/channel/xiaozhi-channel.js`, `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/router/agent-router.js`, and `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/store/static-bindings.js`.

## Module Design

**Exports:**
- Reserve the default export for the package entrypoint in `openclaw-xiaozhi/packages/openclaw-xiaozhi/index.js`.
- Use named exports for reusable plugin objects, classes, and helpers, as in `openclaw-xiaozhi/packages/openclaw-xiaozhi/setup-entry.js`, `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/channel/xiaozhi-channel.js`, `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js`, and `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/store/runtime-overrides.js`.

**Barrel Files:**
- Broad barrel files are not used. `openclaw-xiaozhi/packages/openclaw-xiaozhi/index.js` and `openclaw-xiaozhi/packages/openclaw-xiaozhi/setup-entry.js` act as narrow entry shims only.

## Language and Workspace Boundaries

**Language layering:**
- The visible actively maintained application logic in this repo is plain Node.js ESM JavaScript under `openclaw-xiaozhi/packages/` and `openclaw-xiaozhi/scripts/`.
- Keep runtime plugin code under `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/`, package entry shims under `openclaw-xiaozhi/packages/openclaw-xiaozhi/`, and CLI concerns under `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/`.

**Workspace management:**
- Manage publishable units through the `packages/*` workspace declared in `openclaw-xiaozhi/pnpm-workspace.yaml` and duplicated in `openclaw-xiaozhi/package.json`.
- Keep repo-level automation scripts in `openclaw-xiaozhi/scripts/`; `openclaw-xiaozhi/scripts/prepare-publish.mjs` is the current example for cross-package metadata edits.

**Submodule collaboration:**
- Treat `.gitmodules` as the source of truth for cross-repo boundaries: `openclaw-xiaozhi/`, `xiaozhi-esp32/`, and `xiaozhi-esp32-server/` are separate submodules coordinated at the top level.
- Apply the Node conventions in this document to the `openclaw-xiaozhi/` subtree. The sibling submodules `xiaozhi-esp32/` and `xiaozhi-esp32-server/` are integrated by repository reference, not by shared JavaScript imports or a shared workspace.

---

*Convention analysis: 2026-04-07*
