# Отключает/удаляет мусор Сбера на SaluteTV AT30A6 по ADB.
# Запускать в PowerShell на компьютере в той же сети, что и ТВ.
# Ничего не удаляется навсегда: системные приложения можно вернуть `cmd package install-existing --user 0 <пакет>`.
param(
    [Parameter(Mandatory = $true)][string]$TvIp,
    [string]$Adb = "C:\platform-tools\adb.exe"
)

$ErrorActionPreference = "Continue"
& $Adb connect "${TvIp}:5555"
Start-Sleep -Seconds 2

# Список «лишнего» Сбера (см. docs/ИНСТРУКЦИЯ.md). Нужные для пульта/ТВ не трогаем!
$junk = @(
    "ru.sberdevices.starlauncher",
    "ru.sberdevices.starscreensaver",
    "ru.sberdevices.starmarket",
    "ru.sberdevices.app.setup",
    "ru.sberdevices.openbeta",
    "ru.sberdevices.starcleaner",
    "ru.sberdevices.smarthome.promo",
    "ru.sberdevices.starbrowser",
    "ru.sberdevices.videos",
    "ru.sberdevices.music",
    "ru.sberdevices.sberplay",
    "ru.sberdevices.starprofile",
    "ru.sberdevices.subscriptions",
    "ru.sberdevices.parentcontrol",
    "ru.sberdevices.starkidsroom.prod",
    "ru.sberdevices.bugreporter",
    "ru.sberdevices.survey",
    "com.salute.star",
    "com.sberbank.settings",
    "com.spocky.projengmenu"
)

foreach ($p in $junk) {
    $out = & $Adb shell "pm uninstall --user 0 $p" 2>&1
    Write-Host ("{0,-40} {1}" -f $p, ($out -join " ").Trim())
}

# Free My TV — главный экран и заставка
& $Adb shell "cmd package set-home-activity io.freemytv/.HomeActivity"
& $Adb shell "settings put secure screensaver_components io.freemytv/io.freemytv.Screensaver"

# Автообновления прошивки и приложений — выключить
& $Adb shell "settings put global ota_disable_automatic_update 1"
& $Adb shell "settings put global auto_update_apps 0"

# Рекламный оверлей Сбера — запретить (если ассистенту нужны карточки, верните allow)
& $Adb shell "appops set ru.sberdevices.services SYSTEM_ALERT_WINDOW deny"

Write-Host ""
Write-Host "Готово. Теперь один раз откройте на ТВ Free My TV -> Главный экран -> Free My TV"
Write-Host "и разрешите отладку с галочкой «Всегда разрешать». Потом так же один раз откройте «Сбер-Стоп»."
