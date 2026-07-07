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
      "title": active
          ? strings.t("Cảnh báo khói")
          : strings.t("Khói đã an toàn"),
      "message": active
            ? strings.choose(
                vi: "\"$name\" phát hiện khói trong \"$homeName\".",
                en: "\"$name\" detected smoke in \"$homeName\".",
                ja: "「$name」が「$homeName」で煙を検知しました。",
              )
            : strings.choose(
                vi: "\"$name\" đã trở lại trạng thái bình thường.",
                en: "\"$name\" has returned to normal.",
                ja: "「$name」は通常状態に戻りました。",
              ),
      "severity": active ? "critical" : "success",
    };
  }

  if (changed("sosActive")) {
    final active = current["sosActive"] == true;
    return {
      "type": active ? "device_sos" : "device_sos_clear",
      "title": active
          ? strings.t("SOS được kích hoạt")
          : strings.t("SOS đã kết thúc"),
      "message": active
            ? strings.choose(
                vi: "\"$name\" vừa kích hoạt SOS trong \"$homeName\".",
                en: "\"$name\" triggered SOS in \"$homeName\".",
                ja: "「$name」が「$homeName」で SOS を起動しました。",
              )
            : strings.choose(
                vi: "\"$name\" đã hết trạng thái SOS.",
                en: "\"$name\" is no longer in SOS state.",
                ja: "「$name」の SOS 状態は解除されました。",
              ),
      "severity": active ? "critical" : "success",
    };
  }

  if (changed("tamper")) {
    final active = current["tamper"] == true;
    return {
      "type": active ? "device_tamper" : "device_tamper_clear",
      "title": active
          ? strings.t("Thiết bị bị tháo")
          : strings.t("Tamper bình thường"),
      "message": active
            ? strings.choose(
                vi: "\"$name\" báo bị tháo/cạy trong \"$homeName\".",
                en: "\"$name\" reported tampering in \"$homeName\".",
                ja: "「$name」が「$homeName」で取り外し/こじ開けを検知しました。",
              )
            : strings.choose(
                vi: "\"$name\" đã hết cảnh báo tháo/cạy.",
                en: "\"$name\" tamper alert has cleared.",
                ja: "「$name」の取り外し警告は解除されました。",
              ),
      "severity": active ? "critical" : "success",
    };
  }

  if (_isContactDevice(type) && changed("contact")) {
    final closed = current["contact"] == true;
    return {
      "type": "device_contact",
      "title": closed ? strings.t("Cửa đã đóng") : strings.t("Cửa đang mở"),
      "message": closed
          ? strings.choose(
              vi: "\"$name\" đã đóng trong \"$homeName\".",
              en: "\"$name\" closed in \"$homeName\".",
              ja: "「$name」は「$homeName」で閉じました。",
            )
          : strings.choose(
              vi: "\"$name\" đang mở trong \"$homeName\".",
              en: "\"$name\" is open in \"$homeName\".",
              ja: "「$name」は「$homeName」で開いています。",
            ),
      "severity": closed ? "success" : "warning",
    };
  }

  if (previous["batteryLow"] != true && current["batteryLow"] == true) {
    return {
      "type": "device_battery_low",
      "title": strings.t("Pin yếu"),
      "message": strings.choose(
        vi: "\"$name\" trong \"$homeName\" đang yếu pin.",
        en: "\"$name\" in \"$homeName\" has a low battery.",
        ja: "「$homeName」の「$name」はバッテリー残量が低下しています。",
      ),
      "severity": "warning",
    };
  }

  if (changed("availability")) {
    final availability = current["availability"]?.toString() ?? "";
    if (availability == "offline") {
      return {
        "type": "device_connection",
        "title": strings.t("Thiết bị offline"),
        "message": strings.choose(
          vi: "\"$name\" trong \"$homeName\" đã mất kết nối.",
          en: "\"$name\" in \"$homeName\" went offline.",
          ja: "「$homeName」の「$name」はオフラインになりました。",
        ),
        "severity": "warning",
      };
    }

    if (availability == "online") {
      return {
        "type": "device_connection",
        "title": strings.t("Thiết bị online"),
        "message": strings.choose(
          vi: "\"$name\" trong \"$homeName\" đã kết nối trở lại.",
          en: "\"$name\" in \"$homeName\" is back online.",
          ja: "「$homeName」の「$name」はオンラインに戻りました。",
        ),
        "severity": "success",
      };
    }
  }

  if (previous["temperatureHigh"] != true &&
      current["temperatureHigh"] == true) {
    return {
      "type": "device_environment",
      "title": strings.t("Nhiệt độ cao"),
      "message": strings.choose(
        vi: "\"$name\" ghi nhận nhiệt độ cao trong \"$homeName\".",
        en: "\"$name\" recorded a high temperature in \"$homeName\".",
        ja: "「$name」が「$homeName」で高温を記録しました。",
      ),
      "severity": "warning",
    };
  }

  if (previous["humidityHigh"] != true && current["humidityHigh"] == true) {
    return {
      "type": "device_environment",
      "title": strings.t("Độ ẩm cao"),
      "message": strings.choose(
        vi: "\"$name\" ghi nhận độ ẩm cao trong \"$homeName\".",
        en: "\"$name\" recorded high humidity in \"$homeName\".",
        ja: "「$name」が「$homeName」で高い湿度を記録しました。",
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
