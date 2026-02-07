import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:sonus/core/constants/app_colors.dart';
import 'package:sonus/core/constants/constants.dart';
import 'package:sonus/core/constants/sizes.dart';
import 'package:sonus/core/controllers/theme_controller.dart';
import 'package:sonus/features/home/home_controller.dart';

class NotificationRequestPage extends GetView<HomeController> {
  const NotificationRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<HomeController>(builder: (controller) {
        final themeCtrl = Get.find<ThemeController>();
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: themeCtrl.isDarkMode
                      ? AppColors.darkGradientColors
                      : AppColors.primaryGradientColors,
                ),
              ),
            ),
            Positioned(
              top: 80,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(-30 * (1 - value), 0),
                          child: child,
                        ),
                      );
                    },
                    child: Text('Stay',
                        overflow: TextOverflow.ellipsis,
                        style: themeCtrl.activeTheme.textTheme.headlineLarge!
                            .copyWith(
                                color: AppColors.musicSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 60,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'TitanOne',
                                letterSpacing: 5,
                                shadows: [
                              Shadow(
                                  color: AppColors.darkGrey.withOpacity(0.5),
                                  blurRadius: 1.0,
                                  offset: const Offset(5, 8)),
                            ])),
                  ),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      final opacity =
                          ((value - 0.2).clamp(0.0, 1.0) / 0.8).clamp(0.0, 1.0);
                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(-50 * (1 - value), 0),
                          child: child,
                        ),
                      );
                    },
                    child: Text('  Informed.',
                        overflow: TextOverflow.ellipsis,
                        style: themeCtrl.activeTheme.textTheme.headlineLarge!
                            .copyWith(
                                color:
                                    AppColors.musicSecondary.withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                                fontSize: 45,
                                // fontStyle: FontStyle.italic,
                                fontFamily: 'TitanOne',
                                letterSpacing: 5,
                                shadows: [
                              Shadow(
                                  color: AppColors.black.withOpacity(0.5),
                                  blurRadius: 1.0,
                                  offset: const Offset(5, 8)),
                            ])),
                  ),
                ],
              ),
            ),
            // Positioned(
            //   top: 90,
            //   right: 20,
            //   child: Container(
            //     decoration: BoxDecoration(
            //       color: AppColors.white.withOpacity(0.2),
            //       shape: BoxShape.circle,
            //     ),
            //     child: IconButton(
            //         onPressed: () => Get.back(), icon: const Icon(Icons.close)),
            //   ),
            // ),
            Positioned(
              bottom: 90,
              right: 30,
              left: 30,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1200),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  final opacity =
                      ((value - 0.4).clamp(0.0, 1.0) / 0.6).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(0, 50 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  width: ResponsiveContext(context).isTablet
                      ? Get.width * 0.4
                      : null,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSizes.xs),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor:
                            AppColors.musicSecondary.withOpacity(0.6),
                        foregroundColor: AppColors.white.withOpacity(0.8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.xl, vertical: AppSizes.md),
                      ),
                      onPressed: () async {
                        await controller.fcmService.requestPermission();
                        Get.back();
                      },
                      child: Text(
                        'Enable Notifications'.tr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: themeCtrl.activeTheme.textTheme.titleLarge!
                            .copyWith(color: AppColors.white.withOpacity(0.8)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            LottieBuilder.asset(
              'assets/notification_lottie.json',
            ),
          ],
        );
      }),
    );
  }
}
