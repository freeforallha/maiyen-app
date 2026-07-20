import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../helpers/firebase_paths.dart';

class HomeService {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;

  static Future<String> _requireSignedInUid() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null || currentUid.isEmpty) {
      throw StateError("Không có tài khoản Firebase Auth đang đăng nhập");
    }

    return currentUid;
  }

  static Future<void> _requireManageHome({
    required String ownerUid,
    required String homeId,
  }) async {
    final currentUid = await _requireSignedInUid();

    if (ownerUid.trim().isEmpty || homeId.trim().isEmpty) {
      throw ArgumentError("ownerUid và homeId không được để trống");
    }

    if (currentUid == ownerUid) {
      return;
    }

    final accessSnap = await _db
        .ref("accounts/$currentUid/sharedHomes/$homeId")
        .get();

    final access = accessSnap.value is Map
        ? Map<String, dynamic>.from(accessSnap.value as Map)
        : <String, dynamic>{};

    final sharedOwnerUid = access["ownerUid"]?.toString() ?? "";

    final role = access["role"]?.toString() ?? "member";

    if (sharedOwnerUid != ownerUid || role != "admin") {
      throw StateError("Bạn không có quyền quản lý nhà này");
    }
  }

  static Future<void> renameDevice({
    required String ownerUid,
    required String homeId,
    required String deviceId,
    required String name,
  }) async {
    await _requireManageHome(ownerUid: ownerUid, homeId: homeId);

    final cleanDeviceId = deviceId.trim();
    final cleanName = name.trim();

    if (cleanDeviceId.isEmpty || cleanName.isEmpty) {
      throw ArgumentError("deviceId và tên thiết bị không được để trống");
    }

    await _db
        .ref("${FirebasePaths.device(ownerUid, homeId, cleanDeviceId)}/name")
        .set(cleanName);
  }

  static Future<void> setDeviceRoom({
    required String ownerUid,
    required String homeId,
    required String deviceId,
    required String roomId,
  }) async {
    await _requireManageHome(ownerUid: ownerUid, homeId: homeId);

    final cleanDeviceId = deviceId.trim();
    final cleanRoomId = roomId.trim();

    if (cleanDeviceId.isEmpty || cleanRoomId.isEmpty) {
      throw ArgumentError("deviceId và roomId không được để trống");
    }

    await _db
        .ref("${FirebasePaths.device(ownerUid, homeId, cleanDeviceId)}/roomId")
        .set(cleanRoomId);
  }

  static Future<void> ensureHomeRoomModel({
    required String ownerUid,
    required String homeId,
  }) async {
    await _requireManageHome(ownerUid: ownerUid, homeId: homeId);

    final homeRef = _db.ref(FirebasePaths.home(ownerUid, homeId));

    final snap = await homeRef.get();
    final data = snap.value;

    if (data is! Map) {
      return;
    }

    final home = Map<String, dynamic>.from(data);

    final devices = home["devices"] is Map
        ? Map<String, dynamic>.from(home["devices"] as Map)
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
      final deviceId = entry.key.toString();
      final device = entry.value;

      if (device is! Map || deviceId.isEmpty) {
        continue;
      }

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
    await _requireManageHome(ownerUid: ownerUid, homeId: homeId);

    final cleanDeviceId = deviceId.trim();

    if (cleanDeviceId.isEmpty) {
      throw ArgumentError("deviceId không được để trống");
    }

    await _db
        .ref(FirebasePaths.device(ownerUid, homeId, cleanDeviceId))
        .remove();
  }

  static Future<void> renameHome({
    required String ownerUid,
    required String homeId,
    required String name,
  }) async {
    await _requireManageHome(ownerUid: ownerUid, homeId: homeId);

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw ArgumentError("Tên nhà không được để trống");
    }

    await _db
        .ref("${FirebasePaths.home(ownerUid, homeId)}/name")
        .set(cleanName);
  }

  static Future<void> addHome({
    required String uid,
    required String id,
    required String name,
    String address = "",
  }) async {
    final currentUid = await _requireSignedInUid();

    if (uid != currentUid) {
      throw StateError("Không thể tạo nhà cho tài khoản khác");
    }

    final cleanId = id.trim();
    final cleanName = name.trim();

    if (cleanId.isEmpty || cleanName.isEmpty) {
      throw ArgumentError("ID và tên nhà không được để trống");
    }

    await _db.ref(FirebasePaths.home(currentUid, cleanId)).set({
      "name": cleanName,
      "address": address.trim(),
      "_ownerUid": currentUid,
      "_shared": false,
      "devices": {},
      "rooms": {
        "unassigned": {"name": "Chưa phân phòng", "icon": "home", "order": 0},
        "living_room": {"name": "Phòng khách", "icon": "living", "order": 1},
      },
      "alarm": {"enabled": false, "start": "23:00", "end": "06:00"},
      "schedules": {"alarms": [], "notifications": []},
    });
  }
}
