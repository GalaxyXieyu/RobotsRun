#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBECONFIG_PATH="${KUBECONFIG_PATH:-kubeconfig.yaml}"
NAMESPACE="${NAMESPACE:-ns-lmgpb9nc}"

cd "$ROOT_DIR"

kubectl --kubeconfig "$KUBECONFIG_PATH" create configmap xiaozhi-server-hotfix \
  -n "$NAMESPACE" \
  --from-file=app.py=xiaozhi-esp32-server/main/xiaozhi-server/app.py \
  --from-file=config_loader.py=xiaozhi-esp32-server/main/xiaozhi-server/config/config_loader.py \
  --from-file=http_server.py=xiaozhi-esp32-server/main/xiaozhi-server/core/http_server.py \
  --from-file=websocket_server.py=xiaozhi-esp32-server/main/xiaozhi-server/core/websocket_server.py \
  --from-file=connection.py=xiaozhi-esp32-server/main/xiaozhi-server/core/connection.py \
  --from-file=abortHandle.py=xiaozhi-esp32-server/main/xiaozhi-server/core/handle/abortHandle.py \
  --from-file=intentHandler.py=xiaozhi-esp32-server/main/xiaozhi-server/core/handle/intentHandler.py \
  --from-file=reportHandle.py=xiaozhi-esp32-server/main/xiaozhi-server/core/handle/reportHandle.py \
  --from-file=receiveAudioHandle.py=xiaozhi-esp32-server/main/xiaozhi-server/core/handle/receiveAudioHandle.py \
  --from-file=plugin_executor.py=xiaozhi-esp32-server/main/xiaozhi-server/core/providers/tools/server_plugins/plugin_executor.py \
  --from-file=openclaw___init__.py=xiaozhi-esp32-server/main/xiaozhi-server/core/openclaw/__init__.py \
  --from-file=active_connections.py=xiaozhi-esp32-server/main/xiaozhi-server/core/openclaw/active_connections.py \
  --from-file=bridge_client.py=xiaozhi-esp32-server/main/xiaozhi-server/core/openclaw/bridge_client.py \
  --from-file=bridge_store.py=xiaozhi-esp32-server/main/xiaozhi-server/core/openclaw/bridge_store.py \
  --from-file=bridge_hub.py=xiaozhi-esp32-server/main/xiaozhi-server/core/openclaw/bridge_hub.py \
  --from-file=hub_session.py=xiaozhi-esp32-server/main/xiaozhi-server/core/openclaw/hub_session.py \
  --from-file=spoken_text.py=xiaozhi-esp32-server/main/xiaozhi-server/core/openclaw/spoken_text.py \
  --from-file=openclaw_admin_handler.py=xiaozhi-esp32-server/main/xiaozhi-server/core/api/openclaw_admin_handler.py \
  --from-file=openclaw_bind_peer_agent.py=xiaozhi-esp32-server/main/xiaozhi-server/plugins_func/functions/openclaw_bind_peer_agent.py \
  --dry-run=client -o yaml | kubectl --kubeconfig "$KUBECONFIG_PATH" apply --validate=false -f -

kubectl --kubeconfig "$KUBECONFIG_PATH" apply --validate=false -f deploy/xiaozhi-sealos.yaml

kubectl --kubeconfig "$KUBECONFIG_PATH" rollout restart deployment/xiaozhi-server -n "$NAMESPACE"
kubectl --kubeconfig "$KUBECONFIG_PATH" rollout restart deployment/esp32-server -n "$NAMESPACE"

kubectl --kubeconfig "$KUBECONFIG_PATH" rollout status deployment/xiaozhi-server -n "$NAMESPACE" --timeout=180s
kubectl --kubeconfig "$KUBECONFIG_PATH" rollout status deployment/esp32-server -n "$NAMESPACE" --timeout=180s
