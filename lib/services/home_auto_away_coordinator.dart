import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../helpers/home_helper.dart';
import 'auto_away_service.dart';
import 'platform/platform_auto_away_task_service.dart';
import 'package:safehome_app/helpers/debug_log.dart';

typedef HomeAutoAwayHomesProvider = Map<String, dynamic> Function();

class HomeAutoAwayCoordinator {
  static const Duration _androidForegroundConfirmInterval = Duration(
    minutes: 2,
  );

  Timer? _presenceRefreshTimer;
  DateTime? _lastAndroidForegroundConfirmAt;

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
        safeDebugPrint('AUTO_AWAY_PERIODIC_LOCATION_ERROR: $error');
      }),
    );
  }

  void startPresenceRefreshTimer({
    required String uid,
    required HomeAutoAwayHomesProvider homesProvider,
    String immediateEvent = 'foreground_check',
  }) {
    _presenceRefreshTimer?.cancel();

    // Kiểm tra ngay khi bắt đầu.
    refreshPresenceNow(uid: uid, homes: homesProvider(), event: immediateEvent);

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

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final hasEnabledHome = hasEnabledAutoAwayHome(homes);

      _presenceRefreshTimer?.cancel();
      _presenceRefreshTimer = null;

      try {
        await PlatformAutoAwayTaskService.syncForHomes(uid: uid, homes: homes);
      } catch (error) {
        safeDebugPrint('AUTO_AWAY_FOREGROUND_TASK_SYNC_ERROR: $error');
      }

      final lastConfirmAt = _lastAndroidForegroundConfirmAt;
      final now = DateTime.now();
      final canConfirm =
          lastConfirmAt == null ||
          now.difference(lastConfirmAt) >= _androidForegroundConfirmInterval;

      if (hasEnabledHome && canConfirm) {
        _lastAndroidForegroundConfirmAt = now;

        try {
          await AutoAwayService.refreshPresenceForHomes(
            uid: uid,
            homes: homes,
            event: 'android_foreground_confirm',
          );
        } catch (error) {
          safeDebugPrint('AUTO_AWAY_ANDROID_FOREGROUND_CONFIRM_ERROR: $error');
        }
      }

      return;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final hasEnabledHome = hasEnabledAutoAwayHome(homes);

      if (!hasEnabledHome) {
        _presenceRefreshTimer?.cancel();
        _presenceRefreshTimer = null;

        try {
          await AutoAwayService.syncForHomes(
            uid: uid,
            homes: homes,
            force: true,
          );
        } catch (error) {
          safeDebugPrint('AUTO_AWAY_IOS_CLEANUP_SYNC_ERROR: $error');
        }

        return;
      }

      try {
        await AutoAwayService.syncForHomes(uid: uid, homes: homes, force: true);
      } catch (error) {
        safeDebugPrint('AUTO_AWAY_IOS_SYNC_ERROR: $error');
      }

      startPresenceRefreshTimer(
        uid: uid,
        homesProvider: homesProvider,
        immediateEvent: 'ios_foreground_confirm',
      );
      return;
    }

    if (!hasEnabledAutoAwayHome(homes)) {
      _presenceRefreshTimer?.cancel();
      _presenceRefreshTimer = null;
      return;
    }

    startPresenceRefreshTimer(uid: uid, homesProvider: homesProvider);
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
