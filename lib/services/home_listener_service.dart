import 'package:firebase_database/firebase_database.dart';

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

      final ownerUid = sharedConfig["ownerUid"]?.toString();

      if (ownerUid == null) continue;

      FirebaseDatabase.instance
          .ref(FirebasePaths.home(ownerUid, homeId))
          .onValue
          .listen((sharedEvent) async {
        final sharedData = sharedEvent.snapshot.value;

        if (sharedData == null) {
          onDeleted(homeId);
          return;
        }

        final sharedHome = Map<String, dynamic>.from(sharedData as Map);

        final emailSnap =
        await FirebaseDatabase.instance.ref(FirebasePaths.accountEmail(ownerUid)).get();

        final ownerEmail = emailSnap.value?.toString() ?? "Unknown";

        homes[homeId] = {
          ...sharedHome,

          "alarm": safeMap(sharedHome["alarm"]),

          "_shared": true,
          "_ownerUid": ownerUid,
          "_ownerEmail": ownerEmail,

          "_customName": sharedConfig["customName"],
          "_customAlarm": sharedConfig["alarm"],
          "_role": (await FirebaseDatabase.instance
              .ref("${FirebasePaths.sharedMember(homeId, uid)}/role")
              .get())
              .value
              ?.toString() ??
              sharedConfig["role"] ??
              "member",
        };

        if (homes.isEmpty) return;
        refresh();
      });
    }
  }
}