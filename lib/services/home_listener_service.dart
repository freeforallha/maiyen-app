import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../helpers/firebase_paths.dart';
import '../helpers/home_helper.dart';

class HomeListenerService {
  static Future<void> loadSharedHomes({
    required String uid,
    required Map<String, dynamic> homes,
    required Map sharedHomes,
    required Function() refresh,
    required Function(String homeId) onDeleted,
  }) async {
    for (final entry in sharedHomes.entries) {
      final homeId = entry.key.toString();
      final sharedConfig = safeMap(entry.value);

      final ownerUid = sharedConfig["ownerUid"]?.toString().trim() ?? "";

      if (ownerUid.isEmpty) {
        continue;
      }

      FirebaseDatabase.instance
          .ref(FirebasePaths.home(ownerUid, homeId))
          .onValue
          .listen(
            (sharedEvent) {
              final sharedData = sharedEvent.snapshot.value;

              if (sharedData == null) {
                onDeleted(homeId);
                return;
              }

              final sharedHome = safeMap(sharedData);

              homes[homeId] = {
                ...sharedHome,

                "alarm": safeMap(sharedHome["alarm"]),

                "_shared": true,
                "_ownerUid": ownerUid,

                // Không đọc accounts/$ownerUid/email nữa vì Rules chặn.
                "_ownerEmail": sharedConfig["ownerEmail"]?.toString() ?? "",

                "_customName": sharedConfig["customName"],
                "_customAlarm": sharedConfig["alarm"],

                // Role đã có sẵn trong sharedHomes của tài khoản hiện tại.
                "_role": sharedConfig["role"]?.toString() ?? "member",
              };

              refresh();
            },
            onError: (error) {
              debugPrint(
                "SHARED HOME LISTENER ERROR: "
                "$ownerUid/$homeId - $error",
              );
            },
          );
    }
  }
}
