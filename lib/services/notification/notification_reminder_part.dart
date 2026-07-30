part of '../notification_service.dart';

String _notificationServiceLastScheduleBody = _strings.safetyReminderBody(isSafe: true);

String _notificationServiceLastScheduleTitle = _strings.defaultHomeName();

String _notificationServiceLastReminderItemsJson = "";

String _notificationServiceLastAlarmItemsJson = "";

String _notificationServiceLastAlarmBody = _strings.alarmBody;

String _notificationServiceLastAlarmEventCategory = "";

String _notificationServiceLastAlarmLevel = "";

const String _notificationServiceReminderRouteName = "fullscreen_reminder";

bool _reminderPageOpen = false;

const Duration _reminderMergeWindow = Duration(seconds: 12);

int _lastReminderMergeAt = 0;

final ValueNotifier<int> _notificationServiceReminderRevision = ValueNotifier<int>(0);

void _notificationServiceMarkReminderPageClosed() {
  _reminderPageOpen = false;
}

void _resetReminderSession() {
  _notificationServiceLastReminderItemsJson = '';
  _notificationServiceLastScheduleTitle = _strings.defaultHomeName();
  _notificationServiceLastScheduleBody = _strings.safetyReminderBody(isSafe: true);
  _lastReminderMergeAt = 0;
  _notificationServiceReminderRevision.value++;
}

List<Map<String, dynamic>> _decodeReminderItems(String raw) {
  try {
    final text = raw.trim();

    if (text.isEmpty) return [];

    final decoded = jsonDecode(text);

    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  } catch (_) {
    return [];
  }
}

void _mergeReminderSession({
  required String title,
  required String body,
  required bool isSafe,
  required String reminderItemsJson,
}) {
  final strings = _strings;
  final now = DateTime.now().millisecondsSinceEpoch;
  final keepPreviousBatch =
      _lastReminderMergeAt > 0 &&
      now - _lastReminderMergeAt <= _reminderMergeWindow.inMilliseconds;
  final existingItems = keepPreviousBatch
      ? _decodeReminderItems(_notificationServiceLastReminderItemsJson)
      : <Map<String, dynamic>>[];
  final incomingItems = _decodeReminderItems(reminderItemsJson);

  _lastReminderMergeAt = now;

  if (incomingItems.isEmpty) {
    final cleanBody = strings.stripSafetyStatusText(body);
    final translatedCleanBody = cleanBody.isEmpty
        ? ''
        : strings.statusText(cleanBody);

    incomingItems.add({
      'homeId': '',
      'homeName': title.trim().isEmpty
          ? strings.defaultHomeName()
          : title.trim(),
      'reasons': isSafe
          ? <String>[]
          : <String>[
              translatedCleanBody.isEmpty
                  ? strings.defaultUnsafeReminderReason()
                  : translatedCleanBody,
            ],
    });
  }

  Map<String, dynamic> normalizeItem(Map<String, dynamic> item) {
    final homeId = item['homeId']?.toString().trim() ?? '';
    final homeName = item['homeName']?.toString().trim().isNotEmpty == true
        ? item['homeName'].toString().trim()
        : strings.defaultHomeName();
    final reasons = <String>[];
    final rawReasons = item['reasons'];

    if (rawReasons is List) {
      for (final reason in rawReasons) {
        final text = reason?.toString().trim() ?? '';
        final translatedText = text.isEmpty ? '' : strings.statusText(text);

        if (translatedText.isNotEmpty && !reasons.contains(translatedText)) {
          reasons.add(translatedText);
        }
      }
    }

    return {
      'homeId': homeId,
      'homeName': homeName,
      'reasons': reasons,
    };
  }

  String itemKey(Map<String, dynamic> item) {
    final homeId = item['homeId']?.toString().trim() ?? '';
    final homeName =
        item['homeName']?.toString().trim().toLowerCase() ?? '';

    return homeId.isNotEmpty ? homeId : homeName;
  }

  final merged = <String, Map<String, dynamic>>{};

  for (final item in existingItems) {
    final normalized = normalizeItem(item);
    merged[itemKey(normalized)] = normalized;
  }

  // Payload mới thay thế trạng thái cũ của cùng một nhà. Nhờ vậy một nhà
  // vừa trở lại an toàn sẽ không còn giữ lý do "chưa an toàn" từ Reminder
  // trước. Các nhà khác chỉ được gộp trong cửa sổ 12 giây của cùng một lượt.
  for (final item in incomingItems) {
    final normalized = normalizeItem(item);
    merged[itemKey(normalized)] = normalized;
  }

  final mergedItems = merged.values.toList();
  final hasUnsafe = mergedItems.any((item) {
    final reasons = item['reasons'];

    return reasons is List && reasons.isNotEmpty;
  });

  _notificationServiceLastReminderItemsJson = jsonEncode(mergedItems);
  _notificationServiceLastScheduleTitle = mergedItems.length == 1
      ? mergedItems.first['homeName']?.toString() ?? strings.defaultHomeName()
      : strings.scheduledReminder;

  if (!hasUnsafe) {
    _notificationServiceLastScheduleBody = strings.safetyReminderBody(isSafe: true);
    return;
  }

  final issueLines = <String>[];

  for (final item in mergedItems) {
    final reasons = item['reasons'];

    if (reasons is! List || reasons.isEmpty) continue;

    final homeName =
        item['homeName']?.toString() ?? strings.defaultHomeName();

    issueLines.add('$homeName: ${reasons.join(', ')}');
  }

  _notificationServiceLastScheduleBody =
      '⚠️ ${strings.unsafeStatusTitle()}\n${issueLines.join('\n')}';
}

bool _currentReminderIsSafe() {
  final items = _decodeReminderItems(_notificationServiceLastReminderItemsJson);

  return !items.any((item) {
    final reasons = item['reasons'];

    return reasons is List && reasons.isNotEmpty;
  });
}

String _currentReminderReason() {
  final strings = _strings;
  final lines = <String>[];

  for (final item in _decodeReminderItems(_notificationServiceLastReminderItemsJson)) {
    final reasons = item['reasons'];

    if (reasons is! List || reasons.isEmpty) continue;

    final homeName =
        item['homeName']?.toString().trim().isNotEmpty == true
        ? item['homeName'].toString().trim()
        : strings.defaultHomeName();

    lines.add('$homeName: ${reasons.join(', ')}');
  }

  return lines.join('\n');
}

void _notificationServiceOpenOrMergeReminderPage({
  required String title,
  required String body,
  required bool isSafe,
  String reminderItemsJson = "",
}) {
  _mergeReminderSession(
    title: title,
    body: body,
    isSafe: isSafe,
    reminderItemsJson: reminderItemsJson,
  );

  _notificationServiceReminderRevision.value++;

  if (_reminderPageOpen) {
    return;
  }

  final navigator = appNavigatorKey.currentState;

  if (navigator == null) return;

  _reminderPageOpen = true;

  navigator
      .push(
        MaterialPageRoute(
          settings: const RouteSettings(name: _notificationServiceReminderRouteName),
          builder: (_) => FullscreenAlarmPage(
            title: _notificationServiceLastScheduleTitle,
            body: _notificationServiceLastScheduleBody,
            silentMode: true,
            reminderItemsJson: _notificationServiceLastReminderItemsJson,
          ),
        ),
      )
      .whenComplete(_notificationServiceMarkReminderPageClosed);
}
