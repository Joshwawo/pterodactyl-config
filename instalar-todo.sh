#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

if [[ -t 1 ]]; then
  C_RESET='\033[0m'
  C_BOLD='\033[1m'
  C_DIM='\033[2m'
  C_BLUE='\033[34m'
  C_GREEN='\033[32m'
  C_YELLOW='\033[33m'
  C_RED='\033[31m'
  C_CYAN='\033[36m'
else
  C_RESET=''
  C_BOLD=''
  C_DIM=''
  C_BLUE=''
  C_GREEN=''
  C_YELLOW=''
  C_RED=''
  C_CYAN=''
fi

STEP=0
TOTAL_STEPS=7

line() { printf "%b\n" "${C_DIM}============================================================${C_RESET}"; }
header() {
  line
  printf "%b\n" "${C_BOLD}${C_CYAN}Pterodactyl Installer${C_RESET} ${C_DIM}(bash puro)${C_RESET}"
  printf "%b\n" "${C_DIM}Panel + Wings + MariaDB + Redis en una sola VPS${C_RESET}"
  line
}
section() {
  local title="$1"
  STEP=$((STEP + 1))
  printf "\n%b\n" "${C_BOLD}${C_BLUE}[${STEP}/${TOTAL_STEPS}] ${title}${C_RESET}"
}
info() { printf "%b\n" "${C_BLUE}[INFO]${C_RESET} $1"; }
ok() { printf "%b\n" "${C_GREEN}[OK]${C_RESET} $1"; }
warn() { printf "%b\n" "${C_YELLOW}[AVISO]${C_RESET} $1"; }
fail() { printf "%b\n" "${C_RED}[ERROR]${C_RESET} $1"; exit 1; }

show_plan() {
  printf "%b\n" "${C_BOLD}Este script puede ayudarte a:${C_RESET}"
  printf "  ${C_CYAN}1)${C_RESET} Crear .env\n"
  printf "  ${C_CYAN}2)${C_RESET} Levantar panel + wings\n"
  printf "  ${C_CYAN}3)${C_RESET} Crear el admin\n"
  printf "  ${C_CYAN}4)${C_RESET} Crear location + node base\n"
  printf "  ${C_CYAN}5)${C_RESET} Generar etc/config.yml\n"
  printf "  ${C_CYAN}6)${C_RESET} Reiniciar Wings\n"
  printf "  ${C_CYAN}7)${C_RESET} Hacer un chequeo final\n"
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

check_prerequisites() {
  local missing=0
  if ! command_exists docker; then
    warn "Docker no está instalado. Este instalador lo necesita, pero no lo instala por ti."
    missing=1
  fi
  if ! docker compose version >/dev/null 2>&1; then
    warn "Docker Compose plugin no está disponible. Este instalador lo necesita, pero no lo instala por ti."
    missing=1
  fi
  if (( missing )); then
    fail "Instala Docker + Docker Compose plugin antes de continuar."
  fi
  if ! docker info >/dev/null 2>&1; then
    fail "Docker parece no estar corriendo o este usuario no puede usarlo."
  fi
}

detect_public_ip() {
  local ip=""
  ip="$(curl -4 -fsS --max-time 5 https://icanhazip.com 2>/dev/null | tr -d '[:space:]' || true)"
  if [[ -z "$ip" ]]; then
    ip="$(curl -4 -fsS --max-time 5 https://api.ipify.org 2>/dev/null | tr -d '[:space:]' || true)"
  fi
  if [[ -z "$ip" ]]; then
    ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
  fi
  printf "%s" "$ip"
}

generate_password() {
  python3 - <<'PY'
import secrets, string
alphabet = string.ascii_letters + string.digits
print(''.join(secrets.choice(alphabet) for _ in range(24)))
PY
}

ask() {
  local prompt="$1"
  local default="${2:-}"
  local value
  if [[ -n "$default" ]]; then
    read -r -p "$prompt [$default]: " value
    echo "${value:-$default}"
  else
    read -r -p "$prompt: " value
    echo "$value"
  fi
}

ask_nonempty() {
  local prompt="$1"
  local default="${2:-}"
  local value
  while true; do
    value="$(ask "$prompt" "$default")"
    if [[ -n "${value// /}" ]]; then
      printf "%s" "$value"
      return 0
    fi
    warn "Este valor no puede quedar vacío."
  done
}

ask_secret_with_default() {
  local prompt="$1"
  local generated="$2"
  local value
  printf "%b\n" "${C_DIM}Se generó una contraseña segura por defecto.${C_RESET}" > /dev/tty
  printf "%b\n" "${C_DIM}Pulsa Enter para usarla, o escribe una manual.${C_RESET}" > /dev/tty
  while true; do
    IFS= read -r -s -p "$prompt [$generated]: " value </dev/tty
    printf "\n" > /dev/tty
    value="${value:-$generated}"
    if [[ -n "$value" ]]; then
      printf "%s" "$value"
      return 0
    fi
    warn "La contraseña no puede quedar vacía."
  done
}

is_valid_email() {
  local email="$1"
  [[ "$email" == *@*.* ]] || return 1
  [[ "$email" != @* ]] || return 1
  [[ "$email" != *" "* ]] || return 1
}

is_valid_ipv4() {
  local ip="$1"
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  IFS='.' read -r o1 o2 o3 o4 <<< "$ip"
  for o in "$o1" "$o2" "$o3" "$o4"; do
    [[ "$o" =~ ^[0-9]+$ ]] || return 1
    (( o >= 0 && o <= 255 )) || return 1
  done
}

is_valid_hostname() {
  local host="$1"
  [[ "$host" != *" "* ]] || return 1
  [[ "$host" =~ ^[A-Za-z0-9.-]+$ ]] || return 1
  [[ "$host" == *.* ]]
}

is_valid_url() {
  local url="$1"
  [[ "$url" == http://* || "$url" == https://* ]] || return 1
  [[ "$url" != *" "* ]]
}

ask_email() {
  local prompt="$1"
  local default="${2:-}"
  local value
  while true; do
    value="$(ask_nonempty "$prompt" "$default")"
    if is_valid_email "$value"; then
      printf "%s" "$value"
      return 0
    fi
    warn "Introduce un correo válido, por ejemplo admin@example.com"
  done
}

ask_ipv4() {
  local prompt="$1"
  local default="${2:-}"
  local value
  while true; do
    value="$(ask_nonempty "$prompt" "$default")"
    if is_valid_ipv4 "$value"; then
      printf "%s" "$value"
      return 0
    fi
    warn "Introduce una IPv4 válida, por ejemplo 203.0.113.10"
  done
}

ask_hostname() {
  local prompt="$1"
  local default="${2:-}"
  local value
  while true; do
    value="$(ask_nonempty "$prompt" "$default")"
    if is_valid_hostname "$value"; then
      printf "%s" "$value"
      return 0
    fi
    warn "Introduce un hostname válido, por ejemplo panel.example.com o 203.0.113.10.sslip.io"
  done
}

ask_url() {
  local prompt="$1"
  local default="${2:-}"
  local value
  while true; do
    value="$(ask_nonempty "$prompt" "$default")"
    if is_valid_url "$value"; then
      printf "%s" "$value"
      return 0
    fi
    warn "Introduce una URL válida que empiece por http:// o https://"
  done
}

port_in_use() {
  local port="$1"
  ss -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)$port$"
}

warn_if_port_busy() {
  local port="$1"
  local label="$2"
  if port_in_use "$port"; then
    warn "El puerto $port parece estar en uso antes de instalar ($label). Si algo falla, revisa qué servicio lo ocupa."
  fi
}

yesno() {
  local prompt="$1"
  local default="${2:-y}"
  local value
  local shown="s/N"
  [[ "$default" == "y" ]] && shown="S/n"
  while true; do
    read -r -p "$prompt [$shown]: " value
    value="${value:-$default}"
    case "$value" in
      s|S|y|Y) return 0 ;;
      n|N) return 1 ;;
      *) warn "Respuesta no válida. Escribe s o n." ;;
    esac
  done
}

header
show_plan
check_prerequisites

section "Configuración inicial"
if [[ ! -f .env ]]; then
  info "No existe .env. Voy a crearlo desde .env.example."
  cp .env.example .env

  DETECTED_PUBLIC_IP="$(detect_public_ip)"
  if [[ -n "$DETECTED_PUBLIC_IP" ]]; then
    info "Detecté esta IP pública por defecto: ${DETECTED_PUBLIC_IP}"
  else
    warn "No pude detectar automáticamente la IP pública. Tendrás que escribirla tú."
  fi

  PUBLIC_IP=$(ask_ipv4 "IP pública de la VPS" "$DETECTED_PUBLIC_IP")
  PANEL_HOST=$(ask_hostname "Hostname del panel (si no tienes dominio, usa sslip.io)" "${PUBLIC_IP}.sslip.io")
  APP_URL=$(ask_url "URL pública del panel" "http://${PANEL_HOST}")
  APP_TIMEZONE=$(ask_nonempty "Zona horaria" "UTC")
  PANEL_EMAIL=$(ask_email "Email informativo del panel" "admin@${PANEL_HOST}")

  warn_if_port_busy 80 "panel web"
  warn_if_port_busy 8080 "Wings API"
  warn_if_port_busy 2022 "Wings SFTP"

  printf "\n%b\n" "${C_BOLD}Base de datos:${C_RESET}"
  GENERATED_DB_PASSWORD="$(generate_password)"
  GENERATED_DB_ROOT_PASSWORD="$(generate_password)"
  DB_PASSWORD=$(ask_secret_with_default "Password de la base de datos" "$GENERATED_DB_PASSWORD")
  DB_ROOT_PASSWORD=$(ask_secret_with_default "Password root de MariaDB" "$GENERATED_DB_ROOT_PASSWORD")

  printf "\n%b\n" "${C_BOLD}Admin inicial:${C_RESET}"
  ADMIN_EMAIL=$(ask_email "Email del admin inicial" "admin@example.com")
  ADMIN_USERNAME=$(ask_nonempty "Usuario del admin inicial" "admin")
  ADMIN_FIRST_NAME=$(ask_nonempty "Nombre del admin" "Admin")
  ADMIN_LAST_NAME=$(ask_nonempty "Apellido del admin" "User")
  GENERATED_ADMIN_PASSWORD="$(generate_password)"
  ADMIN_PASSWORD=$(ask_secret_with_default "Password del admin inicial" "$GENERATED_ADMIN_PASSWORD")

  python3 - <<PY
from pathlib import Path
import re, shlex
path = Path('.env')
text = path.read_text()
replacements = {
  'PUBLIC_IP': '''${PUBLIC_IP}''',
  'PANEL_HOST': '''${PANEL_HOST}''',
  'APP_URL': '''${APP_URL}''',
  'APP_TIMEZONE': '''${APP_TIMEZONE}''',
  'PANEL_EMAIL': '''${PANEL_EMAIL}''',
  'DB_PASSWORD': '''${DB_PASSWORD}''',
  'DB_ROOT_PASSWORD': '''${DB_ROOT_PASSWORD}''',
  'ADMIN_EMAIL': '''${ADMIN_EMAIL}''',
  'ADMIN_USERNAME': '''${ADMIN_USERNAME}''',
  'ADMIN_FIRST_NAME': '''${ADMIN_FIRST_NAME}''',
  'ADMIN_LAST_NAME': '''${ADMIN_LAST_NAME}''',
  'ADMIN_PASSWORD': '''${ADMIN_PASSWORD}''',
}
for key, value in replacements.items():
    text = re.sub(rf'^{key}=.*$', f'{key}=' + shlex.quote(value), text, flags=re.M)
path.write_text(text)
PY

  ok ".env creado correctamente."
else
  info "Ya existe .env. Lo voy a reutilizar."
fi

source ./load-env.sh .env
mkdir -p etc

section "Levantar stack"
if yesno "¿Quieres que el script levante el stack ahora? Si dices no, luego puedes hacerlo manual con ./bootstrap.sh" y; then
  ./bootstrap.sh
else
  warn "Saltado. Luego puedes correr: ./bootstrap.sh"
fi

section "Crear admin"
if yesno "¿Quieres que el script cree el admin inicial ahora? Si dices no, luego puedes hacerlo manual con ./create-admin.sh" y; then
  ./create-admin.sh
else
  warn "Saltado. Luego puedes correr: ./create-admin.sh"
fi

section "Crear location y node base"
if yesno "¿Quieres que el script cree location + node base ahora? Si dices no, luego puedes hacerlo manual con ./create-base-node.sh" y; then
  ./create-base-node.sh
else
  warn "Saltado. Luego puedes correr: ./create-base-node.sh"
fi

section "Generar config.yml de Wings"
if yesno "¿Quieres que el script genere y guarde ahora etc/config.yml? Si dices no, luego puedes hacerlo manual con ./create-base-node.sh --show-config > etc/config.yml" y; then
  ./create-base-node.sh --show-config > etc/config.yml
  ok "Guardado en etc/config.yml"
else
  warn "Saltado. Luego puedes generar la config manualmente."
fi

section "Reiniciar Wings"
if yesno "¿Quieres que el script reinicie Wings ahora? Si dices no, luego puedes hacerlo manual con docker compose --env-file .env -f docker-compose.yml restart wings" y; then
  docker compose --env-file .env -f docker-compose.yml restart wings
  ok "Wings reiniciado."
else
  warn "Saltado. Luego puedes reiniciar Wings manualmente."
fi

section "Chequeo final"
if yesno "¿Quieres que el script haga el chequeo final ahora? Si dices no, luego puedes hacerlo manual con ./post-install-check.sh" y; then
  ./post-install-check.sh
else
  warn "Saltado. Luego puedes correr: ./post-install-check.sh"
fi

printf "\n"
header
printf "%b\n" "${C_BOLD}${C_GREEN}Instalación guiada terminada${C_RESET}"
printf "%b\n" "${C_BOLD}Panel:${C_RESET} ${APP_URL}"
printf "%b\n" "${C_BOLD}Admin:${C_RESET} ${ADMIN_USERNAME}"
printf "\n%b\n" "${C_BOLD}Siguientes pasos dentro del panel:${C_RESET}"
printf "  ${C_CYAN}1)${C_RESET} Entrar al panel\n"
printf "  ${C_CYAN}2)${C_RESET} Crear allocations (ejemplo: ${PUBLIC_IP}:25565)\n"
printf "  ${C_CYAN}3)${C_RESET} Crear servidores de juego\n"
printf "  ${C_CYAN}4)${C_RESET} Arrancarlos\n"
printf "\n%b\n" "${C_DIM}Si te pierdes, mira INSTALACION_RAPIDA.md o INSTALACION_PASO_A_PASO.md${C_RESET}"
