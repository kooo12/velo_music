import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:velo/core/constants/app_colors.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:velo/core/services/version_control_service.dart';

class UpdateDialog extends StatelessWidget {
  final bool isForceUpdate;
  final String currentVersion;
  final String latestVersion;
  final String title;
  final String message;

  UpdateDialog({
    super.key,
    required this.isForceUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.title,
    required this.message,
  });

  late final themeCtrl = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            minWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0x30FFFFFF),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildContent(),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildVersionInfo(),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                    child: _buildActions(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isForceUpdate
                ? Colors.red.withOpacity(0.2)
                : AppColors.musicPrimary.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: isForceUpdate
                  ? Colors.red.withOpacity(0.5)
                  : AppColors.musicPrimary.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Text(
            isForceUpdate ? '⚠️' : '🚀',
            style: const TextStyle(
              fontSize: 36,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: themeCtrl.activeTheme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        if (isForceUpdate) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              'Required Update',
              style: themeCtrl.activeTheme.textTheme.bodySmall?.copyWith(
                color: Colors.red.shade300,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          message,
          style: themeCtrl.activeTheme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.9),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildVersionItem('Current', currentVersion, Colors.grey),
          Icon(
            Iconsax.arrow_right_3,
            color: Colors.white.withOpacity(0.5),
            size: 20,
          ),
          _buildVersionItem('Latest', latestVersion, AppColors.green),
        ],
      ),
    );
  }

  Widget _buildVersionItem(String label, String version, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: themeCtrl.activeTheme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'v$version',
          style: themeCtrl.activeTheme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final versionService = Get.find<VersionControlService>();

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: ElevatedButton(
                onPressed: () async {
                  await versionService.launchAppStore();
                  if (!isForceUpdate) {
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isForceUpdate
                      ? Colors.red.withOpacity(0.3)
                      : themeCtrl.currentAppTheme.value.gradientColors.first
                          .withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isForceUpdate
                          ? Colors.red.withOpacity(0.5)
                          : themeCtrl.currentAppTheme.value.gradientColors.last
                              .withOpacity(0.8),
                      width: 1.5,
                    ),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Iconsax.arrow_up_2,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Update Now',
                      style:
                          themeCtrl.activeTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!isForceUpdate) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
            child: Text(
              'Later',
              style: themeCtrl.activeTheme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  static Future<void> show({
    required bool isForceUpdate,
    required String currentVersion,
    required String latestVersion,
    required String title,
    required String message,
  }) async {
    if (Get.isDialogOpen == true) {
      debugPrint('Dialog already open, skipping update dialog');
      return;
    }

    await Get.dialog(
      UpdateDialog(
        isForceUpdate: isForceUpdate,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        title: title,
        message: message,
      ),
      barrierDismissible: !isForceUpdate,
      barrierColor: Colors.black.withOpacity(0.7),
    );
  }
}
