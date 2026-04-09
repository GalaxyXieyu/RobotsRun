#!/usr/bin/env bash
set -euo pipefail

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required env: $name" >&2
    exit 1
  fi
}

json_get() {
  local file="$1"
  local expr="$2"
  jq -r "$expr // empty" "$file"
}

print_step() {
  printf '\n== %s ==\n' "$1"
}

api_call() {
  local method="$1"
  local path="$2"
  local body="${3:-}"
  local outfile="$4"
  local url="${OPENCLAW_BASE_URL%/}${path}"
  local -a curl_args

  curl_args=(
    -sS
    --connect-timeout "${CONNECT_TIMEOUT:-10}"
    --max-time "${MAX_TIME:-60}"
    -X "$method"
    -H "Authorization: Bearer ${OPENCLAW_ADMIN_KEY}"
    -H "X-OpenClaw-Token: ${OPENCLAW_ADMIN_KEY}"
    -H "Content-Type: application/json"
    -o "$outfile"
    -w "%{http_code}"
  )

  if [[ "${CURL_INSECURE:-false}" == "true" ]]; then
    curl_args+=(-k)
  fi

  if [[ -n "$body" ]]; then
    curl_args+=(-d "$body")
  fi

  curl "${curl_args[@]}" "$url"
}

show_summary() {
  local label="$1"
  local file="$2"
  local filter="$3"

  print_step "$label"
  jq "$filter" "$file"
}

require_cmd curl
require_cmd jq
require_env OPENCLAW_BASE_URL
require_env OPENCLAW_ADMIN_KEY

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ACCOUNT="${ACCOUNT:-default}"
BRIDGE_ID="${BRIDGE_ID:-}"
AGENT_ID="${AGENT_ID:-}"
SPEAKER="${SPEAKER:-user}"
TEXT="${TEXT:-OpenClaw smoke test $(date '+%Y-%m-%d %H:%M:%S')}"
DEBUG_SESSION_ID="${DEBUG_SESSION_ID:-smoke-$(date '+%Y%m%d-%H%M%S')}"
ALLOW_LATEST="${ALLOW_LATEST:-true}"

INVENTORY_JSON="$TMP_DIR/inventory.json"
CONNECTIONS_JSON="$TMP_DIR/connections.json"
CHAT_JSON="$TMP_DIR/chat.json"
CLEAR_JSON="$TMP_DIR/clear.json"

print_step "inventory"
inventory_status="$(api_call GET "/admin/openclaw/inventory" "" "$INVENTORY_JSON")"
echo "HTTP ${inventory_status}"
if [[ "$inventory_status" != "200" ]]; then
  cat "$INVENTORY_JSON" >&2
  exit 1
fi

show_summary "inventory summary" "$INVENTORY_JSON" '
  {
    ok: (.ok // true),
    bridgeCount: ((.data.bridges // .bridges // []) | length),
    connectedBridgeCount: ((.data.bridges // .bridges // []) | map(select(.connected == true)) | length),
    agentCount: ((.data.agents // .agents // []) | length),
    defaultAgentId: (.data.defaultAgentId // .defaultAgentId // empty),
    accountCount: ((.data.runtimeAccounts // .runtimeAccounts // .accounts // []) | length)
  }
'

if [[ -z "$BRIDGE_ID" ]]; then
  BRIDGE_ID="$(json_get "$INVENTORY_JSON" '
    (
      ((.data.bridges // .bridges // []) | map(select(.connected == true) | (.id // .bridgeId // .value // ""))) +
      ((.data.bridges // .bridges // []) | map(.id // .bridgeId // .value // ""))
    ) | map(select(length > 0)) | .[0]
  ')"
fi

if [[ -z "$AGENT_ID" ]]; then
  AGENT_ID="$(json_get "$INVENTORY_JSON" '
    (
      .data.defaultAgentId //
      .defaultAgentId //
      (
        ((.data.agents // .agents // []) | map(.id // .agentId // .value // "")) |
        map(select(length > 0)) | .[0]
      )
    )
  ')"
fi

if [[ -z "$BRIDGE_ID" ]]; then
  echo "Unable to resolve BRIDGE_ID from inventory. Set BRIDGE_ID manually." >&2
  exit 1
fi

if [[ -z "$AGENT_ID" ]]; then
  echo "Unable to resolve AGENT_ID from inventory. Set AGENT_ID manually." >&2
  exit 1
fi

print_step "connections"
connections_status="$(api_call GET "/admin/openclaw/connections" "" "$CONNECTIONS_JSON")"
echo "HTTP ${connections_status}"
if [[ "$connections_status" != "200" ]]; then
  cat "$CONNECTIONS_JSON" >&2
  exit 1
fi

show_summary "connections summary" "$CONNECTIONS_JSON" '
  {
    ok: (.ok // true),
    connectionCount: ((.data.connections // .connections // []) | length),
    latestSessionIds: ((.data.connections // .connections // []) | map(select(.isLatest == true) | .sessionId))
  }
'

CHAT_PAYLOAD="$(jq -nc \
  --arg account "$ACCOUNT" \
  --arg bridgeId "$BRIDGE_ID" \
  --arg agentId "$AGENT_ID" \
  --arg debugSessionId "$DEBUG_SESSION_ID" \
  --arg speaker "$SPEAKER" \
  --arg text "$TEXT" \
  '{
    account: $account,
    bridgeId: $bridgeId,
    agentId: $agentId,
    debugSessionId: $debugSessionId,
    speaker: $speaker,
    text: $text
  }')"

print_step "direct-chat"
chat_status="$(api_call POST "/admin/openclaw/direct-chat" "$CHAT_PAYLOAD" "$CHAT_JSON")"
echo "HTTP ${chat_status}"
if [[ "$chat_status" != "200" ]]; then
  cat "$CHAT_JSON" >&2
  exit 1
fi

show_summary "chat summary" "$CHAT_JSON" '
  {
    ok: (.ok // true),
    account: (.data.account // .account // empty),
    bridgeId: (.data.bridgeId // .bridgeId // empty),
    debugSessionId: (.data.debugSessionId // .debugSessionId // empty),
    peerId: (.data.peerId // .peerId // empty),
    agentId: (.data.result.agentId // .result.agentId // empty),
    agentName: (.data.result.agentName // .result.agentName // empty),
    replyText: (
      .data.replyText //
      .replyText //
      .data.result.replyText //
      .result.replyText //
      .data.result.text //
      .result.text //
      empty
    )
  }
'

CHAT_ACCOUNT="$(json_get "$CHAT_JSON" '.data.account // .account')"
CHAT_BRIDGE_ID="$(json_get "$CHAT_JSON" '.data.bridgeId // .bridgeId')"
CHAT_PEER_ID="$(json_get "$CHAT_JSON" '.data.peerId // .peerId')"
CHAT_SESSION_ID="$(json_get "$CHAT_JSON" '.data.sessionId // .sessionId // .data.result.sessionId // .result.sessionId')"
CHAT_DEVICE_ID="$(json_get "$CHAT_JSON" '.data.deviceId // .deviceId // .data.result.deviceId // .result.deviceId')"

CLEAR_PAYLOAD="$(jq -nc \
  --arg account "${CHAT_ACCOUNT:-$ACCOUNT}" \
  --arg bridgeId "${CHAT_BRIDGE_ID:-$BRIDGE_ID}" \
  --arg sessionId "${CHAT_SESSION_ID:-}" \
  --arg deviceId "${CHAT_DEVICE_ID:-}" \
  --arg peerId "${CHAT_PEER_ID:-}" \
  --argjson allowLatest "$([[ "$ALLOW_LATEST" == "true" ]] && echo true || echo false)" \
  '{
    account: $account,
    bridgeId: $bridgeId,
    sessionId: $sessionId,
    deviceId: $deviceId,
    peerId: $peerId,
    allowLatest: $allowLatest
  }')"

print_step "clear-session"
clear_status="$(api_call POST "/admin/openclaw/clear-session" "$CLEAR_PAYLOAD" "$CLEAR_JSON")"
echo "HTTP ${clear_status}"
if [[ "$clear_status" != "200" ]]; then
  cat "$CLEAR_JSON" >&2
  exit 1
fi

show_summary "clear summary" "$CLEAR_JSON" '
  {
    ok: (.ok // true),
    account: (.data.account // .account // empty),
    bridgeId: (.data.bridgeId // .bridgeId // empty),
    sessionId: (.data.sessionId // .sessionId // empty),
    deviceId: (.data.deviceId // .deviceId // empty),
    peerId: (.data.peerId // .peerId // empty)
  }
'

print_step "done"
cat <<EOF
Smoke test finished.
Resolved account : ${ACCOUNT}
Resolved bridgeId: ${BRIDGE_ID}
Resolved agentId : ${AGENT_ID}
Debug session    : ${DEBUG_SESSION_ID}
EOF
