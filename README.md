# Щитовик

Расчёт электрощита и смета: линии, автоматы, УЗО, кабель, баланс фаз, щит на DIN-рейках, PDF.
Android, iOS, Web. Расчёт ориентировочный и не заменяет проект.

```bash
dart pub global activate fvm && fvm install   # Flutter 3.47.6
make bootstrap                                # зависимости и кодогенерация
make analyze && make test
cd app && fvm flutter run --dart-define-from-file=env/.dev.env
```

Параметры сборки (`--dart-define`): `ENVIRONMENT`, `CATALOG_URL`, необязательный `SENTRY_DSN`.

| Документ | О чём |
|---|---|
| [docs/PLAN.md](docs/PLAN.md) | решения, что сделано, что осталось |
| [AGENTS.md](AGENTS.md) | структура и правила кода |
| [verification/VERIFICATION.md](verification/VERIFICATION.md) | проверка формул и данных |
| [docs/RELEASE.md](docs/RELEASE.md) | выпуск в магазины |
| [deploy/README.md](deploy/README.md) | сервер, Web и каталог |
