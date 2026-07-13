import 'package:firebase_database/firebase_database.dart';

import '../helpers/firebase_paths.dart';

enum FirebaseSecurityTestState { completed, homeUnavailable, noDevices }

class FirebaseSecurityTestResult {
  const FirebaseSecurityTestResult({
    required this.state,
    this.results = const <String, String>{},
  });

  final FirebaseSecurityTestState state;
  final Map<String, String> results;

  int get passCount => results.values.where((value) => value == "PASS").length;
}

class FirebaseSecurityTestService {
  static Future<FirebaseSecurityTestResult> run({
    required String ownerUid,
    required String homeId,
  }) async {
    final cleanOwnerUid = ownerUid.trim();
    final cleanHomeId = homeId.trim();

    if (cleanOwnerUid.isEmpty || cleanHomeId.isEmpty) {
      return const FirebaseSecurityTestResult(
        state: FirebaseSecurityTestState.homeUnavailable,
      );
    }

    final homeRef = FirebaseDatabase.instance.ref(
      FirebasePaths.home(cleanOwnerUid, cleanHomeId),
    );

    final homeSnap = await homeRef.get();

    if (!homeSnap.exists || homeSnap.value is! Map) {
      return const FirebaseSecurityTestResult(
        state: FirebaseSecurityTestState.homeUnavailable,
      );
    }

    final homeData = Map<String, dynamic>.from(homeSnap.value as Map);
    final rawDevices = homeData["devices"];

    if (rawDevices is! Map || rawDevices.isEmpty) {
      return const FirebaseSecurityTestResult(
        state: FirebaseSecurityTestState.noDevices,
      );
    }

    final devices = Map<String, dynamic>.from(rawDevices);
    final firstDeviceEntry = devices.entries.first;
    final deviceId = firstDeviceEntry.key.toString();
    final deviceData = firstDeviceEntry.value is Map
        ? Map<String, dynamic>.from(firstDeviceEntry.value as Map)
        : <String, dynamic>{};

    final deviceRef = homeRef.child("devices/$deviceId");
    final results = <String, String>{};

    bool isPermissionDenied(Object error) {
      final text = error.toString().toLowerCase();

      return text.contains("permission-denied") ||
          text.contains("permission_denied") ||
          text.contains("permission denied");
    }

    Future<void> expectDenied({
      required String label,
      required Future<void> Function() action,
      Future<void> Function()? cleanup,
    }) async {
      try {
        await action();

        results[label] = "FAIL — Firebase cho phép ghi";

        if (cleanup != null) {
          try {
            await cleanup();
          } catch (error) {
            results[label] = "FAIL — ghi được, cleanup lỗi: $error";
          }
        }
      } catch (error) {
        if (isPermissionDenied(error)) {
          results[label] = "PASS";
        } else {
          results[label] = "ERROR — $error";
        }
      }
    }

    final testId = DateTime.now().millisecondsSinceEpoch.toString();

    await expectDenied(
      label: "_ownerUid",
      action: () async {
        await homeRef.child("_ownerUid").set(cleanOwnerUid);
      },
    );

    final eventTestRef = homeRef.child("events/security_test_$testId");

    await expectDenied(
      label: "events",
      action: () async {
        await eventTestRef.set({
          "type": "security_test",
          "time": DateTime.now().millisecondsSinceEpoch,
        });
      },
      cleanup: () async {
        await eventTestRef.remove();
      },
    );

    final pauseExists =
        homeData.containsKey("alarmPauseToday") &&
            homeData["alarmPauseToday"] != null;

    final pauseTestValue = pauseExists
        ? homeData["alarmPauseToday"]
        : <String, dynamic>{
      "date": "security_test",
      "start": "00:00",
      "end": "00:01",
      "reason": "security_test",
    };

    await expectDenied(
      label: "alarmPauseToday",
      action: () async {
        await homeRef.child("alarmPauseToday").set(pauseTestValue);
      },
      cleanup: pauseExists
          ? null
          : () async {
        await homeRef.child("alarmPauseToday").remove();
      },
    );

    final fieldFallbackValues = <String, Object?>{
      "contact": false,
      "smoke": false,
      "tamper": false,
      "availability": "online",
      "battery": 100,
      "type": "door",
      "last_seen": DateTime.now().toIso8601String(),
    };

    for (final entry in fieldFallbackValues.entries) {
      final field = entry.key;
      final fieldExists =
          deviceData.containsKey(field) && deviceData[field] != null;

      final testValue = fieldExists ? deviceData[field] : entry.value;
      final fieldRef = deviceRef.child(field);

      await expectDenied(
        label: "device/$field",
        action: () async {
          await fieldRef.set(testValue);
        },
        cleanup: fieldExists
            ? null
            : () async {
          await fieldRef.remove();
        },
      );
    }

    final deviceRootTestData = Map<String, dynamic>.from(deviceData);
    deviceRootTestData["_securityTest"] = testId;

    await expectDenied(
      label: "device root / delete gate",
      action: () async {
        await deviceRef.set(deviceRootTestData);
      },
      cleanup: () async {
        await deviceRef.child("_securityTest").remove();
      },
    );

    return FirebaseSecurityTestResult(
      state: FirebaseSecurityTestState.completed,
      results: Map.unmodifiable(results),
    );
  }
}
