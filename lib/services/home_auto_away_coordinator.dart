import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../helpers/home_helper.dart';
import 'auto_away_service.dart';
import 'platform/platform_auto_away_task_service.dart';

typedef HomeAutoAwayHomesProvider = Map<String, dynamic> Function();

class HomeAutoAwayCoordinator {
  Timer? _presenceRefreshTimer;

  bool hasEnabledAutoAwayHome(Map<String, dynamic> homes) {
    for (final rawHome in homes.values) {
      final home = safeMap(rawHome);
      final autoAway = safeMap(home['autoAway']);

      if (autoAway['enabled'] == true &&
          autoAway['latitude'] is num &&
          autoAway['longitude'] is num) {
        return true;
      }
    }

    return false;
  }

  void refreshPresenceNow({
    required String uid,
    required Map<String, dynamic> homes,
    Position? position,
    String event = 'foreground_check',
  }) {
    if (uid.isEmpty || homes.isEmpty) {
      return;
    }

    unawaited(
      AutoAwayService.refreshPresenceForHomes(
        uid: uid,
        homes: homes,
        position: position,
        event: event,
      ).catchError((Object error) {
        debugPrint('AUTO_AWAY_PERIODIC_LOCATION_ERROR: $error');
      }),
    );
  }

  void startPresenceRefreshTimer({
    required String uid,
    required HomeAutoAwayHomesProvider homesProvider,
  }) {
    _presenceRefreshTimer?.cancel();

    // Kiểm tra ngay khi bắt đầu.
    refreshPresenceNow(uid: uid, homes: homesProvider());

    _presenceRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshPresenceNow(uid: uid, homes: homesProvider());
    });
  }

  Future<void> syncLocationMonitoring({
    required String uid,
    required HomeAutoAwayHomesProvider homesProvider,
  }) async {
    if (uid.isEmpty) {
      return;
    }

    final homes = homesProvider();

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      if (!hasEnabledAutoAwayHome(homes)) {
        _presenceRefreshTimer?.cancel();
        _presenceRefreshTimer = null;
        return;
      }

      startPresenceRefreshTimer(uid: uid, homesProvider: homesProvider);
      return;
    }

    _presenceRefreshTimer?.cancel();
    _presenceRefreshTimer = null;

    try {
      await PlatformAutoAwayTaskService.syncForHomes(uid: uid, homes: homes);
    } catch (error) {
      debugPrint('AUTO_AWAY_FOREGROUND_TASK_SYNC_ERROR: $error');
    }
  }

  void stopPresenceRefreshTimerForBackgroundIfNeeded() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _presenceRefreshTimer?.cancel();
      _presenceRefreshTimer = null;
    }
  }

  void dispose() {
    _presenceRefreshTimer?.cancel();
    _presenceRefreshTimer = null;
  }
}
