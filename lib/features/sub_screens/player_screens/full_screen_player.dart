import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:velo/core/constants/app_colors.dart';
import 'package:velo/core/constants/constants.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:velo/features/home/home_controller.dart';
import 'package:velo/widgets/cached_album_artwork.dart';
import 'package:velo/widgets/seekable_progress_bar.dart';

class FullScreenPlayer extends StatelessWidget {
  final HomeController controller;

  const FullScreenPlayer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Obx(() {
            final song = controller.currentSong;
            return song == null
                ? const SizedBox.shrink()
                : CachedAlbumArtwork(
                    key: ValueKey('bg_artwork_${song.id}'),
                    songId: song.id,
                    width: double.infinity,
                    height: double.infinity,
                    highQuality: false,
                  );
          }),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.transparent),
            ),
          ),
          Obx(
            () => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: themeCtrl.currentAppTheme.value.gradientColors
                      .map((c) => c.withOpacity(0.45))
                      .toList(),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(Get.context!),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.white, size: 28),
                      ),
                      Text(
                        'Now Playing'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Expanded(
                    child: Center(
                      child: SizedBox(
                          height: ResponsiveContext(context).isTablet
                              ? 500
                              : Get.width,
                          width: ResponsiveContext(context).isTablet
                              ? 500
                              : Get.width,
                          child: _ArtworkGlass(controller: controller)),
                    ),
                  ),

                  // Obx(() {
                  //   final song = controller.currentSong;
                  //   return AnimatedSwitcher(
                  //     duration: const Duration(milliseconds: 250),
                  //     child: song == null
                  //         ? const SizedBox(
                  //             key: ValueKey('empty-wave'), height: 80)
                  //         : Container(
                  //             key: ValueKey(song.id),
                  //             height: 84,
                  //             margin:
                  //                 const EdgeInsets.symmetric(horizontal: 20),
                  //             child: WaveformWidget(
                  //               audioPath: song.data,
                  //               activeColor: AppColors.musicPrimary,
                  //               inactiveColor: Colors.white.withOpacity(0.25),
                  //               height: 84,
                  //             ),
                  //           ),
                  //   );
                  // }),

                  const SizedBox(height: 16),

                  Obx(() {
                    final song = controller.currentSong;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          song?.title ?? '—',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          song?.artist ?? 'Unknown Artist',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 14),

                  const SeekableProgressBar(style: ProgressBarStyle.full),

                  const SizedBox(height: 10),

                  Obx(() {
                    final isPlaying = controller.isPlaying;
                    final repeat = controller.repeatMode.value;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ShuffleButton(
                          active: controller.isShuffleOn.value,
                          onTap: controller.toggleShuffle,
                        ),
                        _GlassIconButton(
                          icon: Iconsax.previous,
                          onTap: controller.previousSong,
                          size: 48,
                        ),
                        _PlayPauseButton(
                          isPlaying: isPlaying,
                          onTap: controller.playPause,
                        ),
                        _GlassIconButton(
                          icon: Iconsax.next,
                          onTap: controller.nextSong,
                          size: 48,
                        ),
                        _RepeatButton(
                          mode: repeat,
                          onTap: controller.cycleRepeatMode,
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //  _GlassPill(text: 'Equlizer'.tr, onTap: (){}),
                      _GlassPill(text: 'Queue'.tr, onTap: controller.openQueue),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtworkGlass extends StatelessWidget {
  final HomeController controller;
  const _ArtworkGlass({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [AppColors.musicPrimary, AppColors.musicSecondary],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: Colors.white.withOpacity(0.18), width: 1),
            ),
            child: Obx(() {
              final song = controller.currentSong;
              if (song == null) {
                return const Center(
                  child:
                      Icon(Icons.music_note, color: Colors.white70, size: 64),
                );
              }

              return CachedAlbumArtwork(
                key: ValueKey('artwork_${song.id}'),
                songId: song.id,
                width: double.infinity,
                height: double.infinity,
                borderRadius: 18,
                highQuality: true,
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _GlassIconButton(
      {required this.icon, required this.onTap, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.musicPrimary.withOpacity(0.25),
        highlightColor: AppColors.musicPrimary.withOpacity(0.12),
        borderRadius: borderRadius,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.55),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayPauseButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: Colors.white.withOpacity(0.15),
        highlightColor: Colors.white.withOpacity(0.08),
        child: Ink(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                colors: themeCtrl.currentAppTheme.value.gradientColors),
          ),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}

class _RepeatButton extends StatelessWidget {
  final RepeatMode mode;
  final VoidCallback onTap;

  const _RepeatButton({required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (mode) {
      case RepeatMode.all:
        icon = Iconsax.repeat;
        break;
      case RepeatMode.one:
        icon = Iconsax.repeate_one;
        break;
      case RepeatMode.off:
        icon = Iconsax.repeat;
        break;
    }
    final bool active = mode != RepeatMode.off;
    final borderRadius = BorderRadius.circular(12);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.musicPrimary.withOpacity(0.25),
        highlightColor: AppColors.musicPrimary.withOpacity(0.12),
        borderRadius: borderRadius,
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: active
                ? AppColors.musicPrimary.withOpacity(0.25)
                : Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
            boxShadow: [
              if (active)
                BoxShadow(
                  color: AppColors.musicPrimary.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _GlassPill({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(20);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: AppColors.musicPrimary.withOpacity(0.2),
        highlightColor: AppColors.musicPrimary.withOpacity(0.1),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
          ),
          child: Text(
            text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _ShuffleButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _ShuffleButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.musicPrimary.withOpacity(0.25),
        highlightColor: AppColors.musicPrimary.withOpacity(0.12),
        borderRadius: borderRadius,
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: active
                ? AppColors.musicPrimary.withOpacity(0.25)
                : Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
            boxShadow: [
              if (active)
                BoxShadow(
                  color: AppColors.musicPrimary.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: const Icon(Iconsax.shuffle, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
