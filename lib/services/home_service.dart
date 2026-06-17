import 'package:firebase_database/firebase_database.dart';
import '../helpers/firebase_paths.dart';
class HomeService {
  static Future<void> renameDevice({
    required String ownerUid,
    required String homeId,
    required String deviceId,
    required String name,
  }) async {
    await FirebaseDatabase.instance
        .ref("${FirebasePaths.device(ownerUid, homeId, deviceId)}/name")
        .set(name);
  }

  static Future<void> deleteDevice({
    required String ownerUid,
    required String homeId,
    required String deviceId,
  }) async {
    await FirebaseDatabase.instance
        .ref(FirebasePaths.device(ownerUid, homeId, deviceId))
        .remove();
  }

  static Future<void> renameHome({
    required String ownerUid,
    required String homeId,
    required String name,
  }) async {
    await FirebaseDatabase.instance
        .ref("${FirebasePaths.home(ownerUid, homeId)}/name")
        .set(name);
  }

  static Future<void> addHome({
    required String uid,
    required String id,
    required String name,
    String address = "",
  }) async {
    await FirebaseDatabase.instance.ref(FirebasePaths.home(uid, id)).set({
      "name": name,
      "address": address,
      "_ownerUid": uid,
      "_shared": false,
      "devices": {},
      "rooms": {
        "unassigned": {
          "name": "Chưa phân phòng",
          "icon": "home",
          "order": 0,
        },
      },
      "alarm": {
        "enabled": false,
        "start": "23:00",
        "end": "06:00",
      },
      "schedules": {
        "alarms": [],
        "notifications": [],
      },
    });
  }
}