import 'dart:async';

import 'package:flutter/material.dart';

import '../helpers/home_helper.dart';
import 'home_service.dart';
import 'home_state_parser.dart';
import 'package:safehome_app/helpers/debug_log.dart';
class HomeSelectionStateResult {
  const HomeSelectionStateResult({
    required this.homeOrder,
    required this.selectedHome,
    required this.selectedRoomId,
    required this.securityMode,
    required this.alarmPauseToday,
    required this.alarmEnabled,
    required this.start,
    required this.end,
  });

  final List<String> homeOrder;
  final String selectedHome;
  final String selectedRoomId;
  final String securityMode;
  final Map<String, dynamic> alarmPauseToday;
  final bool alarmEnabled;
  final TimeOfDay start;
  final TimeOfDay end;
}

class HomeSelectionStateService {
  String _ensuredRoomModelKey = "";

  Map<String, dynamic> ownedHomesForState({
    required Set<String> ownedHomeIds,
    required Map<String, dynamic> homes,
  }) {
    final result = <String, dynamic>{};

    for (final homeId in ownedHomeIds) {
      if (homes.containsKey(homeId)) {
        result[homeId] = homes[homeId];
      }
    }

    return result;
  }

  Map<String, dynamic> loadedSharedHomesForState({
    required Map<String, dynamic> sharedHomesSnapshot,
    required Map<String, dynamic> homes,
  }) {
    final result = <String, dynamic>{};

    for (final entry in sharedHomesSnapshot.entries) {
      final homeId = entry.key.toString();
      final home = safeMap(homes[homeId]);

      if (home['_shared'] == true) {
        result[homeId] = entry.value;
      }
    }

    return result;
  }

  HomeSelectionStateResult rebuildHomeOrderAndSelection({
    required Object? savedHomeOrder,
    required Set<String> ownedHomeIds,
    required Map<String, dynamic> sharedHomesSnapshot,
    required Map<String, dynamic> homes,
    required String selectedHome,
    required String selectedRoomId,
    required Map<String, dynamic> alarmSettings,
  }) {
    final ownedHomes = ownedHomesForState(
      ownedHomeIds: ownedHomeIds,
      homes: homes,
    );
    final sharedHomes = loadedSharedHomesForState(
      sharedHomesSnapshot: sharedHomesSnapshot,
      homes: homes,
    );

    final account = <String, dynamic>{};

    if (savedHomeOrder != null) {
      account['homeOrder'] = savedHomeOrder;
    }

    final homeOrder = HomeStateParser.parseHomeOrder(
      account: account,
      homesData: ownedHomes,
      sharedHomes: sharedHomes,
      selectedHome: selectedHome,
    );

    if (homeOrder.isEmpty) {
      return const HomeSelectionStateResult(
        homeOrder: <String>[],
        selectedHome: '',
        selectedRoomId: 'overview',
        securityMode: 'normal',
        alarmPauseToday: <String, dynamic>{},
        alarmEnabled: true,
        start: TimeOfDay(hour: 23, minute: 0),
        end: TimeOfDay(hour: 6, minute: 0),
      );
    }

    var nextSelectedHome = selectedHome;
    var nextSelectedRoomId = selectedRoomId;

    if (!homeOrder.contains(nextSelectedHome)) {
      nextSelectedHome = homeOrder.first;
      nextSelectedRoomId = 'overview';
    }

    final currentHome = safeMap(homes[nextSelectedHome]);
    final parsedAlarm = HomeStateParser.parseAlarm(currentHome);

    return HomeSelectionStateResult(
      homeOrder: homeOrder,
      selectedHome: nextSelectedHome,
      selectedRoomId: nextSelectedRoomId,
      securityMode: normalizeSecurityMode(currentHome['securityMode']),
      alarmPauseToday: safeMap(currentHome['alarmPauseToday']),
      alarmEnabled:
          safeMap(alarmSettings[nextSelectedHome])['enabled'] != false,
      start: parsedAlarm['start'],
      end: parsedAlarm['end'],
    );
  }

  void ensureSelectedHomeRoomModel({
    required String selectedHome,
    required bool canManageHome,
    required String ownerUid,
  }) {
    if (selectedHome.isEmpty || !canManageHome) {
      return;
    }

    final key = '$ownerUid/$selectedHome';

    if (_ensuredRoomModelKey == key) {
      return;
    }

    _ensuredRoomModelKey = key;

    unawaited(
      HomeService.ensureHomeRoomModel(
        ownerUid: ownerUid,
        homeId: selectedHome,
      ).catchError((Object error) {
        safeDebugPrint('ENSURE_HOME_ROOM_MODEL_ERROR: $error');
      }),
    );
  }

  String autoAwayConfigSignature(Map<String, dynamic> home) {
    final autoAway = safeMap(home['autoAway']);

    return [
      autoAway['enabled'] == true,
      autoAway['latitude'],
      autoAway['longitude'],
      autoAway['radiusMeters'],
    ].join('|');
  }
}
