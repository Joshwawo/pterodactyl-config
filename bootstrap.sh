#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

if [[ -t 1 ]]; then
  C_RESET='\033[0m'; C_BOLD='\033[1m'; C_DIM='\033[2m'; C_BLUE='\033[34m'; C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_RED='\033[31m'; C_CYAN='\033[36m'
else
  C_RESET=''; C_BOLD=''; C_DIM=''; C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_CYAN=''
fi

line() { printf "%b\n" "${C_DIM}============================================================${C_RESET}"; }
header() {
  line
  printf "%b\n" "${C_BOLD}${C_CYAN}Bootstrap del stack${C_RESET} ${C_DIM}(Panel + Wings)${C_RESET}"
  line
}
info() { printf "%b\n" "${C_BLUE}[INFO]${C_RESET} $1"; }
ok() { printf "%b\n" "${C_GREEN}[OK]${C_RESET} $1"; }
fail() { printf "%b\n" "${C_RED}[ERROR]${C_RESET} $1"; exit 1; }

if [[ ! -f .env ]]; then
  fail "Falta .env. Copia primero .env.example a .env y edítalo."
fi

source ./load-env.sh .env

require_cmd() { command -v "$1" >/dev/null 2>&1 || fail "Falta el comando: $1"; }
require_cmd docker

header
info "Preparando carpetas necesarias..."
mkdir -p database redis var nginx certs logs etc var-lib var-log tmp /run/wings
chmod 755 /run/wings

info "Creando symlinks globales requeridos por Wings..."
rm -rf /var/lib/pterodactyl
ln -s "$PROJECT_DIR/var-lib" /var/lib/pterodactyl
rm -rf /tmp/pterodactyl
ln -s "$PROJECT_DIR/tmp" /tmp/pterodactyl

info "Ajustando permisos básicos..."
chown -R "${WINGS_UID}:${WINGS_GID}" "$PROJECT_DIR/var-lib" "$PROJECT_DIR/tmp" || true

info "Levantando stack con Docker Compose..."
docker compose --env-file .env -f docker-compose.yml up -d --build

printf "\n"
ok "Stack levantado."
printf "%b\n" "${C_BOLD}Panel:${C_RESET} ${APP_URL}"
printf "%b\n" "${C_BOLD}Wings API:${C_RESET} http://${PUBLIC_IP}:${WINGS_API_PORT}"
printf "%b\n" "${C_BOLD}Wings SFTP:${C_RESET} ${PUBLIC_IP}:${WINGS_SFTP_PORT}"

printf "\n%b\n" "${C_BOLD}Si luego quieres seguir manualmente:${C_RESET}"
printf "  ${C_CYAN}1)${C_RESET} ./create-admin.sh\n"
printf "  ${C_CYAN}2)${C_RESET} ./create-base-node.sh\n"
printf "  ${C_CYAN}3)${C_RESET} ./create-base-node.sh --show-config > etc/config.yml\n"
printf "  ${C_CYAN}4)${C_RESET} docker compose --env-file .env -f docker-compose.yml restart wings\n"
