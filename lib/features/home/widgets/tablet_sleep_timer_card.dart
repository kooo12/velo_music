import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velo/core/constants/app_colors.dart';
import 'package:velo/core/constants/sizes.dart';
import 'package:velo/core/controllers/theme_controller.dart';

import '../home_controller.dart';

Widget buildTabletSleepTimerCard(HomeController controller) {
  final themeCtrl = Get.find<ThemeController>();
  return Obx(() {
    final isActive = controller.isSleepTimerActive;
    final timeText =
        isActive ? controller.sleepTimerFormattedTime : 'Sleep Timer';

    return GestureDetector(
      onTap: () => controller.showSleepTimerDialog(),
      child: Container(
        // height: 200,
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
                    color: AppColors.musicPrimary.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
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
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.musicPrimary
                        : AppColors.musicSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isActive ? Icons.timer : Icons.bedtime,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive ? 'Timer Started' : 'Sleep Timer',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      isActive
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
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
                                )
                              ],
                            )
                          : Text(
                              'Setup',
                              style: themeCtrl.activeTheme.textTheme.bodySmall,
                            ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: AppSizes.spaceBtwItems,
            ),
            Text(
              isActive
                  ? 'Music will pause after timer ends'
                  : 'Drift Off Without a Care: Press play on your calming playlist, set the timer for 30 minutes, and close your eyes.',
              style: themeCtrl.activeTheme.textTheme.bodySmall,
            ),
            // if (!isActive) ...[
            //   Text(
            //     'Drift Off Without a Care: Press play on your calming playlist, set the timer for 30 minutes, and close your eyes.',
            //     style: themeCtrl.activeTheme.textTheme.bodySmall,
            //   ),
            // ],
            if (isActive) ...[
              const SizedBox(height: AppSizes.spaceBtwItems * 2),
              LinearProgressIndicator(
                value: controller.sleepTimerProgress,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  });
}
