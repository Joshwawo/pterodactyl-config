# Pterodactyl Docker Compose Template

Plantilla portable para instalar **Pterodactyl Panel + Wings + MariaDB + Redis** en una sola VPS usando Docker Compose.

## Niveles de uso

### 1. Recomendado: instalador guiado
```bash
chmod +x *.sh
./instalar-todo.sh
```

### 2. Manual corto
Lee `INSTALACION_RAPIDA.md`

### 3. Manual detallado
Lee `INSTALACION_PASO_A_PASO.md`

## Archivos principales

- `instalar-todo.sh` — instalador guiado principal
- `reset-install.sh` — limpia la instalación para reinstalar desde cero
- `docker-compose.yml` — stack portable
- `.env.example` — variables de ejemplo para modo manual
- `bootstrap.sh` — prepara symlinks y levanta el stack
- `create-admin.sh` — crea el admin inicial
- `create-base-node.sh` — crea location/node base y muestra config de Wings
- `post-install-check.sh` — chequeo rápido
- `load-env.sh` — carga `.env` de forma segura, incluso si hay espacios en valores
- `Dockerfile.panel` — parche para la imagen del panel
- `INSTALACION_RAPIDA.md`
- `INSTALACION_PASO_A_PASO.md`

## Qué no se sube

Este repo está pensado como plantilla. No debe incluir:

- `.env`
- bases de datos vivas
- volúmenes de servers
- logs
- `etc/config.yml` generado para una instalación real

## Uso rápido

```bash
cp .env.example .env
nano .env
chmod +x *.sh
./instalar-todo.sh
```

## Requisitos

- Ubuntu 24.04 recomendado
- Docker
- Docker Compose plugin
- puertos abiertos: `80`, `8080`, `2022` y los de tus juegos

> Nota: el instalador valida que Docker y Docker Compose existan y avisa si faltan, pero **no los instala por ti**.

## Nota

Si no tienes dominio, puedes usar un hostname temporal con `sslip.io`, por ejemplo:

- IP: `203.0.113.10`
- hostname: `203.0.113.10.sslip.io`
