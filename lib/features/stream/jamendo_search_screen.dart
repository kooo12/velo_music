import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velo/core/constants/app_colors.dart';
import 'package:velo/core/constants/constants.dart';
import 'package:velo/core/models/jamendo/jamendo_genre_model.dart';
import 'package:velo/core/models/jamendo/jamendo_track_model.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:velo/features/stream/stream_controller.dart';
import 'package:velo/features/stream/widgets/jamendo_track_detail_sheet.dart';
import 'package:velo/widgets/loading_widget.dart';

class JamendoSearchScreen extends StatefulWidget {
  const JamendoSearchScreen({super.key});

  @override
  State<JamendoSearchScreen> createState() => _JamendoSearchScreenState();
}

class _JamendoSearchScreenState extends State<JamendoSearchScreen> {
  late final StreamMusicController _ctrl;
  late final ThemeController _themeCtrl;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<StreamMusicController>();
    _themeCtrl = Get.find<ThemeController>();

    _searchCtrl.text = _ctrl.searchInputQuery.value;

    final initialQuery = Get.arguments?['query'] as String?;
    if (initialQuery != null && initialQuery.isNotEmpty) {
      _searchCtrl.text = initialQuery;
      _ctrl.performSearch(initialQuery);
    }

    ever(_ctrl.searchInputQuery, (String query) {
      if (_searchCtrl.text != query) {
        _searchCtrl.text = query;
      }
    });
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    if (val.trim().isEmpty) {
      _ctrl.clearSearch();
      return;
    }
    _debounce = Timer(
        const Duration(milliseconds: 400), () => _ctrl.performSearch(val));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _themeCtrl.currentAppTheme.value.gradientColors;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: gradientColors.first,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(
                      child: Obx(() {
                        final hasQuery =
                            _ctrl.searchInputQuery.value.trim().isNotEmpty ||
                                _ctrl.selectedTag.value != null;
                        if (hasQuery) {
                          return _buildResults();
                        }
                        return _buildDiscovery();
                      }),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  right: 20,
                  child: Text(
                    'Powered by Jamendo',
                    style: _themeCtrl.activeTheme.textTheme.bodyLarge!
                        .copyWith(color: AppColors.white.withOpacity(0.2)),
                  ),
                )
              ],
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
                          controller: _searchCtrl,
                          onChanged: _onSearchChanged,
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
                      Obx(() => _ctrl.searchInputQuery.value.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                _ctrl.clearSearch();
                              },
                              child: Icon(Icons.close,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 18),
                            )
                          : const SizedBox.shrink()),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ResponsiveContext(context).isTabletLandscape
              ? const SizedBox()
              : GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDiscovery() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrendingHeader(),
          const SizedBox(height: 12),
          _buildTrendingChips(),
          const SizedBox(height: 24),
          _buildTopResultsSection(),
          const SizedBox(height: 24),
          _buildGenresHeader(),
          const SizedBox(height: 12),
          _buildGenreGrid(),
        ],
      ),
    );
  }

  Widget _buildTrendingHeader() {
    return Row(
      children: [
        const Text(
          'Trending',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Text(
            'NOW PLAYING GLOBAL',
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingChips() {
    return Obx(() {
      if (_ctrl.isLoadingTags.value) {
        return SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            itemBuilder: (_, __) => Container(
              width: 80,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      }
      final tags = _ctrl.localTrendingTags;
      if (tags.isEmpty) {
        return const Text('No trending tags available.',
            style: TextStyle(color: Colors.white70));
      }
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags
            .map((t) => _TrendingChip(
                  label: t.displayName,
                  onTap: () => _ctrl.filterByTag(t.name),
                ))
            .toList(),
      );
    });
  }

  Widget _buildTopResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Results',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            // GestureDetector(
            //   onTap: () => _filterByTag('pop'),
            //   child: Text(
            //     'SEE ALL',
            //     style: TextStyle(
            //         color: Colors.white.withOpacity(0.6),
            //         fontSize: 11,
            //         fontWeight: FontWeight.w700),
            //   ),
            // ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          final tracks = _ctrl.topTracks.take(5).toList();
          if (_ctrl.isSearching.value) {
            return Center(
              child: LoadingWidget(
                color: Colors.white.withOpacity(0.5),
              ),
            );
          }
          if (tracks.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                  color: Colors.white38, strokeWidth: 2),
            );
          }
          return Column(
            children: [
              // Featured top result
              _FeaturedResultCard(
                track: tracks.first,
                onTap: () =>
                    JamendoTrackDetailSheet.show(context, tracks.first),
              ),
              const SizedBox(height: 8),
              // List results
              ...tracks.skip(1).map((t) => _SearchResultListItem(
                    track: t,
                    onTap: () => JamendoTrackDetailSheet.show(context, t),
                    ctrl: _ctrl,
                  )),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildGenresHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Browse Genres',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        // GestureDetector(
        //   onTap: () {},
        //   child: const Text(
        //     'EXPLORE',
        //     style: TextStyle(
        //         color: Color(0xFF7C3AED),
        //         fontSize: 11,
        //         fontWeight: FontWeight.w700),
        //   ),
        // ),
      ],
    );
  }

  Widget _buildGenreGrid() {
    return Obx(() {
      final g = _ctrl.localGenres;
      if (g.isEmpty) {
        return const SizedBox(
            height: 60,
            child: Center(
              child: Text('No genres available.',
                  style: TextStyle(color: Colors.white70)),
            ));
      }
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveContext(context).isTabletLandscape ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio:
              ResponsiveContext(context).isTabletLandscape ? 5 : 2.2,
        ),
        itemCount: g.length.clamp(0, 10),
        itemBuilder: (_, i) => _GenreCard(
          genre: g[i],
          index: i,
          onTap: () => _ctrl.filterByTag(g[i].name),
        ),
      );
    });
  }

  Widget _buildResults() {
    return Column(
      children: [
        Obx(() {
          if (_ctrl.selectedTag.value == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tag: ${_ctrl.selectedTag.value!.toUpperCase()}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _ctrl.clearSearch();
                        },
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        Expanded(
          child: Obx(() {
            if (_ctrl.isSearching.value) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // CircularProgressIndicator(color: Colors.white54),
                    LoadingWidget(),
                    SizedBox(height: 14),
                    Text('Searching in Jamendo…',
                        style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              );
            }

            if (_ctrl.searchResults.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 64, color: Colors.white.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    const Text('No results found',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Try different keywords or browse genres below',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 13)),
                  ],
                ),
              );
            }

            return ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              itemCount: _ctrl.searchResults.length,
              itemBuilder: (ctx, i) => _SearchResultListItem(
                track: _ctrl.searchResults[i],
                onTap: () =>
                    JamendoTrackDetailSheet.show(ctx, _ctrl.searchResults[i]),
                ctrl: _ctrl,
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Trending Chip ────────────────────────────────────────────────────────────

class _TrendingChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TrendingChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}

// ─── Featured Result Card ─────────────────────────────────────────────────────

class _FeaturedResultCard extends StatelessWidget {
  final JamendoTrack track;
  final VoidCallback onTap;
  const _FeaturedResultCard({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: track.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.white10,
                  child: const Icon(Icons.music_note,
                      color: Colors.white38, size: 30),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          themeCtrl.currentAppTheme.value.gradientColors.first,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'TOP TRACK',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artistName,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 12),
                  ),
                  if (track.tags.isNotEmpty)
                    Wrap(
                      spacing: 5,
                      children: track.tags.take(2).map((t) {
                        return Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t.toUpperCase(),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 9,
                                fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search Result List Item ──────────────────────────────────────────────────

class _SearchResultListItem extends StatelessWidget {
  final JamendoTrack track;
  final VoidCallback onTap;
  final StreamMusicController ctrl;

  const _SearchResultListItem({
    required this.track,
    required this.onTap,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: track.imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: Colors.white10,
                  child: const Icon(Icons.music_note,
                      color: Colors.white38, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 12),
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
                onTap: () => ctrl.playPreview(track),
                child: loading
                    ? const SizedBox(
                        width: 30,
                        height: 30,
                        child: Padding(
                          padding: EdgeInsets.all(4.0),
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 1.5,
                          ),
                        ),
                      )
                    : Icon(
                        playing ? Icons.pause_circle : Icons.play_circle,
                        color: Colors.white.withOpacity(0.5),
                        size: 30,
                      ),
              );
            }),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onTap,
              child: Icon(Icons.more_vert,
                  color: Colors.white.withOpacity(0.4), size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Genre Card ───────────────────────────────────────────────────────────────

class _GenreCard extends StatelessWidget {
  final JamendoGenre genre;
  final int index;
  final VoidCallback onTap;

  const _GenreCard({
    required this.genre,
    required this.index,
    required this.onTap,
  });

  static const _palettes = [
    [Color(0xFF7C3AED), Color(0xFF4F46E5)],
    [Color(0xFF059669), Color(0xFF0D9488)],
    [Color(0xFFDC2626), Color(0xFF9D174D)],
    [Color(0xFFD97706), Color(0xFFB45309)],
    [Color(0xFF2563EB), Color(0xFF4F46E5)],
    [Color(0xFFDB2777), Color(0xFF9D174D)],
    [Color(0xFF0891B2), Color(0xFF0E7490)],
    [Color(0xFF16A34A), Color(0xFF059669)],
    [Color(0xFF9333EA), Color(0xFF7C3AED)],
    [Color(0xFFEA580C), Color(0xFFDC2626)],
  ];

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[index % _palettes.length];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: palette),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: palette.first.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -6,
              bottom: 6,
              child: Icon(
                Icons.chevron_right,
                size: 40,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                genre.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
