#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XIAOZHI_SERVER_DIR="$ROOT_DIR/xiaozhi-esp32-server/main/xiaozhi-server"
MANAGER_API_DIR="$ROOT_DIR/xiaozhi-esp32-server/main/manager-api"
MANAGER_WEB_DIR="$ROOT_DIR/xiaozhi-esp32-server/main/manager-web"
MANAGER_MOBILE_DIR="$ROOT_DIR/xiaozhi-esp32-server/main/manager-mobile"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/dev-stack.sh help
  ./scripts/dev-stack.sh doctor
  ./scripts/dev-stack.sh quick-up
  ./scripts/dev-stack.sh quick-down
  ./scripts/dev-stack.sh db-up
  ./scripts/dev-stack.sh db-down
  ./scripts/dev-stack.sh run-api
  ./scripts/dev-stack.sh run-web
  ./scripts/dev-stack.sh run-server
  ./scripts/dev-stack.sh run-mobile-h5
  ./scripts/dev-stack.sh smoke-router
  ./scripts/dev-stack.sh smoke-direct

Commands:
  doctor         Check local prerequisites and print recommended debug mode.
  quick-up       Start the full local stack with docker compose.
  quick-down     Stop the full local stack with docker compose.
  db-up          Start only MySQL and Redis for source-mode debugging.
  db-down        Stop only MySQL and Redis used by source-mode debugging.
  run-api        Run manager-api locally via Maven.
  run-web        Run manager-web locally via npm.
  run-server     Run xiaozhi-server locally via current python3 environment.
  run-mobile-h5  Run manager-mobile H5 locally via pnpm.
  smoke-router   Run the local OpenClaw router smoke script.
  smoke-direct   Run direct OpenClaw admin API smoke script.
EOF
}

require_cmd() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Missing required command: $name" >&2
    exit 1
  fi
}

run_compose() {
  require_cmd docker
  (
    cd "$XIAOZHI_SERVER_DIR"
    docker compose -f docker-compose_all.yml "$@"
  )
}

doctor() {
  local missing=0
  local tools=(docker npm mvn python3 ffmpeg node pnpm openclaw)

  echo "Root: $ROOT_DIR"
  echo
  for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      printf "[ok]   %s -> %s\n" "$tool" "$(command -v "$tool")"
    else
      printf "[miss] %s\n" "$tool"
      missing=1
    fi
  done

  echo
  echo "Recommended modes:"
  echo "- Quick integration: docker + docker compose"
  echo "- Source debug: mvn + npm + python3 + ffmpeg + local DB/Redis"
  echo "- OpenClaw smoke: node + openclaw"

  if [[ ! -f "$XIAOZHI_SERVER_DIR/data/.config.yaml" ]]; then
    echo
    echo "Note: missing $XIAOZHI_SERVER_DIR/data/.config.yaml"
    echo "      Copy main/xiaozhi-server/config_from_api.yaml to data/.config.yaml and fill manager-api.secret."
  fi

  return "$missing"
}

quick_up() {
  run_compose up -d
}

quick_down() {
  run_compose down
}

db_up() {
  run_compose up -d xiaozhi-esp32-server-db xiaozhi-esp32-server-redis
}

db_down() {
  run_compose stop xiaozhi-esp32-server-db xiaozhi-esp32-server-redis
}

run_api() {
  require_cmd mvn
  (
    cd "$MANAGER_API_DIR"
    exec mvn spring-boot:run
  )
}

run_web() {
  require_cmd npm
  (
    cd "$MANAGER_WEB_DIR"
    npm install
    exec npm run serve
  )
}

run_server() {
  require_cmd python3
  require_cmd ffmpeg
  (
    cd "$XIAOZHI_SERVER_DIR"
    if [[ ! -f "data/.config.yaml" ]]; then
      echo "Missing data/.config.yaml in $XIAOZHI_SERVER_DIR" >&2
      echo "Copy config_from_api.yaml to data/.config.yaml and fill manager-api.secret first." >&2
      exit 1
    fi
    exec python3 app.py
  )
}

run_mobile_h5() {
  require_cmd pnpm
  (
    cd "$MANAGER_MOBILE_DIR"
    pnpm install
    exec pnpm dev:h5
  )
}

smoke_router() {
  require_cmd node
  (
    cd "$ROOT_DIR"
    exec node scripts/openclaw-xiaozhi-router-smoke.mjs
  )
}

smoke_direct() {
  require_cmd bash
  (
    cd "$ROOT_DIR"
    exec bash scripts/openclaw-direct-smoke.sh
  )
}

main() {
  local cmd="${1:-help}"
  case "$cmd" in
    help|-h|--help)
      usage
      ;;
    doctor)
      doctor
      ;;
    quick-up)
      quick_up
      ;;
    quick-down)
      quick_down
      ;;
    db-up)
      db_up
      ;;
    db-down)
      db_down
      ;;
    run-api)
      run_api
      ;;
    run-web)
      run_web
      ;;
    run-server)
      run_server
      ;;
    run-mobile-h5)
      run_mobile_h5
      ;;
    smoke-router)
      smoke_router
      ;;
    smoke-direct)
      smoke_direct
      ;;
    *)
      echo "Unknown command: $cmd" >&2
      echo >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
