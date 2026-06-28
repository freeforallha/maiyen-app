import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_geofence/native_geofence.dart';

import '../firebase_options.dart';

const String _autoAwayGeofencePrefix = 'safehome_auto_away';

@pragma('vm:entry-point')
Future<void> safeHomeAutoAwayGeofenceCallback(
  GeofenceCallbackParams params,
) async {
  DartPluginRegistrant.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      try {
        user = await FirebaseAuth.instance
            .authStateChanges()
            .first
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }

    if (user == null) {
      return;
    }

    final state = params.event == GeofenceEvent.exit
        ? 'outside'
        : 'inside';

    for (final geofence in params.geofences) {
      final parsed = AutoAwayService.parseGeofenceId(
        geofence.id,
      );

      if (parsed == null || parsed.uid != user.uid) {
        continue;
      }

      await FirebaseDatabase.instance
          .ref(
        'accounts/${user.uid}/homePresence/${parsed.homeId}',
      )
          .set({
        'ownerUid': parsed.ownerUid,
        'homeId': parsed.homeId,
        'state': state,
        'event': params.event.name,
        'source': 'native_geofence',
        'updatedAt': ServerValue.timestamp,
      });
    }
  } catch (error) {
    print('AUTO_AWAY_GEOFENCE_CALLBACK_ERROR: $error');
  }
}

class AutoAwayService {
  static bool _initialized = false;
  static bool _initialPresenceSynced = false;
  static String _lastSignature = '';
  static Future<void>? _syncInProgress;
  static bool _syncRequested = false;
  static bool _pendingForce = false;
  static String _pendingUid = '';
  static Map<String, dynamic> _pendingHomes = {};

  static Future<bool> ensureBackgroundPermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always;
  }

  static Future<void> syncForHomes({
    required String uid,
    required Map<String, dynamic> homes,
    bool force = false,
  }) {
    _pendingUid = uid;
    _pendingHomes = Map<String, dynamic>.from(homes);
    _pendingForce = _pendingForce || force;
    _syncRequested = true;

    final running = _syncInProgress;

    if (running != null) {
      return running;
    }

    final future = _runSyncLoop();
    _syncInProgress = future;

    return future.whenComplete(() {
      _syncInProgress = null;
    });
  }

  static Future<void> _runSyncLoop() async {
    while (_syncRequested) {
      _syncRequested = false;

      final uid = _pendingUid;
      final homes = Map<String, dynamic>.from(
        _pendingHomes,
      );
      final force = _pendingForce;

      _pendingForce = false;

      await _syncForHomesInternal(
        uid: uid,
        homes: homes,
        force: force,
      );
    }
  }

  static Future<void> _syncForHomesInternal({
    required String uid,
    required Map<String, dynamic> homes,
    required bool force,
  }) async {
    if (uid.trim().isEmpty) {
      return;
    }

    final desired = <String, _DesiredGeofence>{};

    for (final entry in homes.entries) {
      final homeId = entry.key.toString().trim();
      final home = _asMap(entry.value);
      final autoAway = _asMap(home['autoAway']);

      if (homeId.isEmpty || autoAway['enabled'] != true) {
        continue;
      }

      final latitude = _asDouble(autoAway['latitude']);
      final longitude = _asDouble(autoAway['longitude']);
      final radius = _asDouble(autoAway['radiusMeters']) ?? 150.0;

      if (latitude == null || longitude == null) {
        continue;
      }

      final ownerUid = home['_shared'] == true
          ? home['_ownerUid']?.toString().trim() ?? ''
          : uid;

      if (ownerUid.isEmpty) {
        continue;
      }

      final geofenceId = buildGeofenceId(
        uid: uid,
        ownerUid: ownerUid,
        homeId: homeId,
      );

      desired[geofenceId] = _DesiredGeofence(
        id: geofenceId,
        ownerUid: ownerUid,
        homeId: homeId,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radius.clamp(100.0, 1000.0).toDouble(),
      );
    }

    final permission = await Geolocator.checkPermission();
    final signature = _buildSignature(
      desired,
      permission,
    );

    if (!force && signature == _lastSignature) {
      return;
    }

    _lastSignature = signature;

    if (!_initialized) {
      await NativeGeofenceManager.instance.initialize();
      _initialized = true;
    }

    final registered = await NativeGeofenceManager.instance
        .getRegisteredGeofences();

    final registeredById = {
      for (final item in registered) item.id: item,
    };

    for (final item in registered) {
      if (!item.id.startsWith('$_autoAwayGeofencePrefix|')) {
        continue;
      }

      if (!desired.containsKey(item.id)) {
        await NativeGeofenceManager.instance
            .removeGeofenceById(item.id);

        final parsed = parseGeofenceId(item.id);

        if (parsed != null && parsed.uid == uid) {
          await FirebaseDatabase.instance
              .ref(
            'accounts/$uid/homePresence/${parsed.homeId}',
          )
              .remove();
        }
      }
    }

    if (permission != LocationPermission.always) {
      for (final item in desired.values) {
        await _writePresence(
          uid: uid,
          item: item,
          state: 'unknown',
          event: 'permission_required',
        );
      }

      return;
    }

    var changed = false;

    for (final item in desired.values) {
      final current = registeredById[item.id];
      final matches = current != null &&
          (current.location.latitude - item.latitude).abs() < 0.000001 &&
          (current.location.longitude - item.longitude).abs() < 0.000001 &&
          (current.radiusMeters - item.radiusMeters).abs() < 0.5;

      if (matches) {
        continue;
      }

      if (current != null) {
        await NativeGeofenceManager.instance
            .removeGeofenceById(item.id);
      }

      final geofence = Geofence(
        id: item.id,
        location: Location(
          latitude: item.latitude,
          longitude: item.longitude,
        ),
        radiusMeters: item.radiusMeters,
        triggers: const {
          GeofenceEvent.enter,
          GeofenceEvent.exit,
        },
        iosSettings: const IosGeofenceSettings(
          initialTrigger: true,
        ),
        androidSettings: const AndroidGeofenceSettings(
          initialTriggers: {
            GeofenceEvent.enter,
          },
          notificationResponsiveness: Duration(minutes: 1),
        ),
      );

      await NativeGeofenceManager.instance.createGeofence(
        geofence,
        safeHomeAutoAwayGeofenceCallback,
      );

      changed = true;
    }

    if (!_initialPresenceSynced || changed || force) {
      await _syncInitialPresence(
        uid: uid,
        desired: desired.values.toList(),
      );

      _initialPresenceSynced = true;
    }
  }

  static Future<void> _syncInitialPresence({
    required String uid,
    required List<_DesiredGeofence> desired,
  }) async {
    if (desired.isEmpty) {
      return;
    }

    Position? position;

    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      position = await Geolocator.getLastKnownPosition();

      final timestamp = position?.timestamp;

      if (timestamp == null ||
          DateTime.now().difference(timestamp).abs() >
              const Duration(minutes: 5)) {
        position = null;
      }
    }

    if (position == null) {
      for (final item in desired) {
        await _writePresence(
          uid: uid,
          item: item,
          state: 'unknown',
          event: 'location_unavailable',
        );
      }

      return;
    }

    for (final item in desired) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        item.latitude,
        item.longitude,
      );

      await _writePresence(
        uid: uid,
        item: item,
        state: distance <= item.radiusMeters
            ? 'inside'
            : 'outside',
        event: 'initial_sync',
      );
    }
  }

  static Future<void> _writePresence({
    required String uid,
    required _DesiredGeofence item,
    required String state,
    required String event,
  }) {
    return FirebaseDatabase.instance
        .ref(
      'accounts/$uid/homePresence/${item.homeId}',
    )
        .set({
      'ownerUid': item.ownerUid,
      'homeId': item.homeId,
      'state': state,
      'event': event,
      'source': 'native_geofence',
      'updatedAt': ServerValue.timestamp,
    });
  }

  static String buildGeofenceId({
    required String uid,
    required String ownerUid,
    required String homeId,
  }) {
    return [
      _autoAwayGeofencePrefix,
      uid,
      ownerUid,
      homeId,
    ].join('|');
  }

  static AutoAwayGeofenceIdentity? parseGeofenceId(
    String rawId,
  ) {
    final parts = rawId.split('|');

    if (parts.length != 4 ||
        parts.first != _autoAwayGeofencePrefix) {
      return null;
    }

    final uid = parts[1].trim();
    final ownerUid = parts[2].trim();
    final homeId = parts[3].trim();

    if (uid.isEmpty || ownerUid.isEmpty || homeId.isEmpty) {
      return null;
    }

    return AutoAwayGeofenceIdentity(
      uid: uid,
      ownerUid: ownerUid,
      homeId: homeId,
    );
  }

  static String _buildSignature(
    Map<String, _DesiredGeofence> desired,
    LocationPermission permission,
  ) {
    final items = desired.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return [
      permission.name,
      for (final item in items)
        '${item.id}:${item.latitude}:${item.longitude}:${item.radiusMeters}',
    ].join(';');
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return <String, dynamic>{};
  }

  static double? _asDouble(dynamic raw) {
    if (raw is num) {
      return raw.toDouble();
    }

    return double.tryParse(raw?.toString() ?? '');
  }
}

class AutoAwayGeofenceIdentity {
  const AutoAwayGeofenceIdentity({
    required this.uid,
    required this.ownerUid,
    required this.homeId,
  });

  final String uid;
  final String ownerUid;
  final String homeId;
}

class _DesiredGeofence {
  const _DesiredGeofence({
    required this.id,
    required this.ownerUid,
    required this.homeId,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final String id;
  final String ownerUid;
  final String homeId;
  final double latitude;
  final double longitude;
  final double radiusMeters;
}
