import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonus/core/constants/app_colors.dart';
import 'package:sonus/core/constants/constants.dart';
import 'package:sonus/core/constants/sizes.dart';
import 'package:sonus/core/helper/glass_dialog.dart';
import 'package:sonus/core/helper/loaders.dart';
import 'package:sonus/core/models/playlist_model.dart';
import 'package:sonus/core/models/song_model.dart';
import 'package:sonus/features/home/home_controller.dart';
import 'package:sonus/routhing/app_routes.dart';
import 'package:sonus/widgets/cached_album_artwork.dart';
import 'package:sonus/widgets/playlist_dialog/add_to_playlist_dialog.dart';
import 'package:sonus/widgets/playlist_dialog/create_playlist_dialog.dart';
import 'package:sonus/widgets/playlist_dialog/edit_playlist_dialog.dart';

class LibraryView extends GetView<HomeController> {
  const LibraryView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveContext(context).isTablet
        ? _buildTabletLayout(context)
        : _buildMobileLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('library_scroll'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryItem(
                  icon: Icons.queue_music,
                  title: 'Playlists'.tr,
                  onTap: () => _showPlaylistsTab(context),
                ),
                _buildCategoryItem(
                  icon: Icons.person,
                  title: 'Artists'.tr,
                  onTap: () => _showArtistsTab(context),
                ),
                _buildCategoryItem(
                  icon: Icons.album,
                  title: 'Albums'.tr,
                  onTap: () => _showAlbumsTab(context),
                ),
                _buildCategoryItem(
                  icon: Icons.music_note,
                  title: 'Songs'.tr,
                  onTap: () => _showAllSongsTab(context),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 16, bottom: 16),
            child: Text(
              'Recently Played'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Obx(() {
          final recentlyPlayed = controller.recentlyPlayed;
          if (recentlyPlayed.isEmpty) {
            return SliverToBoxAdapter(
              child: SizedBox(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recently played songs'.tr,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final recentlyPlayedSongs = recentlyPlayed.take(10).toList();
                  if (index >= recentlyPlayedSongs.length) {
                    return null;
                  }
                  final song = recentlyPlayedSongs[index];
                  return _buildRecentlyAddedCard(song);
                },
                childCount: recentlyPlayed.length.clamp(0, 10),
              ),
            ),
          );
        }),
        const SliverToBoxAdapter(
          child: SizedBox(height: 170),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    var tabbar = TabBar(
      controller: controller.tabController,
      indicator: BoxDecoration(
        color: AppColors.musicPrimary,
        borderRadius: BorderRadius.circular(10),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: const EdgeInsets.all(10),
      dividerColor: Colors.transparent,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withOpacity(0.7),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      onTap: (value) => FocusManager.instance.primaryFocus?.unfocus(),
      tabs: const [
        Tab(text: 'All Songs'),
        Tab(text: 'Artists'),
        Tab(text: 'Albums'),
        Tab(text: 'Playlists'),
      ],
    );
    return DefaultTabController(
      length: tabbar.tabs.length,
      child: Column(
        children: [
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: tabbar),
          Expanded(
            child: TabBarView(
              controller: controller.tabController,
              children: [
                _buildAllSongsTab(context),
                _buildArtistsTab(context),
                _buildAlbumsTab(context),
                _buildPlaylistsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      leading: Icon(
        icon,
        color: Colors.white,
        size: 28,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.white.withOpacity(0.5),
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildRecentlyAddedCard(SongModel song) {
    return GestureDetector(
      onTap: () => controller.playSong(controller.recentlyPlayed, song),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CachedAlbumArtwork(
                key: ValueKey('library_artwork_${song.id}'),
                songId: song.id,
                // width: double.infinity,
                // height: double.infinity,
                borderRadius: 8,
                highQuality: true,
              ),
              //  Container(
              //   margin: const EdgeInsets.all(8),
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(8),
              //     gradient: const LinearGradient(
              //       colors: [
              //         AppColors.musicPrimary,
              //         AppColors.musicSecondary,
              //       ],
              //     ),
              //   ),
              //   child: FutureBuilder<Uint8List?>(
              //     future: controller.getAlbumArtwork(song.id),
              //     builder: (context, snapshot) {
              //       // Try local artwork first
              //       if (snapshot.hasData && snapshot.data != null) {
              //         return ClipRRect(
              //           borderRadius: BorderRadius.circular(8),
              //           child: Image.memory(
              //             snapshot.data!,
              //             fit: BoxFit.cover,
              //             width: double.infinity,
              //             height: double.infinity,
              //           ),
              //         );
              //       }

              //       // If no local artwork, try URL artwork (for YouTube/downloaded songs)
              //       if (snapshot.connectionState == ConnectionState.done) {
              //         final artworkUrl = controller.getArtworkUrl(song.id);
              //         if (artworkUrl != null) {
              //           return ClipRRect(
              //             borderRadius: BorderRadius.circular(8),
              //             child: CachedNetworkImage(
              //               imageUrl: artworkUrl,
              //               fit: BoxFit.cover,
              //               width: double.infinity,
              //               height: double.infinity,
              //               placeholder: (context, url) => Container(
              //                 decoration: BoxDecoration(
              //                   borderRadius: BorderRadius.circular(8),
              //                   gradient: const LinearGradient(
              //                     colors: [
              //                       AppColors.musicPrimary,
              //                       AppColors.musicSecondary,
              //                     ],
              //                   ),
              //                 ),
              //                 child: const Center(
              //                   child: Icon(
              //                     Icons.music_note,
              //                     color: Colors.white,
              //                     size: 32,
              //                   ),
              //                 ),
              //               ),
              //               errorWidget: (context, url, error) => Container(
              //                 decoration: BoxDecoration(
              //                   borderRadius: BorderRadius.circular(8),
              //                   gradient: const LinearGradient(
              //                     colors: [
              //                       AppColors.musicPrimary,
              //                       AppColors.musicSecondary,
              //                     ],
              //                   ),
              //                 ),
              //                 child: const Center(
              //                   child: Icon(
              //                     Icons.music_note,
              //                     color: Colors.white,
              //                     size: 32,
              //                   ),
              //                 ),
              //               ),
              //             ),
              //           );
              //         }
              //       }

              //       // Fallback to placeholder icon
              //       return const Center(
              //         child: Icon(
              //           Icons.music_note,
              //           color: Colors.white,
              //           size: 32,
              //         ),
              //       );
              //     },
              //   ),
              // ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
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
          ],
        ),
      ),
    );
  }

  void _showPlaylistsTab(BuildContext context) {
    _showPlaylistsFullScreen(context);
  }

  void _showArtistsTab(BuildContext context) {
    _showArtistsFullScreen(context);
  }

  void _showAlbumsTab(BuildContext context) {
    _showAlbumsFullScreen(context);
  }

  void _showAllSongsTab(BuildContext context) {
    _showAllSongsFullScreen();
  }

  void _showPlaylistsFullScreen(BuildContext context) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: controller.themeCtrl.isDarkMode
                ? AppColors.darkGradientColors
                : AppColors.primaryGradientColors,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.close(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Playlists'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildPlaylistsTab(context),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showArtistsFullScreen(BuildContext context) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: controller.themeCtrl.isDarkMode
                ? AppColors.darkGradientColors
                : AppColors.primaryGradientColors,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.close(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Artists'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildArtistsTab(context),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showAlbumsFullScreen(BuildContext context) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: controller.themeCtrl.isDarkMode
                ? AppColors.darkGradientColors
                : AppColors.primaryGradientColors,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.close(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Albums'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildAlbumsTab(context),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showAllSongsFullScreen() {
    Get.bottomSheet(
      // isDismissible: false,
      // enableDrag: false,
      Container(
        height: Get.height * 0.9,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: controller.themeCtrl.isDarkMode
                ? AppColors.darkGradientColors
                : AppColors.primaryGradientColors,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.close(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Songs'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildAllSongsTab(Get.context!),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildAllSongsTab(BuildContext context) {
    return Obx(() {
      if (controller.allSongs.isEmpty) {
        return _buildEmptyState(
            'No songs found', 'Add some music to your device'.tr);
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildSearchBar(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      controller.playAllSongs(controller.allSongs);
                      Get.close();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: Text(
                      'Play All'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      controller.shuffleAllSongs(controller.allSongs);
                      Get.close();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.shuffle, size: 20),
                    label: Text(
                      'Shuffle'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              key: const PageStorageKey('library_allSongs_list'),
              controller: controller.allSongsScrollController,
              shrinkWrap: true,
              cacheExtent: 200,
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 170,
              ),
              itemCount: controller.searchResults.length,
              itemBuilder: (context, index) {
                final song = controller.searchResults[index];
                return _buildSongListItem(controller.allSongs, song, index);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      // padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        onChanged: controller.updateSearchQuery,
        controller: controller.searchTextController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          hintText: 'Search songs, artists, albums...'.tr,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.7),
          ),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    controller.updateSearchQuery('');
                    controller.searchTextController.clear();
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  icon: Icon(
                    Icons.clear,
                    color: Colors.white.withOpacity(0.7),
                  ),
                )
              : const SizedBox.shrink()),
        ),
      ),
    );
  }

  Widget _buildSongListItem(
      List<SongModel> songList, SongModel song, int index) {
    return Container(
        key: ValueKey('song_${song.id}'),
        margin: const EdgeInsets.only(bottom: 8),
        child: Obx(() => Container(
              decoration: BoxDecoration(
                gradient: controller.currentSong?.id == song.id
                    ? LinearGradient(
                        colors: [
                          AppColors.musicPrimary.withOpacity(0.3),
                          AppColors.musicPrimary.withOpacity(0.1),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: controller.currentSong?.id == song.id
                      ? AppColors.musicPrimary.withOpacity(0.3)
                      : Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: controller.currentSong?.id == song.id
                        ? AppColors.musicPrimary.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                visualDensity: const VisualDensity(vertical: -2),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedAlbumArtwork(
                    key: ValueKey('song_artwork_${song.id}'),
                    songId: song.id,
                    width: 50,
                    height: 50,
                    borderRadius: 15,
                    highQuality: false,
                  ),
                ),
                // Container(
                //   width: 50,
                //   height: 50,
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(8),
                //     gradient: const LinearGradient(
                //       colors: [
                //         AppColors.musicPrimary,
                //         AppColors.musicSecondary
                //       ],
                //     ),
                //   ),
                //   child: FutureBuilder<Uint8List?>(
                //     key: ValueKey(
                //         'artwork_${song.id}'), // Add key to prevent rebuilds
                //     future: controller.getAlbumArtwork(song.id),
                //     builder: (context, snapshot) {
                //       // Try local artwork first
                //       if (snapshot.hasData && snapshot.data != null) {
                //         return ClipRRect(
                //           borderRadius: BorderRadius.circular(8),
                //           child: Image.memory(
                //             snapshot.data!,
                //             fit: BoxFit.cover,
                //           ),
                //         );
                //       }

                //       // If no local artwork, try URL artwork (for YouTube/downloaded songs)
                //       if (snapshot.connectionState == ConnectionState.done) {
                //         final artworkUrl = controller.getArtworkUrl(song.id);
                //         if (artworkUrl != null) {
                //           return ClipRRect(
                //             borderRadius: BorderRadius.circular(8),
                //             child: CachedNetworkImage(
                //               imageUrl: artworkUrl,
                //               fit: BoxFit.cover,
                //               width: 50,
                //               height: 50,
                //               placeholder: (context, url) => Container(
                //                 width: 50,
                //                 height: 50,
                //                 decoration: BoxDecoration(
                //                   borderRadius: BorderRadius.circular(8),
                //                   gradient: const LinearGradient(
                //                     colors: [
                //                       AppColors.musicPrimary,
                //                       AppColors.musicSecondary
                //                     ],
                //                   ),
                //                 ),
                //                 child: const Icon(
                //                   Icons.music_note,
                //                   color: Colors.white,
                //                   size: 24,
                //                 ),
                //               ),
                //               errorWidget: (context, url, error) => Container(
                //                 width: 50,
                //                 height: 50,
                //                 decoration: BoxDecoration(
                //                   borderRadius: BorderRadius.circular(8),
                //                   gradient: const LinearGradient(
                //                     colors: [
                //                       AppColors.musicPrimary,
                //                       AppColors.musicSecondary
                //                     ],
                //                   ),
                //                 ),
                //                 child: const Icon(
                //                   Icons.music_note,
                //                   color: Colors.white,
                //                   size: 24,
                //                 ),
                //               ),
                //             ),
                //           );
                //         }
                //       }

                //       // Fallback to placeholder icon
                //       return const Icon(Icons.music_note, color: Colors.white);
                //     },
                //   ),
                // ),
                title: Text(
                  song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${song.artist} • ${song.album}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.formattedDuration,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Builder(
                        builder: (context) => Theme(
                              data: Theme.of(context).copyWith(
                                splashColor:
                                    AppColors.musicPrimary.withOpacity(0.22),
                                highlightColor:
                                    AppColors.musicPrimary.withOpacity(0.12),
                                hoverColor:
                                    AppColors.musicPrimary.withOpacity(0.08),
                                popupMenuTheme: const PopupMenuThemeData(
                                  surfaceTintColor: Colors.transparent,
                                ),
                              ),
                              child: PopupMenuButton<String>(
                                onSelected: (value) =>
                                    _handleSongMenuAction(value, song),
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                elevation: 0,
                                color: AppColors.darkerGrey.withOpacity(0.7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                      color: Colors.white.withOpacity(0.18),
                                      width: 1),
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'like',
                                    child: Row(
                                      children: [
                                        Icon(
                                          controller.isSongLiked(song)
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: 20,
                                          color: controller.isSongLiked(song)
                                              ? Colors.red
                                              : Colors.white,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          controller.isSongLiked(song)
                                              ? 'Unlike'.tr
                                              : 'Like'.tr,
                                          style: controller.themeCtrl
                                              .activeTheme.textTheme.bodySmall!
                                              .copyWith(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'add_to_playlist',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.playlist_add,
                                            size: 20, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Text('Add to Playlist'.tr,
                                            style: controller
                                                .themeCtrl
                                                .activeTheme
                                                .textTheme
                                                .bodySmall!
                                                .copyWith(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'details',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline,
                                            size: 20, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Text('Song Details'.tr,
                                            style: controller
                                                .themeCtrl
                                                .activeTheme
                                                .textTheme
                                                .bodySmall!
                                                .copyWith(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                  ],
                ),
                onTap: () {
                  debugPrint(
                      'Library song tapped: ${song.title} (id: ${song.id})');
                  controller.playSong(songList, song);
                },
              ),
            )));
  }

  Widget _buildArtistsTab(BuildContext context) {
    return Obx(() {
      final artists = controller.allArtists;
      if (artists.isEmpty) {
        return _buildEmptyState(
            'No artists found', 'Add some music to see artists');
      }

      return ListView.builder(
        key: const PageStorageKey('library_artists_list'),
        controller: controller.artistsScrollController,
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 170,
        ),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          final artistSongs = controller.getSongsByArtist(artist);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              // contentPadding: const EdgeInsets.all(16),
              visualDensity: const VisualDensity(vertical: -2),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(
                    colors: [AppColors.musicPrimary, AppColors.musicAccent],
                  ),
                ),
                child: Center(
                  child: Text(
                    artist.isNotEmpty ? artist[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                artist,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${artistSongs.length} songs',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
              onTap: () => _showArtistSongs(artist, artistSongs),
            ),
          );
        },
      );
    });
  }

  Widget _buildAlbumsTab(BuildContext context) {
    return Obx(() {
      final albums = controller.allAlbums;
      if (albums.isEmpty) {
        return _buildEmptyState(
            'No albums found', 'Add some music to see albums');
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: GridView.builder(
          key: const PageStorageKey('library_albums_grid'),
          controller: controller.albumsScrollController,
          padding: const EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: 150,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveContext(context).isTablet ? 4 : 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.8,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            final albumSongs = controller.getSongsByAlbum(album);
            final firstSong = albumSongs.isNotEmpty ? albumSongs.first : null;

            return GestureDetector(
              onTap: () => _showAlbumSongs(album, albumSongs),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.musicPrimary,
                              AppColors.musicSecondary
                            ],
                          ),
                        ),
                        child: firstSong != null
                            ? CachedAlbumArtwork(
                                key:
                                    ValueKey('library_artwork_${firstSong.id}'),
                                songId: firstSong.id,
                                width: double.infinity,
                                height: double.infinity,
                                borderRadius: 8,
                                highQuality: true,
                              )
                            // FutureBuilder<Uint8List?>(
                            //     future:
                            //         controller.getAlbumArtwork(firstSong.id),
                            //     builder: (context, snapshot) {
                            //       if (snapshot.hasData &&
                            //           snapshot.data != null) {
                            //         return ClipRRect(
                            //           borderRadius: BorderRadius.circular(12),
                            //           child: Image.memory(
                            //             snapshot.data!,
                            //             fit: BoxFit.cover,
                            //             width: double.infinity,
                            //             height: double.infinity,
                            //           ),
                            //         );
                            //       }
                            //       return const Center(
                            //         child: Icon(
                            //           Icons.album,
                            //           color: Colors.white,
                            //           size: 40,
                            //         ),
                            //       );
                            //     },
                            //   )
                            : const Center(
                                child: Icon(
                                  Icons.album,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${albumSongs.length} songs',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildPlaylistsTab(BuildContext context) {
    return Obx(() {
      final allPlaylists = controller.allPlaylists;

      return Column(
        children: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.musicGradientStart,
                  AppColors.musicGradientEnd,
                ]),
                borderRadius:
                    BorderRadius.all(Radius.circular(AppSizes.borderRadiusLg))),
            child: ElevatedButton.icon(
              onPressed: () => _showCreatePlaylistDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Create Playlist'.tr,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            child: allPlaylists.isEmpty
                ? _buildEmptyState(
                    'No playlists yet', 'Create your first playlist'.tr)
                : ListView.builder(
                    key: const PageStorageKey('library_playlists_list'),
                    controller: controller.playlistsScrollController,
                    cacheExtent: 200,
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 170,
                    ),
                    itemCount: allPlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist = allPlaylists[index];
                      return _buildPlaylistListItem(playlist);
                    },
                  ),
          ),
        ],
      );
    });
  }

  Widget _buildPlaylistListItem(PlaylistModel playlist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        // contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: playlist.isDefault
                ? const LinearGradient(
                    colors: [AppColors.musicAccent, AppColors.musicSecondary],
                  )
                : playlist.colorHex != null
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
            playlist.isDefault ? Icons.music_note_outlined : Icons.queue_music,
            color: Colors.white,
          ),
        ),
        title: Text(
          playlist.name.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${playlist.songCount} songs • ${playlist.formattedTotalDuration}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        trailing: playlist.isDefault
            ? null
            : Builder(
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
                        color: AppColors.darkerGrey.withOpacity(0.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                              color: Colors.white.withOpacity(0.18), width: 1),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Edit Playlist'.tr,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Delete Playlist'.tr,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),

        onTap: () => _showPlaylistSongs(playlist),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_off,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSongMenuAction(String action, SongModel song) {
    switch (action) {
      case 'like':
        controller.toggleLikeSong(song);
        break;
      case 'add_to_playlist':
        _showAddToPlaylistDialog(song);
        break;
      case 'details':
        _showSongDetailsDialog(song);
        break;
    }
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

  void _showCreatePlaylistDialog() {
    Get.dialog(
      CreatePlaylistDialog(
        onCreatePlaylist: (name, description, color) async {
          try {
            await controller.createPlaylist(
              name: name,
              description: description,
              colorHex: color,
            );
            AppLoader.customToast(
                message: 'Playlist "$name" created successfully!');
          } catch (e) {
            AppLoader.customToast(message: 'Failed to create playlist: $e');
          }
        },
      ),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
  }

  void _showEditPlaylistDialog(PlaylistModel playlist) {
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
            AppLoader.customToast(message: 'Playlist updated successfully!'.tr);
          } catch (e) {
            AppLoader.customToast(message: 'Failed to update playlist: $e');
          }
        },
      ),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
  }

  void _showDeletePlaylistDialog(PlaylistModel playlist) {
    Get.dialog(
      GlassAlertDialog(
        backgroundColor: AppColors.darkGrey.withOpacity(0.3),
        textColor: Colors.white,
        title: Text('Delete Playlist'.tr),
        content: Text(
          '${"Are you sure you want to delete".tr} "${playlist.name}"? ${"This action cannot be undone.".tr}',
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
                    message: 'Playlist deleted successfully!'.tr);
              } catch (e) {
                AppLoader.customToast(message: 'Failed to delete playlist: $e');
              }
            },
            child: Text(
              'Delete'.tr,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(SongModel song) {
    Get.dialog(
      AddToPlaylistDialog(
        song: song,
        controller: controller,
      ),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
  }

  void _showSongDetailsDialog(SongModel song) {
    Get.dialog(
      GlassAlertDialog(
        backgroundColor: AppColors.darkGrey.withOpacity(0.3),
        textColor: Colors.white,
        title: Text(song.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Artist: ${song.artist}'),
            Text('Album: ${song.album}'),
            Text('Duration: ${song.formattedDuration}'),
            Text('Size: ${song.formattedSize}'),
            Text('Format: ${song.fileExtension}'),
            if (song.genre != null) Text('Genre: ${song.genre}'),
            const SizedBox(height: 8),
            const Text('Location:'),
            SelectableText(
              song.data,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child:
                Text('Close'.tr, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
  }

  void _showArtistSongs(String artist, List<SongModel> songs) {
    Get.toNamed(Routes.ARTISTSONGSCREEN, arguments: {
      'artist': artist,
      'songs': songs,
      'controller': controller,
    });
  }

  void _showAlbumSongs(String album, List<SongModel> songs) {
    Get.toNamed(Routes.ALBUMSONGSCREEN, arguments: {
      'album': album,
      'songs': songs,
      'controller': controller,
    });
  }

  void _showPlaylistSongs(PlaylistModel playlist) {
    final playlistSongs = controller.getPlaylistSongs(playlist.id);
    Get.toNamed(Routes.PLAYLISTSONGSCREEN, arguments: {
      'playlist': playlist,
      'playlistSongs': playlistSongs,
      'controller': controller,
    });
  }
}

Widget buildEmptyState(String title, String subtitle) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.music_note,
          size: 64,
          color: Colors.white.withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}
