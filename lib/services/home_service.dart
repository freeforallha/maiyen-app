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

  static Future<void> setDeviceRoom({
    required String ownerUid,
    required String homeId,
    required String deviceId,
    required String roomId,
  }) async {
    await FirebaseDatabase.instance
        .ref("${FirebasePaths.device(ownerUid, homeId, deviceId)}/roomId")
        .set(roomId);
  }

  static Future<void> ensureHomeRoomModel({
    required String ownerUid,
    required String homeId,
  }) async {
    final homeRef = FirebaseDatabase.instance.ref(
      FirebasePaths.home(ownerUid, homeId),
    );

    final snap = await homeRef.get();
    final data = snap.value;

    if (data is! Map) return;

    final home = Map<String, dynamic>.from(data);
    final devices = home["devices"] is Map
        ? Map<String, dynamic>.from(home["devices"])
        : <String, dynamic>{};

    final updates = <String, Object?>{};

    if (home["rooms"] == null) {
      updates["rooms/unassigned"] = {
        "name": "Chưa phân phòng",
        "icon": "home",
        "order": 0,
      };
    }

    for (final entry in devices.entries) {
      final deviceId = entry.key;
      final device = entry.value;

      if (device is! Map) continue;

      final deviceMap = Map<String, dynamic>.from(device);
      final roomId = deviceMap["roomId"]?.toString().trim();

      if (roomId == null || roomId.isEmpty) {
        updates["devices/$deviceId/roomId"] = "unassigned";
      }
    }

    if (updates.isNotEmpty) {
      await homeRef.update(updates);
    }
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