import 'dart:async';
import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonus/core/controllers/app_controller.dart';
import 'package:sonus/core/helper/orientation_helper.dart';
import 'package:sonus/core/services/audio_service.dart';
import 'package:sonus/core/services/network_manager.dart';
import 'package:sonus/core/controllers/theme_controller.dart';
import 'package:sonus/routhing/app_routes.dart';

class SplashController extends GetxController {
  final _appCtrl = Get.find<AppController>();
  final themeCtrl = Get.find<ThemeController>();
  final networkManager = Get.find<NetworkManager>();

  var isLoading = true.obs;
  var loadingText = 'Initializing...'.obs;
  var progress = 0.0.obs;

  @override
  void onInit() async {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OrientationHelper.setOrientation(Get.context!);
    });

    await _startInitialization();
  }

  Future<void> _startInitialization() async {
    try {
      _appCtrl.setup().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('App setup timeout - continuing with offline mode');
        },
      ).catchError((e) {
        debugPrint('App setup error: $e');
      });

      await _performCriticalStartupTasks();
    } catch (e) {
      debugPrint('Initialization error: $e');
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateToHome();
    }
  }

  Future<void> _performCriticalStartupTasks() async {
    _startBackgroundTasks();

    await _loadSongsInBackground();

    progress.value = 1.0;
    await Future.delayed(const Duration(milliseconds: 300));
    _navigateToHome();
  }

  Future<void> _startBackgroundTasks() async {
    Future.wait([
      _initializeNotifications(),
      _loadUserPreferences(),
    ]).catchError((e, stackTrace) {
      debugPrint('Background task error: $e');
      debugPrint('Stack trace: $stackTrace');
      return <void>[];
    });
  }

  Future<void> _loadSongsInBackground() async {
    try {
      if (Get.isRegistered<AudioPlayerService>()) {
        final audioService = Get.find<AudioPlayerService>();

        final hasPermission = await audioService.checkPermissionStatusOnly();

        if (hasPermission) {
          debugPrint(
              'Permission already granted, loading songs in background...');
          if (Platform.isAndroid) {
            await audioService.loadSongs(skipPermissionCheck: true);
          } else if (Platform.isIOS) {
            await audioService.loadSongsForIOS(skipPermissionCheck: true);
          }
          debugPrint(
              'Songs loaded in background: ${audioService.allSongs.length} songs');
        } else {
          debugPrint(
              'No audio permission granted yet, skipping song loading during startup');
        }
      }
    } catch (e) {
      debugPrint('Error loading songs in background: $e');
    }
  }

  Future<void> _initializeNotifications() async {
    loadingText.value = 'Setting up notifications...';
    try {
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic tests',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
          ),
          NotificationChannel(
            channelKey: 'music_channel',
            channelName: 'Music Player',
            channelDescription:
                'Notification channel for music player controls',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            playSound: false,
            enableVibration: false,
          ),
          NotificationChannel(
            channelKey: 'sleep_timer',
            channelName: 'Sleep Timer',
            channelDescription: 'Notification channel for sleep timer alerts',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true,
          ),
        ],
      );
      // NotificationSettings settings = await messaging.requestPermission(
      //   alert: true,
      //   announcement: false,
      //   badge: true,
      //   carPlay: false,
      //   criticalAlert: false,
      //   provisional: false,
      //   sound: true,
      // );

      // if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      //   debugPrint('User granted permission');
      //   // Get FCM token
      //   String? token = await messaging.getToken();
      //   debugPrint('FCM Token: $token');
      // } else {
      //   debugPrint('User declined or has not accepted permission');
      // }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<void> _loadUserPreferences() async {
    loadingText.value = 'Loading preferences...';
    try {
      _appCtrl.updateTheme();
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> _navigateToHome() async {
    Get.offAllNamed(Routes.HOME);
  }
}
