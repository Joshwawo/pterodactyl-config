#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

if [[ -t 1 ]]; then
  C_RESET='\033[0m'; C_BOLD='\033[1m'; C_DIM='\033[2m'; C_BLUE='\033[34m'; C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_RED='\033[31m'; C_CYAN='\033[36m'
else
  C_RESET=''; C_BOLD=''; C_DIM=''; C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_CYAN=''
fi
section() { printf "\n%b\n" "${C_BOLD}${C_BLUE}$1${C_RESET}"; }
ok() { printf "%b\n" "${C_GREEN}[OK]${C_RESET} $1"; }
fail() { printf "%b\n" "${C_RED}[ERROR]${C_RESET} $1"; exit 1; }

[[ -f .env ]] || fail "Falta .env"
source ./load-env.sh .env

section "Contenedores"
docker compose --env-file .env -f docker-compose.yml ps || true

section "URL pública del panel"
printf "%s\n" "$APP_URL"

section "Symlinks del host"
ls -ld /var/lib/pterodactyl || true
ls -ld /tmp/pterodactyl || true

section "Prueba panel web"
curl -I -sS --max-time 10 "$APP_URL" | head -n 5 || true

section "Prueba Wings API"
curl -I -sS --max-time 10 "http://${PUBLIC_IP}:${WINGS_API_PORT}/" | head -n 8 || true

section "Últimas líneas de Wings"
WINGS_CID="$(docker compose --env-file .env -f docker-compose.yml ps -q wings 2>/dev/null || true)"
[[ -n "$WINGS_CID" ]] && docker logs --tail 30 "$WINGS_CID" || true

section "Últimas líneas del panel"
PANEL_CID="$(docker compose --env-file .env -f docker-compose.yml ps -q panel 2>/dev/null || true)"
[[ -n "$PANEL_CID" ]] && docker logs --tail 30 "$PANEL_CID" || true

printf "\n"
ok "Revisión terminada"
