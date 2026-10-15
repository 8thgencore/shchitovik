# Деплой на VPS

Web-версия и каталог цен — один Docker-образ (`deploy/docker/Dockerfile`), который compose
запускает на VPS за общим Caddy хоста. Выкладка — Actions → Release → `deploy-web`. Вариант без
Docker (файлы в `/var/www`, nginx или Caddy) — в конце.

## Образ

Стадии: Flutter Web (SDK ставится по версии из `.fvmrc`, публичные образы Flutter отстают),
каталог цен (`tools/catalog`), итог на `scratch` — static-web-server, busybox для healthcheck и
файлы сайта, ~35 МБ. Сервер отдаёт заголовки COOP/COEP, CORS каталога и `no-cache`; работает от
`nobody` на порту 8080. Каталог входит в образ: новые цены — новый деплой.

CanvasKit release-сборка грузит с CDN `gstatic.com`, поэтому локальная копия из образа удалена.

## Настройка сервера (один раз)

```bash
# Docker с плагином compose: https://docs.docker.com/engine/install/
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy           # группа docker равносильна root: ключ только для CI
# A-запись shchitovik.ru → VPS
```

Открытый SSH-ключ для CI — в `~deploy/.ssh/authorized_keys`.

В общий `/etc/caddy/Caddyfile` хоста добавьте блок из `deploy/caddy/Caddyfile.compose`:

```bash
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

## Выкладка из GitHub Actions

Release → `deploy-web` собирает образ (кеш слоёв в GitHub Actions), передаёт его по SSH
(`docker save | docker load`, без registry), копирует `deploy/compose/prod.yaml` в
`~deploy/shchitovik/` и выполняет `docker compose up -d --wait`.

Settings → Secrets and variables → Actions:

| Тип | Имя | Значение |
|---|---|---|
| Secret | `DEPLOY_SSH_KEY` | закрытый ключ |
| Secret | `DEPLOY_KNOWN_HOSTS` | вывод `ssh-keyscan <адрес VPS>` |
| Variable | `DEPLOY_HOST`, `DEPLOY_USER` | адрес VPS, `deploy` |
| Variable | `APP_BASE_URL` | `https://shchitovik.ru` |

## Вручную

```bash
cd deploy/compose
APP_BASE_URL=https://shchitovik.ru docker compose -f prod.yaml build
docker save shchitovik-web:latest | gzip | ssh deploy@<VPS> 'gunzip | docker load'
scp prod.yaml deploy@<VPS>:shchitovik/prod.yaml
ssh deploy@<VPS> 'docker compose -f ~/shchitovik/prod.yaml up -d --no-build --pull never --wait'
```

Переменные compose: `APP_BASE_URL` (адрес сайта, вшивается при сборке), `SHCHITOVIK_WEB_IMAGE`
(имя образа), `WEB_HTTP_HOST_PORT` (порт на loopback, по умолчанию 8082).

## Проверка

```bash
curl -I https://shchitovik.ru/sqlite3.wasm            # Content-Type: application/wasm
curl -I https://shchitovik.ru/                        # Cross-Origin-Opener/Embedder-Policy
curl https://shchitovik.ru/catalog/manifest.json      # актуальная catalog_version
```

## Без Docker

nginx (`deploy/nginx/shchitovik.conf`, сертификат через certbot) или Caddy
(`deploy/caddy/Caddyfile`) раздаёт `/var/www/shchitovik/{web,catalog}`; заголовки те же. Файлы
выкладывают задачи `deploy_web` и `deploy_catalog` в GitLab CI (rsync от пользователя `deploy`,
владельца `/var/www/shchitovik`).

```bash
sudo cp deploy/nginx/shchitovik.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/shchitovik.conf /etc/nginx/sites-enabled/
sudo certbot --nginx -d shchitovik.ru
sudo nginx -t && sudo systemctl reload nginx
```
