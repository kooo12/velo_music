import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonus/core/services/audio_service.dart';
import 'package:sonus/core/services/notification_settings_service.dart';

class SleepTimerService extends GetxService {
  final audioService = Get.find<AudioPlayerService>();
  final settingsService = Get.find<NotificationSettingsService>();

  Timer? _timer;
  Timer? _notificationUpdateTimer;
  final RxBool _isActive = false.obs;
  final RxInt _remainingSeconds = 0.obs;
  final RxInt _totalSeconds = 0.obs;
  final RxInt _lastSelectedMinutes = 15.obs;
  static const int _sleepTimerNotificationId = 9999;
  // int? _lastNotificationMinutes;

  // Getters
  bool get isActive => _isActive.value;
  int get remainingSeconds => _remainingSeconds.value;
  int get totalSeconds => _totalSeconds.value;
  int get lastSelectedMinutes => _lastSelectedMinutes.value;

  RxBool get isActiveObs => _isActive;
  RxInt get remainingSecondsObs => _remainingSeconds;
  RxInt get totalSecondsObs => _totalSeconds;
  RxInt get lastSelectedMinutesObs => _lastSelectedMinutes;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadLastSelectedDuration();
  }

  String get formattedTime {
    final minutes = _remainingSeconds.value ~/ 60;
    final seconds = _remainingSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    if (_totalSeconds.value == 0) return 0.0;
    return 1.0 - (_remainingSeconds.value / _totalSeconds.value);
  }

  void startTimer(int minutes) {
    if (minutes <= 0) return;

    _stopTimer();

    _totalSeconds.value = minutes * 60;
    _remainingSeconds.value = _totalSeconds.value;
    _isActive.value = true;

    _saveLastSelectedDuration(minutes);

    _showSleepTimerCountdownNotification();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds.value > 0) {
        _remainingSeconds.value--;
      } else {
        _stopMusicAndTimer();
      }
    });

    // _notificationUpdateTimer =
    //     Timer.periodic(const Duration(seconds: 30), (timer) {
    //   _updateSleepTimerNotification();
    // });

    debugPrint('Sleep timer started for $minutes minutes');
  }

  void stopTimer() {
    _stopTimer();
    debugPrint('Sleep timer stopped');
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _notificationUpdateTimer?.cancel();
    _notificationUpdateTimer = null;
    _isActive.value = false;
    _remainingSeconds.value = 0;
    _totalSeconds.value = 0;

    _cancelSleepTimerNotification();
  }

  void _stopMusicAndTimer() {
    try {
      audioService.audioPlayer.pause();
      debugPrint('Music stopped by sleep timer');

      if (settingsService.sleepTimerNotifications.value) {
        _showSleepTimerNotification();
      }
    } catch (e) {
      debugPrint('Error stopping music: $e');
    }

    _stopTimer();
  }

  Future<void> _showSleepTimerNotification() async {
    try {
      if (!settingsService.sleepTimerNotifications.value) {
        debugPrint('Sleep timer notifications disabled, skipping notification');
        return;
      }

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'music_channel',
          title: 'Sleep Timer Complete'.tr,
          body: 'Your sleep timer has ended and music has been paused.'.tr,
          category: NotificationCategory.Reminder,
          payload: {
            'type': 'sleep_timer',
            'action': 'timer_complete',
          },
          notificationLayout: NotificationLayout.Default,
          autoDismissible: true,
          showWhen: true,
          displayOnForeground: true,
          displayOnBackground: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'restart_timer',
            label: 'Restart Timer'.tr,
            autoDismissible: true,
          ),
          NotificationActionButton(
            key: 'dismiss',
            label: 'Dismiss'.tr,
            autoDismissible: true,
          ),
        ],
      );

      debugPrint('Sleep timer push notification shown');
    } catch (e) {
      debugPrint('Error showing sleep timer push notification: $e');
    }
  }

  void addTime(int minutes) {
    if (!_isActive.value) return;

    final additionalSeconds = minutes * 60;
    _remainingSeconds.value += additionalSeconds;
    _totalSeconds.value += additionalSeconds;

    // _updateSleepTimerNotification();

    debugPrint('Added $minutes minutes to sleep timer');
  }

  int get remainingMinutes => (_remainingSeconds.value / 60).ceil();

  Future<void> _loadLastSelectedDuration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMinutes =
          prefs.getInt('sleep_timer_last_selected_minutes') ?? 15;
      _lastSelectedMinutes.value = lastMinutes;
      debugPrint(
          'Loaded last selected sleep timer duration: $lastMinutes minutes');
    } catch (e) {
      debugPrint('Error loading last selected duration: $e');
    }
  }

  Future<void> _saveLastSelectedDuration(int minutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('sleep_timer_last_selected_minutes', minutes);
      _lastSelectedMinutes.value = minutes;
      debugPrint('Saved last selected sleep timer duration: $minutes minutes');
    } catch (e) {
      debugPrint('Error saving last selected duration: $e');
    }
  }

  Future<void> _showSleepTimerCountdownNotification() async {
    try {
      if (!settingsService.sleepTimerNotifications.value) {
        debugPrint(
            'Sleep timer notifications disabled, skipping countdown notification');
        return;
      }

      final minutes = _remainingSeconds.value ~/ 60;
      final seconds = _remainingSeconds.value % 60;
      final timeText =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _sleepTimerNotificationId,
          channelKey: 'sleep_timer',
          title: 'Sleep Timer Active'.tr,
          body: '${"Set Time".tr}: $timeText ${"minutes".tr}',
          category: NotificationCategory.Reminder,
          payload: {
            'type': 'sleep_timer_countdown',
            'action': 'timer_running',
          },
          notificationLayout: NotificationLayout.Default,
          autoDismissible: false,
          showWhen: true,
          displayOnForeground: true,
          displayOnBackground: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'stop_timer',
            label: 'Stop Timer'.tr,
            autoDismissible: false,
          ),
        ],
      );

      debugPrint('Sleep timer countdown notification shown');
    } catch (e) {
      debugPrint('Error showing sleep timer countdown notification: $e');
    }
  }

  // Future<void> _updateSleepTimerNotification() async {
  //   try {
  //     if (!_isActive.value) return;

  //     // Check if sleep timer notifications are enabled
  //     if (!settingsService.sleepTimerNotifications.value) {
  //       debugPrint('Sleep timer notifications disabled, skipping update');
  //       return;
  //     }

  //     final minutes = _remainingSeconds.value ~/ 60;
  //     final seconds = _remainingSeconds.value % 60;
  //     final timeText =
  //         '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

  //     // Only update if minutes have changed (to avoid unnecessary updates)
  //     if (_lastNotificationMinutes == minutes) return;
  //     _lastNotificationMinutes = minutes;

  //     await AwesomeNotifications().createNotification(
  //       content: NotificationContent(
  //         id: _sleepTimerNotificationId,
  //         channelKey: 'sleep_timer',
  //         title: 'Sleep Timer Active',
  //         body: 'Set Time: $timeText',
  //         category: NotificationCategory.Reminder,
  //         payload: {
  //           'type': 'sleep_timer_countdown',
  //           'action': 'timer_running',
  //         },
  //         notificationLayout: NotificationLayout.Default,
  //         autoDismissible: false,
  //         showWhen: true,
  //         displayOnForeground: true,
  //         displayOnBackground: true,
  //       ),
  //       actionButtons: [
  //         NotificationActionButton(
  //           key: 'stop_timer',
  //           label: 'Stop Timer',
  //           autoDismissible: false,
  //         ),
  //       ],
  //     );

  //     debugPrint('Sleep timer countdown notification updated: $timeText');
  //   } catch (e) {
  //     debugPrint('Error updating sleep timer countdown notification: $e');
  //   }
  // }

  Future<void> _cancelSleepTimerNotification() async {
    try {
      await AwesomeNotifications().cancel(_sleepTimerNotificationId);
      debugPrint('Sleep timer countdown notification cancelled');
    } catch (e) {
      debugPrint('Error cancelling sleep timer countdown notification: $e');
    }
  }

  @override
  void onClose() {
    _stopTimer();
    super.onClose();
  }
}
