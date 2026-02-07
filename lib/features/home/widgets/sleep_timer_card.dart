import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonus/core/constants/app_colors.dart';
import 'package:sonus/core/constants/sizes.dart';
import 'package:sonus/core/controllers/theme_controller.dart';
import 'package:sonus/features/home/home_controller.dart';

Widget buildSleepTimerCard(HomeController controller) {
  final themeCtrl = Get.find<ThemeController>();
  return Obx(() {
    final isActive = controller.isSleepTimerActive;
    final timeText =
        isActive ? controller.sleepTimerFormattedTime : 'Sleep Timer'.tr;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => controller.showSleepTimerDialog(),
        child: Padding(
          padding: const EdgeInsets.only(right: AppSizes.defaultSpace),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.musicSecondary.withOpacity(0.2)
                  : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isActive
                    ? AppColors.musicPrimary.withOpacity(0.5)
                    : Colors.white.withOpacity(0.2),
                width: isActive ? 2 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.musicPrimary.withOpacity(0.15),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.musicPrimary
                            : AppColors.musicSecondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isActive ? Icons.timer : Icons.bedtime,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isActive ? 'Sleep Timer'.tr : 'Sleep Timer'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (!isActive)
                      Text(
                        'Set up'.tr,
                        style: themeCtrl.activeTheme.textTheme.bodySmall,
                      ),
                    if (isActive) ...[
                      Text(
                        timeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSizes.spaceBtwItems),
                      GestureDetector(
                        onTap: () => controller.stopSleepTimer(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.stop,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
                if (isActive) ...[
                  const SizedBox(height: AppSizes.spaceBtwItems * 2),
                  LinearProgressIndicator(
                    value: controller.sleepTimerProgress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  });
}
