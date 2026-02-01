import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:sonus/core/constants/app_colors.dart';
import 'package:sonus/core/constants/constants.dart';
import 'package:sonus/core/constants/sizes.dart';
import 'package:sonus/core/models/song_model.dart';
import 'package:sonus/core/utils/theme_controller.dart';
import 'package:sonus/features/home/home_controller.dart';
import 'package:sonus/features/home/widgets/sleep_timer_card.dart';
import 'package:sonus/features/home/widgets/tablet_sleep_timer_card.dart';
import 'package:sonus/features/views/library_view.dart';
import 'package:sonus/features/views/profile_view.dart';
import 'package:sonus/widgets/cached_album_artwork.dart';
import 'package:sonus/widgets/loading_widget.dart';

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
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: themeCtrl.isDarkMode
                        ? AppColors.darkGradientColors
                        : AppColors.primaryGradientColors,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: _buildResponsiveLayout(context),
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
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Image.asset('assets/app_icon.png',
              fit: BoxFit.cover, width: 60, height: 60),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Good ${_getGreeting()}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
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
      {'icon': Iconsax.profile_circle, 'label': 'Profile', 'view': 'profile'},
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
      ],
    );
  }

  Widget _buildCustomAppBar() {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_getGreeting()}'.tr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
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
          ? _tabletHomeView()
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
            const SizedBox(height: 20),
            if (controller.recentlyPlayed.isNotEmpty) ...[
              _buildSectionTitle('Recently Played'.tr,
                  onTap: () =>
                      controller.showPlaylistSongs(controller.allPlaylists[1]),
                  showPlay: true,
                  songlist: controller.recentlyPlayed),
              const SizedBox(height: 15),
              _buildRecentlyPlayed(controller),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tabletHomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: AppSizes.defaultSpace * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              Expanded(child: buildTabletSleepTimerCard(controller)),
              const SizedBox(width: 10),
              Expanded(
                  child: Container(
                decoration: BoxDecoration(border: Border.all()),
                child: const Center(
                  child: Text('widget'),
                ),
              )),
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
          ],
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
      child: Obx(() => ListView.builder(
            scrollDirection: Axis.horizontal,
            cacheExtent: 200,
            itemCount: controller.recentlyPlayed.length.clamp(0, 10),
            itemBuilder: (context, index) {
              final song = controller.recentlyPlayed[index];
              return _buildSongCard(
                  controller.recentlyPlayed, song, controller);
            },
          )),
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
                  //     offset: Offset(0, 3), // Reduced from 5
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
      case 'profile':
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
          key: const ValueKey('profile'),
          child: _buildProfileView(),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSizes.defaultSpace * 2),
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
                      Icons.person,
                      'Profile',
                      controller.currentView.value == 'profile',
                      () => controller.changeView('profile'),
                    ),
                  ],
                )),
          ),
        ),
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
