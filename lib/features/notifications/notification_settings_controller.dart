import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/notification_settings_service.dart';

class NotificationSettingsController extends GetxController {
  final NotificationSettingsService _settingsService =
      Get.find<NotificationSettingsService>();

  late RxBool pushNotificationsEnabled;
  late RxBool notificationSound;
  late RxBool notificationVibration;
  late RxBool sleepTimerNotifications;
  late RxBool quietHoursEnabled;
  late Rx<TimeOfDay> quietStartTime;
  late Rx<TimeOfDay> quietEndTime;

  RxBool get isPushNotificationsEnabled => pushNotificationsEnabled;
  RxBool get isNotificationSoundEnabled => notificationSound;
  RxBool get isNotificationVibrationEnabled => notificationVibration;
  RxBool get isSleepTimerNotificationsEnabled => sleepTimerNotifications;
  RxBool get isQuietHoursEnabled => quietHoursEnabled;
  Rx<TimeOfDay> get quietStart => quietStartTime;
  Rx<TimeOfDay> get quietEnd => quietEndTime;

  @override
  void onInit() {
    super.onInit();
    _initializeSettings();
  }

  void _initializeSettings() {
    pushNotificationsEnabled = _settingsService.pushNotificationsEnabled;
    notificationSound = _settingsService.notificationSound;
    notificationVibration = _settingsService.notificationVibration;
    sleepTimerNotifications = _settingsService.sleepTimerNotifications;
    quietHoursEnabled = _settingsService.quietHoursEnabled;
    quietStartTime = Rx<TimeOfDay>(TimeOfDay(
      hour: _settingsService.quietStartHour.value,
      minute: _settingsService.quietStartMinute.value,
    ));
    quietEndTime = Rx<TimeOfDay>(TimeOfDay(
      hour: _settingsService.quietEndHour.value,
      minute: _settingsService.quietEndMinute.value,
    ));

    _settingsService.quietStartHour.listen((hour) {
      quietStartTime.value = TimeOfDay(
        hour: hour,
        minute: _settingsService.quietStartMinute.value,
      );
    });

    _settingsService.quietStartMinute.listen((minute) {
      quietStartTime.value = TimeOfDay(
        hour: _settingsService.quietStartHour.value,
        minute: minute,
      );
    });

    _settingsService.quietEndHour.listen((hour) {
      quietEndTime.value = TimeOfDay(
        hour: hour,
        minute: _settingsService.quietEndMinute.value,
      );
    });

    _settingsService.quietEndMinute.listen((minute) {
      quietEndTime.value = TimeOfDay(
        hour: _settingsService.quietEndHour.value,
        minute: minute,
      );
    });
  }

  void togglePushNotifications(bool value) {
    pushNotificationsEnabled.value = value;
    _settingsService.pushNotificationsEnabled.value = value;
    _settingsService.saveSettings();
  }

  void toggleNotificationSound(bool value) {
    notificationSound.value = value;
    _settingsService.notificationSound.value = value;
    _settingsService.saveSettings();
  }

  void toggleNotificationVibration(bool value) {
    notificationVibration.value = value;
    _settingsService.notificationVibration.value = value;
    _settingsService.saveSettings();
  }

  void toggleSleepTimerNotifications(bool value) {
    sleepTimerNotifications.value = value;
    _settingsService.sleepTimerNotifications.value = value;
    _settingsService.saveSettings();
  }

  void toggleQuietHours(bool value) {
    quietHoursEnabled.value = value;
    _settingsService.quietHoursEnabled.value = value;
    _settingsService.saveSettings();
  }

  Future<void> selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? quietStartTime.value : quietEndTime.value,
    );

    if (picked != null) {
      if (isStartTime) {
        quietStartTime.value = picked;
        _settingsService.quietStartHour.value = picked.hour;
        _settingsService.quietStartMinute.value = picked.minute;
      } else {
        quietEndTime.value = picked;
        _settingsService.quietEndHour.value = picked.hour;
        _settingsService.quietEndMinute.value = picked.minute;
      }
      _settingsService.saveSettings();
    }
  }

  Future<void> saveSettings() async {
    await _settingsService.saveSettings();
    Get.snackbar(
      'Settings Saved',
      'Your notification preferences have been updated',
      snackPosition: SnackPosition.bottom,
    );
    Get.back();
  }
}
