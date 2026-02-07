import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:sonus/features/home/home_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'notification_settings_service.dart';
import 'sleep_timer_service.dart';

class NotificationHandlerService extends GetxService {
  late final NotificationSettingsService _settingsService;

  @override
  void onInit() {
    super.onInit();
    _initializeSettingsService();
    _initializeNotificationHandling();
  }

  void _initializeSettingsService() {
    try {
      _settingsService = Get.find<NotificationSettingsService>();
      debugPrint('Notification settings service found');
    } catch (e) {
      _settingsService =
          Get.put(NotificationSettingsService(), permanent: true);
      debugPrint('Notification settings service created');
    }
  }

  Future<void> _initializeNotificationHandling() async {
    try {
      debugPrint('Initializing notification handling...');

      await _setupFCMHandlers();

      await _setupAwesomeNotifications();

      debugPrint('Notification handling initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notification handling: $e');
    }
  }

  Future<void> _setupFCMHandlers() async {
    try {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      debugPrint('FCM handlers setup complete');
    } catch (e) {
      debugPrint('Error setting up FCM handlers: $e');
    }
  }

  Future<void> _setupAwesomeNotifications() async {
    try {
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: 'push_notifications',
            channelName: 'Push Notifications',
            channelDescription: 'Channel for push notifications',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            playSound: _settingsService.notificationSound.value,
            enableVibration: _settingsService.notificationVibration.value,
          ),
          NotificationChannel(
            channelKey: 'in_app_messages',
            channelName: 'In-App Messages',
            channelDescription: 'Channel for in-app messages',
            defaultColor: const Color(0xFF2196F3),
            ledColor: Colors.blue,
            importance: NotificationImportance.High,
            playSound: _settingsService.notificationSound.value,
            enableVibration: _settingsService.notificationVibration.value,
          ),
        ],
        debug: kDebugMode,
      );

      AwesomeNotifications().setListeners(
        onActionReceivedMethod: _onNotificationActionReceived,
        onNotificationCreatedMethod: _onNotificationCreated,
        onNotificationDisplayedMethod: _onNotificationDisplayed,
        onDismissActionReceivedMethod: _onNotificationDismissed,
      );

      debugPrint('Awesome Notifications setup complete');
    } catch (e) {
      debugPrint('Error setting up Awesome Notifications: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      debugPrint('Received foreground message: ${message.messageId}');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      if (!_settingsService.areNotificationsAllowed) {
        debugPrint('Notifications disabled, ignoring message');
        return;
      }

      await _showPushNotification(
        title: message.notification?.title ?? 'New Message',
        body: message.notification?.body ?? '',
        data: message.data,
        imageUrl: message.notification?.android?.imageUrl ??
            message.notification?.apple?.imageUrl,
      );
    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }

  Future<void> _handleMessageTap(RemoteMessage message) async {
    try {
      debugPrint('Message tapped: ${message.messageId}');
      debugPrint('Data: ${message.data}');

      final data = message.data;
      final actionUrl = data['action_url'];
      final actionTitle = data['action_title'];

      if (actionUrl != null && actionUrl.isNotEmpty) {
        await _handleNotificationAction(actionTitle, actionUrl);
      } else {
        debugPrint('No specific action defined');
      }
    } catch (e) {
      debugPrint('Error handling message tap: $e');
    }
  }

  Future<void> _showPushNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: 'push_notifications',
          title: title,
          body: body,
          bigPicture: imageUrl,
          notificationLayout: imageUrl != null
              ? NotificationLayout.BigPicture
              : NotificationLayout.Default,
          payload: data != null
              ? Map<String, String?>.from(
                  data.map((k, v) => MapEntry(k, v?.toString())))
              : null,
        ),
      );
    } catch (e) {
      debugPrint('Error showing push notification: $e');
    }
  }

  Future<void> _handleNotificationAction(
      String? actionTitle, String actionUrl) async {
    try {
      debugPrint('Handling notification action: $actionTitle -> $actionUrl');

      if (actionUrl.startsWith('http')) {
        try {
          final uri = Uri.parse(actionUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
            debugPrint('Opening external URL: $actionUrl');
          } else {
            debugPrint('Could not launch URL: $actionUrl');
          }
        } catch (e) {
          debugPrint('Error launching URL: $e');
        }
      } else {
        debugPrint('Navigating to: $actionUrl');
        Get.toNamed(actionUrl);
      }
    } catch (e) {
      debugPrint('Error handling notification action: $e');
    }
  }

  static Future<void> _onNotificationActionReceived(
      ReceivedAction action) async {
    try {
      debugPrint('Notification action received: ${action.id}');
      debugPrint('Action data: ${action.payload}');

      final payload = action.payload ?? {};
      final type = payload['type'];
      final actionUrl = payload['actionUrl'];
      final actionTitle = payload['actionTitle'];
      final actionKey = action.buttonKeyPressed;

      if (type == 'sleep_timer' || type == 'sleep_timer_countdown') {
        final service = Get.find<NotificationHandlerService>();
        await service._handleSleepTimerAction(actionKey);
        return;
      }

      if (actionUrl != null && actionUrl.isNotEmpty) {
        final service = Get.find<NotificationHandlerService>();
        await service._handleNotificationAction(actionTitle, actionUrl);
      }
    } catch (e) {
      debugPrint('Error in notification action handler: $e');
    }
  }

  static Future<void> _onNotificationCreated(
      ReceivedNotification notification) async {
    debugPrint('Notification created: ${notification.id}');
  }

  static Future<void> _onNotificationDisplayed(
      ReceivedNotification notification) async {
    debugPrint('Notification displayed: ${notification.id}');
  }

  static Future<void> _onNotificationDismissed(ReceivedAction action) async {
    debugPrint('Notification dismissed: ${action.id}');
  }

  Future<void> _handleSleepTimerAction(String? actionKey) async {
    try {
      debugPrint('Sleep timer action received: $actionKey');

      if (actionKey == 'restart_timer') {
        final homeCtrl = Get.find<HomeController>();
        homeCtrl.restartSleepTimer();

        debugPrint('Sleep timer restarted');
      } else if (actionKey == 'stop_timer') {
        try {
          final sleepTimerService = Get.find<SleepTimerService>();
          sleepTimerService.stopTimer();
          debugPrint('Sleep timer stopped from notification');
        } catch (e) {
          debugPrint('Error stopping sleep timer: $e');
        }
      } else if (actionKey == 'dismiss') {
        debugPrint('Sleep timer notification dismissed');
      }
    } catch (e) {
      debugPrint('Error handling sleep timer action: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}
