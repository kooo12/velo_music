import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velo/core/controllers/app_controller.dart';
import 'package:velo/features/splash/splash_controller.dart';
import 'package:velo/widgets/loading_widget.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SplashController controller = Get.put(SplashController());
    final appCtrl = Get.find<AppController>();

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: controller.themeCtrl.currentAppTheme.value.gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/app_icon.png',
                        fit: BoxFit.fill,
                        height: 120,
                        width: 140,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Velo',
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 36,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Music, Your World',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Obx(
                      () => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          controller.loadingText.value,
                          key: ValueKey(controller.loadingText.value),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: Obx(
                        () => Column(
                          children: [
                            LinearProgressIndicator(
                              value: controller.progress.value,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.8),
                              ),
                              minHeight: 3,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(controller.progress.value * 100).toInt()}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Obx(
                      () => controller.isLoading.value
                          ? const LoadingWidget()
                          : const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ],
                ),
              ),
              Obx(
                () => Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Text(
                    'Version ${appCtrl.version?.value ?? '1.0.0'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
