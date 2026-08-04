MAIYEN - HOTFIX ANDROID TREO MAN HINH TRANG
=============================================

KET LUAN TU GOI CHAN DOAN 2026-08-03
-------------------------------------
1. App khong bi Java crash va khong co ANR:
   - 11_logcat_crash.txt rong.
   - Khong co FATAL EXCEPTION / ANR trong logcat.

2. Process Android van song nhung Flutter Engine da tach khoi JNI:
   - Log lap lai 37 lan:
     "FlutterJNI was detached from native C++. Could not send."
   - MainActivity van duoc Android resume lai cung PID, nhung UI Flutter
     khong the nhan message Firebase nua.

3. Flutter khong ve duoc giao dien:
   - gfxinfo chi ghi nhan 2 frame trong process bi loi.

4. Foreground service van giu process song:
   - Native geofence / WorkManager foreground service.
   - flutter_foreground_task ForegroundService (stopWithTask=false).
   - GeolocatorLocationService.
   Vi vay dong/mo icon app khong tao lai process sach; Force stop hoac xoa
   du lieu moi lam app hoat dong lai.

5. Source co hai diem nguy hiem trung khop voi trang thai tren:
   - lib/pages/fullscreen_alarm_page.dart goi SystemNavigator.pop() tai 3
     duong dong Alarm/Reminder. Khi trang fullscreen la route goc, lenh nay
     dong FlutterActivity trong khi foreground service van giu process song.
   - lib/main.dart goi runApp() hai lan trong mot Flutter Engine.

CAC FILE DA SUA
---------------
1. lib/main.dart
   - Chi con mot runApp().
   - Splash duoc ve ngay bang bootstrap StatefulWidget.
   - Firebase retry ma khong thay toan bo root app bang runApp lan hai.

2. lib/pages/fullscreen_alarm_page.dart
   - Xoa toan bo 3 SystemNavigator.pop().
   - Khi co route truoc: Navigator.pop binh thuong.
   - Khi fullscreen la route goc: thay bang AuthGate, sau do dua task Android
     xuong background ma khong huy Flutter Engine.

3. android/app/src/main/kotlin/com/myfamily/maiyen/MainActivity.kt
   - Them MethodChannel moveTaskToBack.
   - Them lop tu phuc hoi mot lan: neu Activity da foreground 8 giay ma Dart
     hoac Flutter UI khong hoat dong, MainActivity duoc recreate dung mot lan.
   - Co chan vong lap recreate.

CACH AP DUNG
------------
Giai nen ZIP, mo PowerShell tai thu muc vua giai nen, chay:

powershell -ExecutionPolicy Bypass -File ".\apply_maiyen_white_screen_fix.ps1" -ProjectPath "DUONG_DAN_DEN_PROJECT_MAIYEN"

Vi du:

powershell -ExecutionPolicy Bypass -File ".\apply_maiyen_white_screen_fix.ps1" -ProjectPath "C:\Projects\maiyen_app"

Script se:
- Kiem tra dung project.
- Backup 3 file cu vao thu muc maiyen_white_screen_backup_YYYYMMDD_HHMMSS.
- Copy dung 3 file moi vao dung duong dan.
- Chay kiem tra tinh mot runApp / khong con SystemNavigator.pop / MethodChannel.

PHAM VI
-------
- Khong sua Firebase Rules.
- Khong sua backend HUB.
- Khong doi database schema.
- Khong doi logic bao dong, nhac nho, Auto Away hay foreground service.
