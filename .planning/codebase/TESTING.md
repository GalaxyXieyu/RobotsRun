# Testing Patterns

**Analysis Date:** 2026-04-07

## Test Framework

**Runner:**
- No dedicated test runner such as Jest, Vitest, Mocha, Ava, or TAP is detected in the visible repository tree.
- The only automated validation entrypoint currently wired into scripts and CI is the syntax check in `openclaw-xiaozhi/package.json`, which runs `node --check` over a curated list of JavaScript files.
- Config: `openclaw-xiaozhi/package.json`

**Assertion Library:**
- Not detected.

**Run Commands:**
```bash
cd openclaw-xiaozhi && npm run check   # Run the current automated gate (syntax validation only)
# Watch mode: Not detected
# Coverage: Not detected
```

## Test File Organization

**Location:**
- Co-located or centralized test directories are not detected. A repository-wide scan does not show `*.test.*`, `*.spec.*`, `tests/`, or `__tests__/` under the active workspace `openclaw-xiaozhi/`.

**Naming:**
- Not applicable in current state because test files are not detected.

**Structure:**
```text
Not detected.
The active quality gate is the explicit file list inside `openclaw-xiaozhi/package.json`.
```

## Test Structure

**Suite Organization:**
```text
Not detected.
Current automation validates syntax for these maintained entrypoints:
- `openclaw-xiaozhi/packages/openclaw-xiaozhi/index.js`
- `openclaw-xiaozhi/packages/openclaw-xiaozhi/setup-entry.js`
- `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/channel/xiaozhi-channel.js`
- `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/store/static-bindings.js`
- `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/store/runtime-overrides.js`
- `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/router/agent-router.js`
- `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js`
- `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js`
```

**Patterns:**
- Setup pattern: manual environment setup is documented in `openclaw-xiaozhi/packages/openclaw-xiaozhi/README.md`, where the plugin is installed, enabled, and the OpenClaw gateway is restarted.
- Teardown pattern: the only visible teardown-like path is the manual `unbind` command in `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js`.
- Assertion pattern: current validation relies on command exit status, CLI output, and runtime logs from `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js`; automated assertions are not detected.

## Mocking

**Framework:**
- Not detected.

**Patterns:**
```text
Not detected.
The current repository has no visible mock helpers, spy utilities, or test doubles.
```

**What to Mock:**
- Current code exposes no formal test guidance. If the first automated tests are added, the clearest seam boundaries are external side effects in `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js` (`spawnSync`, `fetch`) and `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js` (`WebSocket`, timer/reconnect behavior).

**What NOT to Mock:**
- Keep pure data-shaping helpers real when possible, especially `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/store/static-bindings.js`, `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/store/runtime-overrides.js`, and pure selection logic in `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/router/agent-router.js`.

## Fixtures and Factories

**Test Data:**
```text
Not detected.
There are no fixture directories, factories, or reusable sample payload modules in the visible tree.
```

**Location:**
- Not applicable in current state.

## Coverage

**Requirements:**
- Coverage thresholds are not enforced. No coverage command, report directory, or coverage config is detected in `openclaw-xiaozhi/`.

**View Coverage:**
```bash
# Not detected
```

## Test Types

**Unit Tests:**
- Not detected.

**Integration Tests:**
- A formal integration harness is not detected. The closest automated integration gate is `openclaw-xiaozhi/.github/workflows/publish.yml`, which runs `npm run check` before publishing packages.

**E2E Tests:**
- Not used in the visible repository tree.

## Current Verification Path

**Pragmatic validation for the current stage:**
```bash
cd openclaw-xiaozhi
npm run check

openclaw plugins install ./packages/openclaw-xiaozhi
openclaw plugins enable xiaozhi
openclaw gateway restart

node ./packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js status --account default
```

- Use `npm run check` in `openclaw-xiaozhi/package.json` as the first gate because it is the only validation wired into CI at `openclaw-xiaozhi/.github/workflows/publish.yml`.
- Use the manual plugin install sequence from `openclaw-xiaozhi/packages/openclaw-xiaozhi/README.md` to verify that packaging and OpenClaw plugin registration still work.
- Use the CLI commands defined in `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js` (`install`, `status`, `unbind`) against a disposable OpenClaw profile and a real `xiaozhi-server` admin endpoint when validating bridge setup behavior.
- Inspect runtime logs from `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js` for connection, payload, and close-cycle behavior because no automated assertions currently cover WebSocket flows.

## Common Patterns

**Async Testing:**
```text
Not detected.
The async-heavy code paths that would need the first coverage are `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js` and `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js`.
```

**Error Testing:**
```text
Not detected.
Current failure behavior surfaces through thrown `Error` values, non-zero exit codes, CLI stderr, JSON-RPC error payloads, and `[xiaozhi]` runtime log lines.
```

## Coverage Gaps

- `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/router/agent-router.js` contains most of the routing and response extraction logic, but no automated tests verify precedence between runtime overrides, static bindings, and fallback agent selection.
- `openclaw-xiaozhi/packages/openclaw-xiaozhi/src/bridge/client.js` owns reconnect timing, payload parsing, and JSON-RPC dispatch, but no automated tests exercise socket lifecycle or malformed payload handling.
- `openclaw-xiaozhi/packages/openclaw-xiaozhi-cli/bin/openclaw-xiaozhi.js` orchestrates interactive prompts, `fetch`, and `spawnSync`, but no tests cover successful install, status lookup, unbind, or failure branches.
- `openclaw-xiaozhi/scripts/prepare-publish.mjs` rewrites package metadata, but no tests protect argument parsing or generated `package.json` mutations.

---

*Testing analysis: 2026-04-07*
