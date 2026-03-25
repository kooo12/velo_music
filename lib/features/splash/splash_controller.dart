import 'dart:async';
import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velo/core/controllers/app_controller.dart';
import 'package:velo/core/helper/orientation_helper.dart';
import 'package:velo/core/helper/update_dialog.dart';
import 'package:velo/core/services/audio_service.dart';
import 'package:velo/core/services/network_manager.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:velo/core/services/version_control_service.dart';
import 'package:velo/routhing/app_routes.dart';

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
      _checkAppVersion(),
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
        } else if (kIsWeb) {
          await audioService.loadSongs(skipPermissionCheck: true);
        } else {
          debugPrint(
              'No audio permission granted yet, skipping song loading during startup');
        }
      }
    } catch (e) {
      debugPrint('Error loading songs in background: $e');
    }
  }

  Future<void> _checkAppVersion() async {
    loadingText.value = 'Checking app version...';
    try {
      await Future.delayed(const Duration(seconds: 2));

      if (!Get.isRegistered<VersionControlService>()) {
        debugPrint('VersionControlService not registered yet');
        return;
      }

      final versionService = Get.find<VersionControlService>();
      final updateStatus = await versionService.checkForUpdate();

      if (updateStatus == UpdateStatus.forceUpdate ||
          updateStatus == UpdateStatus.optionalUpdate) {
        await Future.delayed(const Duration(milliseconds: 500));

        final isForceUpdate = updateStatus == UpdateStatus.forceUpdate;
        final currentVersion = versionService.currentVersion;
        final latestVersion = versionService.latestVersion;
        final title = versionService.getUpdateTitle();
        final message = versionService.getUpdateMessage();

        await UpdateDialog.show(
          isForceUpdate: isForceUpdate,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          title: title,
          message: message,
        );
      } else {
        debugPrint('App is up to date');
      }
    } catch (e) {
      debugPrint('Error checking app version: $e');
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

  Future<void> _navigateToHome() async {
    Get.offAllNamed(Routes.HOME);
  }
}
