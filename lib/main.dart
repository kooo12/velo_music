import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:velo/core/bindings/app_binding.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:velo/core/services/app_audio_handler.dart';
import 'package:velo/core/services/app_audio_session.dart';
import 'package:velo/core/services/app_lifecycle_manager.dart';
import 'package:velo/core/services/audio_service.dart' as svc;
import 'package:velo/core/translations/app_translations.dart';
import 'package:velo/features/splash/splash.dart';
import 'package:velo/routhing/app_pages.dart';
import 'package:velo/routhing/app_routes.dart';

FutureOr<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  if (Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [
        SystemUiOverlay.top,
      ],
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        // systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  try {
    FirebaseOptions? firebaseOptions;

    if (Platform.isAndroid) {
      firebaseOptions = const FirebaseOptions(
        apiKey: "AIzaSyA1p04lX1jOdHeARyi_SoyCdfkoWQ3QzqA",
        appId: '1:615822783937:android:8a9e82f7ca58a01d112b40',
        messagingSenderId: '615822783937',
        projectId: 'velo-muisc',
        storageBucket: 'velo-muisc.firebasestorage.app',
      );
    } else if (Platform.isIOS) {
      firebaseOptions = const FirebaseOptions(
        apiKey: "AIzaSyAgupPVPyRvPRqDoijHvhPaEymrMY_awcE",
        appId: '1:615822783937:ios:934f16dc2541bccc112b40',
        messagingSenderId: '615822783937',
        projectId: 'velo-muisc',
        storageBucket: 'velo-muisc.firebasestorage.app',
        iosBundleId: 'com.ako.velo',
      );
    }

    if (firebaseOptions != null) {
      await Firebase.initializeApp(options: firebaseOptions);
      debugPrint(
          "=>Firebase initialized successfully on ${Platform.operatingSystem}");
    } else {
      await Firebase.initializeApp();
      debugPrint(
          "=>Firebase initialized with default config on ${Platform.operatingSystem}");
    }

    await _initializeCrashlytics();
  } catch (e, stackTrace) {
    debugPrint("=>Firebase initialization failed: $e");
    debugPrint("=>Stack trace: $stackTrace");
    try {
      await Firebase.initializeApp();
      await _initializeCrashlytics();
      FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
    } catch (_) {
      debugPrint("=>Could not initialize Firebase or Crashlytics");
    }
  }

  Get.put<svc.AudioPlayerService>(svc.AudioPlayerService(), permanent: true);
  final appSession = AppAudioSession();
  await appSession.configure();
  Get.put<AppAudioSession>(appSession, permanent: true);

  AppAudioHandler handler;
  try {
    handler = Get.find<AppAudioHandler>();
    debugPrint('AppAudioHandler already exists in GetX, reusing...');
  } catch (_) {
    handler = await AudioService.init(
      builder: () => AppAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'media_playback',
        androidNotificationChannelName: 'Media Playback',
        androidNotificationChannelDescription: 'Music playback controls',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
        androidShowNotificationBadge: false,
        androidNotificationClickStartsActivity: true,
        androidResumeOnClick: true,
        fastForwardInterval: Duration(seconds: 10),
        rewindInterval: Duration(seconds: 10),
      ),
    );
    Get.put<AppAudioHandler>(handler, permanent: true);
    final lifecycleManager = AppLifecycleManager(
      Get.find<svc.AudioPlayerService>(),
      handler,
    );
    Get.put<AppLifecycleManager>(lifecycleManager, permanent: true);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var themeController = Get.put(ThemeController());

    return Obx(
      () => GetMaterialApp(
        // showPerformanceOverlay: kDebugMode,
        // showSemanticsDebugger: kDebugMode,
        // debugShowMaterialGrid: kDebugMode,
        themeMode:
            themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        debugShowCheckedModeBanner: false,
        binds: AppBinding().dependencies(),

        initialRoute: Routes.SPLASH,
        theme: themeController.activeTheme,
        defaultTransition: Transition.fade,
        getPages: AppPages.pages,
        darkTheme: themeController.darkTheme,
        home: const SplashScreen(),
        locale: AppTranslation.locale,
        fallbackLocale: AppTranslation.fallbackLocale,
        translations: AppTranslation(),
      ),
    );
  }
}

Future<void> _initializeCrashlytics() async {
  try {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      kReleaseMode,
    );

    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      if (kDebugMode) {
        FlutterError.presentError(errorDetails);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    debugPrint("=>Firebase Crashlytics initialized (enabled: $kReleaseMode)");
  } catch (e, stackTrace) {
    debugPrint("=>Firebase Crashlytics initialization failed: $e");
    debugPrint("=>Stack trace: $stackTrace");
  }
}
