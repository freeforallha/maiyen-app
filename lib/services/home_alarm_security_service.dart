import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:safehome_app/helpers/debug_log.dart';

import '../localization/app_language_controller.dart';
import '../localization/app_strings.dart';
import 'home_notification_service.dart';

enum HomeSecurityRepeatStatus { saved, homeUnavailable, noPermission, failed }

class HomeSecurityRepeatResult {
  const HomeSecurityRepeatResult({
    required this.status,
    required this.normalizedMinutes,
  });

  final HomeSecurityRepeatStatus status;
  final int normalizedMinutes;
}

enum HomeSecurityModePlanStatus {
  ready,
  requiresManualConfirmation,
  unchanged,
  homeUnavailable,
  noPermission,
}

class HomeSecurityModePlan {
  const HomeSecurityModePlan({
    required this.status,
    required this.nextMode,
    required this.repeatMinutes,
  });

  final HomeSecurityModePlanStatus status;
  final String nextMode;
  final int repeatMinutes;
}

enum HomeSecurityModeSaveStatus { saved, failed }

class HomeSecurityModeSaveResult {
  const HomeSecurityModeSaveResult({
    required this.status,
    required this.nextMode,
  });

  final HomeSecurityModeSaveStatus status;
  final String nextMode;
}

enum HomeSecurityNotificationStatus { sent, failed }

enum HomeSecurityReauthStatus {
  success,
  cancelled,
  currentUserUnavailable,
  wrongPassword,
  failed,
}

class HomeSecurityReauthResult {
  const HomeSecurityReauthResult(this.status);

  final HomeSecurityReauthStatus status;
}

enum HomeAlarmTogglePlanStatus {
  ready,
  requiresDisableConfirmation,
  unchanged,
  homeUnavailable,
}

class HomeAlarmTogglePlan {
  const HomeAlarmTogglePlan({required this.status, required this.enabled});

  final HomeAlarmTogglePlanStatus status;
  final bool enabled;
}

enum HomeAlarmToggleSaveStatus { saved, failed }

class HomeAlarmToggleSaveResult {
  const HomeAlarmToggleSaveResult(this.status);

  final HomeAlarmToggleSaveStatus status;
}

class HomeAlarmSecurityService {
  int normalizeSecurityModeRepeatMinutes(dynamic value) {
    final minutes = int.tryParse(value?.toString() ?? "") ?? 0;

    return const <int>[0, 15, 30, 60].contains(minutes) ? minutes : 0;
  }

  Future<HomeSecurityRepeatResult> setSecurityModeRepeatMinutes({
    required String ownerUid,
    required String homeId,
    required bool canManageHome,
    required int minutes,
  }) async {
    final normalized = normalizeSecurityModeRepeatMinutes(minutes);

    if (homeId.isEmpty) {
      return HomeSecurityRepeatResult(
        status: HomeSecurityRepeatStatus.homeUnavailable,
        normalizedMinutes: normalized,
      );
    }

    if (!canManageHome) {
      return HomeSecurityRepeatResult(
        status: HomeSecurityRepeatStatus.noPermission,
        normalizedMinutes: normalized,
      );
    }

    try {
      await FirebaseDatabase.instance
          .ref("accounts/$ownerUid/homes/$homeId/securityModeRepeatMinutes")
          .set(normalized);

      return HomeSecurityRepeatResult(
        status: HomeSecurityRepeatStatus.saved,
        normalizedMinutes: normalized,
      );
    } catch (error) {
      safeDebugPrint("SET_SECURITY_MODE_REPEAT_ERROR: $error");

      return HomeSecurityRepeatResult(
        status: HomeSecurityRepeatStatus.failed,
        normalizedMinutes: normalized,
      );
    }
  }

  HomeSecurityModePlan planSecurityModeChange({
    required String homeId,
    required bool canManageHome,
    required String mode,
    required Map<String, dynamic> currentHome,
  }) {
    final nextMode = mode == "armed" ? "armed" : "normal";

    if (homeId.isEmpty) {
      return HomeSecurityModePlan(
        status: HomeSecurityModePlanStatus.homeUnavailable,
        nextMode: nextMode,
        repeatMinutes: 0,
      );
    }

    if (!canManageHome) {
      return HomeSecurityModePlan(
        status: HomeSecurityModePlanStatus.noPermission,
        nextMode: nextMode,
        repeatMinutes: 0,
      );
    }

    final currentMode = currentHome["securityMode"]?.toString() == "armed"
        ? "armed"
        : "normal";
    final currentSource =
        currentHome["securityModeSource"]?.toString().trim() ?? "";
    final repeatMinutes = normalizeSecurityModeRepeatMinutes(
      currentHome["securityModeRepeatMinutes"],
    );

    if (currentMode == nextMode) {
      if (nextMode == "normal" || currentSource == "manual") {
        return HomeSecurityModePlan(
          status: HomeSecurityModePlanStatus.unchanged,
          nextMode: nextMode,
          repeatMinutes: repeatMinutes,
        );
      }
    }

    return HomeSecurityModePlan(
      status: nextMode == "armed"
          ? HomeSecurityModePlanStatus.requiresManualConfirmation
          : HomeSecurityModePlanStatus.ready,
      nextMode: nextMode,
      repeatMinutes: repeatMinutes,
    );
  }

  Future<HomeSecurityModeSaveResult> setSecurityMode({
    required String ownerUid,
    required String homeId,
    required String nextMode,
  }) async {
    try {
      await FirebaseDatabase.instance.ref().update({
        "accounts/$ownerUid/homes/$homeId/securityMode": nextMode,

        // Chuyển về normal phải xoá nguồn manual.
        "accounts/$ownerUid/homes/$homeId/securityModeSource":
            nextMode == "armed" ? "manual" : null,
      });

      return HomeSecurityModeSaveResult(
        status: HomeSecurityModeSaveStatus.saved,
        nextMode: nextMode,
      );
    } catch (error) {
      safeDebugPrint("SET_SECURITY_MODE_ERROR: $error");

      return HomeSecurityModeSaveResult(
        status: HomeSecurityModeSaveStatus.failed,
        nextMode: nextMode,
      );
    }
  }

  Future<HomeSecurityNotificationStatus> notifyManualSecurityModeEnabled({
    required String ownerUid,
    required String homeId,
    required String homeName,
    required String actorUid,
    required String actorName,
    required int securityModeRepeatMinutes,
  }) async {
    try {
      final strings = AppStrings.fromLocale(appLanguageController.locale);

      await HomeNotificationService.notifyHome(
        ownerUid: ownerUid,
        homeId: homeId,
        homeName: homeName,
        type: "manual_security_mode_enabled",
        category: "home",
        severity: "warning",
        title: strings.manualSecurityModeEnabledTitle(),
        message: strings.manualSecurityModeEnabledMessage(
          actorName: actorName,
          homeName: homeName,
          securityModeRepeatMinutes: securityModeRepeatMinutes,
        ),
        actorUid: actorUid,
        entityType: "home",
        entityId: homeId,
        includeActor: true,
        writeHomeTimeline: true,
        data: {
          "type": "manual_security_mode_enabled",
          "actorName": actorName,
          "homeName": homeName,
          "securityMode": "armed",
          "securityModeSource": "manual",
          "securityModeRepeatMinutes": securityModeRepeatMinutes,
        },
      );

      return HomeSecurityNotificationStatus.sent;
    } catch (error) {
      safeDebugPrint("MANUAL_SECURITY_NOTIFICATION_ERROR: $error");

      return HomeSecurityNotificationStatus.failed;
    }
  }

  Future<HomeSecurityReauthResult> reauthenticateForManualSecurityMode({
    required String password,
  }) async {
    if (password.isEmpty) {
      return const HomeSecurityReauthResult(HomeSecurityReauthStatus.cancelled);
    }

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.trim() ?? "";

    if (user == null || email.isEmpty) {
      return const HomeSecurityReauthResult(
        HomeSecurityReauthStatus.currentUserUnavailable,
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return const HomeSecurityReauthResult(HomeSecurityReauthStatus.success);
    } on FirebaseAuthException catch (error) {
      final wrongPassword =
          error.code == "wrong-password" ||
          error.code == "invalid-credential" ||
          error.code == "invalid-login-credentials";

      return HomeSecurityReauthResult(
        wrongPassword
            ? HomeSecurityReauthStatus.wrongPassword
            : HomeSecurityReauthStatus.failed,
      );
    } catch (error) {
      safeDebugPrint("MANUAL_SECURITY_REAUTH_ERROR: $error");

      return const HomeSecurityReauthResult(HomeSecurityReauthStatus.failed);
    }
  }

  HomeAlarmTogglePlan planAlarmEnabled({
    required String homeId,
    required bool currentEnabled,
    required bool nextEnabled,
  }) {
    if (homeId.isEmpty) {
      return HomeAlarmTogglePlan(
        status: HomeAlarmTogglePlanStatus.homeUnavailable,
        enabled: nextEnabled,
      );
    }

    if (currentEnabled == nextEnabled) {
      return HomeAlarmTogglePlan(
        status: HomeAlarmTogglePlanStatus.unchanged,
        enabled: nextEnabled,
      );
    }

    return HomeAlarmTogglePlan(
      status: nextEnabled
          ? HomeAlarmTogglePlanStatus.ready
          : HomeAlarmTogglePlanStatus.requiresDisableConfirmation,
      enabled: nextEnabled,
    );
  }

  Future<HomeAlarmToggleSaveResult> setAlarmEnabled({
    required String uid,
    required String homeId,
    required bool enabled,
  }) async {
    try {
      await FirebaseDatabase.instance
          .ref(
            "accounts/$uid/alarmSettings/"
            "$homeId/enabled",
          )
          .set(enabled);

      return const HomeAlarmToggleSaveResult(HomeAlarmToggleSaveStatus.saved);
    } catch (error) {
      safeDebugPrint("SET_ALARM_ENABLED_ERROR: $error");

      return const HomeAlarmToggleSaveResult(HomeAlarmToggleSaveStatus.failed);
    }
  }

  Future<void> recordAlarmEnabledNotification({
    required String uid,
    required String homeId,
    required String homeName,
    required bool enabled,
    required AppStrings strings,
  }) async {
    await HomeNotificationService.addNotification(
      uid: uid,
      type: "alarm_setting_changed",
      title: strings.alarmSettingChangedTitle(enabled),
      message: strings.alarmSettingChangedMessage(
        enabled: enabled,
        homeName: homeName,
      ),
      homeId: homeId,
      homeName: homeName,
      data: {
        "type": "alarm_setting_changed",
        "alarmEnabled": enabled,
        "homeName": homeName,
      },
    );
  }
}
