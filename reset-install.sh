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
  printf "%b\n" "${C_BOLD}${C_CYAN}Reset de instalación${C_RESET} ${C_DIM}(Pterodactyl)${C_RESET}"
  line
}
info() { printf "%b\n" "${C_BLUE}[INFO]${C_RESET} $1"; }
ok() { printf "%b\n" "${C_GREEN}[OK]${C_RESET} $1"; }
warn() { printf "%b\n" "${C_YELLOW}[AVISO]${C_RESET} $1"; }

header
info "Parando y eliminando contenedores/volúmenes del proyecto..."
(docker compose down -v || true)

info "Eliminando symlinks globales usados por Pterodactyl..."
rm -rf /var/lib/pterodactyl /tmp/pterodactyl

info "Limpiando archivos generados por la instalación..."
rm -f .env
rm -rf database redis var var-lib var-log logs certs nginx tmp
rm -f etc/config.yml
mkdir -p etc

printf "\n"
ok "Instalación limpiada."
warn "Quedó solo la plantilla lista para reinstalar."
printf "\n%b\n" "${C_BOLD}Siguiente paso:${C_RESET}"
printf "  ${C_CYAN}1)${C_RESET} chmod +x *.sh\n"
printf "  ${C_CYAN}2)${C_RESET} ./instalar-todo.sh\n"
