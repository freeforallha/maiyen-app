import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

final FlutterLocalNotificationsPlugin localNotif =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService {
  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission();

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    await localNotif.initialize(const InitializationSettings(android: android));

    const channel = AndroidNotificationChannel(
      'alarm_channel',
      'Alarm Channel',
      importance: Importance.max,
      playSound: true,
    );

    await localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // APP ĐANG MỞ
    FirebaseMessaging.onMessage.listen((message) async {
      final type = message.data['type'] ?? '';

      String title = 'SafeHome';
      String body = '';

      switch (type) {
        case 'door_open':
          title = '🚪 Cửa mở';
          body = message.data['body'] ?? 'Có cửa đang mở';
          break;

        case 'alarm':
          title = '🚨 Báo động';
          body = message.data['body'] ?? 'Phát hiện xâm nhập';
          break;

        case 'low_battery':
          title = '🔋 Pin yếu';
          body = message.data['body'] ?? 'Thiết bị sắp hết pin';
          break;

        case 'sensor_offline':
          title = '📶 Mất kết nối';
          body = message.data['body'] ?? 'Sensor đã offline';
          break;

        case 'pair':
          title = '👤 Pair thiết bị';
          body = message.data['body'] ?? 'Có người đang pair sensor';
          break;

        case 'share_home':
          title = '🏠 Home được share';
          body = message.data['body'] ?? 'Bạn được share home mới';
          break;

        default:
          title = message.notification?.title ?? 'SafeHome';
          body = message.notification?.body ?? '';
      }

      await localNotif.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel',
            'Alarm Channel',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
      );
    });
  }
}
