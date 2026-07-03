import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../helpers/home_helper.dart';
import '../localization/app_strings.dart';
import 'chat_service.dart';
import 'device_notification_event_service.dart';

typedef HomeNotificationUnreadChanged = void Function(int count);
typedef HomeEventsChanged = void Function(Map<String, dynamic> events);
typedef HomeAlarmPauseCleared = void Function();
typedef HomeAlarmPauseChanged =
    void Function(HomeRealtimeAlarmPauseUpdate update);
typedef HomeChatUnreadChanged =
    void Function(HomeRealtimeChatUnreadSnapshot snapshot);
typedef HomeDeviceNotificationChanged =
    void Function(HomeRealtimeDeviceNotification notification);

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

class HomeRealtimeCoordinator {
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
            debugPrint("ALARM_PAUSE_LISTENER_ERROR: $error");
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
        debugPrint("CHAT_UNREAD_LISTENER_ERROR: $error");
        _chatUnreadSnapshot = {};
        _emitChatUnreadSnapshot(homes: homes, onUnreadChanged: onUnreadChanged);
      },
    );
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
  }
}
