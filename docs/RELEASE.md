# Выпуск в магазины

Что сделать владельцу перед первой публикацией. В репозитории уже готово: id `ru.shchitovik.app`,
release-подпись Android, CI-задача `build_store_android` (подписанные AAB и APK), политика
`app/web/privacy.html`, тексты и анкеты — [store/listing.md](store/listing.md).

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

Сохранить ключ и пароли в менеджере паролей. В GitLab CI (Settings → CI/CD → Variables, Protected):
`ANDROID_KEYSTORE` (тип File), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` = `upload`,
`ANDROID_KEY_PASSWORD`. В GitHub (Settings → Secrets → Actions) те же секреты, но ключ —
`ANDROID_KEYSTORE_BASE64` (`base64 -w0 ~/shchitovik-upload.jks`); сборка — Actions → Release →
`store-android`. Для локальной сборки — `app/android/key.properties` с теми же полями
(`storeFile`, `storePassword`, `keyAlias`, `keyPassword`); файл в `.gitignore`.

## 3. Google Play и RuStore

- [ ] Запустить `build_store_android` (GitLab) или Release → `store-android` (GitHub), взять AAB/APK из артефактов.
- [ ] Google Play: создать приложение, включить Play App Signing, заполнить Data safety, рейтинг,
      аудиторию и политику по `listing.md`. Новым личным аккаунтам нужно закрытое тестирование
      (сейчас 12 тестировщиков, 14 дней) — сверить правила в консоли.
- [ ] RuStore: создать приложение, загрузить APK или AAB, заполнить карточку по `listing.md`.

## 4. App Store (на Mac)

- [ ] Apple Developer Program, bundle id `ru.shchitovik.app`, команда подписи в Xcode.
- [ ] Собрать и загрузить через Transporter или Xcode Organizer:

```bash
make bootstrap
cd app && flutter build ipa --release --dart-define=ENVIRONMENT=prod --dart-define=CATALOG_URL=https://shchitovik.ru
```

- [ ] App Store Connect: App Privacy («Data Not Collected»), карточка по `listing.md`, TestFlight, ревью.

## Если включать Sentry

Задать `SENTRY_DSN` в сборках, обновить политику и анкеты о данных (журналы сбоев, не связаны с
пользователем), в Sentry включить «Prevent Storing of IP Addresses», оценить требования 152-ФЗ.
