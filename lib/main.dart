import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sonus/core/bindings/app_binding.dart';
import 'package:sonus/core/utils/theme_controller.dart';
import 'package:sonus/features/splash/splash.dart';
import 'package:sonus/routhing/app_pages.dart';
import 'package:sonus/routhing/app_routes.dart';

FutureOr<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        apiKey: "AIzaSyBbxyR0dQK3jJceq_dd4DIUOOTIQiJZRJo",
        appId: '1:756997181231:android:bd65ae870d1537ca7b5bda',
        messagingSenderId: '756997181231',
        projectId: 'music-player-a4a63',
        storageBucket: 'music-player-a4a63.firebasestorage.app',
      );
    } else if (Platform.isIOS) {
      firebaseOptions = const FirebaseOptions(
        apiKey: "AIzaSyAb3J8LZl-hHkaGE1-0uX8kLAC5PCx-5Ls",
        appId: '1:756997181231:ios:ae511bb0eb49ca787b5bda',
        messagingSenderId: '756997181231',
        projectId: 'music-player-a4a63',
        storageBucket: 'music-player-a4a63.firebasestorage.app',
        iosBundleId: 'com.ako.sonus',
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
  } catch (e, stackTrace) {
    debugPrint("=>Firebase initialization failed: $e");
    debugPrint("=>Stack trace: $stackTrace");
    try {
      await Firebase.initializeApp();
      FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
    } catch (_) {
      debugPrint("=>Could not initialize Firebase or Crashlytics");
    }
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
      ),
    );
  }
}
