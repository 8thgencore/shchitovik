# App icon

Launcher icons (Android, iOS) and favicons/PWA icons (web) of «Щитовик».

- `render_icons.py` draws the sources into `app/assets/icon/` and the link preview
  `app/web/opengraph.png` with headless Chrome (any Chromium binary, e.g. Playwright's).
- [launcher_icons](https://pub.dev/packages/launcher_icons) turns them into platform icons by
  `app/launcher_icons.yaml`. It lives in this standalone package: it pins `xml ^6`, while
  `printing` in the app needs `xml 7`.

```shell
python3 -I tools/app_icon/render_icons.py <chrome>
cd tools/app_icon && dart pub get
dart run launcher_icons -d "$(realpath ../../app)" -c "$(realpath ../../app)"
```

Pass `-d` as an **absolute** path: launcher_icons 0.16.0 joins a relative project root twice
for web icons and writes `web/icons/*` outside the project.
