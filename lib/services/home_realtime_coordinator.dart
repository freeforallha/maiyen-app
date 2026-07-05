import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../helpers/home_helper.dart';
import '../localization/app_strings.dart';
import 'chat_service.dart';
import 'device_notification_event_service.dart';
import 'package:safehome_app/helpers/debug_log.dart';
typedef HomeNotificationUnreadChanged = void Function(int count);
typedef HomeEventsChanged = void Function(Map<String, dynamic> events);
typedef HomeAlarmPauseCleared = void Function();
typedef HomeAlarmPauseChanged =
    void Function(HomeRealtimeAlarmPauseUpdate update);
typedef HomeChatUnreadChanged =
    void Function(HomeRealtimeChatUnreadSnapshot snapshot);
typedef HomeDeviceNotificationChanged =
    void Function(HomeRealtimeDeviceNotification notification);
typedef HomePresenceChanged =
    void Function({
      required String homeId,
      required Map<String, dynamic> presenceSummary,
      required Map<String, dynamic> memberPresenceStatus,
    });

class HomeRealtimeAlarmPauseUpdate {
  const HomeRealtimeAlarmPauseUpdate({
    required this.homeId,
    required this.alarmPauseToday,
  });

  final String homeId;
  final Map<String, dynamic> alarmPauseToday;
}

class HomeRealtimeChatUnreadSnapshot {
  const HomeRealtimeChatUnreadSnapshot({
    required this.unreadByHome,
    required this.total,
  });

  final Map<String, int> unreadByHome;
  final int total;
}

class HomeRealtimeDeviceNotification {
  const HomeRealtimeDeviceNotification({
    required this.homeId,
    required this.homeName,
    required this.deviceId,
    required this.device,
    required this.deviceName,
    required this.event,
  });

  final String homeId;
  final String homeName;
  final String deviceId;
  final Map<String, dynamic> device;
  final String deviceName;
  final Map<String, String> event;
}

class _HomePresenceListenState {
  _HomePresenceListenState({
    required this.ownerUid,
  });

  String ownerUid;
  StreamSubscription<DatabaseEvent>? sharedMembersSubscription;
  StreamSubscription<DatabaseEvent>? fallbackMemberStatusSubscription;
  bool sharedMembersPrimed = false;
  bool fallbackMemberStatusPrimed = false;
  String fallbackMemberStatusOwnerUid = "";
  final Set<String> sharedMemberUids = <String>{};
  final Set<String> memberUids = <String>{};
  final Set<String> primedMemberUids = <String>{};
  final Map<String, StreamSubscription<DatabaseEvent>> memberSubscriptions = {};
  final Map<String, Map<String, dynamic>> rawPresenceByMember = {};
  final Map<String, Map<String, dynamic>> fallbackPresenceByMember = {};
  String lastEmittedSignature = "";

  void cancel() {
    sharedMembersSubscription?.cancel();
    fallbackMemberStatusSubscription?.cancel();

    for (final subscription in memberSubscriptions.values) {
      subscription.cancel();
    }

    sharedMembersSubscription = null;
    fallbackMemberStatusSubscription = null;
    sharedMembersPrimed = false;
    fallbackMemberStatusPrimed = false;
    fallbackMemberStatusOwnerUid = "";
    memberSubscriptions.clear();
    rawPresenceByMember.clear();
    fallbackPresenceByMember.clear();
    memberUids.clear();
    primedMemberUids.clear();
    sharedMemberUids.clear();
    lastEmittedSignature = "";
  }
}

class _HomePresenceSnapshot {
  const _HomePresenceSnapshot({
    required this.presenceSummary,
    required this.memberPresenceStatus,
    required this.signature,
  });

  final Map<String, dynamic> presenceSummary;
  final Map<String, dynamic> memberPresenceStatus;
  final String signature;
}

class HomeRealtimeCoordinator {
  static const Duration _presenceFreshnessLimit = Duration(minutes: 30);

  StreamSubscription<DatabaseEvent>? _notificationSubscription;
  StreamSubscription<DatabaseEvent>? _homeEventsSubscription;
  StreamSubscription<DatabaseEvent>? _alarmPauseSubscription;
  String _homeEventsListenKey = "";
  String _alarmPauseListenKey = "";
  StreamSubscription<DatabaseEvent>? _chatUnreadSubscription;
  String _chatUnreadListenUid = "";
  Map<String, int> _chatUnreadSnapshot = {};
  final Map<String, Map<String, Map<String, dynamic>>>
  _deviceNotificationSnapshots = {};
  final Set<String> _deviceNotificationPrimedHomes = {};
  final Map<String, _HomePresenceListenState> _homePresenceStates = {};
  Timer? _homePresenceRefreshTimer;
  HomePresenceChanged? _homePresenceChanged;

  void startNotificationUnreadListener({
    required String uid,
    required HomeNotificationUnreadChanged onUnreadChanged,
  }) {
    _notificationSubscription?.cancel();
    _notificationSubscription = FirebaseDatabase.instance
        .ref("accounts/$uid/notifications")
        .onValue
        .listen((event) {
          final data = event.snapshot.value;
          var count = 0;

          if (data is Map) {
            final map = Map<String, dynamic>.from(data);

            for (final item in map.values) {
              if (item is! Map) continue;

              final notification = Map<String, dynamic>.from(item);

              if (notification["read"] != true) {
                count++;
              }
            }
          }

          onUnreadChanged(count);
        });
  }

  void startHomeEventsListener({
    required String ownerUid,
    required String homeId,
    required HomeEventsChanged onHomeEventsChanged,
  }) {
    if (homeId.isEmpty) {
      _homeEventsSubscription?.cancel();
      _homeEventsSubscription = null;
      _homeEventsListenKey = "";
      return;
    }

    final listenKey = "$ownerUid/$homeId";

    if (_homeEventsListenKey == listenKey && _homeEventsSubscription != null) {
      return;
    }

    _homeEventsSubscription?.cancel();
    _homeEventsListenKey = listenKey;

    _homeEventsSubscription = FirebaseDatabase.instance
        .ref("accounts/$ownerUid/homes/$homeId/events")
        .limitToLast(50)
        .onValue
        .listen((event) {
          onHomeEventsChanged(safeMap(event.snapshot.value));
        });
  }

  void startAlarmPauseListener({
    required String ownerUid,
    required String homeId,
    required HomeAlarmPauseCleared onSelectedHomeCleared,
    required HomeAlarmPauseChanged onAlarmPauseChanged,
  }) {
    if (homeId.isEmpty) {
      _alarmPauseSubscription?.cancel();
      _alarmPauseSubscription = null;
      _alarmPauseListenKey = "";
      onSelectedHomeCleared();
      return;
    }

    final listenKey = "$ownerUid/$homeId";

    if (_alarmPauseListenKey == listenKey && _alarmPauseSubscription != null) {
      return;
    }

    _alarmPauseSubscription?.cancel();
    _alarmPauseListenKey = listenKey;

    _alarmPauseSubscription = FirebaseDatabase.instance
        .ref("accounts/$ownerUid/homes/$homeId/alarmPauseToday")
        .onValue
        .listen(
          (event) {
            if (_alarmPauseListenKey != listenKey) {
              return;
            }

            onAlarmPauseChanged(
              HomeRealtimeAlarmPauseUpdate(
                homeId: homeId,
                alarmPauseToday: safeMap(event.snapshot.value),
              ),
            );
          },
          onError: (Object error) {
            safeDebugPrint("ALARM_PAUSE_LISTENER_ERROR: $error");
          },
        );
  }

  void syncHomeChatListeners({
    required String uid,
    required Map<String, dynamic> homes,
    required HomeChatUnreadChanged onUnreadChanged,
  }) {
    if (uid.isEmpty) {
      return;
    }

    if (_chatUnreadSubscription != null && _chatUnreadListenUid == uid) {
      _emitChatUnreadSnapshot(homes: homes, onUnreadChanged: onUnreadChanged);
      return;
    }

    _chatUnreadSubscription?.cancel();
    _chatUnreadListenUid = uid;
    _chatUnreadSnapshot = {};

    _chatUnreadSubscription = ChatService.unreadCountersStream(uid).listen(
      (event) {
        final data = event.snapshot.value;
        final nextSnapshot = <String, int>{};

        if (data is Map) {
          final map = Map<String, dynamic>.from(data);

          for (final entry in map.entries) {
            final count = ChatService.unreadCounterCount(entry.value);

            if (count > 0) {
              nextSnapshot[entry.key.toString()] = count;
            }
          }
        }

        _chatUnreadSnapshot = nextSnapshot;
        _emitChatUnreadSnapshot(homes: homes, onUnreadChanged: onUnreadChanged);
      },
      onError: (Object error) {
        safeDebugPrint("CHAT_UNREAD_LISTENER_ERROR: $error");
        _chatUnreadSnapshot = {};
        _emitChatUnreadSnapshot(homes: homes, onUnreadChanged: onUnreadChanged);
      },
    );
  }

  void syncHomePresenceListeners({
    required String uid,
    required Map<String, dynamic> homes,
    required HomePresenceChanged onPresenceChanged,
  }) {
    if (uid.isEmpty) {
      _clearHomePresenceListeners();
      return;
    }

    _homePresenceChanged = onPresenceChanged;

    final activeHomeIds = homes.keys
        .map((homeId) => homeId.toString().trim())
        .where((homeId) => homeId.isNotEmpty)
        .toSet();

    final removedHomeIds = _homePresenceStates.keys
        .where((homeId) => !activeHomeIds.contains(homeId))
        .toList();

    for (final homeId in removedHomeIds) {
      _disposeHomePresenceState(homeId);
    }

    for (final entry in homes.entries) {
      final homeId = entry.key.toString().trim();

      if (homeId.isEmpty) {
        continue;
      }

      final home = safeMap(entry.value);
      final ownerUid = _presenceOwnerUidFor(uid: uid, home: home);
      final state = _homePresenceStates.putIfAbsent(
        homeId,
        () => _HomePresenceListenState(ownerUid: ownerUid),
      );

      state.ownerUid = ownerUid;

      _startSharedMembersPresenceListener(homeId: homeId, state: state);
      _startFallbackMemberStatusListener(homeId: homeId, state: state);
      _seedFallbackMemberStatusFromHome(home: home, state: state);
      _syncHomePresenceMembers(homeId: homeId, state: state, forceEmit: true);
    }

    _updateHomePresenceRefreshTimer();
  }

  String _presenceOwnerUidFor({
    required String uid,
    required Map<String, dynamic> home,
  }) {
    final ownerUid = home["_ownerUid"]?.toString().trim() ?? "";

    if (ownerUid.isNotEmpty) {
      return ownerUid;
    }

    if (home["_shared"] == true) {
      return "";
    }

    return uid;
  }

  void _startSharedMembersPresenceListener({
    required String homeId,
    required _HomePresenceListenState state,
  }) {
    if (state.sharedMembersSubscription != null) {
      return;
    }

    state.sharedMembersSubscription = FirebaseDatabase.instance
        .ref("sharedByHome/$homeId")
        .onValue
        .listen(
          (event) {
            final currentState = _homePresenceStates[homeId];

            if (!identical(currentState, state)) {
              return;
            }

            final sharedMembers = safeMap(event.snapshot.value).keys
                .map((memberUid) => memberUid.toString().trim())
                .where((memberUid) => memberUid.isNotEmpty)
                .toSet();

            state.sharedMemberUids
              ..clear()
              ..addAll(sharedMembers);
            state.sharedMembersPrimed = true;

            _syncHomePresenceMembers(homeId: homeId, state: state);
          },
          onError: (Object error) {
            safeDebugPrint("HOME_PRESENCE_MEMBERS_LISTENER_ERROR: $error");
            state.sharedMembersPrimed = true;
            _syncHomePresenceMembers(homeId: homeId, state: state);
          },
        );
  }

  void _seedFallbackMemberStatusFromHome({
    required Map<String, dynamic> home,
    required _HomePresenceListenState state,
  }) {
    final fallbackStatus = safeMap(home["memberPresenceStatus"]);

    for (final entry in fallbackStatus.entries) {
      final memberUid = entry.key.toString().trim();

      if (memberUid.isEmpty) {
        continue;
      }

      state.fallbackPresenceByMember[memberUid] = {
        ...safeMap(state.fallbackPresenceByMember[memberUid]),
        ...safeMap(entry.value),
      };
    }
  }

  void _startFallbackMemberStatusListener({
    required String homeId,
    required _HomePresenceListenState state,
  }) {
    final ownerUid = state.ownerUid.trim();

    if (ownerUid.isEmpty) {
      state.fallbackMemberStatusSubscription?.cancel();
      state.fallbackMemberStatusSubscription = null;
      state.fallbackMemberStatusOwnerUid = "";
      state.fallbackPresenceByMember.clear();
      state.fallbackMemberStatusPrimed = true;
      _syncHomePresenceMembers(homeId: homeId, state: state);
      return;
    }

    if (state.fallbackMemberStatusSubscription != null &&
        state.fallbackMemberStatusOwnerUid == ownerUid) {
      return;
    }

    state.fallbackMemberStatusSubscription?.cancel();
    state.fallbackMemberStatusSubscription = null;
    state.fallbackMemberStatusOwnerUid = ownerUid;
    state.fallbackMemberStatusPrimed = false;
    state.fallbackPresenceByMember.clear();

    state.fallbackMemberStatusSubscription = FirebaseDatabase.instance
        .ref("accounts/$ownerUid/homes/$homeId/memberPresenceStatus")
        .onValue
        .listen(
          (event) {
            final currentState = _homePresenceStates[homeId];

            if (!identical(currentState, state)) {
              return;
            }

            final fallbackPresence = <String, Map<String, dynamic>>{};
            final rawFallback = safeMap(event.snapshot.value);

            for (final entry in rawFallback.entries) {
              final memberUid = entry.key.toString().trim();

              if (memberUid.isEmpty) {
                continue;
              }

              fallbackPresence[memberUid] = safeMap(entry.value);
            }

            state.fallbackPresenceByMember
              ..clear()
              ..addAll(fallbackPresence);
            state.fallbackMemberStatusPrimed = true;

            _syncHomePresenceMembers(homeId: homeId, state: state);
          },
          onError: (Object error) {
            safeDebugPrint("HOME_MEMBER_PRESENCE_STATUS_LISTENER_ERROR: $error");
            state.fallbackMemberStatusPrimed = true;
            _syncHomePresenceMembers(homeId: homeId, state: state);
          },
        );
  }

  void _syncHomePresenceMembers({
    required String homeId,
    required _HomePresenceListenState state,
    bool forceEmit = false,
  }) {
    final desiredMemberUids = <String>{
      if (state.ownerUid.trim().isNotEmpty) state.ownerUid.trim(),
      ...state.sharedMemberUids,
      ...state.fallbackPresenceByMember.keys,
      ...state.rawPresenceByMember.keys,
    };

    final removedMemberUids = state.memberSubscriptions.keys
        .where((memberUid) => !desiredMemberUids.contains(memberUid))
        .toList();

    for (final memberUid in removedMemberUids) {
      state.memberSubscriptions.remove(memberUid)?.cancel();
      state.rawPresenceByMember.remove(memberUid);
      state.primedMemberUids.remove(memberUid);
    }

    state.memberUids
      ..clear()
      ..addAll(desiredMemberUids);

    for (final memberUid in desiredMemberUids) {
      if (state.memberSubscriptions.containsKey(memberUid)) {
        continue;
      }

      state.memberSubscriptions[memberUid] = FirebaseDatabase.instance
          .ref("accounts/$memberUid/homePresence/$homeId")
          .onValue
          .listen(
            (event) {
              final currentState = _homePresenceStates[homeId];

              if (!identical(currentState, state)) {
                return;
              }

              state.rawPresenceByMember[memberUid] =
                  safeMap(event.snapshot.value);
              state.primedMemberUids.add(memberUid);
              _emitHomePresence(homeId);
            },
            onError: (Object error) {
              safeDebugPrint("HOME_PRESENCE_LISTENER_ERROR: $error");

              state.rawPresenceByMember[memberUid] = <String, dynamic>{};
              state.primedMemberUids.add(memberUid);
              _emitHomePresence(homeId);
            },
          );
    }

    _emitHomePresence(homeId, force: forceEmit);
  }

  DateTime? _presenceTimestamp(Map<String, dynamic> rawPresence) {
    return parseLastSeen(
      rawPresence["lastConfirmedAt"] ??
          rawPresence["lastEventOccurredAt"] ??
          rawPresence["lastSeenAt"] ??
          rawPresence["lastLocationCheckAt"] ??
          rawPresence["updatedAt"],
    );
  }

  bool _hasFreshKnownPresence(
    Map<String, dynamic> rawPresence,
    DateTime now,
  ) {
    final rawState = rawPresence["state"]?.toString().trim().toLowerCase() ?? "";
    final lastSeenAt = _presenceTimestamp(rawPresence);
    final isKnownState = rawState == "inside" || rawState == "outside";

    if (!isKnownState || lastSeenAt == null) {
      return false;
    }

    return !lastSeenAt.toUtc().isBefore(
      now.toUtc().subtract(_presenceFreshnessLimit),
    );
  }

  Map<String, dynamic> _normalizeKnownPresence({
    required Map<String, dynamic> primaryPresence,
    required Map<String, dynamic> fallbackPresence,
    required bool usePrimary,
    required DateTime now,
  }) {
    final selectedPresence = usePrimary ? primaryPresence : fallbackPresence;
    final rawState =
        selectedPresence["state"]?.toString().trim().toLowerCase() ??
            "unknown";
    final lastSeenAt = _presenceTimestamp(selectedPresence);

    return <String, dynamic>{
      ...fallbackPresence,
      ...primaryPresence,
      "state": rawState,
      "online": true,
      "stale": false,
      "lastSeenAt": lastSeenAt?.millisecondsSinceEpoch,
      "presenceSource": usePrimary ? "homePresence" : "memberPresenceStatus",
    };
  }

  Map<String, dynamic> _normalizeMemberPresence({
    required Map<String, dynamic> primaryPresence,
    required Map<String, dynamic> fallbackPresence,
    required DateTime now,
  }) {
    if (_hasFreshKnownPresence(primaryPresence, now)) {
      return _normalizeKnownPresence(
        primaryPresence: primaryPresence,
        fallbackPresence: fallbackPresence,
        usePrimary: true,
        now: now,
      );
    }

    if (_hasFreshKnownPresence(fallbackPresence, now)) {
      return _normalizeKnownPresence(
        primaryPresence: primaryPresence,
        fallbackPresence: fallbackPresence,
        usePrimary: false,
        now: now,
      );
    }

    final lastSeenAt =
        _presenceTimestamp(primaryPresence) ?? _presenceTimestamp(fallbackPresence);

    return <String, dynamic>{
      ...fallbackPresence,
      ...primaryPresence,
      "state": "unknown",
      "online": false,
      "stale": true,
      "lastSeenAt": lastSeenAt?.millisecondsSinceEpoch,
      "presenceSource": primaryPresence.isNotEmpty
          ? "homePresence"
          : fallbackPresence.isNotEmpty
          ? "memberPresenceStatus"
          : "none",
    };
  }

  _HomePresenceSnapshot _buildHomePresenceSnapshot(
    _HomePresenceListenState state,
  ) {
    final now = DateTime.now();
    final memberUids = state.memberUids.toList()..sort();
    final memberPresenceStatus = <String, dynamic>{};
    var insideCount = 0;
    var outsideCount = 0;

    for (final memberUid in memberUids) {
      final status = _normalizeMemberPresence(
        primaryPresence:
            state.rawPresenceByMember[memberUid] ?? <String, dynamic>{},
        fallbackPresence:
            state.fallbackPresenceByMember[memberUid] ?? <String, dynamic>{},
        now: now,
      );

      memberPresenceStatus[memberUid] = status;

      if (status["state"] == "inside") {
        insideCount++;
      } else if (status["state"] == "outside") {
        outsideCount++;
      }
    }

    final totalMemberCount = memberUids.length;
    final knownLocationCount = insideCount + outsideCount;
    final unknownCount = totalMemberCount > knownLocationCount
        ? totalMemberCount - knownLocationCount
        : 0;
    final presenceSummary = <String, dynamic>{
      "insideCount": insideCount,
      "outsideCount": outsideCount,
      "unknownCount": unknownCount,
      "knownLocationCount": knownLocationCount,
      "totalMemberCount": totalMemberCount,
    };

    return _HomePresenceSnapshot(
      presenceSummary: presenceSummary,
      memberPresenceStatus: memberPresenceStatus,
      signature: _homePresenceSignature(
        presenceSummary: presenceSummary,
        memberPresenceStatus: memberPresenceStatus,
      ),
    );
  }

  String _homePresenceSignature({
    required Map<String, dynamic> presenceSummary,
    required Map<String, dynamic> memberPresenceStatus,
  }) {
    final parts = <String>[
      presenceSummary["insideCount"]?.toString() ?? "0",
      presenceSummary["outsideCount"]?.toString() ?? "0",
      presenceSummary["unknownCount"]?.toString() ?? "0",
      presenceSummary["knownLocationCount"]?.toString() ?? "0",
      presenceSummary["totalMemberCount"]?.toString() ?? "0",
    ];

    final memberUids = memberPresenceStatus.keys.toList()..sort();

    for (final memberUid in memberUids) {
      final status = safeMap(memberPresenceStatus[memberUid]);

      parts.add(
        [
          memberUid,
          status["state"]?.toString() ?? "unknown",
          status["online"]?.toString() ?? "false",
          status["stale"]?.toString() ?? "true",
          status["lastSeenAt"]?.toString() ?? "",
        ].join(":"),
      );
    }

    return parts.join("|");
  }

  void _emitHomePresence(String homeId, {bool force = false}) {
    final callback = _homePresenceChanged;
    final state = _homePresenceStates[homeId];

    if (callback == null || state == null) {
      return;
    }

    final allPresenceStreamsPrimed =
        state.sharedMembersPrimed &&
        state.fallbackMemberStatusPrimed &&
        state.memberUids.every(
          (memberUid) => state.primedMemberUids.contains(memberUid),
        );

    if (!allPresenceStreamsPrimed) {
      return;
    }

    final snapshot = _buildHomePresenceSnapshot(state);

    if (!force && state.lastEmittedSignature == snapshot.signature) {
      return;
    }

    state.lastEmittedSignature = snapshot.signature;

    callback(
      homeId: homeId,
      presenceSummary: snapshot.presenceSummary,
      memberPresenceStatus: snapshot.memberPresenceStatus,
    );
  }

  void _updateHomePresenceRefreshTimer() {
    if (_homePresenceStates.isEmpty) {
      _homePresenceRefreshTimer?.cancel();
      _homePresenceRefreshTimer = null;
      return;
    }

    _homePresenceRefreshTimer ??= Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        for (final homeId in _homePresenceStates.keys.toList()) {
          _emitHomePresence(homeId);
        }
      },
    );
  }

  void _disposeHomePresenceState(String homeId) {
    final state = _homePresenceStates.remove(homeId);
    state?.cancel();
  }

  void stopHomePresenceListeners() {
    _clearHomePresenceListeners();
  }

  void _clearHomePresenceListeners() {
    for (final state in _homePresenceStates.values) {
      state.cancel();
    }

    _homePresenceStates.clear();
    _homePresenceChanged = null;
    _homePresenceRefreshTimer?.cancel();
    _homePresenceRefreshTimer = null;
  }

  void syncDeviceNotificationBridge({
    required Map<String, dynamic> homes,
    required AppStrings strings,
    required String Function(String homeId) homeNameForId,
    required HomeDeviceNotificationChanged onDeviceNotification,
  }) {
    final activeHomeIds = homes.keys
        .where((id) => id.toString().isNotEmpty)
        .map((id) => id.toString())
        .toSet();

    _deviceNotificationSnapshots.removeWhere(
      (homeId, _) => !activeHomeIds.contains(homeId),
    );
    _deviceNotificationPrimedHomes.removeWhere(
      (homeId) => !activeHomeIds.contains(homeId),
    );

    for (final homeEntry in homes.entries) {
      final homeId = homeEntry.key.toString();
      final home = safeMap(homeEntry.value);
      final devices = safeMap(home["devices"]);
      final previousByDevice = _deviceNotificationSnapshots.putIfAbsent(
        homeId,
        () => <String, Map<String, dynamic>>{},
      );
      final homeWasPrimed = _deviceNotificationPrimedHomes.contains(homeId);
      final homeName = homeNameForId(homeId);

      previousByDevice.removeWhere(
        (deviceId, _) => !devices.containsKey(deviceId),
      );

      for (final deviceEntry in devices.entries) {
        final deviceId = deviceEntry.key.toString();
        final device = safeMap(deviceEntry.value);
        final deviceName = DeviceNotificationEventService.deviceName(
          deviceId,
          device,
        );
        final currentState = DeviceNotificationEventService.state(device);
        final previousState = previousByDevice[deviceId];

        previousByDevice[deviceId] = currentState;

        if (previousState == null) {
          if (homeWasPrimed) {
            onDeviceNotification(
              HomeRealtimeDeviceNotification(
                homeId: homeId,
                homeName: homeName,
                deviceId: deviceId,
                device: device,
                deviceName: deviceName,
                event: {
                  "type": "device_added",
                  "title": strings.t("Thiết bị mới"),
                  "message": strings.choose(
                    vi: "Thiết bị \"$deviceName\" đã xuất hiện trong \"$homeName\".",
                    en: "Device \"$deviceName\" was added to \"$homeName\".",
                  ),
                  "severity": "info",
                },
              ),
            );
          }

          continue;
        }

        final event = DeviceNotificationEventService.event(
          strings: strings,
          homeName: homeName,
          deviceId: deviceId,
          device: device,
          previous: previousState,
          current: currentState,
        );

        if (event == null) continue;

        onDeviceNotification(
          HomeRealtimeDeviceNotification(
            homeId: homeId,
            homeName: homeName,
            deviceId: deviceId,
            device: device,
            deviceName: deviceName,
            event: event,
          ),
        );
      }

      _deviceNotificationPrimedHomes.add(homeId);
    }
  }

  void _emitChatUnreadSnapshot({
    required Map<String, dynamic> homes,
    required HomeChatUnreadChanged onUnreadChanged,
  }) {
    final activeHomeIds = homes.keys
        .where((homeId) => homeId.toString().isNotEmpty)
        .map((homeId) => homeId.toString())
        .toSet();

    final nextUnreadByHome = <String, int>{};

    for (final entry in _chatUnreadSnapshot.entries) {
      if (activeHomeIds.contains(entry.key) && entry.value > 0) {
        nextUnreadByHome[entry.key] = entry.value;
      }
    }

    final nextTotal = nextUnreadByHome.values.fold<int>(
      0,
      (total, count) => total + count,
    );

    onUnreadChanged(
      HomeRealtimeChatUnreadSnapshot(
        unreadByHome: nextUnreadByHome,
        total: nextTotal,
      ),
    );
  }

  void dispose() {
    _notificationSubscription?.cancel();
    _homeEventsSubscription?.cancel();
    _alarmPauseSubscription?.cancel();
    _chatUnreadSubscription?.cancel();
    _notificationSubscription = null;
    _homeEventsSubscription = null;
    _alarmPauseSubscription = null;
    _chatUnreadSubscription = null;
    _homeEventsListenKey = "";
    _alarmPauseListenKey = "";
    _chatUnreadListenUid = "";
    _chatUnreadSnapshot = {};
    _deviceNotificationSnapshots.clear();
    _deviceNotificationPrimedHomes.clear();
    _clearHomePresenceListeners();
  }
}
