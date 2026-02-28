import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:velo/core/services/network_manager.dart';
import 'package:velo/features/notifications/service/notification_settings_service.dart';
import 'package:velo/routhing/app_routes.dart';

class FCMService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final networkManager = Get.find<NetworkManager>();

  final RxString fcmToken = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // initializeFCM();
  }

  Future<void> shouldShowNotiRequest() async {
    final notiSettings = Get.find<NotificationSettingsService>();
    PermissionStatus status = await Permission.notification.status;

    if (!status.isGranted && !notiSettings.hasShownNotificationRequest.value) {
      notiSettings.hasShownNotificationRequest.value = true;
      await notiSettings.saveSettings();
      Get.toNamed(Routes.NOTIFICATIONSREQUESTPAGE);
    }

    await initializeFCM();
  }

  Future<void> initializeFCM() async {
    try {
      // final hasInternet =
      //     networkManager.networkStatus.value == NetworkStatus.connected;
      // if (!hasInternet) {
      //   debugPrint('FCM: No internet connection - skipping initialization');
      //   return;
      // }

      await _getAndSaveToken();

      _messaging.onTokenRefresh.listen(_handleTokenRefresh);
    } catch (e) {
      debugPrint('FCM: Error initializing: $e');
    }
  }

  Future<void> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        debugPrint('FCM: User granted permission');
      }
    } catch (e) {
      debugPrint('FCM: Error requesting permission: $e');
    }
  }

  Future<void> _getAndSaveToken() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          final apnsToken = await _messaging.getAPNSToken();
          if (apnsToken == null) {
            debugPrint('FCM: APNS token not available yet, waiting...');
            await Future.delayed(const Duration(seconds: 2));
            final retryApnsToken = await _messaging.getAPNSToken();
            if (retryApnsToken == null) {
              debugPrint('FCM: APNS token still not available after retry');
            } else {
              debugPrint('FCM: APNS token obtained: $retryApnsToken');
            }
          } else {
            debugPrint('FCM: APNS token obtained: $apnsToken');
          }
        } catch (apnsError) {
          debugPrint('FCM: Error getting APNS token: $apnsError');
        }
      }

      String? token = await _messaging.getToken();
      if (token != null) {
        fcmToken.value = token;
        debugPrint('FCM: Token obtained: $token');

        await _saveTokenToDatabase(token);
      } else {
        debugPrint('FCM: Token is null');
      }
    } catch (e) {
      debugPrint('FCM: Error getting token: $e');
    }
  }

  Future<void> _handleTokenRefresh(String newToken) async {
    try {
      debugPrint('FCM: Token refreshed: $newToken');
      fcmToken.value = newToken;

      await _saveTokenToDatabase(newToken);
    } catch (e) {
      debugPrint('FCM: Error handling token refresh: $e');
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final timestamp = FieldValue.serverTimestamp();

      await _firestore.collection('fcm_tokens').doc(token).set({
        'token': token,
        'userId': null,
        'userEmail': null,
        'deviceType': defaultTargetPlatform.name,
        'createdAt': timestamp,
        'lastUsed': timestamp,
        'isActive': true,
      }, SetOptions(merge: true));

      debugPrint('FCM: Token saved to fcm_tokens collection');
    } catch (e) {
      debugPrint('FCM: Error saving token to database: $e');
    }
  }
}
