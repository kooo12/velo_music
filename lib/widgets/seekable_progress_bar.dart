import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonus/core/constants/app_colors.dart';
import 'package:sonus/features/home/home_controller.dart';

class SeekableProgressBar extends StatelessWidget {
  final ProgressBarStyle style;

  const SeekableProgressBar({
    super.key,
    this.style = ProgressBarStyle.mini,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(() {
      final current = controller.currentPosition;
      final total = controller.totalDuration;
      final clampedTotal = total <= 0 ? 1.0 : total;

      final displayPosition =
          controller.isSeeking ? controller.seekingPosition : current;

      switch (style) {
        case ProgressBarStyle.mini:
          return _buildMiniStyle(controller, displayPosition, total);
        case ProgressBarStyle.full:
          return _buildFullStyle(
              context, controller, displayPosition, total, clampedTotal);
        case ProgressBarStyle.landscape:
          return _buildLandscapeStyle(
              context, controller, displayPosition, total, clampedTotal);
      }
    });
  }

  Widget _buildMiniStyle(
    HomeController controller,
    double displayPosition,
    double total,
  ) {
    final displayValue =
        total > 0 ? (displayPosition / total).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Text(
            controller.formatTime(displayPosition),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: const SliderThemeData(
                trackHeight: 2,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: displayValue,
                onChanged: (value) {
                  final newPosition = value * total;
                  controller.updateSeekingPosition(newPosition);
                },
                onChangeEnd: (value) {
                  final newPosition = value * total;
                  controller.completeSeeking(newPosition);
                },
                activeColor: Colors.white,
                inactiveColor: Colors.white.withOpacity(0.3),
                thumbColor: Colors.white,
              ),
            ),
          ),
          Text(
            controller.formatTime(total),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullStyle(
    BuildContext context,
    HomeController controller,
    double displayPosition,
    double total,
    double clampedTotal,
  ) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: AppColors.musicSecondary,
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: AppColors.musicAccent,
            overlayColor: AppColors.musicPrimary.withOpacity(0.25),
          ),
          child: Slider(
            value: displayPosition.clamp(0, clampedTotal),
            min: 0,
            max: clampedTotal,
            onChanged: (v) {
              controller.updateSeekingPosition(v);
            },
            onChangeEnd: (v) {
              controller.completeSeeking(v);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              controller.formatTime(displayPosition),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            Text(
              controller.formatTime(total),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLandscapeStyle(
    BuildContext context,
    HomeController controller,
    double displayPosition,
    double total,
    double clampedTotal,
  ) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: AppColors.musicSecondary,
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: AppColors.musicAccent,
            overlayColor: AppColors.musicPrimary.withOpacity(0.25),
          ),
          child: Slider(
            value: displayPosition.clamp(0, clampedTotal),
            min: 0,
            max: clampedTotal,
            onChanged: (v) {
              controller.updateSeekingPosition(v);
            },
            onChangeEnd: (v) {
              controller.completeSeeking(v);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              controller.formatTime(displayPosition),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            Text(
              controller.formatTime(total),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum ProgressBarStyle {
  mini,
  full,
  landscape,
}
