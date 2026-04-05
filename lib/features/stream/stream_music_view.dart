import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velo/core/constants/app_colors.dart';
import 'package:velo/core/constants/sizes.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:velo/core/models/jamendo/jamendo_album_model.dart';
import 'package:velo/core/models/jamendo/jamendo_track_model.dart';
import 'package:velo/features/stream/stream_controller.dart';
import 'package:velo/features/stream/widgets/jamendo_track_detail_sheet.dart';
import 'package:velo/routhing/app_routes.dart';
import 'package:velo/widgets/loading_widget.dart';
import 'package:velo/widgets/no_connection_widget.dart';
import 'package:velo/core/services/network_manager.dart';
import 'package:velo/core/constants/constants.dart';

class StreamMusicView extends GetView<StreamMusicController> {
  StreamMusicView({super.key});

  final themeCtrl = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final network = Get.find<NetworkManager>();

    return Obx(() {
      final isOffline =
          network.networkStatus.value == NetworkStatus.disconnected;
      final hasData = controller.topTracks.isNotEmpty;

      if (isOffline && !hasData) {
        return NoConnectionWidget(onRetry: controller.refresh);
      }

      return Stack(
        children: [
          RefreshIndicator(
            color: Colors.white,
            backgroundColor: Colors.white12,
            onRefresh: controller.refresh,
            child: SingleChildScrollView(
              key: const PageStorageKey('stream_scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                left: AppSizes.defaultSpace,
                bottom: 180,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _SectionHeader(
                    title: 'Top Charts',
                    subtitle: 'Global pulse of the indie scene',
                    actionLabel: 'VIEW ALL',
                    onAction: () => Get.toNamed(Routes.JAMENDO_LIST,
                        arguments: {'title': 'Top Charts', 'type': 'top'}),
                  ),
                  const SizedBox(height: 14),
                  _buildTopChartsHero(context),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'New Releases',
                    actionLabel: 'SEE ALL',
                    onAction: () => Get.toNamed(Routes.JAMENDO_LIST,
                        arguments: {
                          'title': 'New Releases',
                          'type': 'newreleases'
                        }),
                  ),
                  const SizedBox(height: 14),
                  _buildNewReleases(),
                  const SizedBox(height: 24),
                  const _SectionHeader(
                    title: 'Your Daily Mix',
                    subtitle: 'Curated just for you',
                  ),
                  const SizedBox(height: 14),
                  _buildDailyMix(context),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Recommended',
                    actionLabel: 'SEE ALL',
                    onAction: () => Get.toNamed(Routes.JAMENDO_LIST,
                        arguments: {
                          'title': 'Recommended Tracks',
                          'type': 'recommended'
                        }),
                  ),
                  const SizedBox(height: 14),
                  _buildRecommended(context),
                  ResponsiveContext(context).isTabletLandscape
                      ? const SizedBox()
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Powered by Jamendo',
                              style: themeCtrl.activeTheme.textTheme.bodyLarge!
                                  .copyWith(
                                      color: Colors.white.withOpacity(0.2)),
                            ),
                          )),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 8),
                    Text(
                      'Offline Mode • No Internet Connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ResponsiveContext(context).isTabletLandscape
              ? Positioned(
                  bottom: 10,
                  right: 20,
                  child: Text(
                    'Powered by Jamendo',
                    style: themeCtrl.activeTheme.textTheme.bodyLarge!
                        .copyWith(color: AppColors.white.withOpacity(0.2)),
                  ),
                )
              : const SizedBox()
        ],
      );
    });
  }

  Widget _buildTopChartsHero(BuildContext context) {
    if (controller.isLoadingTop.value && controller.topTracks.isEmpty) {
      return _shimmerPlaceholder(height: 280);
    }
    if (controller.hasErrorTop.value && controller.topTracks.isEmpty) {
      return _errorWidget('Failed to load top charts', controller.refresh);
    }
    if (controller.topTracks.isEmpty) return const SizedBox.shrink();

    final featured = controller.topTracks.first;

    return Column(
      children: [
        RepaintBoundary(
          child: GestureDetector(
            onTap: () => JamendoTrackDetailSheet.show(context, featured),
            child: Container(
            margin: const EdgeInsets.only(right: AppSizes.defaultSpace),
            height: 280,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: featured.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.white10,
                    child: const Icon(Icons.music_note,
                        color: Colors.white38, size: 60),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.3, 0.6, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeCtrl
                              .currentAppTheme.value.gradientColors.first,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '#1 TRENDING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        featured.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        featured.artistName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Obx(() {
                    final isCurrent =
                        controller.currentTrack.value?.id == featured.id;
                    final playing = isCurrent && controller.isPlaying;
                    final loading = isCurrent && controller.isLoadingPreview;
                    return _PlayPillButton(
                      isPlaying: playing,
                      isLoading: loading,
                      onTap: () => controller.playPreview(featured,
                          contextList: controller.topTracks),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
        SizedBox(
          height: 72,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollEndNotification && n.metrics.extentAfter < 100) {
                controller.loadMoreTopTracks();
              }
              return false;
            },
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.topTracks.length - 1,
              itemBuilder: (ctx, i) {
                final t = controller.topTracks[i + 1];
                return RepaintBoundary(
                  child: _TopTrackListItem(
                    rank: i + 2,
                    track: t,
                    onTap: () => JamendoTrackDetailSheet.show(ctx, t),
                    ctrl: controller,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewReleases() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGenreFilters(),
        const SizedBox(height: 12),
        if (controller.isLoadingReleases.value &&
            controller.newReleases.isEmpty)
          _horizontalShimmerRow(height: 160)
        else if (controller.newReleases.isEmpty)
          const SizedBox.shrink()
        else
          SizedBox(
            height: 180,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollEndNotification && n.metrics.extentAfter < 100) {
                  controller.loadMoreNewReleases();
                }
                return false;
              },
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.newReleases.length +
                    (controller.hasMoreReleases.value ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == controller.newReleases.length) {
                    return const _LoadingCard();
                  }
                  return RepaintBoundary(
                    child: _AlbumCard(album: controller.newReleases[i]),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGenreFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: AppSizes.defaultSpace),
      child: Obx(() => Row(
            children: controller.availableGenres.map((genre) {
              final isSelected =
                  controller.selectedNewReleaseGenre.value == genre;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(genre),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) controller.setGenre(genre);
                  },
                  selectedColor: themeCtrl
                      .currentAppTheme.value.gradientColors.first
                      .withOpacity(0.8),
                  backgroundColor: themeCtrl
                      .currentAppTheme.value.gradientColors.last
                      .withOpacity(0.8),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? themeCtrl.currentAppTheme.value.gradientColors.first
                              .withOpacity(0.5)
                          : Colors.black.withOpacity(0.1),
                    ),
                  ),
                  showCheckmark: false,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              );
            }).toList(),
          )),
    );
  }

  Widget _buildDailyMix(BuildContext context) {
    if (controller.isLoadingMix.value && controller.dailyMix.isEmpty) {
      return _shimmerPlaceholder(height: 200);
    }
    if (controller.dailyMix.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        itemCount: controller.dailyMix.length,
        padEnds: false,
        itemBuilder: (ctx, i) {
          final track = controller.dailyMix[i];
          return RepaintBoundary(
            child: _MixCard(track: track, ctrl: controller),
          );
        },
      ),
    );
  }

  Widget _buildRecommended(BuildContext context) {
    if (controller.isLoadingRec.value && controller.recommended.isEmpty) {
      return _horizontalShimmerRow(height: 160);
    }
    if (controller.hasErrorRec.value && controller.recommended.isEmpty) {
      return _errorWidget(
          'Failed to load recommendations', controller.loadMoreRecommended);
    }
    if (controller.recommended.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 175,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollEndNotification && n.metrics.extentAfter < 100) {
            controller.loadMoreRecommended();
          }
          return false;
        },
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.recommended.length +
              (controller.hasMoreRec.value ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i == controller.recommended.length) {
              return const _LoadingCard();
            }
            final t = controller.recommended[i];
            return RepaintBoundary(
              child: _RecommendedCard(
                track: t,
                onTap: () => JamendoTrackDetailSheet.show(ctx, t),
                ctrl: controller,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _shimmerPlaceholder({double height = 200}) {
    return Container(
      margin: const EdgeInsets.only(right: AppSizes.defaultSpace),
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: const Center(
        child: LoadingWidget(color: Colors.white38),
      ),
    );
  }

  Widget _horizontalShimmerRow({double height = 160}) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          width: 140,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _errorWidget(String msg, VoidCallback onRetry) {
    return Container(
      margin: const EdgeInsets.only(right: AppSizes.defaultSpace),
      height: 120,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(msg,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child:
                  const Text('Retry', style: TextStyle(color: Colors.white60)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.defaultSpace),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
              ],
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopTrackListItem extends StatelessWidget {
  final int rank;
  final JamendoTrack track;
  final VoidCallback onTap;
  final StreamMusicController ctrl;

  const _TopTrackListItem({
    required this.rank,
    required this.track,
    required this.onTap,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Text(
              '#$rank',
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: track.imageUrl,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 42,
                  height: 42,
                  color: Colors.white10,
                  child: const Icon(Icons.music_note,
                      color: Colors.white38, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    track.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artistName,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Obx(() {
              final isCurrent = ctrl.currentTrack.value?.id == track.id;
              final playing = isCurrent && ctrl.isPlaying;
              final loading = isCurrent && ctrl.isLoadingPreview;
              return GestureDetector(
                onTap: () =>
                    ctrl.playPreview(track, contextList: ctrl.topTracks),
                child: loading
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: Padding(
                          padding: EdgeInsets.all(6.0),
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 1.2,
                          ),
                        ),
                      )
                    : Icon(
                        playing ? Icons.pause_circle : Icons.play_circle,
                        color: Colors.white.withOpacity(0.5),
                        size: 28,
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final JamendoAlbum album;
  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    // final themeCtrl = Get.find<ThemeController>();

    return GestureDetector(
      onTap: () => Get.toNamed(Routes.JAMENDO_LIST, arguments: {
        'title': album.name,
        'type': 'album',
        'id': album.id,
      }),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: album.imageUrl,
                    width: 140,
                    height: 120,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 140,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.album,
                          color: Colors.white38, size: 40),
                    ),
                  ),
                ),
                // Positioned(
                //   right: 8,
                //   bottom: 8,
                //   child: Container(
                //     width: 32,
                //     height: 32,
                //     decoration: BoxDecoration(
                //       color:
                //           themeCtrl.currentAppTheme.value.gradientColors.last,
                //       shape: BoxShape.circle,
                //     ),
                //     child: const Icon(Icons.play_arrow_rounded,
                //         color: Colors.white, size: 20),
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              album.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${album.artistName} • ${album.releaseYear}',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


class _RecommendedCard extends StatelessWidget {
  final JamendoTrack track;
  final VoidCallback onTap;
  final StreamMusicController ctrl;

  const _RecommendedCard({
    required this.track,
    required this.onTap,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: track.imageUrl,
                    width: 150,
                    height: 130,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 150,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Icon(Icons.music_note,
                          color: Colors.white38, size: 40),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Obx(() {
                    final isCurrent = ctrl.currentTrack.value?.id == track.id;
                    final playing = isCurrent && ctrl.isPlaying;
                    final loading = isCurrent && ctrl.isLoadingPreview;
                    return GestureDetector(
                      onTap: () => ctrl.playPreview(track,
                          contextList: ctrl.recommended),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: themeCtrl
                              .currentAppTheme.value.gradientColors.first,
                          shape: BoxShape.circle,
                        ),
                        child: loading
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 1.2,
                                ),
                              )
                            : Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              track.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              track.artistName,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


class _PlayPillButton extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;
  const _PlayPillButton(
      {required this.isPlaying, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: themeCtrl.currentAppTheme.value.gradientColors.last
                  .withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 1.2,
                        ),
                      )
                    : Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                const SizedBox(width: 4),
                Text(
                  isPlaying ? 'Pause' : 'Play',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 14),
      child: const Center(
        child: LoadingWidget(),
      ),
    );
  }
}

class _MixCard extends StatelessWidget {
  final JamendoTrack track;
  final StreamMusicController ctrl;

  const _MixCard({required this.track, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => JamendoTrackDetailSheet.show(context, track),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: track.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: Colors.white10),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.artistName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Obx(() {
                  final isCurrent = ctrl.currentTrack.value?.id == track.id;
                  final playing = isCurrent && ctrl.isPlaying;
                  final loading = isCurrent && ctrl.isLoadingPreview;

                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: GestureDetector(
                      onTap: () =>
                          ctrl.playPreview(track, contextList: ctrl.dailyMix),
                      child: loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
