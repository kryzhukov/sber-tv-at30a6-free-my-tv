#!/usr/bin/env bash
# Установка YouTube через Cobalt — приложение «YouTube.com» (com.yandex.tv.ytplayer)
# на SaluteTV AT30A6 (Amlogic T5W, Android 13, 32-бит, ADB по TCP).
#
# Два режима:
#   --mode user    обычное приложение (без root, ничего не перезагружаем)
#   --mode system  системное приложение в /system/app/YtPlayer (нужен root, перезагрузка)
#
# Примеры:
#   ./install-cobalt-youtube.sh --apk ./YtPlayer.apk
#   ./install-cobalt-youtube.sh --apk ./YtPlayer.apk --mode system --reboot
#   TV_SERIAL=192.168.1.50:5555 ./install-cobalt-youtube.sh --apk ./YtPlayer.apk
#
# Подробности, ограничения и откат — docs/КОБАЛЬТ-YOUTUBE.md
set -euo pipefail

SERIAL="${TV_SERIAL:-192.168.1.118:5555}"
APK="./YtPlayer.apk"
MODE="user"
DO_REBOOT=0
EXPECT_MD5="f39e535b8aaa75d76c8a89733a2603f0"
PKG="com.yandex.tv.ytplayer"
ACT="dev.cobalt.app.MainActivity"

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --apk)    APK="$2"; shift 2 ;;
    --serial) SERIAL="$2"; shift 2 ;;
    --mode)   MODE="$2"; shift 2 ;;
    --reboot) DO_REBOOT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Неизвестный аргумент: $1" >&2; usage; exit 64 ;;
  esac
done

say()  { printf '\n\033[1m== %s\033[0m\n' "$*"; }
ok()   { printf '   \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '   \033[33m!\033[0m %s\n' "$*"; }
die()  { printf '\n\033[31mОШИБКА:\033[0m %s\n' "$*" >&2; exit 1; }

adbx() { adb -s "$SERIAL" "$@"; }

md5_of() {
  if command -v md5sum >/dev/null 2>&1; then md5sum "$1" | awk '{print $1}'
  elif command -v md5 >/dev/null 2>&1; then md5 -q "$1"
  else echo "unknown"; fi
}

# ---------- исходные проверки ----------
command -v adb >/dev/null 2>&1 || die "adb не найден в PATH (Android platform-tools)."
[ -f "$APK" ] || die "Нет файла APK: $APK (укажите --apk /путь/к/YtPlayer.apk)."
case "$MODE" in user|system) ;; *) die "--mode должен быть user или system (получено: $MODE)." ;; esac

say "APK"
ok "файл: $APK ($(wc -c < "$APK" | tr -d ' ') байт)"
got_md5="$(md5_of "$APK")"
ok "md5: $got_md5"
if [ "$got_md5" != "unknown" ] && [ "$got_md5" != "$EXPECT_MD5" ]; then
  warn "md5 не совпадает с ожидаемым ($EXPECT_MD5) — это другая версия APK, продолжаю, но проверьте, что это вообще YtPlayer."
fi

say "Телевизор $SERIAL"
adb connect "$SERIAL" >/dev/null 2>&1 || true
state="$(adb -s "$SERIAL" get-state 2>/dev/null || true)"
[ "$state" = "device" ] || die "Телевизор не отвечает по ADB (state='${state:-none}'). Включите отладку по сети / проверьте IP."
ok "ADB: device"
adb -s "$SERIAL" shell 'getprop ro.product.model; getprop ro.build.version.release; getprop ro.product.cpu.abilist' 2>/dev/null | tr -d '\r' | paste -sd' | ' -
ok "модель/Android/ABI выше — должен быть SaluteTV, 13, armeabi-v7a"

# ---------- установка ----------
say "Установка APK"
adbx install -r "$APK" | grep -q Success || die "install не удался (см. вывод выше)."
ok "установлено: $PKG"

say "Голосовой поиск (RECORD_AUDIO)"
if adbx shell "pm grant $PKG android.permission.RECORD_AUDIO" 2>/dev/null; then
  ok "разрешение выдано"
else
  warn "pm grant не сработал — выдать вручную: Настройки → Приложения → YouTube.com → Разрешения → Микрофон"
fi

# ---------- режим user ----------
if [ "$MODE" = "user" ]; then
  say "Запуск"
  adbx shell "am start -n $PKG/$ACT" >/dev/null 2>&1 || die "не удалось запустить активность"
  ok "запущено (первые 10–20 секунд чёрный экран — Cobalt грузит веб-приложение, это норма)"
  say "Готово (обычное приложение)"
  adbx shell "pm path $PKG; dumpsys package $PKG | grep -m1 'versionName'"
  exit 0
fi

# ---------- режим system ----------
say "Режим system: проверяю root"
adbx shell 'su -c id' 2>/dev/null | tr -d '\r' | grep -q 'uid=0' \
  || die "root недоступен (su -c id не даёт uid=0). Для варианта без root используйте --mode user."

say "Копирую в /system/app/YtPlayer"
adbx shell 'su -c "
set -e
APK=\$(pm path '"$PKG"' | sed s/package://)
mount -o remount,rw /
mkdir -p /system/app/YtPlayer
cp \$APK /system/app/YtPlayer/YtPlayer.apk
chown root:root /system/app/YtPlayer /system/app/YtPlayer/YtPlayer.apk
chmod 755 /system/app/YtPlayer
chmod 644 /system/app/YtPlayer/YtPlayer.apk
chcon u:object_r:system_file:s0 /system/app/YtPlayer /system/app/YtPlayer/YtPlayer.apk
sync
mount -o remount,ro /
md5sum /system/app/YtPlayer/YtPlayer.apk
"' | tr -d '\r'
ok "файл на месте, /system снова ro"

say "Убираю копию из /data/app (иначе система оставит именно её)"
adbx shell 'su -c "pm uninstall '"$PKG"'"' 2>&1 | tr -d '\r' | tail -1

if [ "$DO_REBOOT" = "1" ]; then
  say "Перезагрузка"
  adbx reboot >/dev/null 2>&1 || true
  echo "   ждём загрузку (до 240 с)..."
  for i in $(seq 1 40); do
    sleep 6
    adb connect "$SERIAL" >/dev/null 2>&1 || true
    bc="$(adb -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r\n' || true)"
    if [ "$bc" = "1" ]; then ok "телевизор загрузился"; break; fi
    [ "$i" = "40" ] && warn "не дождались sys.boot_completed за 240 с — проверьте телевизор вручную"
  done
else
  warn "Перезагрузка не запрошена. Системное приложение появится ТОЛЬКО после перезагрузки: adb -s $SERIAL reboot"
fi

say "Проверка"
adbx shell 'pm path '"$PKG"' 2>/dev/null; dumpsys package '"$PKG"' 2>/dev/null | grep -m1 "flags=\["' | tr -d '\r'
adbx shell 'su -c "pm grant '"$PKG"' android.permission.RECORD_AUDIO"' >/dev/null 2>&1 \
  && ok "RECORD_AUDIO выдан" || warn "RECORD_AUDIO не выдан — сделайте вручную"
adbx shell "cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.LEANBACK_LAUNCHER 2>/dev/null | grep -c $PKG" 2>/dev/null | tr -d '\r' | sed 's/^/   плитка в лаунчере (ожидается 1): /'
echo
echo "Ожидаемо: package:/system/app/YtPlayer/YtPlayer.apk и flags=[ SYSTEM ... ]"
echo "Откат: docs/КОБАЛЬТ-YOUTUBE.md, раздел «Откат»."
