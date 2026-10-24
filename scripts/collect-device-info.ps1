# Собирает свойства телевизора и сохраняет в docs/device-info-raw.txt
param(
    [Parameter(Mandatory = $true)][string]$TvIp,
    [string]$Adb = "C:\platform-tools\adb.exe",
    [string]$Out = "docs/device-info-raw.txt"
)

& $Adb connect "${TvIp}:5555"
Start-Sleep -Seconds 2

$lines = @()
$lines += "# SaluteTV AT30A6 — свойства ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
$lines += "## Модель"
foreach ($p in @("ro.product.brand","ro.product.model","ro.product.device","ro.product.name",
                 "ro.board.platform","ro.hardware","ro.cvte.model","ro.cvte.panelname",
                 "ro.build.version.release","ro.build.version.sdk","ro.build.display.id",
                 "ro.build.fingerprint","ro.boot.verifiedbootstate","ro.boot.veritymode",
                 "ro.adb.secure","ro.boot.memsize")) {
    $v = (& $Adb shell "getprop $p" 2>$null) -join " "
    $lines += "$p = $($v.Trim())"
}
$lines += "`n## device-tree"
$lines += ((& $Adb shell "cat /proc/device-tree/model" 2>$null) -join "")
$lines += ((& $Adb shell "cat /proc/device-tree/compatible" 2>$null) -join "")
$lines += "`n## getprop (серийный номер скрыт)"
$props = ((& $Adb shell getprop) -join "`n")
$props = $props -replace "`[ro.serialno`]: `[.*?`]", "[ro.serialno]: [скрыт]"
$props = $props -replace "`[ro.boot.serialno`]: `[.*?`]", "[ro.boot.serialno]: [скрыт]"
$lines += $props

[System.IO.File]::WriteAllLines((Resolve-Path -LiteralPath (Split-Path $Out)).Path + "\" + (Split-Path $Out -Leaf), $lines + "`n", (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Сохранено: $Out"
