import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../notification_service.dart';
import 'android/android_background_notification_service.dart' as android;

@pragma('vm:entry-point')
Future<void> safeHomeFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await android.firebaseMessagingBackgroundHandler(message);
    return;
  }

  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }

  DartPluginRegistrant.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final type = message.data['type']?.toString() ?? '';

  // [iOS] APNs tự hiển thị các cảnh báo khi app ở background/terminated.
  // Background isolate chỉ cần xử lý push đóng incident để dọn trạng thái cũ.
  if (type != 'alarm_resolved') {
    return;
  }

  await localNotif.initialize(
    const InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );

  final hasRemainingActiveIncidents =
      message.data['hasRemainingActiveIncidents']?.toString() == 'true';

  if (!hasRemainingActiveIncidents) {
    await Future.wait([
      localNotif.cancel(NotificationService.emergencyNotificationId),
      localNotif.cancel(NotificationService.alarmNotificationId),
    ]);
  }
}
