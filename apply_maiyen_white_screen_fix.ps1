param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath
)

$ErrorActionPreference = "Stop"

$PatchRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = (Resolve-Path $ProjectPath).Path
$PubspecPath = Join-Path $ProjectRoot "pubspec.yaml"

if (-not (Test-Path $PubspecPath)) {
    throw "STOP: Khong tim thay pubspec.yaml tai $ProjectRoot"
}

$Pubspec = Get-Content -Raw -Path $PubspecPath
if ($Pubspec -notmatch '(?m)^name:\s*maiyen_app\s*$') {
    throw "STOP: Thu muc nay khong phai project maiyen_app"
}

$RelativeFiles = @(
    "lib\main.dart",
    "lib\pages\fullscreen_alarm_page.dart",
    "android\app\src\main\kotlin\com\myfamily\maiyen\MainActivity.kt"
)

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupRoot = Join-Path $ProjectRoot "maiyen_white_screen_backup_$Timestamp"

foreach ($RelativeFile in $RelativeFiles) {
    $Source = Join-Path $PatchRoot $RelativeFile
    $Destination = Join-Path $ProjectRoot $RelativeFile

    if (-not (Test-Path $Source)) {
        throw "STOP: Thieu file hotfix: $Source"
    }

    if (-not (Test-Path $Destination)) {
        throw "STOP: Project thieu file dich: $Destination"
    }

    $Backup = Join-Path $BackupRoot $RelativeFile
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Backup) | Out-Null
    Copy-Item -Force -Path $Destination -Destination $Backup

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    Copy-Item -Force -Path $Source -Destination $Destination
}

$MainPath = Join-Path $ProjectRoot "lib\main.dart"
$FullscreenPath = Join-Path $ProjectRoot "lib\pages\fullscreen_alarm_page.dart"
$MainActivityPath = Join-Path $ProjectRoot "android\app\src\main\kotlin\com\myfamily\maiyen\MainActivity.kt"

$MainText = Get-Content -Raw -Path $MainPath
$FullscreenText = Get-Content -Raw -Path $FullscreenPath
$MainActivityText = Get-Content -Raw -Path $MainActivityPath

$RunAppCount = ([regex]::Matches($MainText, 'runApp\s*\(')).Count
$SystemNavigatorPopCount = ([regex]::Matches($FullscreenText, 'SystemNavigator\.pop\s*\(')).Count

if ($RunAppCount -ne 1) {
    throw "STOP: main.dart phai co dung 1 runApp(), hien co $RunAppCount"
}

if ($SystemNavigatorPopCount -ne 0) {
    throw "STOP: fullscreen_alarm_page.dart van con SystemNavigator.pop()"
}

if ($FullscreenText -notmatch "invokeMethod<bool>\('moveTaskToBack'\)") {
    throw "STOP: Dart MethodChannel moveTaskToBack chua duoc cai dat"
}

if ($MainActivityText -notmatch '"moveTaskToBack"\s*->') {
    throw "STOP: Native MethodChannel moveTaskToBack chua duoc cai dat"
}

if ($MainActivityText -notmatch 'isDisplayingFlutterUi' -or
    $MainActivityText -notmatch 'recreate\(\)') {
    throw "STOP: Native white-screen recovery guard chua day du"
}

Write-Host ""
Write-Host "MAIYEN WHITE SCREEN HOTFIX APPLIED"
Write-Host "PROJECT: $ProjectRoot"
Write-Host "BACKUP:  $BackupRoot"
Write-Host "runApp count: $RunAppCount"
Write-Host "SystemNavigator.pop count: $SystemNavigatorPopCount"
Write-Host ""
Write-Host "Buoc tiep theo: build va cai APK moi len may Android test."
