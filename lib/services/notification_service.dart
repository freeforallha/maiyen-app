import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app/maiyen_app.dart';
import '../config/brand_config.dart';
import '../helpers/top_toast.dart';
import '../localization/app_language_controller.dart';
import '../localization/app_strings.dart';
import '../pages/fullscreen_alarm_page.dart';
import 'platform/android/android_notification_config.dart';
import 'platform/ios/ios_notification_config.dart';
import 'notification/notification_incident_normalizer.dart';
import 'notification/notification_payload_codec.dart';
import 'package:maiyen_app/helpers/debug_log.dart';
import '../config/maiyen_identifiers.dart';

part 'notification/notification_navigation_part.dart';
part 'notification/notification_alarm_validation_part.dart';
part 'notification/notification_alarm_actions_part.dart';
part 'notification/notification_alarm_delivery_part.dart';
part 'notification/notification_delivery_part.dart';
part 'notification/notification_reminder_part.dart';
part 'notification/notification_bootstrap_part.dart';
part 'notification/notification_alarm_session_part.dart';

final FlutterLocalNotificationsPlugin localNotif =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static ValueNotifier<Map<String, String>?> get chatOpenRequest => _notificationServiceChatOpenRequest;

  static ValueNotifier<Map<String, String>?> get hubUpdateOpenRequest => _notificationServiceHubUpdateOpenRequest;

  static String hubUpdatePayload({
    required String homeId,
    required String homeName,
    required String ownerUid,
    required String releaseId,
  }) {
    return _notificationServiceHubUpdatePayload(
          homeId: homeId,
          homeName: homeName,
          ownerUid: ownerUid,
          releaseId: releaseId,
        );
  }

  static int hubUpdateNotificationId(String homeId) {
    return _notificationServiceHubUpdateNotificationId(homeId);
  }

  static Future<void> cancelHubUpdateNotification(String homeId) {
    return _notificationServiceCancelHubUpdateNotification(homeId);
  }

  static void requestOpenHubUpdate(Map<String, dynamic> rawData) {
    _notificationServiceRequestOpenHubUpdate(rawData);
  }

  static String homeChatPayload({
    required String homeId,
    required String homeName,
    required String ownerUid,
    required String messageId,
  }) {
    return _notificationServiceHomeChatPayload(
          homeId: homeId,
          homeName: homeName,
          ownerUid: ownerUid,
          messageId: messageId,
        );
  }

  static int homeChatNotificationId(String homeId) {
    return _notificationServiceHomeChatNotificationId(homeId);
  }

  static String localizedExactTextOrRaw(String raw, AppStrings strings) {
    return _notificationServiceLocalizedExactTextOrRaw(raw, strings);
  }

  static void markHomeChatOpened(String homeId) {
    _notificationServiceMarkHomeChatOpened(homeId);
  }

  static void markHomeChatClosed(String homeId) {
    _notificationServiceMarkHomeChatClosed(homeId);
  }

  static void requestOpenHomeChat(Map<String, dynamic> rawData) {
    _notificationServiceRequestOpenHomeChat(rawData);
  }

  static const int emergencyNotificationId = _notificationServiceEmergencyNotificationId;

  static const int alarmNotificationId = _notificationServiceAlarmNotificationId;

  static ValueNotifier<int> get alarmResolvedRevision => _notificationServiceAlarmResolvedRevision;

  static bool get hasActiveAlarmIncidents => _notificationServiceHasActiveAlarmIncidents;

  static Future<Map<String, dynamic>?> validateIncomingAlarmData(
    Map<String, dynamic> rawData, {
    bool updateLocalState = true,
  }) {
    return _notificationServiceValidateIncomingAlarmData(rawData, updateLocalState: updateLocalState);
  }

  static String localizedAlarmBodyForData(
    Map<String, dynamic> data,
    AppStrings strings,
  ) {
    return _notificationServiceLocalizedAlarmBodyForData(data, strings);
  }

  static String localizedNotificationTitle(
    String rawTitle,
    AppStrings strings,
    String fallback,
  ) {
    return _notificationServiceLocalizedNotificationTitle(
          rawTitle,
          strings,
          fallback,
        );
  }

  static String normalizedIncidentEventCategory(Map<String, dynamic> data) {
    return _notificationServiceNormalizedIncidentEventCategory(data);
  }

  static String normalizedIncidentAlarmLevel(Map<String, dynamic> data) {
    return _notificationServiceNormalizedIncidentAlarmLevel(data);
  }

  static String normalizedIncidentStatus(Map<String, dynamic> data) {
    return _notificationServiceNormalizedIncidentStatus(data);
  }

  static void rememberAlarmIncident(Map<String, dynamic> data) {
    _notificationServiceRememberAlarmIncident(data);
  }

  static Future<bool> muteHomeSiren({
    required String homeId,
    required String hubId,
  }) {
    return _notificationServiceMuteHomeSiren(homeId: homeId, hubId: hubId);
  }

  static Future<bool> resolveActiveAlarmIncidents({
    required String action,
    String incidentId = '',
  }) {
    return _notificationServiceResolveActiveAlarmIncidents(action: action, incidentId: incidentId);
  }

  static Future<bool> muteActiveHomeSirens({String incidentId = ''}) {
    return _notificationServiceMuteActiveHomeSirens(incidentId: incidentId);
  }

  static Future<void> showPriorityAlarmNotification({
    required Map<String, dynamic> data,
  }) {
    return _notificationServiceShowPriorityAlarmNotification(data: data);
  }

  static Future<void> handlePriorityAlarmOpened(
    Map<String, dynamic> data,
  ) {
    return _notificationServiceHandlePriorityAlarmOpened(data);
  }

  static Future<void> handleAlarmResolved(Map<String, dynamic> data) {
    return _notificationServiceHandleAlarmResolved(data);
  }

  static Future<bool> reconcileActiveAlarmIncidents() {
    return _notificationServiceReconcileActiveAlarmIncidents();
  }

  static Future<bool> handleAlarmNotificationPayload(String payload) {
    return _notificationServiceHandleAlarmNotificationPayload(payload);
  }

  static Future<void> openAlarmFromData(
    Map<String, dynamic> data, {
    bool validate = true,
  }) {
    return _notificationServiceOpenAlarmFromData(data, validate: validate);
  }

  static Future<void> openIosAlarmFromData(Map<String, dynamic> data) {
    return _notificationServiceOpenIosAlarmFromData(data);
  }

  static Future<void> showSensorNotification({
    required Map<String, dynamic> data,
  }) {
    return _notificationServiceShowSensorNotification(data: data);
  }

  static Future<void> showChatNotification({
    required Map<String, dynamic> data,
  }) {
    return _notificationServiceShowChatNotification(data: data);
  }

  static Future<void> stopAlarmNotification() {
    return _notificationServiceStopAlarmNotification();
  }

  static Future<void> stopEmergencyNotification() {
    return _notificationServiceStopEmergencyNotification();
  }

  static Future<void> stopAllAlarmNotifications() {
    return _notificationServiceStopAllAlarmNotifications();
  }

  static Future<void> stopReminderNotification() {
    return _notificationServiceStopReminderNotification();
  }

  static String get lastScheduleBody => _notificationServiceLastScheduleBody;
  static set lastScheduleBody(String value) => _notificationServiceLastScheduleBody = value;

  static String get lastScheduleTitle => _notificationServiceLastScheduleTitle;
  static set lastScheduleTitle(String value) => _notificationServiceLastScheduleTitle = value;

  static String get lastReminderItemsJson => _notificationServiceLastReminderItemsJson;
  static set lastReminderItemsJson(String value) => _notificationServiceLastReminderItemsJson = value;

  static String get lastAlarmItemsJson => _notificationServiceLastAlarmItemsJson;
  static set lastAlarmItemsJson(String value) => _notificationServiceLastAlarmItemsJson = value;

  static String get lastAlarmBody => _notificationServiceLastAlarmBody;
  static set lastAlarmBody(String value) => _notificationServiceLastAlarmBody = value;

  static String get lastAlarmEventCategory => _notificationServiceLastAlarmEventCategory;
  static set lastAlarmEventCategory(String value) => _notificationServiceLastAlarmEventCategory = value;

  static String get lastAlarmLevel => _notificationServiceLastAlarmLevel;
  static set lastAlarmLevel(String value) => _notificationServiceLastAlarmLevel = value;

  static const String reminderRouteName = _notificationServiceReminderRouteName;

  static ValueNotifier<int> get reminderRevision => _notificationServiceReminderRevision;

  static void markReminderPageClosed() {
    _notificationServiceMarkReminderPageClosed();
  }

  static void openOrMergeReminderPage({
    required String title,
    required String body,
    required bool isSafe,
    String reminderItemsJson = "",
  }) {
    _notificationServiceOpenOrMergeReminderPage(
          title: title,
          body: body,
          isSafe: isSafe,
          reminderItemsJson: reminderItemsJson,
        );
  }

  static Future<void> init() {
    return _notificationServiceInit();
  }

  static const String alarmRouteName = _notificationServiceAlarmRouteName;

  static ValueNotifier<int> get alarmRevision => _notificationServiceAlarmRevision;

  static List<Map<String, dynamic>> get activeAlarmItems => _notificationServiceActiveAlarmItems;

  static void markAlarmPageOpened({
    String body = '',
    String alarmItemsJson = '',
    String eventCategory = '',
    String alarmLevel = '',
  }) {
    _notificationServiceMarkAlarmPageOpened(
          body: body,
          alarmItemsJson: alarmItemsJson,
          eventCategory: eventCategory,
          alarmLevel: alarmLevel,
        );
  }

  static void markAlarmPageClosed() {
    _notificationServiceMarkAlarmPageClosed();
  }

  static void openAlarmPage({
    required String title,
    required String body,
    String alarmItemsJson = '',
    String incidentId = '',
    String receiverUid = '',
    String ownerUid = '',
    String homeId = '',
    String flowType = '',
    String eventCategory = '',
    String alarmLevel = '',
  }) {
    _notificationServiceOpenAlarmPage(
          title: title,
          body: body,
          alarmItemsJson: alarmItemsJson,
          incidentId: incidentId,
          receiverUid: receiverUid,
          ownerUid: ownerUid,
          homeId: homeId,
          flowType: flowType,
          eventCategory: eventCategory,
          alarmLevel: alarmLevel,
        );
  }

  static void clearActiveAlarms({bool clearIncidentContexts = true}) {
    _notificationServiceClearActiveAlarms(
          clearIncidentContexts: clearIncidentContexts,
        );
  }

  static Future<void> showSafetyReminder({
    required bool isSafe,
    String reason = '',
    String reminderItemsJson = '',
    String title = '',
    bool forceShow = false,
  }) {
    return _notificationServiceShowSafetyReminder(
          isSafe: isSafe,
          reason: reason,
          reminderItemsJson: reminderItemsJson,
          title: title,
          forceShow: forceShow,
        );
  }

}
