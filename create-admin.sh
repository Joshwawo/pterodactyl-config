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

[[ -n "$(docker compose --env-file .env -f docker-compose.yml ps -q panel 2>/dev/null)" ]] || fail "El servicio panel no está corriendo"

info "Creando admin inicial..."
docker compose --env-file .env -f docker-compose.yml exec -T panel php artisan p:user:make \
  --email="$ADMIN_EMAIL" \
  --username="$ADMIN_USERNAME" \
  --name-first="$ADMIN_FIRST_NAME" \
  --name-last="$ADMIN_LAST_NAME" \
  --password="$ADMIN_PASSWORD" \
  --admin=1 \
  --no-interaction

ok "Admin creado"
printf "%b\n" "${C_BOLD}Usuario:${C_RESET} $ADMIN_USERNAME"
printf "%b\n" "${C_BOLD}Email:${C_RESET} $ADMIN_EMAIL"
printf "%b\n" "${C_BOLD}Password:${C_RESET} $ADMIN_PASSWORD"
