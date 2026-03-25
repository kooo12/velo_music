import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:velo/core/constants/sizes.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();

    return Obx(
      () => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          // backgroundColor: themeCtrl.currentAppTheme.value.gradientColors.first,
          elevation: 0,
          // flexibleSpace: Container(
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       begin: Alignment.topCenter,
          //       end: Alignment.bottomRight,
          //       colors: themeCtrl.currentAppTheme.value.gradientColors,
          //     ),
          //   ),
          // ),
          title: Text(
            'privacy_title'.tr,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: themeCtrl.currentAppTheme.value.gradientColors,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.defaultSpace * 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Text(
                        'privacy_last_updated'.tr,
                        style: themeCtrl.activeTheme.textTheme.bodyMedium
                            ?.copyWith(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _PrivacySection(
                      title: 'privacy_info_collect_title'.tr,
                      content: 'privacy_info_collect_content'.tr,
                    ),
                    _PrivacySection(
                      title: 'privacy_how_use_title'.tr,
                      content: 'privacy_how_use_content'.tr,
                    ),
                    _PrivacySection(
                      title: 'privacy_sharing_title'.tr,
                      content: 'privacy_sharing_content'.tr,
                    ),
                    _PrivacySection(
                      title: 'privacy_security_title'.tr,
                      content: 'privacy_security_content'.tr,
                    ),
                    _PrivacySection(
                      title: 'privacy_rights_title'.tr,
                      content: 'privacy_rights_content'.tr,
                    ),
                    _PrivacySection(
                      title: 'privacy_cookies_title'.tr,
                      content: 'privacy_cookies_content'.tr,
                    ),
                    _PrivacySection(
                      title: 'privacy_children_title'.tr,
                      content: 'privacy_children_content'.tr,
                    ),
                    _PrivacySection(
                      title: 'privacy_changes_title'.tr,
                      content: 'privacy_changes_content'.tr,
                    ),
                    _PrivacySection(
                      title: 'privacy_contact_title'.tr,
                      content: 'privacy_contact_content'.tr,
                      showSocialLinks: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final String title;
  final String content;
  final bool showSocialLinks;

  const _PrivacySection({
    required this.title,
    required this.content,
    this.showSocialLinks = false,
  });

  Widget _buildFormattedContent(String content) {
    final themeCtrl = Get.find<ThemeController>();
    final lines = content.split('\n');
    final formattedLines = <Widget>[];

    for (var line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) {
        formattedLines.add(const SizedBox(height: 8));
        continue;
      }

      if (trimmedLine.startsWith('•')) {
        formattedLines.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    trimmedLine.substring(1).trim(),
                    style: themeCtrl.activeTheme.textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        formattedLines.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              trimmedLine,
              style: themeCtrl.activeTheme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: formattedLines,
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    return Container(
      margin: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: themeCtrl.activeTheme.textTheme.headlineSmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormattedContent(content),
          if (showSocialLinks) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SocialLinkButton(
                  icon: FontAwesomeIcons.facebook,
                  label: 'Facebook',
                  onTap: () => _launchUrl('htApp://www.facebook.com/kooo1210'),
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                _SocialLinkButton(
                  icon: FontAwesomeIcons.linkedin,
                  label: 'LinkedIn',
                  onTap: () => _launchUrl(
                      'htApp://www.linkedin.com/in/aung-ko-oo-042342242/'),
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                _SocialLinkButton(
                  icon: FontAwesomeIcons.telegram,
                  label: 'Telegram',
                  onTap: () => _launchUrl('htApp://t.me/kooo2109'),
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SocialLinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _SocialLinkButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: themeCtrl.isDarkMode
              ? color.withOpacity(0.2)
              : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
