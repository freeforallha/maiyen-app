import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../helpers/firebase_paths.dart';
import '../helpers/home_helper.dart';
import 'package:safehome_app/helpers/debug_log.dart';

class HomeListenerService {
  final Map<String, StreamSubscription<DatabaseEvent>> _subscriptions = {};
  final Map<String, String> _ownerUidByHome = {};
  final Map<String, Map<String, dynamic>> _sharedConfigByHome = {};
  final Map<String, Map<String, dynamic>> _latestHomeDataByHome = {};

  Map<String, dynamic> _decorateSharedHome({
    required String homeId,
    required Map<String, dynamic> home,
  }) {
    final sharedConfig = _sharedConfigByHome[homeId] ?? {};
    final ownerUid = _ownerUidByHome[homeId] ?? '';

    return {
      ...home,
      'alarm': safeMap(home['alarm']),
      '_shared': true,
      '_ownerUid': ownerUid,
      '_ownerEmail': sharedConfig['ownerEmail']?.toString() ?? '',
      '_customName': sharedConfig['customName'],
      '_customAlarm': sharedConfig['alarm'],
      '_role': sharedConfig['role']?.toString() ?? 'member',
    };
  }

  void syncSharedHomes({
    required Map<String, dynamic> sharedHomes,
    required void Function(String homeId, Map<String, dynamic> home) onChanged,
    required void Function(String homeId) onDeleted,
  }) {
    final desiredHomeIds = sharedHomes.keys
        .map((key) => key.toString())
        .where((homeId) => homeId.isNotEmpty)
        .toSet();

    final removedHomeIds = _subscriptions.keys
        .where((homeId) => !desiredHomeIds.contains(homeId))
        .toList();

    for (final homeId in removedHomeIds) {
      unawaited(_subscriptions.remove(homeId)?.cancel());
      _ownerUidByHome.remove(homeId);
      _sharedConfigByHome.remove(homeId);
      _latestHomeDataByHome.remove(homeId);
      onDeleted(homeId);
    }

    for (final entry in sharedHomes.entries) {
      final homeId = entry.key.toString().trim();
      final sharedConfig = safeMap(entry.value);
      final ownerUid = sharedConfig['ownerUid']?.toString().trim() ?? '';

      if (homeId.isEmpty || ownerUid.isEmpty) {
        continue;
      }

      final previousOwnerUid = _ownerUidByHome[homeId];
      final ownerChanged =
          previousOwnerUid != null && previousOwnerUid != ownerUid;

      _sharedConfigByHome[homeId] = sharedConfig;
      _ownerUidByHome[homeId] = ownerUid;

      if (ownerChanged) {
        unawaited(_subscriptions.remove(homeId)?.cancel());
        _latestHomeDataByHome.remove(homeId);
      }

      final cachedHome = _latestHomeDataByHome[homeId];

      if (cachedHome != null && !ownerChanged) {
        onChanged(
          homeId,
          _decorateSharedHome(homeId: homeId, home: cachedHome),
        );
      }

      if (_subscriptions.containsKey(homeId)) {
        continue;
      }

      _subscriptions[homeId] = FirebaseDatabase.instance
          .ref(FirebasePaths.home(ownerUid, homeId))
          .onValue
          .listen(
            (event) {
              final rawHome = event.snapshot.value;

              if (rawHome == null) {
                _latestHomeDataByHome.remove(homeId);
                onDeleted(homeId);
                return;
              }

              final homeData = safeMap(rawHome);
              _latestHomeDataByHome[homeId] = homeData;

              onChanged(
                homeId,
                _decorateSharedHome(homeId: homeId, home: homeData),
              );
            },
            onError: (Object error) {
              safeDebugPrint('SHARED_HOME_LISTENER_ERROR: $error');
            },
          );
    }
  }

  Future<void> dispose() async {
    final subscriptions = _subscriptions.values.toList();

    _subscriptions.clear();
    _ownerUidByHome.clear();
    _sharedConfigByHome.clear();
    _latestHomeDataByHome.clear();

    await Future.wait(
      subscriptions.map((subscription) => subscription.cancel()),
    );
  }
}
