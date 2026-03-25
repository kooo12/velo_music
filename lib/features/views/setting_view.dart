import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:velo/core/constants/app_colors.dart';
import 'package:velo/core/controllers/app_controller.dart';
import 'package:velo/core/controllers/language_controller.dart';
import 'package:velo/core/helper/loaders.dart';
import 'package:velo/core/services/audio_service.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:velo/features/home/home_controller.dart';
import 'package:velo/routhing/app_routes.dart';

class ProfileView extends GetView<HomeController> {
  ProfileView({super.key});

  final themeCtrl = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (!kIsWeb && Platform.isAndroid) _buildStatistics(),
          if (!kIsWeb && Platform.isAndroid) const SizedBox(height: 15),
          if (kIsWeb) _buildStatistics(),
          if (kIsWeb) const SizedBox(height: 15),
          _buildSettingsSection(),
          const SizedBox(height: 15),
          _buildAboutSection(),
          const SizedBox(
            height: 170,
          )
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Obx(() => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Music Stats'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Songs'.tr,
                      '${controller.allSongs.length}',
                      Icons.music_note,
                      AppColors.white,
                      AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatItem(
                      'Playlists'.tr,
                      '${controller.userPlaylists.length}',
                      Icons.queue_music,
                      AppColors.musicAccent,
                      AppColors.musicAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                        'Liked Songs'.tr,
                        '${controller.likedSongs.length}',
                        Icons.favorite,
                        AppColors.musicAccent,
                        Colors.redAccent),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatItem(
                      'Artists'.tr,
                      '${controller.allArtists.length}',
                      Icons.person,
                      AppColors.white,
                      AppColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    AppLoader.customToast(
                        message:
                            'Refreshing Library: scanning for new music files...');
                    final svc = Get.find<AudioPlayerService>();
                    await svc.loadSongs();
                    AppLoader.customToast(
                        message:
                            'Scan complete. Found ${svc.allSongs.length} songs');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.musicSecondary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    'Refresh Library'.tr,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    final languageCtrl = Get.find<LanguageController>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Settings'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Obx(() => _buildSettingItem(
                'Language'.tr,
                'Switch language preferences to change English / မြန်မာ'.tr,
                Icons.language,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Text(
                    //   'EN',
                    //   style: TextStyle(
                    //     color: Colors.white.withOpacity(0.7),
                    //     fontSize: 14,
                    //   ),
                    // ),
                    Switch(
                      value: languageCtrl.currentLangIndex.value == 1,
                      onChanged: (value) {
                        if (value) {
                          languageCtrl.changeLanguage('မြန်မာ');
                        } else {
                          languageCtrl.changeLanguage('English');
                        }
                      },
                      activeColor:
                          themeCtrl.currentAppTheme.value.gradientColors.first,
                      inactiveThumbColor: Colors.white,
                      activeTrackColor: Colors.white.withOpacity(0.2),
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                    ),
                    // Text(
                    //   'MM',
                    //   style: TextStyle(
                    //     color: Colors.white.withOpacity(0.7),
                    //     fontSize: 14,
                    //   ),
                    // ),
                  ],
                ),
              )),
          _buildSettingItem(
            'Notifications'.tr,
            'Manage notification preferences'.tr,
            Icons.notifications,
            onTap: () {
              Get.toNamed(Routes.NOTIFICATIONSETTINGS);
            },
          ),
          _buildSettingItem(
            'Theme'.tr,
            'Choose your desired theme'.tr,
            Iconsax.sun_1_copy,
            onTap: () {
              Get.toNamed(Routes.THEME);
            },
          ),
          if (!kIsWeb && Platform.isAndroid)
            _buildSettingItem(
              'Storage'.tr,
              'Manage music folder locations'.tr,
              Icons.storage,
              onTap: () {
                Get.toNamed(Routes.STORAGEMANAGERPAGE);
              },
            ),
          if (kIsWeb)
            _buildSettingItem(
              'Storage'.tr,
              'Manage music folder locations'.tr,
              Icons.storage,
              onTap: () {
                Get.toNamed(Routes.STORAGEMANAGERPAGE);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.musicSecondary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.white),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white.withOpacity(0.5),
            size: 16,
          ),
      onTap: onTap,
    );
  }

  Widget _buildAboutSection() {
    var appCtrl = Get.find<AppController>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildAboutItem(
            'Version'.tr,
            appCtrl.version?.value.isNotEmpty == true
                ? 'v${appCtrl.version!.value} (Build ${appCtrl.buildNumber!.value})'
                : '1.0.0',
            Icons.info_outline,
          ),
          _buildAboutItem(
            'Privacy Policy'.tr,
            'View our privacy policy'.tr,
            Icons.privacy_tip,
            onTap: () => Get.toNamed(Routes.PRIVACY),
          ),
          _buildAboutItem(
            'Terms of Service'.tr,
            'View terms and conditions'.tr,
            Icons.description,
            onTap: () => Get.toNamed(Routes.TERMS),
          ),
          _buildAboutItem('Feedback'.tr,
              'Share your feedback and suggestions'.tr, Icons.feedback,
              onTap: () => Get.toNamed(Routes.FEEDBACK)
              // controller.launchWeb(
              //   Uri.parse(
              //       'https://docs.google.com/forms/d/e/1FAIpQLSeomxUmZBcReLAUMAv8SPDlzrpxUbJmD2fpDWl28vmzCNadfA/viewform?usp=dialog'),
              // ),
              ),

          // Obx(() {
          //   if (!Get.isRegistered<RemoteConfigService>()) {
          //     return const SizedBox.shrink();
          //   }
          //   final remoteConfigService = Get.find<RemoteConfigService>();

          //   final developerLink =
          //       remoteConfigService.currentDeveloperProfileLink;
          //   if (developerLink.isEmpty) {
          //     return const SizedBox.shrink();
          //   }

          //   return _buildAboutItem(
          //     'Meet the Developer'.tr,
          //     'Connect with the creator and see more work'.tr,
          //     Icons.contact_support,
          //     onTap: () {
          //       try {
          //         controller.launchWeb(Uri.parse(developerLink));
          //       } catch (e) {
          //         AppLoader.customToast(
          //           message: 'Invalid developer profile link',
          //         );
          //       }
          //     },
          //   );
          // }),
        ],
      ),
    );
  }

  Widget _buildAboutItem(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white.withOpacity(0.8)),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      trailing: onTap != null
          ? Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            )
          : null,
      onTap: onTap,
    );
  }
}
