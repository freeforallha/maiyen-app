# MaiYen Android white-screen diagnosis

## Evidence from the live capture

- Package: `com.myfamily.maiyen`; affected PID: `29611`.
- `11_logcat_crash.txt` is empty; no Java fatal exception or ANR marker was found.
- `10_logcat_all.txt` contains 37 occurrences of:
  `FlutterJNI was detached from native C++. Could not send.`
- Android repeatedly resumes the existing `MainActivity` and PID instead of creating a clean process.
- `31_gfxinfo.txt` reports only 2 rendered frames for the affected process.
- `30_meminfo.txt`: total PSS 522,764 KB; swap PSS 427,236 KB; 149 AppContexts; 2 Activities.
- `40_proc_status.txt`: VmHWM 985,116 KB and VmSwap 448,312 KB.
- Persistent services in the same process include WorkManager foreground service, `flutter_foreground_task` service, and Geolocator service.

## Source audit

- Entire supplied Dart source contains exactly three `SystemNavigator.pop()` calls; all three are in `lib/pages/fullscreen_alarm_page.dart`.
- `lib/main.dart` contains two `runApp()` calls.
- FCM foreground registration and notification initialization already contain idempotency guards, so they were not changed.
- Foreground location monitoring is intentionally persistent and was not disabled.

## Fix strategy

1. Preserve the Flutter engine when closing a root fullscreen alarm/reminder route.
2. Bootstrap the app with exactly one `runApp()`.
3. Add a one-shot native recovery guard for an already-detached/non-rendering Flutter UI.
