import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:velo/core/constants/app_colors.dart';
import 'package:velo/core/constants/constants.dart';
import 'package:velo/core/constants/sizes.dart';
import 'package:velo/core/helper/glass_dialog.dart';
import 'package:velo/core/helper/loaders.dart';
import 'package:velo/core/models/playlist_model.dart';
import 'package:velo/core/models/song_model.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:velo/features/home/home_controller.dart';
import 'package:velo/features/home/widgets/music_discovery_widget.dart';
import 'package:velo/features/home/widgets/music_mood_widget.dart';
import 'package:velo/features/home/widgets/sleep_timer_card.dart';
import 'package:velo/features/home/widgets/smart_recommendations_widget.dart';
import 'package:velo/features/home/widgets/tablet_sleep_timer_card.dart';
import 'package:velo/features/promoted_apps/promoted_apps_bottom_sheet.dart';
import 'package:velo/features/promoted_apps/controller/promoted_apps_controller.dart';
import 'package:velo/features/sub_screens/player_screens/landscape_mini_player.dart';
import 'package:velo/routhing/app_routes.dart';
import 'package:velo/features/views/library_view.dart';
import 'package:velo/features/views/setting_view.dart';
import 'package:velo/widgets/cached_album_artwork.dart';
import 'package:velo/widgets/loading_widget.dart';
import 'package:velo/widgets/playlist_dialog/edit_playlist_dialog.dart';

import '../sub_screens/player_screens/mini_player.dart';
import '../views/search_view.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SafeArea(
        top: false,
        bottom: Platform.isIOS ? false : true,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Obx(
                () => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: themeCtrl.currentAppTheme.value.gradientColors,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: _buildResponsiveLayout(context),
                  ),
                ),
              ),
              if (!ResponsiveContext(context).isTabletLandscape)
                Positioned(
                    bottom: 10,
                    child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: _buildBottomNavigation())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context) {
    if (ResponsiveContext(context).isTabletLandscape) {
      return _buildTabletLandscapeLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _buildCustomAppBar(),
            Expanded(
              child: Obx(() => _buildCurrentView(context)),
            ),
          ],
        ),
        Positioned(
          bottom: 58,
          left: 0,
          right: 0,
          child: Obx(() {
            final song = controller.currentSong;

            return song != null ? const MiniPlayer() : const SizedBox.shrink();
          }),
        ),
      ],
    );
  }

  Widget _buildTabletLandscapeLayout(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.defaultSpace,
              vertical: AppSizes.defaultSpace),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.3,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.defaultSpace,
                vertical: AppSizes.defaultSpace),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
              ),
              borderRadius: const BorderRadius.all(
                  Radius.circular(AppSizes.spaceBtwSections)),
            ),
            child: Column(
              children: [
                _buildTabletLandscapeAppBar(),
                Expanded(
                  child: _buildTabletLandscapeNavigation(),
                ),
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: const LandscapeMiniPlayer(),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Obx(
            () => Padding(
              padding: const EdgeInsets.only(
                top: AppSizes.defaultSpace,
                right: AppSizes.defaultSpace,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  );
                },
                key: ValueKey(controller.currentView.value),
                child: _buildCurrentView(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLandscapeAppBar() {
    final promotedAppsCtrl = Get.find<PromotedAppsController>();

    final shouldShow = promotedAppsCtrl.shouldShowGiftboxRx.value;

    final badgeCount = promotedAppsCtrl.badgeCount.value;
    final isShaking = promotedAppsCtrl.isShaking;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Image.asset('assets/app_icon.png',
              fit: BoxFit.cover, width: 60, height: 60),
          const SizedBox(width: 10),
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Good ${_getGreeting()}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                  ),
                ),
                if (shouldShow)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: isShaking ? 1.0 : 0.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: isShaking
                            ? value * 0.2 * (value < 0.5 ? 1 : -1)
                            : 0,
                        child: Transform.scale(
                          scale: isShaking ? 1.0 + (value * 0.1) : 1.0,
                          child: Stack(
                            children: [
                              IconButton(
                                onPressed: () {
                                  promotedAppsCtrl.openAppList();
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) =>
                                        const PromotedAppsBottomSheet(),
                                  );
                                },
                                icon: const Text(
                                  '🎁',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                              if (badgeCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.5),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      badgeCount > 99
                                          ? '99+'
                                          : badgeCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLandscapeNavigation() {
    final navItems = [
      {'icon': Iconsax.home, 'label': 'Home', 'view': 'home'},
      {'icon': Iconsax.search_normal, 'label': 'Search', 'view': 'search'},
      {'icon': Iconsax.music_library_2, 'label': 'Library', 'view': 'library'},
      {'icon': Iconsax.setting, 'label': 'Settings', 'view': 'settings'},
    ];

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: navItems.length,
          itemBuilder: (context, index) {
            return Obx(() {
              final item = navItems[index];
              final isActive = controller.currentView.value == item['view'];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isActive
                      ? Colors.white.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => controller.changeView(item['view'] as String),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: isActive ? Colors.white : Colors.white70,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              item['label'] as String,
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.white70,
                                fontSize: 16,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            });
          },
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 23),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => Get.toNamed(Routes.RADIO),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Iconsax.radio_copy,
                      color: Colors.white70,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Radio'.tr,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomAppBar() {
    final promotedAppsCtrl = Get.find<PromotedAppsController>();

    final shouldShow = promotedAppsCtrl.shouldShowGiftboxRx.value;

    final badgeCount = promotedAppsCtrl.badgeCount.value;
    final isShaking = promotedAppsCtrl.isShaking;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Good ${_getGreeting()}'.tr,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 20,
              ),
            ),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (shouldShow)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: isShaking ? 1.0 : 0.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: isShaking
                              ? value * 0.2 * (value < 0.5 ? 1 : -1)
                              : 0,
                          child: Transform.scale(
                            scale: isShaking ? 1.0 + (value * 0.1) : 1.0,
                            child: Stack(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    promotedAppsCtrl.openAppList();
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) =>
                                          const PromotedAppsBottomSheet(),
                                    );
                                  },
                                  icon: const Text(
                                    '🎁',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                                if (badgeCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.5),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Text(
                                        badgeCount > 99
                                            ? '99+'
                                            : badgeCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  Image.asset('assets/app_icon.png',
                      fit: BoxFit.cover, width: 40, height: 40)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeView(BuildContext context) {
    return Obx(() {
      if (!controller.hasPermission) {
        return _buildPermissionView(controller);
      }

      if (controller.isAudioLoading || !controller.hasAttemptedLoad) {
        return _buildLoadingView();
      }

      if (controller.allSongs.isEmpty) {
        return _buildEmptyStateView(controller);
      }

      return ResponsiveContext(context).isTablet
          ? _tabletHomeView(context)
          : _mobileHomeView();
    });
  }

  Widget _mobileHomeView() {
    return SingleChildScrollView(
      key: const PageStorageKey('home_scroll'),
      padding: const EdgeInsets.only(left: AppSizes.defaultSpace),
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            buildSleepTimerCard(controller),
            const SizedBox(height: 16),
            const MusicMoodWidget(),
            const SizedBox(height: 16),
            if (controller.recentlyPlayed.isNotEmpty) ...[
              _buildSectionTitle('Recently Played'.tr,
                  onTap: () =>
                      controller.showPlaylistSongs(controller.allPlaylists[1]),
                  showPlay: true,
                  songlist: controller.recentlyPlayed),
              const SizedBox(height: 15),
              _buildRecentlyPlayed(controller),
              const SizedBox(height: 10),
              const SmartRecommendationsWidget(),
              const SizedBox(height: 16),
            ],
            _buildSectionTitle('Made for You'.tr),
            const SizedBox(height: 15),
            _buildMadeForYou(),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(right: AppSizes.defaultSpace),
              child: MusicDiscoveryWidget(isCompact: true),
            ),
            const SizedBox(height: 16),
            if (controller.userPlaylists.isNotEmpty) ...[
              _buildSectionTitle(
                'Your Playlists'.tr,
                showMore: true,
                onTap: () =>
                    controller.titleTapAction('library', 'Recently Played'),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.only(right: AppSizes.defaultSpace),
                child: _buildPlaylists(controller),
              ),
              const SizedBox(height: 10),
            ],
            _buildSectionTitle('Songs'.tr,
                onTap: () => controller.titleTapAction('library', 'All Songs'),
                showShuffle: true,
                showPlay: true,
                songlist: controller.allSongs),
            const SizedBox(height: 15),
            _buildAllSongsPreview(controller),
            const SizedBox(height: 170),
          ],
        ),
      ),
    );
  }

  Widget _tabletHomeView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: AppSizes.defaultSpace * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: buildTabletSleepTimerCard(controller, context)),
              const SizedBox(width: 10),
              const Expanded(
                child: MusicMoodWidget(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (controller.recentlyPlayed.isNotEmpty) ...[
            _buildSectionTitle('Recently Played'.tr,
                onTap: () =>
                    controller.titleTapAction('library', 'Recently Played'),
                showPlay: true,
                songlist: controller.recentlyPlayed),
            const SizedBox(height: 15),
            _buildRecentlyPlayed(controller),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.only(right: AppSizes.defaultSpace),
              child: SmartRecommendationsWidget(),
            ),
          ],
          const SizedBox(height: 16),
          _buildSectionTitle('Made for You'.tr),
          const SizedBox(height: 15),
          _buildMadeForYou(),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(right: AppSizes.defaultSpace),
            child: MusicDiscoveryWidget(),
          ),
          const SizedBox(height: 16),
          if (controller.userPlaylists.isNotEmpty) ...[
            _buildSectionTitle('Your Playlists'.tr, showMore: true),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.only(right: AppSizes.defaultSpace),
              child: _buildPlaylists(controller),
            ),
            const SizedBox(height: 10),
          ],
          _buildSectionTitle('All Songs'.tr,
              onTap: () => controller.titleTapAction('library', 'All Songs'),
              showShuffle: true,
              showPlay: true,
              songlist: controller.allSongs),
          const SizedBox(height: 15),
          _buildAllSongsPreview(controller),
          const SizedBox(height: 170),
        ],
      ),
    );
  }

  Widget _buildPermissionView(HomeController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.music_note,
              size: 80,
              color: Colors.white70,
            ),
            const SizedBox(height: 30),
            const Text(
              'Music Access Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              'To play music from your device, we need permission to access your music library.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => controller.requestPermissions(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.musicPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Grant Permission',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // CircularProgressIndicator(
          //   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          // ),
          LoadingWidget(
            color: Colors.white,
          ),
          SizedBox(height: 20),
          Text(
            'Loading your music...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateView(HomeController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.music_off,
              size: 80,
              color: Colors.white70,
            ),
            const SizedBox(height: 30),
            const Text(
              'No Music Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              'No music files were found on your device. Make sure you have music files stored locally.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => controller.requestPermissions(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.musicPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title,
      {VoidCallback? onTap,
      bool showShuffle = false,
      bool showPlay = false,
      bool showMore = false,
      List<SongModel>? songlist}) {
    final controller = Get.find<HomeController>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(children: [
          if (showShuffle)
            IconButton(
              onPressed: () => controller.shuffleAllSongs(songlist ?? []),
              icon: const Icon(
                Iconsax.shuffle,
                color: Colors.white70,
                size: 18,
              ),
            ),
          if (showPlay)
            IconButton(
              onPressed: () => controller.playAllSongs(songlist ?? []),
              icon: const Icon(
                Iconsax.play,
                color: Colors.white70,
                size: 18,
              ),
            ),
          if (showMore)
            TextButton(
                onPressed: () {
                  controller.changeView('library');
                  controller.tabController.index = 3;
                },
                child: Text(
                  'Show all'.tr,
                  style: const TextStyle(color: Colors.white70),
                )),
        ]),
      ],
    );
  }

  Widget _buildRecentlyPlayed(HomeController controller) {
    return SizedBox(
      height: 180,
      child: Obx(() {
        final songCount = controller.recentlyPlayed.length;
        final displayCount = songCount.clamp(0, 10);
        final showSeeAll = songCount > 10;
        final itemCount = showSeeAll ? displayCount + 1 : displayCount;

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          cacheExtent: 200,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index < displayCount) {
              final song = controller.recentlyPlayed[index];
              return _buildSongCard(
                  controller.recentlyPlayed, song, controller);
            } else {
              return _buildSeeAllCard(
                  onTap: () {
                    controller.showPlaylistSongs(controller.allPlaylists[1]);
                  },
                  subTitle: 'Recently Played',
                  iconData: Iconsax.clock_copy);
            }
          },
        );
      }),
    );
  }

  Widget _buildSongCard(
      List<SongModel> songList, SongModel song, HomeController controller) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        debugPrint('Song card tapped: ${song.title} (id: ${song.id})');
        controller.playSong(songList, song);
      },
      child: Container(
        key: ValueKey('song_card_${song.id}'),
        width: 140,
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RepaintBoundary(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  // boxShadow: const [
                  //   BoxShadow(
                  //     color: Colors.black26,
                  //     blurRadius: 8, // Reduced from 10
                  //     offset: Offset(0, 3),
                  //   ),
                  // ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: CachedAlbumArtwork(
                    key: ValueKey('artwork_${song.id}'),
                    songId: song.id,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 15,
                    highQuality: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              song.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song.artist,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMadeForYou() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        cacheExtent: 200,
        itemCount: 3,
        itemBuilder: (context, index) {
          final dailyMix =
              controller.playlistService.generateDailyMix(controller.allSongs);
          final weeklyMix =
              controller.playlistService.generateWeeklyMix(controller.allSongs);
          final releaseRadar = _createReleaseRadar(controller);

          final madeForYouData = [
            {
              'title': 'Daily Mix'.tr,
              'subtitle':
                  'Updated ${controller.playlistService.getDailyMixLastGenerated()}',
              'colors': [const Color(0xFF6C63FF), const Color(0xFF4A4AFF)],
              'songCount': '${dailyMix.length} songs',
            },
            {
              'title': 'Discover Weekly'.tr,
              'subtitle':
                  'Updated ${controller.playlistService.getWeeklyMixLastGenerated()}',
              'colors': [const Color(0xFFFF6B6B), const Color(0xFFE53E3E)],
              'songCount': '${weeklyMix.length} songs',
            },
            {
              'title': 'Release Radar'.tr,
              'subtitle': 'Made for You'.tr,
              'colors': [const Color(0xFF4ECDC4), const Color(0xFF38B2AC)],
              'songCount': '${releaseRadar.length} songs',
            },
          ];

          final data = madeForYouData[index];

          return RepaintBoundary(
              child: GestureDetector(
            onTap: () {
              _handleMadeForYouTap(controller, index);
            },
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: (data['colors'] as List<Color>)[0],
                boxShadow: [
                  BoxShadow(
                    color: (data['colors'] as List<Color>)[0].withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['subtitle'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data['songCount'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ));
        },
      ),
    );
  }

  void _handleMadeForYouTap(HomeController controller, int index) {
    List<SongModel> personalizedSongs = [];

    switch (index) {
      case 0:
        personalizedSongs = _createDailyMix(controller);
        break;
      case 1:
        personalizedSongs = _createDiscoverWeekly(controller);
        break;
      case 2:
        personalizedSongs = _createReleaseRadar(controller);
        break;
    }

    if (personalizedSongs.isNotEmpty) {
      controller.shuffleAllSongs(personalizedSongs);
    }
  }

  List<SongModel> _createDailyMix(HomeController controller) {
    return controller.playlistService.generateDailyMix(controller.allSongs);
  }

  List<SongModel> _createDiscoverWeekly(HomeController controller) {
    return controller.playlistService.generateWeeklyMix(controller.allSongs);
  }

  List<SongModel> _createReleaseRadar(HomeController controller) {
    final List<SongModel> radar = [];
    final allSongs = List<SongModel>.from(controller.allSongs);

    final Map<String, List<SongModel>> songsByArtist = {};
    for (final song in allSongs) {
      songsByArtist[song.artist] = songsByArtist[song.artist] ?? [];
      songsByArtist[song.artist]!.add(song);
    }

    for (final artist in songsByArtist.keys) {
      if (radar.length >= 20) break;
      final artistSongs = songsByArtist[artist]!;
      artistSongs.shuffle();
      radar.addAll(artistSongs.take(2));
    }
    if (radar.length < 20) {
      final remaining = 20 - radar.length;
      final availableSongs = allSongs
          .where((song) => !radar.any((radarSong) => radarSong.id == song.id))
          .toList();
      availableSongs.shuffle();
      radar.addAll(availableSongs.take(remaining));
    }

    return radar.take(20).toList();
  }

  Widget _buildAllSongsPreview(HomeController controller) {
    return SizedBox(
      height: 180,
      child: Obx(() {
        final songCount = controller.allSongs.length;
        final displayCount = songCount.clamp(0, 10);
        final showSeeAll = songCount > 10;
        final itemCount = showSeeAll ? displayCount + 1 : displayCount;

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          cacheExtent: 200,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index < displayCount) {
              final song = controller.allSongs[index];
              return _buildSongCard(controller.allSongs, song, controller);
            } else {
              return _buildSeeAllCard(
                  onTap: () {
                    controller.changeView('library');
                    controller.tabController.index = 0;
                  },
                  iconData: Iconsax.music);
            }
          },
        );
      }),
    );
  }

  Widget _buildSeeAllCard(
      {VoidCallback? onTap,
      String subTitle = 'Your Library',
      IconData iconData = Iconsax.play}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Center(
                child: Icon(
                  iconData,
                  color: Colors.white70,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'See All',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subTitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylists(HomeController controller) {
    return Obx(() => Column(
          children: controller.userPlaylists
              .take(3)
              .map((playlist) => _buildPlaylistItem(playlist, controller))
              .toList(),
        ));
  }

  Widget _buildPlaylistItem(PlaylistModel playlist, HomeController controller) {
    return GestureDetector(
      onTap: () => _showPlaylistSongs(playlist),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: playlist.colorHex != null
                    ? LinearGradient(
                        colors: [
                          Color(
                              int.parse('FF${playlist.colorHex!}', radix: 16)),
                          Color(int.parse('FF${playlist.colorHex!}', radix: 16))
                              .withOpacity(0.7),
                        ],
                      )
                    : const LinearGradient(
                        colors: [
                          AppColors.musicPrimary,
                          AppColors.musicSecondary
                        ],
                      ),
              ),
              child: Icon(
                playlist.isDefault
                    ? Icons.music_note_outlined
                    : Icons.queue_music,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${playlist.songCount} songs • ${playlist.formattedTotalDuration}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Builder(
                builder: (context) => Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: AppColors.musicPrimary.withOpacity(0.22),
                        highlightColor:
                            AppColors.musicPrimary.withOpacity(0.12),
                        hoverColor: AppColors.musicPrimary.withOpacity(0.08),
                        popupMenuTheme: const PopupMenuThemeData(
                          surfaceTintColor: Colors.transparent,
                        ),
                      ),
                      child: PopupMenuButton<String>(
                        onSelected: (value) =>
                            _handlePlaylistMenuAction(value, playlist),
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        elevation: 0,
                        color: AppColors.darkGrey.withOpacity(0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                              color: Colors.white.withOpacity(0.18), width: 1),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Edit Playlist',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Delete Playlist',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
          ],
        ),
      ),
    );
  }

  void _showPlaylistSongs(PlaylistModel playlist) {
    final controller = Get.find<HomeController>();

    controller.showPlaylistSongs(playlist);
  }

  void _handlePlaylistMenuAction(String action, PlaylistModel playlist) {
    switch (action) {
      case 'edit':
        _showEditPlaylistDialog(playlist);
        break;
      case 'delete':
        _showDeletePlaylistDialog(playlist);
        break;
    }
  }

  void _showEditPlaylistDialog(PlaylistModel playlist) {
    final controller = Get.find<HomeController>();
    Get.dialog(
      EditPlaylistDialog(
        playlist: playlist,
        onUpdatePlaylist: (name, description, color) async {
          try {
            await controller.updatePlaylistDetails(
              playlistId: playlist.id,
              name: name,
              description: description,
              colorHex: color,
            );
            AppLoader.customToast(message: 'Playlist updated successfully!');
            // Get.snackbar(
            //   'Success',
            //   'Playlist updated successfully!',
            //   backgroundColor: AppColors.musicPrimary.withOpacity(0.8),
            //   colorText: Colors.white,
            // );
          } catch (e) {
            AppLoader.customToast(message: 'Failed to update playlist: $e');
            // Get.snackbar(
            //   'Error',
            //   'Failed to update playlist: $e',
            //   backgroundColor: Colors.red.withOpacity(0.8),
            //   colorText: Colors.white,
            // );
          }
        },
      ),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
  }

  void _showDeletePlaylistDialog(PlaylistModel playlist) {
    final controller = Get.find<HomeController>();
    Get.dialog(
      GlassAlertDialog(
        backgroundColor: AppColors.darkGrey.withOpacity(0.3),
        textColor: Colors.white,
        title: const Text('Delete Playlist'),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await controller.deletePlaylist(playlist.id);
                Navigator.pop(Get.context!);
                AppLoader.customToast(
                    message: 'Playlist deleted successfully!');
              } catch (e) {
                AppLoader.customToast(message: 'Failed to delete playlist: $e');
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibrarySearchView() {
    return const SearchView(
      key: Key('LibraeyView'),
    );
  }

  Widget _buildLibraryView() {
    return const LibraryView();
  }

  Widget _buildProfileView() {
    return ProfileView();
  }

  Widget _buildCurrentView(BuildContext context) {
    int currentIndex = 0;
    switch (controller.currentView.value) {
      case 'search':
        currentIndex = 1;
        break;
      case 'library':
        currentIndex = 2;
        break;
      case 'settings':
        currentIndex = 3;
        break;
      default:
        currentIndex = 0;
        break;
    }

    return IndexedStack(
      index: currentIndex,
      children: [
        Container(
          key: const ValueKey('home'),
          child: _buildHomeView(context),
        ),
        Container(
            key: const ValueKey('search'), child: _buildLibrarySearchView()),
        Container(
          key: const ValueKey('library'),
          child: _buildLibraryView(),
        ),
        Container(
          key: const ValueKey('settings'),
          child: _buildProfileView(),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSizes.defaultSpace * 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.dark.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Obx(() => Row(
                        children: [
                          _buildNavItem(
                            Icons.home,
                            'Home',
                            controller.currentView.value == 'home',
                            () => controller.changeView('home'),
                          ),
                          _buildNavItem(
                            Icons.search,
                            'Search',
                            controller.currentView.value == 'search',
                            () => controller.changeView('search'),
                          ),
                          _buildNavItem(
                            Icons.library_music,
                            'Library',
                            controller.currentView.value == 'library',
                            () => controller.changeView('library'),
                          ),
                          _buildNavItem(
                            Icons.settings,
                            'Settings',
                            controller.currentView.value == 'settings',
                            () => controller.changeView('settings'),
                          ),
                        ],
                      )),
                ),
              ),
            ),
          ),
          const SizedBox(
            width: AppSizes.spaceBtwItems,
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.dark.withOpacity(0.1),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: IconButton(
                  onPressed: () => Get.toNamed(Routes.RADIO),
                  icon: const Icon(
                    Iconsax.radio_copy,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(2),
                child: Icon(
                  icon,
                  color:
                      isActive ? Colors.white : Colors.white.withOpacity(0.5),
                  size: isActive ? 22 : 20,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                style: TextStyle(
                  color:
                      isActive ? Colors.white : Colors.white.withOpacity(0.5),
                  fontSize: isActive ? 11 : 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}
