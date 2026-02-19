import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonus/core/constants/app_colors.dart';
import 'package:sonus/core/constants/sizes.dart';
import 'package:sonus/core/controllers/theme_controller.dart';
import 'package:sonus/features/notifications/notification_settings_controller.dart';

class NotificationSettingsPage extends StatelessWidget {
  NotificationSettingsPage({super.key});

  final themeCtrl = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationSettingsController>();

    return Scaffold(
      backgroundColor: themeCtrl.currentAppTheme.value.gradientColors.first,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        // actions: [
        //   TextButton(
        //       onPressed: controller.saveSettings,
        //       child: Text(
        //         'Save',
        //         style: themeCtrl.activeTheme.textTheme.bodyMedium,
        //       ))
        // ],
        title: Text(
          'Notification Settings',
          style: themeCtrl.activeTheme.textTheme.headlineSmall!
              .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
            // gradient: LinearGradient(
            //   begin: Alignment.topLeft,
            //   end: Alignment.bottomRight,
            //   colors: [
            //     AppColors.musicGradientStart,
            //     AppColors.musicGradientEnd,
            //   ],
            // ),
            ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                title: 'Push Notifications',
                icon: Icons.notifications,
                children: [
                  _buildSwitchTile(
                    title: 'Enable Push Notifications',
                    subtitle: 'Receive notifications from the app',
                    value: controller.isPushNotificationsEnabled,
                    onChanged: controller.togglePushNotifications,
                  ),
                  _buildSwitchTile(
                    title: 'Notification Sound',
                    subtitle: 'Play sound when notifications arrive',
                    value: controller.isNotificationSoundEnabled,
                    onChanged: controller.toggleNotificationSound,
                    enabled: controller.isPushNotificationsEnabled,
                  ),
                  _buildSwitchTile(
                    title: 'Vibration',
                    subtitle: 'Vibrate when notifications arrive',
                    value: controller.isNotificationVibrationEnabled,
                    onChanged: controller.toggleNotificationVibration,
                    enabled: controller.isPushNotificationsEnabled,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildSectionCard(
                title: 'Sleep Timer Notifications',
                icon: Icons.timer,
                children: [
                  _buildSwitchTile(
                    title: 'Sleep Timer Alerts',
                    subtitle: 'Get notified when sleep timer ends',
                    value: controller.isSleepTimerNotificationsEnabled,
                    onChanged: controller.toggleSleepTimerNotifications,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildSectionCard(
                title: 'Quiet Hours',
                icon: Icons.bedtime,
                children: [
                  _buildSwitchTile(
                    title: 'Enable Quiet Hours',
                    subtitle: 'Disable notifications during specific times',
                    value: controller.isQuietHoursEnabled,
                    onChanged: controller.toggleQuietHours,
                  ),
                  Obx(() {
                    if (controller.isQuietHoursEnabled.value) {
                      return Column(
                        children: [
                          _buildTimeTile(
                            title: 'Start Time',
                            subtitle: 'When to start quiet hours',
                            time: controller.quietStart.value,
                            onTap: () => controller.selectTime(context, true),
                          ),
                          _buildTimeTile(
                            title: 'End Time',
                            subtitle: 'When to end quiet hours',
                            time: controller.quietEnd.value,
                            onTap: () => controller.selectTime(context, false),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),

              const SizedBox(height: 40),

              // Save Button
              // _buildSaveButton(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0x30FFFFFF),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.musicPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: themeCtrl.activeTheme.textTheme.headlineSmall!
                          .copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required RxBool value,
    required ValueChanged<bool> onChanged,
    RxBool? enabled,
  }) {
    return Obx(() {
      final isEnabled = enabled?.value ?? true;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: themeCtrl.activeTheme.textTheme.bodyLarge!.copyWith(
                      color: isEnabled ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
                      color: isEnabled ? Colors.white70 : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isEnabled ? value.value : false,
              onChanged: isEnabled ? onChanged : null,
              activeColor: themeCtrl.currentAppTheme.value.gradientColors.last,
              inactiveThumbColor: Colors.white54,
              inactiveTrackColor: Colors.white24,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTimeTile({
    required String title,
    required String subtitle,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: themeCtrl.activeTheme.textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time.format(Get.context!),
              style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}
