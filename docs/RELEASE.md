# Выпуск в магазины

Что сделать владельцу перед первой публикацией. В репозитории уже готово: id `ru.shchitovik.app`,
release-подпись Android, workflow `.github/workflows/release.yml` (подписанные AAB и APK, черновик
GitHub Release, выкладка Web, IPA на своём Mac), политика `app/web/privacy.html`, тексты и анкеты —
[store/listing.md](store/listing.md).

## 1. До выпуска

- [ ] Закрыть ручную верификацию — [VERIFICATION.md](../verification/VERIFICATION.md).
- [ ] Зарегистрировать `shchitovik.ru`, настроить сервер — [deploy/README.md](../deploy/README.md).
- [ ] Заполнить `⟨…⟩` в `app/web/privacy.html` (разработчик, e-mail, срок хранения журналов),
      выложить веб-версию, проверить `https://shchitovik.ru/privacy.html`.
- [ ] Иконка (сейчас стандартная Flutter) и скриншоты: телефон, iPad 13″.
- [ ] Версия `1.0.0` в `app/pubspec.yaml`.

## 2. Ключ Android

```bash
keytool -genkey -v -keystore ~/shchitovik-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Сохранить ключ и пароли в менеджере паролей: без ключа загрузки обновления в сторы придётся
восстанавливать через поддержку. В GitHub (Settings → Secrets and variables → Actions):

| Тип | Имя | Значение |
|---|---|---|
| Secret | `ANDROID_KEYSTORE_BASE64` | `base64 -w0 ~/shchitovik-upload.jks` |
| Secret | `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD` | пароли ключа |
| Secret | `ANDROID_KEY_ALIAS` | `upload` |
| Variable | `APP_BASE_URL` | `https://shchitovik.ru` |

Для локальной сборки — `app/android/key.properties` с теми же полями (`storeFile`,
`storePassword`, `keyAlias`, `keyPassword`); файл в `.gitignore`.

Защитить теги релиза: Settings → Rules → Rulesets → New tag ruleset, шаблон `v*`, создание и
удаление — только владельцу. В PR из форков секреты не передаются; запуск workflow из форков —
только с одобрения (Settings → Actions → General → «Require approval for all outside
collaborators»).

## 3. Выпуск версии

1. Поднять `version` в `app/pubspec.yaml` (например, `1.0.0+1`; номер сборки CI ставит сам —
   `github.run_number`), закоммитить в `main`.
2. Поставить тег и отправить его:

   ```bash
   git tag v1.0.0 && git push origin v1.0.0
   ```

3. Workflow Release проверит, что тег совпадает с версией, соберёт `shchitovik-1.0.0.aab` и
   `shchitovik-1.0.0.apk` и создаст **черновик** GitHub Release с ними и списком изменений.
   Проверить текст и опубликовать (Releases → Edit → Publish).
4. Веб-версия: Actions → Release → Run workflow → `deploy-web` (Docker) или `deploy-files`
   (nginx/Caddy без Docker) — [deploy/README.md](../deploy/README.md).

Без тега AAB и APK собирает Actions → Release → `store-android` (артефакт на 30 дней).

APK в GitHub Release подписан ключом загрузки, а Google Play при Play App Signing переподписывает
приложение своим ключом: установленное из GitHub не обновится из Google Play, и наоборот. RuStore
распространяет APK с подписью ключа загрузки.

## 4. Google Play и RuStore

- [ ] Взять AAB/APK из GitHub Release (или из артефакта `store-android`).
- [ ] Google Play: создать приложение, включить Play App Signing, заполнить Data safety, рейтинг,
      аудиторию и политику по `listing.md`. Новым личным аккаунтам нужно закрытое тестирование
      (сейчас 12 тестировщиков, 14 дней) — сверить правила в консоли.
- [ ] RuStore: создать приложение, загрузить APK или AAB, заполнить карточку по `listing.md`.

## 5. App Store (на Mac)

- [ ] Apple Developer Program, bundle id `ru.shchitovik.app`, команда подписи в Xcode.
- [ ] Собрать и загрузить через Transporter или Xcode Organizer:

```bash
make bootstrap
cd app && flutter build ipa --release --dart-define=ENVIRONMENT=prod --dart-define=CATALOG_URL=https://shchitovik.ru
```

Или через Actions: подключить Mac как self-hosted runner (Settings → Actions → Runners → New
self-hosted runner → macOS, при `./config.sh` добавить `--labels macos`, затем
`./svc.sh install && ./svc.sh start`). Нужны Xcode, CocoaPods, `jq` и вход в аккаунт Apple в Xcode.
Actions → Release → `ios` собирает IPA в артефакт; загрузка — через Transporter. Этот runner
используется только ручной задачей `ios`: CI с PR из форков на нём не запускается.

- [ ] App Store Connect: App Privacy («Data Not Collected»), карточка по `listing.md`, TestFlight, ревью.

## Если включать Sentry

Задать `SENTRY_DSN` в сборках, обновить политику и анкеты о данных (журналы сбоев, не связаны с
пользователем), в Sentry включить «Prevent Storing of IP Addresses», оценить требования 152-ФЗ.
