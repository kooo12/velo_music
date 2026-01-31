import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:sonus/core/constants/app_colors.dart';
import 'package:sonus/features/home/home_controller.dart';
import 'package:sonus/features/queue/queue_controller.dart';
import 'package:sonus/widgets/cached_album_artwork.dart';
import 'package:sonus/widgets/seekable_progress_bar.dart';

class FullScreenPlayerLandscape extends StatelessWidget {
  final HomeController controller;

  const FullScreenPlayerLandscape({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final q = Get.put(QueueController());
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black.withOpacity(0.6)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.85),
                  Colors.black.withOpacity(0.95),
                ],
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: Get.width * 0.38,
                          margin: const EdgeInsets.only(right: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.14)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Queue'.tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: q.clearAll,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.18)),
                                      ),
                                      child: Text('Clear All'.tr,
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Obx(() {
                                  if (q.queue.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'Queue is empty'.tr,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    );
                                  }
                                  return ReorderableListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 4),
                                    itemCount: q.queue.length,
                                    onReorder: q.move,
                                    proxyDecorator: (child, index, animation) {
                                      return Material(
                                          color: Colors.transparent,
                                          child: child);
                                    },
                                    itemBuilder: (context, index) {
                                      final song = q.queue[index];
                                      final isCurrent =
                                          index == q.currentIndex.value;
                                      return Container(
                                        key: ValueKey(song.id),
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.06),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.14)),
                                        ),
                                        child: ListTile(
                                          onTap: () => q.playAt(index),
                                          leading: CircleAvatar(
                                            backgroundColor: isCurrent
                                                ? AppColors.musicPrimary
                                                : Colors.white.withOpacity(0.2),
                                            child: Icon(
                                                isCurrent
                                                    ? Icons.equalizer
                                                    : Icons.music_note,
                                                color: Colors.white),
                                          ),
                                          title: Text(
                                            song.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Text(
                                            song.artist,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7)),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.close,
                                                    color: Colors.white70),
                                                onPressed: () =>
                                                    q.removeAt(index),
                                              ),
                                              const Icon(Icons.drag_handle,
                                                  color: Colors.white54),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              SizedBox(
                                height: Get.height * 0.45,
                                child: Center(
                                  child: _ArtworkGlass(controller: controller),
                                ),
                              ),
                              const SizedBox(height: 20),
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
                              const SeekableProgressBar(
                                  style: ProgressBarStyle.landscape),
                              const SizedBox(height: 10),
                              Obx(() {
                                final isPlaying = controller.isPlaying;
                                final repeat = controller.repeatMode.value;
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
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
                            ],
                          ),
                        ),
                      ],
                    ),

                    // const SizedBox(height: 16),

                    // // Bottom actions
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     // _GlassPill(text: 'Lyrics', onTap: () {}),
                    //     // _GlassPill(
                    //     //     text: 'Equalizer'.tr,
                    //     //     onTap: () => controller.openEqualizer(controller)),
                    //     _GlassPill(text: 'Queue'.tr, onTap: controller.openQueue),
                    //   ],
                    // ),
                  )
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
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                colors: [AppColors.musicPrimary, AppColors.musicSecondary]),
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

class GlassPill extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const GlassPill({super.key, required this.text, required this.onTap});

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
