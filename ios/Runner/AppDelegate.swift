import Flutter
import native_geofence
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let maiYenAlarmTypes: Set<String> = [
    "alarm_detected",
    "alarm",
    "alarm_siren",
    "emergency_notification",
  ]

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let launched = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )

    // Để Firebase Messaging và flutter_local_notifications cùng nhận đúng
    // sự kiện notification khi MaiYen đang foreground trên iOS.
    UNUserNotificationCenter.current().delegate = self

    return launched
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    // Push đóng incident là background push. Khi iOS giao được push này,
    // dọn notification APNs đã hiển thị của đúng incident; nếu không còn
    // incident nào thì dọn toàn bộ notification Alarm của MaiYen.
    if String(describing: userInfo["type"] ?? "") == "alarm_resolved" {
      let incidentId = String(describing: userInfo["incidentId"] ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
      let hasRemaining = String(
        describing: userInfo["hasRemainingActiveIncidents"] ?? "false"
      ).lowercased() == "true"

      removeDeliveredAlarmNotifications(
        incidentId: incidentId,
        removeAll: !hasRemaining
      )
    }

    super.application(
      application,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: completionHandler
    )
  }

  private func removeDeliveredAlarmNotifications(
    incidentId: String,
    removeAll: Bool
  ) {
    let center = UNUserNotificationCenter.current()
    let alarmTypes = maiYenAlarmTypes

    center.getDeliveredNotifications { [alarmTypes] notifications in
      let identifiers = notifications.compactMap { notification -> String? in
        let userInfo = notification.request.content.userInfo
        let type = String(describing: userInfo["type"] ?? "")

        guard alarmTypes.contains(type) else {
          return nil
        }

        if removeAll {
          return notification.request.identifier
        }

        let deliveredIncidentId = String(
          describing: userInfo["incidentId"] ?? ""
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        return !incidentId.isEmpty && deliveredIncidentId == incidentId
          ? notification.request.identifier
          : nil
      }

      if !identifiers.isEmpty {
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
      }
    }
  }

  func didInitializeImplicitFlutterEngine(
    _ engineBridge: FlutterImplicitEngineBridge
  ) {
    NativeGeofencePlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    GeneratedPluginRegistrant.register(
      with: engineBridge.pluginRegistry
    )
  }
}
