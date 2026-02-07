import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class NotificationSettingsService extends GetxService {
  static const String _keyPushNotifications = 'push_notifications_enabled';
  static const String _keyNotificationSound = 'notification_sound_enabled';
  static const String _keyNotificationVibration =
      'notification_vibration_enabled';
  static const String _keySleepTimerNotifications =
      'sleep_timer_notifications_enabled';
  static const String _keyQuietHoursEnabled = 'quiet_hours_enabled';
  static const String _keyQuietStartHour = 'quiet_start_hour';
  static const String _keyQuietStartMinute = 'quiet_start_minute';
  static const String _keyQuietEndHour = 'quiet_end_hour';
  static const String _keyQuietEndMinute = 'quiet_end_minute';
  static const String _keyNotificationRequestShown =
      'notification_request_shown';

  final RxBool pushNotificationsEnabled = true.obs;
  final RxBool notificationSound = true.obs;
  final RxBool notificationVibration = true.obs;
  final RxBool sleepTimerNotifications = true.obs;
  final RxBool quietHoursEnabled = false.obs;
  final RxInt quietStartHour = 22.obs;
  final RxInt quietStartMinute = 0.obs;
  final RxInt quietEndHour = 7.obs;
  final RxInt quietEndMinute = 0.obs;
  final RxBool hasShownNotificationRequest = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      pushNotificationsEnabled.value =
          prefs.getBool(_keyPushNotifications) ?? true;
      notificationSound.value = prefs.getBool(_keyNotificationSound) ?? true;
      notificationVibration.value =
          prefs.getBool(_keyNotificationVibration) ?? true;
      sleepTimerNotifications.value =
          prefs.getBool(_keySleepTimerNotifications) ?? true;
      quietHoursEnabled.value = prefs.getBool(_keyQuietHoursEnabled) ?? false;
      quietStartHour.value = prefs.getInt(_keyQuietStartHour) ?? 22;
      quietStartMinute.value = prefs.getInt(_keyQuietStartMinute) ?? 0;
      quietEndHour.value = prefs.getInt(_keyQuietEndHour) ?? 7;
      quietEndMinute.value = prefs.getInt(_keyQuietEndMinute) ?? 0;
      hasShownNotificationRequest.value =
          prefs.getBool(_keyNotificationRequestShown) ?? false;

      debugPrint('Notification settings loaded successfully');
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(
          _keyPushNotifications, pushNotificationsEnabled.value);
      await prefs.setBool(_keyNotificationSound, notificationSound.value);
      await prefs.setBool(
          _keyNotificationVibration, notificationVibration.value);
      await prefs.setBool(
          _keySleepTimerNotifications, sleepTimerNotifications.value);
      await prefs.setBool(_keyQuietHoursEnabled, quietHoursEnabled.value);
      await prefs.setInt(_keyQuietStartHour, quietStartHour.value);
      await prefs.setInt(_keyQuietStartMinute, quietStartMinute.value);
      await prefs.setInt(_keyQuietEndHour, quietEndHour.value);
      await prefs.setInt(_keyQuietEndMinute, quietEndMinute.value);
      await prefs.setBool(
          _keyNotificationRequestShown, hasShownNotificationRequest.value);

      debugPrint('Notification settings saved successfully');
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  bool get areNotificationsAllowed {
    if (!pushNotificationsEnabled.value) return false;

    if (quietHoursEnabled.value && _isInQuietHours()) return false;

    return true;
  }

  bool _isInQuietHours() {
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute;

    final startTime = quietStartHour.value * 60 + quietStartMinute.value;
    final endTime = quietEndHour.value * 60 + quietEndMinute.value;

    if (startTime > endTime) {
      return currentTime >= startTime || currentTime < endTime;
    } else {
      return currentTime >= startTime && currentTime < endTime;
    }
  }

  String get quietHoursStatus {
    if (!quietHoursEnabled.value) return 'Disabled';

    final startTime =
        '${quietStartHour.value.toString().padLeft(2, '0')}:${quietStartMinute.value.toString().padLeft(2, '0')}';
    final endTime =
        '${quietEndHour.value.toString().padLeft(2, '0')}:${quietEndMinute.value.toString().padLeft(2, '0')}';

    return 'Enabled ($startTime - $endTime)';
  }

  Future<void> resetToDefaults() async {
    pushNotificationsEnabled.value = true;
    notificationSound.value = true;
    notificationVibration.value = true;
    sleepTimerNotifications.value = true;
    quietHoursEnabled.value = false;
    quietStartHour.value = 22;
    quietStartMinute.value = 0;
    quietEndHour.value = 7;
    quietEndMinute.value = 0;
    hasShownNotificationRequest.value = false;

    await saveSettings();
    debugPrint('Notification settings reset to defaults');
  }

  void updateQuietHours({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) {
    quietStartHour.value = startHour;
    quietStartMinute.value = startMinute;
    quietEndHour.value = endHour;
    quietEndMinute.value = endMinute;
  }

  void debugSettings() {
    debugPrint('Notification Settings Debug:');
    debugPrint('Push Notifications: ${pushNotificationsEnabled.value}');
    debugPrint('Notification Sound: ${notificationSound.value}');
    debugPrint('Notification Vibration: ${notificationVibration.value}');
    debugPrint('Sleep Timer: ${sleepTimerNotifications.value}');
    debugPrint('Quiet Hours: $quietHoursStatus');
    debugPrint('Notifications Allowed: $areNotificationsAllowed');
  }
}
