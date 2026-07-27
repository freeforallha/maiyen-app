import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'account_session_service.dart';
import 'auto_away_service.dart';
import 'auto_login_service.dart';
import 'fcm_service.dart';
import 'platform/platform_auto_away_task_service.dart';
import 'single_device_session_service.dart';
import 'package:maiyen_app/helpers/debug_log.dart';

class SessionLogoutService {
  const SessionLogoutService._();

  static final ValueNotifier<int> forcedLogoutNoticeRevision =
      ValueNotifier<int>(0);
  static bool _forcedLogoutNoticePending = false;

  static bool consumeForcedLogoutNotice() {
    if (!_forcedLogoutNoticePending) {
      return false;
    }

    _forcedLogoutNoticePending = false;
    return true;
  }

  static void _publishForcedLogoutNotice() {
    _forcedLogoutNoticePending = true;
    forcedLogoutNoticeRevision.value++;
  }

  static Future<void> signOutCurrentUser({
    bool forcedByRemoteSession = false,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid.trim() ?? '';
      final shouldPublishForcedLogoutNotice =
          forcedByRemoteSession && user != null;
      final localSessionId = uid.isEmpty
          ? ''
          : await SingleDeviceSessionService.readLocalSessionId(uid: uid);

      await SingleDeviceSessionService.beginLocalLogout();

      if (uid.isNotEmpty) {
        try {
          await SingleDeviceSessionService.requireInteractiveLogin(uid: uid);
        } catch (error) {
          safeDebugPrint('MARK_INTERACTIVE_LOGIN_REQUIRED_ERROR: $error');
        }
        try {
          await PlatformAutoAwayTaskService.stop();
        } catch (error) {
          safeDebugPrint('AUTO_AWAY_FOREGROUND_TASK_STOP_ERROR: $error');
        }

        try {
          await AutoAwayService.prepareForLogout(
            uid: uid,
            writePresence: !forcedByRemoteSession,
          );
        } catch (error) {
          safeDebugPrint('AUTO_AWAY_PREPARE_LOGOUT_ERROR: $error');
        }

        // Đánh dấu session sau khi geofence đã được dọn.
        // Nếu callback geofence chạy đúng lúc đăng xuất, lần ghi
        // signed_out cuối cùng vẫn luôn là trạng thái thắng.
        try {
          await AccountSessionService.markSignedOut(
            uid: uid,
            sessionId: localSessionId,
          );
        } catch (error) {
          safeDebugPrint('MARK_ACCOUNT_SESSION_SIGNED_OUT_ERROR: $error');
        }

        try {
          await FCMService.removeCurrentInstallationToken(uid: uid);
        } catch (error) {
          safeDebugPrint('REMOVE_PUSH_REGISTRATION_ON_LOGOUT_ERROR: $error');
        }

        // Giữ lại activeSession như dấu vết phiên cuối cùng.
        // Nhờ đó thiết bị cũ đang offline không thể tự chiếm lại phiên
        // nếu thiết bị hiện tại đã đăng xuất.
      }

      try {
        await AutoLoginService.clearLogin();
      } catch (error) {
        safeDebugPrint('CLEAR_AUTO_LOGIN_ON_LOGOUT_ERROR: $error');
      }

      if (uid.isNotEmpty) {
        try {
          await SingleDeviceSessionService.clearLocalSession(uid: uid);
        } catch (error) {
          safeDebugPrint('CLEAR_LOCAL_SESSION_ON_LOGOUT_ERROR: $error');
        }
      }

      try {
        await AccountSessionService.deactivateLocal();
      } catch (error) {
        safeDebugPrint('DEACTIVATE_ACCOUNT_SESSION_ON_LOGOUT_ERROR: $error');
      }

      await FirebaseAuth.instance.signOut();

      if (shouldPublishForcedLogoutNotice) {
        _publishForcedLogoutNotice();
      }
    } finally {
      SingleDeviceSessionService.finishLocalLogout();
    }
  }
}
