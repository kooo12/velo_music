import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velo/core/constants/sizes.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:velo/features/onboarding/onboarding_controller.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static const List<String> _backgroundImages = [
    'https://ik.imagekit.io/aungkooo/Velo%20Music%20Player/Onboarding/photo-1566808907623-51b8fc382454.jpeg',
    'https://ik.imagekit.io/aungkooo/Velo%20Music%20Player/Onboarding/photo-1619983081563-430f63602796.jpeg',
    'https://ik.imagekit.io/aungkooo/Velo%20Music%20Player/Onboarding/photo-1459749411175-04bf5292ceea.jpeg',
  ];

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    final controller = Get.put(OnboardingController());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildAnimatedBackground(controller),
          _buildGradientOverlay(themeCtrl),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildWelcomeStep(themeCtrl, controller),
                      _buildMusicPermissionStep(themeCtrl, controller),
                      _buildNotificationPermissionStep(themeCtrl, controller),
                    ],
                  ),
                ),
                _buildDotIndicators(controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(OnboardingController controller) {
    return Obx(() {
      final currentIndex = controller.currentPage.value;
      return Stack(
        fit: StackFit.expand,
        children: List.generate(_backgroundImages.length, (index) {
          return AnimatedOpacity(
            opacity: currentIndex == index ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            child: CachedNetworkImage(
              imageUrl: _backgroundImages[index],
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.2),
              colorBlendMode: BlendMode.darken,
            ),
          );
        }),
      );
    });
  }

  Widget _buildGradientOverlay(ThemeController themeCtrl) {
    return Obx(() {
      final colors = themeCtrl.currentAppTheme.value.gradientColors;
      final dominantColor = colors.isNotEmpty ? colors.first : Colors.black;

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.4, 0.7, 1.0],
            colors: [
              Colors.transparent,
              dominantColor.withOpacity(0.3),
              dominantColor.withOpacity(0.8),
              dominantColor,
            ],
          ),
        ),
      );
    });
  }

  Widget _buildWelcomeStep(
      ThemeController themeCtrl, OnboardingController controller) {
    return _buildContentCard(
      themeCtrl: themeCtrl,
      title: 'Welcome\nto Velo',
      subtitle:
          "Immerse yourself in a universe of sound and rhythm without limits.",
      primaryActionText: 'Get Started',
      onPrimaryAction: () => controller.nextPage(),
    );
  }

  Widget _buildMusicPermissionStep(
      ThemeController themeCtrl, OnboardingController controller) {
    return _buildContentCard(
      themeCtrl: themeCtrl,
      title: 'Local\nMusic',
      subtitle:
          "Grant access to your device's music folder to experience your locally saved tracks alongside our library.",
      primaryActionText: 'Allow Access',
      onPrimaryAction: () => controller.requestMusicPermission(),
      secondaryActionText: 'Skip for now',
      onSecondaryAction: () => controller.skipPermission(),
    );
  }

  Widget _buildNotificationPermissionStep(
      ThemeController themeCtrl, OnboardingController controller) {
    return _buildContentCard(
      themeCtrl: themeCtrl,
      title: 'Stay\nInformed',
      subtitle:
          "Turn on notifications for exclusive new releases, personalized daily mixes, and live events.",
      primaryActionText: 'Enable Notifications',
      onPrimaryAction: () => controller.requestNotificationPermission(),
      secondaryActionText: 'Skip for now',
      onSecondaryAction: () => controller.skipPermission(),
    );
  }

  Widget _buildContentCard({
    required ThemeController themeCtrl,
    required String title,
    required String subtitle,
    required String primaryActionText,
    required VoidCallback onPrimaryAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.tr,
            style: themeCtrl.activeTheme.textTheme.headlineLarge!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 56,
              height: 1.1,
              fontFamily: 'TitanOne',
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  offset: const Offset(2, 4),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            subtitle.tr,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w400,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.8),
                  offset: const Offset(1, 1),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xl * 1.5),
          _buildPrimaryButton(primaryActionText, onPrimaryAction),
          if (secondaryActionText != null && onSecondaryAction != null) ...[
            const SizedBox(height: AppSizes.sm),
            _buildSecondaryButton(secondaryActionText, onSecondaryAction),
          ],
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: onPressed,
            child: Text(
              text.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: TextButton(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text.tr,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDotIndicators(OnboardingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xl),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final isSelected = controller.currentPage.value == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: isSelected ? 32 : 10,
              height: 10,
              decoration: BoxDecoration(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
            );
          }),
        ),
      ),
    );
  }
}
