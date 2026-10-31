# РЎРєСЂРёРїС‚ РІРѕСЃСЃС‚Р°РЅРѕРІР»РµРЅРёСЏ СЃРёСЃС‚РµРјРЅС‹С… С„Р°Р№Р»РѕРІ РЅР° РўР’ РїСЂРё СЃР±СЂРѕСЃРµ
param(
    [string]$IP = "192.168.1.118"
)

$adb = "adb"
if (Test-Path "$env:USERPROFILE\dsh-tv-build\platform-tools\adb.exe") {
    $adb = "$env:USERPROFILE\dsh-tv-build\platform-tools\adb.exe"
}

Write-Host "РџРѕРґРєР»СЋС‡РµРЅРёРµ Рє РўР’ $IP..."
& $adb connect "$IP`:5555"

Write-Host "Р’РѕСЃСЃС‚Р°РЅРѕРІР»РµРЅРёРµ СЃРєСЂРёРїС‚РѕРІ РјРѕРЅС‚РёСЂРѕРІР°РЅРёСЏ С„Р»РµС€РєРё..."
& $adb push (Join-Path $PSScriptRoot "mount_usb_apps.sh") /data/local/tmp/mount_usb_apps.sh
& $adb push (Join-Path $PSScriptRoot "init.usb_apps.rc") /data/local/tmp/init.usb_apps.rc
& $adb push (Join-Path $PSScriptRoot "hosts.txt") /data/local/tmp/hosts_new

& $adb shell "su -c '
mount -o remount,rw /
cp /data/local/tmp/mount_usb_apps.sh /system/bin/mount_usb_apps.sh
chmod 755 /system/bin/mount_usb_apps.sh
cp /data/local/tmp/init.usb_apps.rc /system/etc/init/init.usb_apps.rc
chmod 644 /system/etc/init/init.usb_apps.rc
cp /data/local/tmp/hosts_new /system/etc/hosts
chmod 644 /system/etc/hosts
mount -o remount,ro /
rm /data/local/tmp/mount_usb_apps.sh /data/local/tmp/init.usb_apps.rc /data/local/tmp/hosts_new
'"

Write-Host "Р“РѕС‚РѕРІРѕ! Р’СЃРµ РєРѕРЅС„РёРіСѓСЂР°С†РёРё РІРѕСЃСЃС‚Р°РЅРѕРІР»РµРЅС‹."
