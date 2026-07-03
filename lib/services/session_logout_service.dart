import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'account_session_service.dart';
import 'auto_away_service.dart';
import 'auto_login_service.dart';
import 'fcm_service.dart';
import 'platform/platform_auto_away_task_service.dart';

class SessionLogoutService {
  const SessionLogoutService._();

  static Future<void> signOutCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid.trim() ?? '';

    if (uid.isNotEmpty) {
      try {
        await PlatformAutoAwayTaskService.stop();
      } catch (error, stackTrace) {
        debugPrint('AUTO_AWAY_FOREGROUND_TASK_STOP_ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      try {
        await AutoAwayService.prepareForLogout(uid: uid);
      } catch (error, stackTrace) {
        debugPrint('AUTO_AWAY_PREPARE_LOGOUT_ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      // Đánh dấu session sau khi geofence đã được dọn.
      // Nếu callback geofence chạy đúng lúc đăng xuất, lần ghi
      // signed_out cuối cùng vẫn luôn là trạng thái thắng.
      try {
        await AccountSessionService.markSignedOut(uid: uid);
      } catch (error, stackTrace) {
        debugPrint('MARK_ACCOUNT_SESSION_SIGNED_OUT_ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      try {
        await FCMService.removeCurrentInstallationToken(uid: uid);
      } catch (error, stackTrace) {
        debugPrint('REMOVE_FCM_TOKEN_ON_LOGOUT_ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    try {
      await AutoLoginService.clearLogin();
    } catch (error, stackTrace) {
      debugPrint('CLEAR_AUTO_LOGIN_ON_LOGOUT_ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    await FirebaseAuth.instance.signOut();
  }
}
