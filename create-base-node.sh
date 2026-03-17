#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

if [[ -t 1 ]]; then
  C_RESET='\033[0m'; C_BOLD='\033[1m'; C_DIM='\033[2m'; C_BLUE='\033[34m'; C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_RED='\033[31m'; C_CYAN='\033[36m'
else
  C_RESET=''; C_BOLD=''; C_DIM=''; C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_CYAN=''
fi
info() { printf "%b\n" "${C_BLUE}[INFO]${C_RESET} $1"; }
ok() { printf "%b\n" "${C_GREEN}[OK]${C_RESET} $1"; }
fail() { printf "%b\n" "${C_RED}[ERROR]${C_RESET} $1"; exit 1; }

[[ -f .env ]] || fail "Falta .env"
source ./load-env.sh .env

SHOW_CONFIG="false"
[[ "${1:-}" == "--show-config" ]] && SHOW_CONFIG="true"

[[ -n "$(docker compose --env-file .env -f docker-compose.yml ps -q panel 2>/dev/null)" ]] || fail "El servicio panel no está corriendo"

if [[ "$SHOW_CONFIG" == "false" ]]; then
  info "Creando location base..."
  docker compose --env-file .env -f docker-compose.yml exec -T panel php artisan p:location:make \
    --short="$NODE_LOCATION_SHORT" \
    --long="$NODE_LOCATION_LONG" \
    --no-interaction || true

  info "Creando node base..."
  docker compose --env-file .env -f docker-compose.yml exec -T panel php artisan p:node:make \
    --name="$NODE_NAME" \
    --description="$NODE_DESCRIPTION" \
    --locationId=1 \
    --fqdn="$PANEL_HOST" \
    --public=1 \
    --scheme=http \
    --proxy=0 \
    --maintenance=0 \
    --maxMemory="$NODE_MEMORY_MB" \
    --overallocateMemory=0 \
    --maxDisk="$NODE_DISK_MB" \
    --overallocateDisk=0 \
    --uploadSize="$NODE_UPLOAD_MB" \
    --daemonListeningPort="$WINGS_API_PORT" \
    --daemonSFTPPort="$WINGS_SFTP_PORT" \
    --daemonBase="$NODE_DAEMON_BASE" \
    --no-interaction || true

  ok "Location y node base creados (o ya existentes)."
  printf "%b\n" "${C_DIM}Si quieres la config YAML, usa: ./create-base-node.sh --show-config > etc/config.yml${C_RESET}"
  exit 0
fi

docker compose --env-file .env -f docker-compose.yml exec -T panel php artisan p:node:configuration 1 --format=yaml
