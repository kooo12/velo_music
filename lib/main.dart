import 'dart:async';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:velo/core/bindings/app_binding.dart';
import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:velo/core/config/app_config.dart';
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

  if (!kIsWeb && Platform.isAndroid) {
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
    await Firebase.initializeApp(options: _getFirebaseOptions());
    debugPrint(
        "=>Firebase initialized successfully on ${!kIsWeb ? Platform.operatingSystem : 'web'}");

    if (!kIsWeb) {
      await _initializeCrashlytics();
    }
  } catch (e, stackTrace) {
    debugPrint("=>Firebase initialization failed: $e");
    debugPrint("=>Stack trace: $stackTrace");
    try {
      await Firebase.initializeApp();
      if (!kIsWeb) {
        await _initializeCrashlytics();
      }
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
    handler = await _initAudioService();
    debugPrint('AudioService initialized successfully');
  } catch (e) {
    debugPrint('AudioService initialization failed: $e');
    handler = AppAudioHandler();
  }

  if (!Get.isRegistered<AppAudioHandler>()) {
    Get.put<AppAudioHandler>(handler, permanent: true);
  }

  final lifecycleManager = AppLifecycleManager(
    Get.find<svc.AudioPlayerService>(),
    handler,
  );
  Get.put<AppLifecycleManager>(lifecycleManager, permanent: true);

  _initAppLinks();

  runApp(
    DevicePreview(
      enabled: kIsWeb,
      defaultDevice: Devices.android.googlePixel9,
      backgroundColor: const Color(0xFF134E5E),
      isToolbarVisible: false,
      builder: (context) => const MyApp(),
    ),
  );
}

void _initAppLinks() {
  final appLinks = AppLinks();

  appLinks.uriLinkStream.listen((uri) {
    debugPrint('==> AppLinks Received URI (bg/fg): $uri');
    if (uri.path.isNotEmpty) {
      debugPrint('==> AppLinks Path: ${uri.path}');
    }
  });

  appLinks.getInitialLink().then((uri) {
    if (uri != null) {
      debugPrint('==> AppLinks Received URI (cold start): $uri');
      if (uri.path.isNotEmpty) {
        debugPrint('==> AppLinks Path: ${uri.path}');
      }
    }
  }).catchError((e) {
    debugPrint('==> AppLinks Failed to get initial link: $e');
  });
}

FirebaseOptions _getFirebaseOptions() {
  if (kIsWeb) {
    return const FirebaseOptions(
      apiKey: AppConfig.firebaseWebApiKey,
      appId: AppConfig.firebaseWebAppId,
      messagingSenderId: AppConfig.firebaseMessagingSenderId,
      projectId: AppConfig.firebaseProjectId,
      storageBucket: AppConfig.firebaseStorageBucket,
      measurementId: AppConfig.firebaseWebMeasurementId,
      authDomain: AppConfig.firebaseWebAuthDomain,
    );
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return const FirebaseOptions(
        apiKey: AppConfig.firebaseAndroidApiKey,
        appId: AppConfig.firebaseAndroidAppId,
        messagingSenderId: AppConfig.firebaseMessagingSenderId,
        projectId: AppConfig.firebaseProjectId,
        storageBucket: AppConfig.firebaseStorageBucket,
      );
    case TargetPlatform.iOS:
      return const FirebaseOptions(
        apiKey: AppConfig.firebaseIosApiKey,
        appId: AppConfig.firebaseIosAppId,
        messagingSenderId: AppConfig.firebaseMessagingSenderId,
        projectId: AppConfig.firebaseProjectId,
        storageBucket: AppConfig.firebaseStorageBucket,
        iosBundleId: AppConfig.firebaseIosBundleId,
      );
    default:
      throw UnsupportedError('Platform not supported');
  }
}

Future<AppAudioHandler> _initAudioService() async {
  return await AudioService.init(
    builder: () => AppAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ako.velo.audio',
      androidNotificationChannelName: 'Velo Music Playback',
      androidNotificationChannelDescription: 'Velo music playback controls',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidShowNotificationBadge: true,
      androidNotificationClickStartsActivity: true,
      androidResumeOnClick: true,
      fastForwardInterval: Duration(seconds: 10),
      rewindInterval: Duration(seconds: 10),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var themeController = Get.put(ThemeController());

    return Obx(
      () => GetMaterialApp(
        useInheritedMediaQuery: true,
        // showPerformanceOverlay: kDebugMode,
        // showSemanticsDebugger: kDebugMode,
        // debugShowMaterialGrid: kDebugMode,
        themeMode:
            themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        debugShowCheckedModeBanner: false,
        builder: DevicePreview.appBuilder,
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
