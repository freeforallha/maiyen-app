import 'package:firebase_database/firebase_database.dart';

class HomeService {
  static Future<void> renameDevice({
    required String ownerUid,
    required String homeId,
    required String deviceId,
    required String name,
  }) async {
    await FirebaseDatabase.instance
        .ref("accounts/$ownerUid/homes/$homeId/devices/$deviceId/name")
        .set(name);
  }

  static Future<void> deleteDevice({
    required String ownerUid,
    required String homeId,
    required String deviceId,
  }) async {
    await FirebaseDatabase.instance
        .ref("accounts/$ownerUid/homes/$homeId/devices/$deviceId")
        .remove();
  }

  static Future<void> renameHome({
    required String ownerUid,
    required String homeId,
    required String name,
  }) async {
    await FirebaseDatabase.instance
        .ref("accounts/$ownerUid/homes/$homeId/name")
        .set(name);
  }

  static Future<void> addHome({
    required String uid,
    required String id,
    required String name,
  }) async {
    await FirebaseDatabase.instance.ref("accounts/$uid/homes/$id").set({
      "name": name,
      "devices": {},
      "alarm": {"enabled": false, "start": "23:00", "end": "06:00"},
    });
  }
}
