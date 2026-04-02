import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:velo/core/constants/constants.dart';
import 'package:velo/core/constants/sizes.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:velo/features/home/home_controller.dart';

class NotificationRequestPage extends GetView<HomeController> {
  const NotificationRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    final isTablet = ResponsiveContext(context).isTablet;

    return Scaffold(
      body: GetBuilder<HomeController>(builder: (controller) {
        return Stack(
          children: [
            _buildBackground(themeCtrl),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Column(
                  children: [
                    const Spacer(flex: 1),
                    _buildHeadline(themeCtrl),
                    const SizedBox(height: AppSizes.xl * 1.5),
                    _buildGlassCard(context, isTablet),
                    const Spacer(flex: 2),
                    _buildActionButtons(controller, themeCtrl, isTablet),
                    const SizedBox(height: AppSizes.md),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildBackground(ThemeController themeCtrl) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.4, 1.0],
          colors: [
            themeCtrl.currentAppTheme.value.gradientColors.first,
            themeCtrl.currentAppTheme.value.gradientColors.first
                .withOpacity(0.8),
            themeCtrl.currentAppTheme.value.gradientColors.last,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: _buildBlurCircle(
                250, themeCtrl.currentAppTheme.value.gradientColors.last),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBlurCircle(
                200, themeCtrl.currentAppTheme.value.gradientColors.first),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildHeadline(ThemeController themeCtrl) {
    return Column(
      children: [
        _StaggeredAnimation(
          delay: 200,
          child: Text(
            'Stay'.tr.toUpperCase(),
            style: themeCtrl.activeTheme.textTheme.headlineLarge!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 70,
              fontFamily: 'TitanOne',
              letterSpacing: 4,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.35),
                  offset: const Offset(4, 4),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
        _StaggeredAnimation(
          delay: 400,
          child: Text(
            'Informed'.tr,
            style: themeCtrl.activeTheme.textTheme.headlineMedium!.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.bold,
              fontSize: 38,
              fontFamily: 'TitanOne',
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.25),
                  offset: const Offset(2, 2),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard(BuildContext context, bool isTablet) {
    return _StaggeredAnimation(
      delay: 600,
      slideOffset: const Offset(0, 0.2),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LottieBuilder.asset(
                'assets/notification_lottie.json',
                height: 180,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                'Never miss a beat'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                "Enable notifications to get updates on new releases, personalized playlists, and more."
                    .tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      HomeController controller, ThemeController themeCtrl, bool isTablet) {
    return Column(
      children: [
        _StaggeredAnimation(
          delay: 800,
          slideOffset: const Offset(0, 0.5),
          child: Container(
            width: isTablet ? 350 : double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF7FC7D9), Color(0xFF365486)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF365486).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () async {
                await controller.fcmService.requestPermission();
                Get.back();
              },
              child: Text(
                'Enable Notifications'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        _StaggeredAnimation(
          delay: 1000,
          child: TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Maybe Later'.tr,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StaggeredAnimation extends StatelessWidget {
  final Widget child;
  final int delay;
  final Offset slideOffset;

  const _StaggeredAnimation({
    required this.child,
    required this.delay,
    this.slideOffset = const Offset(-0.3, 0),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        final animationValue =
            ((value - (delay / 2000)).clamp(0.0, 1.0) / (1 - (delay / 2000)))
                .clamp(0.0, 1.0);

        return Opacity(
          opacity: animationValue,
          child: Transform.translate(
            offset: Offset(
              slideOffset.dx * 100 * (1 - animationValue),
              slideOffset.dy * 100 * (1 - animationValue),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
