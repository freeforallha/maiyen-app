import '../helpers/home_helper.dart';
import '../localization/app_strings.dart';

class DeviceNotificationEventService {
  static Map<String, dynamic> state(Map<String, dynamic> device) {
    return _deviceNotificationState(device);
  }

  static Map<String, String>? event({
    required AppStrings strings,
    required String homeName,
    required String deviceId,
    required Map<String, dynamic> device,
    required Map<String, dynamic> previous,
    required Map<String, dynamic> current,
  }) {
    return _deviceNotificationEvent(
      strings: strings,
      homeName: homeName,
      deviceId: deviceId,
      device: device,
      previous: previous,
      current: current,
    );
  }

  static String deviceName(String deviceId, Map<String, dynamic> device) {
    return _deviceName(deviceId, device);
  }

  static bool isContactDevice(String type) {
    return _isContactDevice(type);
  }
}

Map<String, dynamic> _deviceNotificationState(Map<String, dynamic> device) {
  final battery = int.tryParse(device["battery"]?.toString() ?? "");
  final temperature = double.tryParse(device["temperature"]?.toString() ?? "");
  final humidity = double.tryParse(device["humidity"]?.toString() ?? "");

  return {
    "availability": device["availability"]?.toString().toLowerCase() ?? "",
    "contact": device["contact"],
    "smoke": device["smoke"] == true,
    "tamper": device["tamper"] == true,
    "status": device["status"]?.toString() ?? "",
    "batteryLow": battery != null && battery <= 20,
    "sosActive": isSosActive(device),
    "temperatureHigh":
        temperature != null && temperature > environmentWarningTemperatureC,
    "humidityHigh":
        humidity != null && humidity >= environmentWarningHumidityPercent,
  };
}

Map<String, String>? _deviceNotificationEvent({
  required AppStrings strings,
  required String homeName,
  required String deviceId,
  required Map<String, dynamic> device,
  required Map<String, dynamic> previous,
  required Map<String, dynamic> current,
}) {
  final type = device["type"]?.toString() ?? "door";
  final name = _deviceName(deviceId, device);

  bool changed(String key) => previous[key] != current[key];

  if (changed("smoke")) {
    final active = current["smoke"] == true;
    return {
      "type": active ? "device_smoke" : "device_smoke_clear",
      "event": active ? "smoke_detected" : "smoke_cleared",
      "title": active
          ? strings.t("Cảnh báo khói")
          : strings.t("Khói đã an toàn"),
      "message": active
          ? strings.deviceSmokeDetectedMessage(name: name, homeName: homeName)
          : strings.deviceReturnedNormalMessage(name),
      "severity": active ? "critical" : "success",
    };
  }

  if (changed("sosActive")) {
    final active = current["sosActive"] == true;
    return {
      "type": active ? "device_sos" : "device_sos_clear",
      "event": active ? "sos_triggered" : "sos_cleared",
      "title": active
          ? strings.t("SOS được kích hoạt")
          : strings.t("SOS đã kết thúc"),
      "message": active
          ? strings.deviceSosTriggeredMessage(name: name, homeName: homeName)
          : strings.deviceSosClearedMessage(name),
      "severity": active ? "critical" : "success",
    };
  }

  if (changed("tamper")) {
    final active = current["tamper"] == true;
    return {
      "type": active ? "device_tamper" : "device_tamper_clear",
      "event": active ? "tamper_detected" : "tamper_cleared",
      "title": active
          ? strings.t("Thiết bị bị tháo")
          : strings.t("Tamper bình thường"),
      "message": active
          ? strings.deviceTamperDetectedMessage(name: name, homeName: homeName)
          : strings.deviceTamperClearedMessage(name),
      "severity": active ? "critical" : "success",
    };
  }

  if (_isContactDevice(type) && changed("contact")) {
    final closed = current["contact"] == true;
    return {
      "type": "device_contact",
      "event": closed ? "door_closed" : "door_open",
      "closed": closed.toString(),
      "title": closed ? strings.t("Cửa đã đóng") : strings.t("Cửa đang mở"),
      "message": closed
          ? strings.deviceDoorClosedMessage(name: name, homeName: homeName)
          : strings.deviceDoorOpenMessage(name: name, homeName: homeName),
      "severity": closed ? "success" : "warning",
    };
  }

  if (previous["batteryLow"] != true && current["batteryLow"] == true) {
    return {
      "type": "device_battery_low",
      "event": "battery_low",
      "title": strings.t("Pin yếu"),
      "message": strings.deviceLowBatteryMessage(
        name: name,
        homeName: homeName,
      ),
      "severity": "warning",
    };
  }

  if (changed("availability")) {
    final availability = current["availability"]?.toString() ?? "";
    if (availability == "offline") {
      return {
        "type": "device_connection",
        "event": "device_offline",
        "availability": "offline",
        "title": strings.t("Thiết bị offline"),
        "message": strings.deviceOfflineMessage(name: name, homeName: homeName),
        "severity": "warning",
      };
    }

    if (availability == "online") {
      return {
        "type": "device_connection",
        "event": "device_online",
        "availability": "online",
        "title": strings.t("Thiết bị online"),
        "message": strings.deviceOnlineMessage(name: name, homeName: homeName),
        "severity": "success",
      };
    }
  }

  if (previous["temperatureHigh"] != true &&
      current["temperatureHigh"] == true) {
    return {
      "type": "device_environment",
      "event": "high_temperature",
      "condition": "temperature_high",
      "title": strings.t("Nhiệt độ cao"),
      "message": strings.deviceHighTemperatureMessage(
        name: name,
        homeName: homeName,
      ),
      "severity": "warning",
    };
  }

  if (previous["humidityHigh"] != true && current["humidityHigh"] == true) {
    return {
      "type": "device_environment",
      "event": "high_humidity",
      "condition": "humidity_high",
      "title": strings.t("Độ ẩm cao"),
      "message": strings.deviceHighHumidityMessage(
        name: name,
        homeName: homeName,
      ),
      "severity": "warning",
    };
  }

  return null;
}

bool _isContactDevice(String type) {
  return type == "door" || type == "window" || type == "gate" || type == "lock";
}

String _deviceName(String deviceId, Map<String, dynamic> device) {
  final name = device["name"]?.toString().trim() ?? "";
  return name.isNotEmpty ? name : deviceId;
}
