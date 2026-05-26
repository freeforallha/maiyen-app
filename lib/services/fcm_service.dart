import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class FCMService {
  static Future<void> setupFCM({required String uid}) async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();

    print("NEW FCM TOKEN: $token");

    if (token != null) {
      await FirebaseDatabase.instance.ref("accounts/$uid/fcmToken").set(token);
    }

    messaging.onTokenRefresh.listen((newToken) async {
      print("REFRESH TOKEN: $newToken");

      await FirebaseDatabase.instance
          .ref("accounts/$uid/fcmToken")
          .set(newToken);
    });
  }

  static void listenForeground({
    required FlutterLocalNotificationsPlugin localNotif,
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    FirebaseMessaging.onMessage.listen((message) async {
      print("MESSAGE DATA: ${message.data}");
      print("MESSAGE NOTIF: ${message.notification}");

      final type = message.data["type"]?.toString() ?? "alarm";
      final isSchedule = type == "schedule_notification";

      final title =
          message.notification?.title ?? message.data["title"] ?? "SafeHome";

      final body = message.notification?.body ??
          message.data["body"] ??
          (isSchedule ? "Đã đến giờ kiểm tra SafeHome" : "Alarm triggered");

      final isSafeText = message.data["isSafe"]?.toString() ?? "false";
      final isSafe =
          isSafeText == "true" || isSafeText == "1" || isSafeText == "yes";

      final reason = message.data["reason"]?.toString() ?? body;

      final nav = navigatorKey.currentState;

      if (isSchedule) {
        if (nav != null) {
          showDialog(
            context: nav.overlay!.context,
            useRootNavigator: true,
            barrierDismissible: true,
            barrierColor: Colors.black.withValues(alpha: 0.35),
            builder: (_) {
              return Stack(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                  ),

                  Center(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: MediaQuery.of(nav.overlay!.context).size.width * 0.86,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.home_rounded,
                              size: 58,
                              color: Colors.green,
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              "SafeHome",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 18),

                            Text(
                              isSafe ? "✅ ĐÃ AN TOÀN" : "⚠️ CHƯA AN TOÀN",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isSafe ? Colors.green : Colors.orange.shade800,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              isSafe
                                  ? "Hãy an tâm nghỉ ngơi."
                                  : "Lý do: $reason",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                height: 1.35,
                              ),
                            ),

                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(nav.overlay!.context);
                                },
                                child: const Text("Đã hiểu"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }

        await localNotif.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title.toString(),
          body.toString(),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'safehome_schedule_fullscreen_channel',
              'SafeHome Schedule Fullscreen',
              importance: Importance.max,
              priority: Priority.high,
              category: AndroidNotificationCategory.reminder,
              fullScreenIntent: true,
              playSound: false,
              enableVibration: false,
              visibility: NotificationVisibility.public,
            ),
          ),
          payload: 'schedule_notification',
        );

        return;
      }

      if (nav != null) {
        showDialog(
          context: nav.overlay!.context,
          useRootNavigator: true,
          builder: (_) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.red.shade700,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                body.toString(),
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(nav.overlay!.context),
                  child: const Text("Đóng"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(nav.overlay!.context);
                  },
                  child: const Text("Kiểm tra"),
                ),
              ],
            );
          },
        );
      }

      await localNotif.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title.toString(),
        body.toString(),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel',
            'Alarm',
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.alarm,
            fullScreenIntent: true,
            playSound: true,
            enableVibration: true,
          ),
        ),
        payload: 'alarm',
      );
    });
  }
}