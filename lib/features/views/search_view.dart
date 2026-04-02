import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velo/core/constants/app_colors.dart';
import 'package:velo/core/constants/constants.dart';
import 'package:velo/core/constants/sizes.dart';
import 'package:velo/core/helper/glass_dialog.dart';
import 'package:velo/core/models/playlist_model.dart';
import 'package:velo/core/models/song_model.dart';
import 'package:velo/features/home/home_controller.dart';
import 'package:velo/routhing/app_routes.dart';
import 'package:velo/widgets/cached_album_artwork.dart';
import 'package:velo/widgets/playlist_dialog/add_to_playlist_dialog.dart';

import '../../core/controllers/theme_controller.dart';

class SearchView extends GetView<HomeController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      // appBar: AppBar(
      //   centerTitle: true,
      //   title: Text(
      //     'Search',
      //     style: themeCtrl.activeTheme.textTheme.headlineMedium
      //         ?.copyWith(color: Colors.white),
      //   ),
      // ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: themeCtrl.currentAppTheme.value.gradientColors,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSizes.defaultSpace),
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: AppSizes.sm),
                  Expanded(
                    child: Obx(() {
                      if (controller.searchQuery.value.isEmpty) {
                        return _buildSearchSuggestions(context);
                      }

                      final results = controller.searchResults;
                      if (results.isEmpty) {
                        return _buildNoResults();
                      }

                      return _buildSearchResults(results);
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search,
                          color: Colors.white.withOpacity(0.6), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: controller.searchTextController,
                          onChanged: controller.updateSearchQuery,
                          onSubmitted: (value) {
                            controller.addRecentSearch(value);
                          },
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: 'Artists, tracks, or vibes…',
                            hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none),
                            enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none),
                            errorBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none),
                            disabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      Obx(() => controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                controller.updateSearchQuery('');
                                controller.searchTextController.clear();
                              },
                              icon: Icon(
                                Icons.clear,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            )
                          : const SizedBox.shrink()),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildSearchBar() {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: AppSizes.defaultSpace),
  //     // padding: const EdgeInsets.symmetric(horizontal: 20),
  //     decoration: BoxDecoration(
  //       color: Colors.white.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(30),
  //       border: Border.all(color: Colors.white.withOpacity(0.2)),
  //     ),
  //     child: TextField(
  //       controller: controller.searchTextController,
  //       onChanged: controller.updateSearchQuery,
  //       onSubmitted: (value) {
  //         controller.addRecentSearch(value);
  //       },
  //       style: const TextStyle(color: Colors.white),
  //       decoration: InputDecoration(
  //         hintText: 'Search songs, artists, albums...'.tr,
  //         hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
  //         border: InputBorder.none,
  //         prefixIcon: Icon(
  //           Icons.search,
  //           color: Colors.white.withOpacity(0.7),
  //         ),
  //         suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
  //             ? IconButton(
  //                 onPressed: () {
  //                   controller.updateSearchQuery('');
  //                   controller.searchTextController.clear();
  //                 },
  //                 icon: Icon(
  //                   Icons.clear,
  //                   color: Colors.white.withOpacity(0.7),
  //                 ),
  //               )
  //             : const SizedBox.shrink()),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSearchSuggestions(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
          right: AppSizes.defaultSpace,
          left: AppSizes.defaultSpace,
          bottom: 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: controller.clearAllRecentSearches,
                child: Text(
                  'Clear all'.tr,
                  style: controller.themeCtrl.activeTheme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white70, fontSize: 10),
                ),
              )
            ],
          ),
          const SizedBox(height: 15),
          Obx(() {
            final items = controller.recentSearches;
            if (items.isEmpty) {
              return Column(
                children: [
                  const SizedBox(
                    height: 30,
                  ),
                  _buildEmptyState(
                    'No recent searches'.tr,
                    'Start typing to search for music'.tr,
                    Icons.search,
                  ),
                ],
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final term = items[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    visualDensity: const VisualDensity(vertical: -4),
                    leading: const Icon(Icons.history,
                        color: Colors.white70, size: 18),
                    title: Text(
                      term,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white54, size: 18),
                      onPressed: () => controller.removeRecentSearch(term),
                    ),
                    onTap: () {
                      controller.searchTextController.text = term;
                      controller.updateSearchQuery(term);
                    },
                  ),
                );
              },
            );
          }),
          const SizedBox(height: 100),
          Text(
            'Browse Categories'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildCategoriesGrid(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    final categories = [
      {
        'name': 'Recently Played'.tr,
        'icon': Icons.history,
        'color': AppColors.blue
      },
      {
        'name': 'Most Played'.tr,
        'icon': Icons.trending_up,
        'color': AppColors.success
      },
      {
        'name': 'Liked Songs'.tr,
        'icon': Icons.favorite,
        'color': AppColors.error
      },
      {
        'name': 'All Artists'.tr,
        'icon': Icons.person,
        'color': AppColors.musicDiscoveryStart
      },
      {
        'name': 'All Albums'.tr,
        'icon': Icons.album,
        'color': AppColors.musicAccent
      },
      {
        'name': 'Playlists'.tr,
        'icon': Icons.queue_music,
        'color': AppColors.tickOrange
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveContext(context).isTablet ? 3 : 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 2.5,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () => _handleCategoryTap(category['name'] as String),
          child: Container(
            padding: const EdgeInsets.all(15),
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
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: category['color'] as Color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(List<SongModel> results) {
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      cacheExtent: 200,
      padding: const EdgeInsets.only(
          right: AppSizes.spaceBtwItems,
          left: AppSizes.spaceBtwItems,
          bottom: 170),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final song = results[index];
        return _buildSongItem(controller.allSongs, song, index);
      },
    );
  }

  Widget _buildSongItem(List<SongModel> songList, SongModel song, int index) {
    return Container(
      key: ValueKey('search_song_${song.id}'),
      margin: const EdgeInsets.only(bottom: 8),
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: CachedAlbumArtwork(
          key: ValueKey('search_song_artwork_${song.id}'),
          songId: song.id,
          width: 50,
          height: 50,
          borderRadius: 12,
          highQuality: false,
        ),
        // Container(
        //   width: 50,
        //   height: 50,
        //   decoration: BoxDecoration(
        //     borderRadius: BorderRadius.circular(8),
        //     gradient: const LinearGradient(
        //       colors: [AppColors.musicPrimary, AppColors.musicSecondary],
        //     ),
        //   ),
        //   child: FutureBuilder<Uint8List?>(
        //     key: ValueKey(
        //         'search_artwork_${song.id}'), // Add key to prevent rebuilds
        //     future: controller.getAlbumArtwork(song.id),
        //     builder: (context, snapshot) {
        //       if (snapshot.hasData && snapshot.data != null) {
        //         return ClipRRect(
        //           borderRadius: BorderRadius.circular(8),
        //           child: Image.memory(
        //             snapshot.data!,
        //             fit: BoxFit.cover,
        //           ),
        //         );
        //       }
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
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Colors.white.withOpacity(0.7),
              ),
              onSelected: (value) => _handleSongMenuAction(value, song),
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
                            : Colors.black,
                      ),
                      const SizedBox(width: 12),
                      Text(controller.isSongLiked(song)
                          ? 'Unlike'.tr
                          : 'Like'.tr),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'add_to_playlist',
                  child: Row(
                    children: [
                      const Icon(Icons.playlist_add, size: 20),
                      const SizedBox(width: 12),
                      Text('Add to Playlist'.tr),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20),
                      const SizedBox(width: 12),
                      Text('Song Details'.tr),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          // print('Search song tapped: ${song.title} (id: ${song.id})');
          controller.playSong(songList, song);
        },
      ),
    );
  }

  Widget _buildNoResults() {
    return _buildEmptyState(
      'No results found'.tr,
      'Try searching with different keywords'.tr,
      Icons.search_off,
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleCategoryTap(String category) {
    switch (category) {
      case 'Recently Played':
        // controller.titleTapAction('library', 'Recently Played');
        _showPlaylistSongs(controller.allPlaylists[1]);
        break;
      case 'Most Played':
        // controller.changeView('library');
        _showPlaylistSongs(controller.allPlaylists[2]);
        break;
      case 'Liked Songs':
        // controller.changeView('library');
        _showPlaylistSongs(controller.allPlaylists[0]);
        break;
      case 'All Artists':
        controller.titleTapAction('library', 'All Artists');
        break;
      case 'All Albums':
        controller.titleTapAction('library', 'All Albums');
        break;
      case 'Playlists':
        controller.titleTapAction('library', 'Playlists');
        break;
    }
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child: Text(
              'Close'.tr,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
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
