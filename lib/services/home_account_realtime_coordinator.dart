import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../helpers/firebase_paths.dart';
import '../helpers/home_helper.dart';

typedef HomeAccountProfileChanged = void Function(Map<String, dynamic> profile);
typedef HomeAccountHomeChanged =
    void Function(String homeId, Map<String, dynamic> homeData);
typedef HomeAccountMapChanged = void Function(Map<String, dynamic> data);
typedef HomeAccountHomeOrderChanged = void Function(Object? rawOrder);

class HomeAccountRealtimeCoordinator {
  StreamSubscription<DatabaseEvent>? _profileSubscription;
  StreamSubscription<DatabaseEvent>? _ownedHomeAddedSubscription;
  StreamSubscription<DatabaseEvent>? _ownedHomeChangedSubscription;
  StreamSubscription<DatabaseEvent>? _ownedHomeRemovedSubscription;
  StreamSubscription<DatabaseEvent>? _sharedHomesSubscription;
  StreamSubscription<DatabaseEvent>? _homeOrderSubscription;
  StreamSubscription<DatabaseEvent>? _alarmSettingsSubscription;
  StreamSubscription<DatabaseEvent>? _customRulesSubscription;
  StreamSubscription<DatabaseEvent>? _shareRequestsSubscription;

  void start({
    required String uid,
    required HomeAccountProfileChanged onProfileChanged,
    required HomeAccountHomeChanged onOwnedHomeAdded,
    required HomeAccountHomeChanged onOwnedHomeChanged,
    required HomeAccountHomeChanged onOwnedHomeRemoved,
    required HomeAccountMapChanged onSharedHomesChanged,
    required HomeAccountHomeOrderChanged onHomeOrderChanged,
    required HomeAccountMapChanged onAlarmSettingsChanged,
    required HomeAccountMapChanged onCustomRulesChanged,
    required HomeAccountMapChanged onShareRequestsChanged,
  }) {
    dispose();

    _profileSubscription = FirebaseDatabase.instance
        .ref(FirebasePaths.profile(uid))
        .onValue
        .listen(
          (event) {
            onProfileChanged(safeMap(event.snapshot.value));
          },
          onError: (Object error) {
            debugPrint('PROFILE_LISTENER_ERROR: $error');
          },
        );

    final ownedHomesRef = FirebaseDatabase.instance.ref(
      FirebasePaths.homes(uid),
    );

    _ownedHomeAddedSubscription = ownedHomesRef.onChildAdded.listen(
      (event) {
        onOwnedHomeAdded(
          event.snapshot.key?.trim() ?? '',
          safeMap(event.snapshot.value),
        );
      },
      onError: (Object error) {
        debugPrint('OWNED_HOME_ADDED_LISTENER_ERROR: $error');
      },
    );

    _ownedHomeChangedSubscription = ownedHomesRef.onChildChanged.listen(
      (event) {
        onOwnedHomeChanged(
          event.snapshot.key?.trim() ?? '',
          safeMap(event.snapshot.value),
        );
      },
      onError: (Object error) {
        debugPrint('OWNED_HOME_CHANGED_LISTENER_ERROR: $error');
      },
    );

    _ownedHomeRemovedSubscription = ownedHomesRef.onChildRemoved.listen(
      (event) {
        onOwnedHomeRemoved(
          event.snapshot.key?.trim() ?? '',
          safeMap(event.snapshot.value),
        );
      },
      onError: (Object error) {
        debugPrint('OWNED_HOME_REMOVED_LISTENER_ERROR: $error');
      },
    );

    _sharedHomesSubscription = FirebaseDatabase.instance
        .ref(FirebasePaths.sharedHomes(uid))
        .onValue
        .listen(
          (event) {
            onSharedHomesChanged(safeMap(event.snapshot.value));
          },
          onError: (Object error) {
            debugPrint('SHARED_HOMES_LISTENER_ERROR: $error');
          },
        );

    _homeOrderSubscription = FirebaseDatabase.instance
        .ref(FirebasePaths.homeOrder(uid))
        .onValue
        .listen(
          (event) {
            onHomeOrderChanged(event.snapshot.value);
          },
          onError: (Object error) {
            debugPrint('HOME_ORDER_LISTENER_ERROR: $error');
          },
        );

    _alarmSettingsSubscription = FirebaseDatabase.instance
        .ref(FirebasePaths.alarmSettings(uid))
        .onValue
        .listen(
          (event) {
            onAlarmSettingsChanged(safeMap(event.snapshot.value));
          },
          onError: (Object error) {
            debugPrint('ALARM_SETTINGS_LISTENER_ERROR: $error');
          },
        );

    _customRulesSubscription = FirebaseDatabase.instance
        .ref(FirebasePaths.customRules(uid))
        .onValue
        .listen(
          (event) {
            onCustomRulesChanged(safeMap(event.snapshot.value));
          },
          onError: (Object error) {
            debugPrint('CUSTOM_RULES_LISTENER_ERROR: $error');
          },
        );

    _shareRequestsSubscription = FirebaseDatabase.instance
        .ref(FirebasePaths.shareRequests(uid))
        .onValue
        .listen(
          (event) {
            onShareRequestsChanged(safeMap(event.snapshot.value));
          },
          onError: (Object error) {
            debugPrint('SHARE_REQUESTS_LISTENER_ERROR: $error');
          },
        );
  }

  void dispose() {
    _profileSubscription?.cancel();
    _ownedHomeAddedSubscription?.cancel();
    _ownedHomeChangedSubscription?.cancel();
    _ownedHomeRemovedSubscription?.cancel();
    _sharedHomesSubscription?.cancel();
    _homeOrderSubscription?.cancel();
    _alarmSettingsSubscription?.cancel();
    _customRulesSubscription?.cancel();
    _shareRequestsSubscription?.cancel();
    _profileSubscription = null;
    _ownedHomeAddedSubscription = null;
    _ownedHomeChangedSubscription = null;
    _ownedHomeRemovedSubscription = null;
    _sharedHomesSubscription = null;
    _homeOrderSubscription = null;
    _alarmSettingsSubscription = null;
    _customRulesSubscription = null;
    _shareRequestsSubscription = null;
  }
}
