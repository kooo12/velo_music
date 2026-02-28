import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:velo/core/constants/sizes.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();

    return Obx(
      () => Scaffold(
        appBar: AppBar(
          backgroundColor: themeCtrl.currentAppTheme.value.gradientColors.first,
          elevation: 0,
          // flexibleSpace: Container(
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       begin: Alignment.topLeft,
          //       end: Alignment.bottomRight,
          //       colors: themeCtrl.currentAppTheme.value.gradientColors,
          //     ),
          //   ),
          // ),
          title: Text(
            'terms_title'.tr,
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.defaultSpace * 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'terms_last_updated'.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                        ),
                  ),
                  const SizedBox(height: 40),
                  _TermsSection(
                    title: 'terms_acceptance_title'.tr,
                    content: 'terms_acceptance_content'.tr,
                  ),
                  _TermsSection(
                    title: 'terms_description_title'.tr,
                    content: 'terms_description_content'.tr,
                  ),
                  _TermsSection(
                    title: 'terms_user_accounts_title'.tr,
                    content: 'terms_user_accounts_content'.tr,
                  ),
                  _TermsSection(
                    title: 'terms_acceptable_use_title'.tr,
                    content: 'terms_acceptable_use_content'.tr,
                  ),
                  _TermsSection(
                    title: 'terms_intellectual_property_title'.tr,
                    content: 'terms_intellectual_property_content'.tr,
                  ),
                  _TermsSection(
                    title: 'terms_download_content_title'.tr,
                    content: 'terms_download_content_content'.tr,
                  ),
                  _TermsSection(
                    title: 'terms_privacy_data_title'.tr,
                    content: 'terms_privacy_data_content'.tr,
                  ),
                  _TermsSection(
                    title: 'terms_disclaimers_title'.tr,
                    content: 'terms_disclaimers_content'.tr,
                  ),
                  _TermsSection(
                    title: 'terms_termination_title'.tr,
                    content: 'terms_termination_content'.tr,
                  ),
                  _TermsSection(
                    title: 'terms_changes_title'.tr,
                    content: 'terms_changes_content'.tr,
                  ),
                  _TermsSection(
                    title: 'terms_governing_law_title'.tr,
                    content: 'terms_governing_law_content'.tr,
                  ),
                  _TermsSection(
                    title: 'terms_contact_title'.tr,
                    content: 'terms_contact_content'.tr,
                    showSocialLinks: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String content;
  final bool showSocialLinks;

  const _TermsSection({
    required this.title,
    required this.content,
    this.showSocialLinks = false,
  });

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
                    style: themeCtrl.activeTheme.textTheme.bodyLarge?.copyWith(
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

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    return Container(
      margin: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(width: 12),
                _SocialLinkButton(
                  icon: FontAwesomeIcons.linkedin,
                  label: 'LinkedIn',
                  onTap: () => _launchUrl(
                      'htApp://www.linkedin.com/in/aung-ko-oo-042342242/'),
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
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
