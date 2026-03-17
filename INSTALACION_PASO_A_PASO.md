# Pterodactyl con Docker Compose — guía paso a paso

> Si quieres la versión más fácil, usa primero `./instalar-todo.sh`.

## Qué instala esta plantilla

- Pterodactyl Panel
- Wings
- MariaDB
- Redis
- todo en una sola VPS

## Requisitos recomendados

- Ubuntu 24.04
- 4 GB RAM mínimo para pruebas
- Docker y Docker Compose plugin
- puertos abiertos:
  - `80/tcp`
  - `8080/tcp`
  - `2022/tcp`
  - los puertos de tus juegos

## Conceptos rápidos

- **Panel**: la web de administración
- **Wings**: el servicio que crea y controla los servidores de juego
- **MariaDB**: base de datos del panel
- **Redis**: caché/colas del panel

## Pasos resumidos

1. Copia el proyecto a la VPS
2. Crea `.env` desde `.env.example`
3. Ejecuta `./bootstrap.sh`
4. Ejecuta `./create-admin.sh`
5. Ejecuta `./create-base-node.sh`
6. Ejecuta `./create-base-node.sh --show-config > etc/config.yml`
7. Reinicia Wings
8. Ejecuta `./post-install-check.sh`
9. Entra al panel
10. Crea allocations y servers

## Hostname temporal sin dominio

Si no tienes dominio real, usa `sslip.io`.

Ejemplo:
- IP: `203.0.113.10`
- hostname: `203.0.113.10.sslip.io`
- URL del panel: `http://203.0.113.10.sslip.io`

## Reset de instalación

Si quieres borrar una instalación anterior y empezar desde cero:

```bash
./reset-install.sh
```

## Comandos útiles

Levantar:
```bash
docker compose --env-file .env -f docker-compose.yml up -d --build
```

Ver estado:
```bash
docker compose --env-file .env -f docker-compose.yml ps
```

Logs del panel:
```bash
docker logs -f pterodactyl-panel-1
```

Logs de Wings:
```bash
docker logs -f pterodactyl-wings-1
```

## Después de instalar

En el panel tendrás que:
- crear allocations
- crear servers
- arrancarlos

Ejemplo de allocation para Minecraft Java:
- IP: tu IP pública
- Puerto: `25565`
- Alias: `Minecraft`
