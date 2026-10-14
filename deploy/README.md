# Деплой на VPS

nginx или Caddy раздаёт Web-версию и каталог цен с `shchitovik.ru`; конфиги равнозначны, выберите один. Выкладка — ручные задачи `deploy_web` и
`deploy_catalog` в GitLab CI или workflow Release в GitHub Actions.

## Настройка сервера (один раз)

```bash
sudo mkdir -p /var/www/shchitovik/{web,catalog}
sudo useradd -m -s /bin/bash deploy && sudo chown -R deploy: /var/www/shchitovik
# A-запись shchitovik.ru → VPS
```

**nginx** — сертификат через certbot:

```bash
sudo cp deploy/nginx/shchitovik.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/shchitovik.conf /etc/nginx/sites-enabled/
sudo certbot --nginx -d shchitovik.ru
sudo nginx -t && sudo systemctl reload nginx
```

**Caddy** — сертификат Caddy получает и продлевает сам, нужны открытые порты 80 и 443:

```bash
sudo cp deploy/caddy/Caddyfile /etc/caddy/Caddyfile
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

Открытый SSH-ключ для CI — в `~deploy/.ssh/authorized_keys`.

## Переменные GitLab CI

| Переменная | Значение |
|---|---|
| `DEPLOY_HOST`, `DEPLOY_USER` | адрес VPS, `deploy` |
| `DEPLOY_SSH_KEY` | закрытый ключ (File, Protected) |
| `DEPLOY_KNOWN_HOSTS` | вывод `ssh-keyscan <адрес VPS>` |
| `APP_BASE_URL` | `https://shchitovik.ru` |

В GitHub: `DEPLOY_SSH_KEY` и `DEPLOY_KNOWN_HOSTS` — секреты, `DEPLOY_HOST`, `DEPLOY_USER`,
`APP_BASE_URL` — переменные (Settings → Secrets and variables → Actions); деплой — Actions → Release.

## Проверка

```bash
curl -I https://shchitovik.ru/sqlite3.wasm            # Content-Type: application/wasm
curl -I https://shchitovik.ru/                        # Cross-Origin-Opener/Embedder-Policy
curl https://shchitovik.ru/catalog/manifest.json      # актуальная catalog_version
```
