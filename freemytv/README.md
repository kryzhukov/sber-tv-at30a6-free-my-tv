# Free My TV — наш форк для Сбер ТВ (SaluteTV AT30A6)

Это исходники [Free My TV](https://github.com/simbasjungles/free-my-tv) © simbasjungles (MIT, см. [LICENSE](LICENSE)) с правками под телевизор **SaluteTV (Сбер ТВ) AT30A6** и с виджетом курсов валют.

## Что изменено относительно upstream

| Файл | Что добавлено |
|---|---|
| `app/src/io/freemytv/HomeApps.java` | СберTube (`ru.sberdevices.startube`) виден в «Приложениях»: у него нет своей launcher-категории, только приватная `ru.sberdevices.category.STAR_LAUNCHER` — добавлен запрос этой категории и запуск по компоненту; подпись «СберTube»; в полке по умолчанию — YouTube, СберTube, SmartTube, Кинопоиск, Okko, RUTUBE, VK Видео; «Телеканалы» на Сбер ТВ открываются ссылкой `livetv://playback` (на новых прошивках активити StarLiveTv не экспортирована, явный компонент работает только из shell); лишние системные экраны Сбера скрыты из «Приложений». |
| `app/src/io/freemytv/HomeMode.java` | В `DEBLOAT` — 20 приложений Сбера (магазин, промо, браузер, музыка/видео, очистка памяти, подписки, родительский контроль, детская комната, баг-репортер, опросы, бета-канал, установщик приложений, лаунчер, заставка, Умный дом, СберБанк, Projectivy). В `PROTECTED` — всё, без чего отваливаются пульт/ТВ (assistant, services, gamepad, onekey, rcfupdater, starlivetv, tvinputs, settings, startube, webview, оверлеи, CVTE/DroidLogic). |
| `app/AndroidManifest.xml` | `<queries>`: `ru.sberdevices.startube` + категория `ru.sberdevices.category.STAR_LAUNCHER`; версия 1.2. |
| `app/src/io/freemytv/HomeData.java` | Вместо криптовалют (Binance) — **курсы ЦБ РФ**: доллар, евро, юань, турецкая лира к рублю (`https://www.cbr-xml-daily.ru/daily_json.js`, `Nominal` учитывается: юань/лира приходят за 10 единиц). |
| `app/assets/i18n/*.json` | Строки «Currency rates», «US Dollar», «Euro», «Chinese Yuan», «Turkish Lira» (ru — по-русски). |

Всё остальное — upstream без изменений.

## Сборка

**Linux/macOS:** `./build.sh` (JDK 17 + Android SDK build-tools 34 + platform android-34).

**Windows (PowerShell, без Gradle):**

```powershell
# положите исходники так: %USERPROFILE%\dsh-tv-build\src\free-my-tv-main
# JDK 17: %USERPROFILE%\dsh-tv-build\jdk\jdk17.0.21_0
# Android SDK: %USERPROFILE%\dsh-tv-build\sdk
.\build-windows.ps1
```

На выходе — `FreeMyTV.apk`. Ключ подписи — `freemytv.keystore`, пароль `freemytv` (тестовый, чтобы обновление ставилось поверх уже установленного APK).

## Настройки

`config.properties` (создаётся из `config.example.properties`): город/координаты, язык, валюта, `language=ru`, `show_crypto=true` включает виджет курсов, `temperature=C`. Ключ TMDB не нужен для курсов/погоды (нужен только для рекомендаций и обоев).
