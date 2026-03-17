# Instalación rápida de Pterodactyl

## La forma más fácil

```bash
chmod +x *.sh
./instalar-todo.sh
```

Ese script te guía para:
- crear `.env`
- cargar `.env` sin romperse por espacios en valores
- levantar el stack
- crear el admin
- crear el node base
- generar `etc/config.yml`
- reiniciar Wings
- hacer un chequeo final

---

## Antes de empezar

Este proyecto **necesita**:
- Docker
- Docker Compose plugin

El instalador lo comprueba y te avisa si falta algo, pero **no lo instala por ti**.

Si quieres borrar una instalación anterior y empezar de cero:

```bash
./reset-install.sh
```

## Si quieres hacerlo manualmente

### 1) Prepara variables

```bash
cp .env.example .env
nano .env
```

Cambia mínimo:
- `PUBLIC_IP`
- `PANEL_HOST`
- `APP_URL`
- `DB_PASSWORD`
- `DB_ROOT_PASSWORD`
- `ADMIN_EMAIL`
- `ADMIN_USERNAME`
- `ADMIN_PASSWORD`

Si no tienes dominio, usa:
- `PANEL_HOST=<TU_IP>.sslip.io`
- `APP_URL=http://<TU_IP>.sslip.io`

### 2) Da permisos

```bash
chmod +x *.sh
```

### 3) Levanta el stack

```bash
./bootstrap.sh
```

### 4) Crea el admin

```bash
./create-admin.sh
```

### 5) Crea el node base

```bash
./create-base-node.sh
```

### 6) Genera la config de Wings

```bash
./create-base-node.sh --show-config > etc/config.yml
```

Luego reinicia Wings:

```bash
docker compose --env-file .env -f docker-compose.yml restart wings
```

### 7) Revisión final

```bash
./post-install-check.sh
```

### 8) Entra al panel

Abre:

```text
http://TU_IP.sslip.io
```

Y luego:
- crea allocations
- crea servers
- arráncalos
