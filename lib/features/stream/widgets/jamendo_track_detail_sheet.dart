import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:velo/features/home/home_controller.dart';
import 'package:velo/features/stream/stream_controller.dart';
import 'package:velo/routhing/app_routes.dart';
import 'package:get/get.dart';
import 'package:velo/core/constants/app_colors.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:velo/core/models/jamendo/jamendo_track_model.dart';
import 'package:velo/core/repository/lastfm_repository.dart';
import 'package:velo/core/models/lyric_model.dart';
import 'package:velo/widgets/loading_widget.dart';

class JamendoTrackDetailSheet extends StatefulWidget {
  final JamendoTrack track;
  const JamendoTrackDetailSheet({super.key, required this.track});

  static void show(BuildContext context, JamendoTrack track) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JamendoTrackDetailSheet(track: track),
    );
  }

  @override
  State<JamendoTrackDetailSheet> createState() =>
      _JamendoTrackDetailSheetState();
}

class _JamendoTrackDetailSheetState extends State<JamendoTrackDetailSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final StreamMusicController _ctrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _ctrl = Get.find<StreamMusicController>();

    _ctrl.fetchLyrics(widget.track.artistName, widget.track.name);
    _ctrl.fetchSimilarArtists(widget.track.artistName);
    _ctrl.refreshDownloadStatus(widget.track);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.85;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: h,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _InfoTab(track: widget.track, ctrl: _ctrl),
                    _LyricsTab(ctrl: _ctrl),
                    _SimilarTab(ctrl: _ctrl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final homeCtrl = Get.find<HomeController>();

    return Obx(
      () {
        final isCurrent = _ctrl.currentTrack.value?.id == widget.track.id;
        final isPlaying = isCurrent && _ctrl.isPlaying;
        final isLoading = isCurrent && _ctrl.isLoadingPreview;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: GestureDetector(
            onTap: isPlaying ? () => homeCtrl.openFullPlayer(homeCtrl) : null,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: widget.track.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: Colors.white10,
                      child:
                          const Icon(Icons.music_note, color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.track.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.track.artistName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: LoadingWidget(color: Colors.white),
                      )
                    : _GlassIconButton(
                        icon: isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        onTap: () => _ctrl.playPreview(widget.track),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Info'),
          Tab(text: 'Lyrics'),
          Tab(text: 'Similar'),
        ],
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final JamendoTrack track;
  final StreamMusicController ctrl;

  const _InfoTab({required this.track, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: CachedNetworkImage(
                imageUrl: track.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: Colors.white10,
                  child: const Icon(Icons.music_note,
                      color: Colors.white54, size: 64),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Obx(() {
            final isCurrent = ctrl.currentTrack.value?.id == track.id;
            final playing = isCurrent && ctrl.isPlaying;
            final loading = isCurrent && ctrl.isLoadingPreview;
            return _PlayButton(
              isPlaying: playing,
              isLoading: loading,
              onTap: () => ctrl.playPreview(track),
            );
          }),
          const SizedBox(height: 20),
          _InfoRow('Album', track.albumName),
          _InfoRow('Duration', track.formattedDuration),
          _InfoRow('Artist', track.artistName),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _StatBox(
                      label: 'PLAYS',
                      value: _formatCount(track.rateListenedTotal))),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatBox(
                      label: 'LIKES', value: _formatCount(track.likes))),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatBox(
                      label: 'FAVS', value: _formatCount(track.favorited))),
            ],
          ),
          const SizedBox(height: 12),
          if (track.vocalInstrumental.isNotEmpty || track.speed.isNotEmpty)
            Row(
              children: [
                if (track.vocalInstrumental.isNotEmpty)
                  _InfoPill(track.vocalInstrumental.toUpperCase()),
                const SizedBox(width: 8),
                if (track.speed.isNotEmpty)
                  _InfoPill(track.speed.toUpperCase()),
              ],
            ),
          const SizedBox(height: 20),
          Obx(() {
            final isThisDownloading = ctrl.downloadingTrackId.value == track.id;
            return _DownloadButton(
              isDownloading: isThisDownloading,
              isDownloaded: ctrl.downloadedTrackIds.contains(track.id),
              progress: isThisDownloading ? ctrl.downloadProgress.value : 0.0,
              onTap: () {
                if (!ctrl.downloadedTrackIds.contains(track.id)) {
                  ctrl.downloadTrack(track);
                }
              },
            );
          }),
          const SizedBox(height: 20),
          if (track.tagsGenres.isNotEmpty || track.tagsVartags.isNotEmpty) ...[
            const Text(
              'Genres & Tags',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...track.tagsGenres
                    .map((t) => _TagChip(label: t, isGenre: true)),
                ...track.tagsVartags
                    .map((t) => _TagChip(label: t, isGenre: false)),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;
  const _PlayButton(
      {required this.isPlaying, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    final themeColor = themeCtrl.currentAppTheme.value.gradientColors.first;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: themeColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? const LoadingWidget(color: Colors.white)
                : Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
            const SizedBox(width: 8),
            Text(
              isPlaying ? 'Pause Preview' : 'Play Preview',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool isGenre;
  const _TagChip({required this.label, this.isGenre = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isGenre
            ? AppColors.musicPrimary.withOpacity(0.15)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isGenre
                ? AppColors.musicPrimary.withOpacity(0.3)
                : Colors.white.withOpacity(0.15)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: isGenre ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isGenre ? FontWeight.bold : FontWeight.normal),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  const _InfoPill(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final bool isDownloading;
  final bool isDownloaded;
  final double progress;
  final VoidCallback onTap;
  const _DownloadButton({
    required this.isDownloading,
    required this.isDownloaded,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDownloaded
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDownloaded
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isDownloading)
              SizedBox(
                width: 24,
                height: 24,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress > 0 ? progress : null,
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                    if (progress > 0)
                      Text(
                        '${(progress * 100).toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              )
            else if (isDownloaded)
              const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.greenAccent, size: 24)
            else
              const Icon(Icons.file_download_outlined,
                  color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(
              isDownloading
                  ? 'Downloading ${progress > 0 ? '${(progress * 100).toInt()}%' : '…'}'
                  : isDownloaded
                      ? 'Downloaded'
                      : 'Download MP3',
              style: TextStyle(
                  color: isDownloaded ? Colors.white60 : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _LyricsTab extends StatelessWidget {
  final StreamMusicController ctrl;
  const _LyricsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingLyrics.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingWidget(color: Colors.white54),
              SizedBox(height: 16),
              Text('Fetching lyrics…',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        );
      }

      if (ctrl.lyricsUnavailable.value || ctrl.lyrics.value == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_off_rounded,
                  size: 60, color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 16),
              const Text(
                'Lyrics Unavailable',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Could not find lyrics for this track.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 13),
              ),
            ],
          ),
        );
      }

      final String? plainLyrics = ctrl.lyrics.value;
      final List<LyricLine> synced = ctrl.syncedLyrics;

      if (synced.isEmpty && plainLyrics == null) {
        return const Center(
            child: Text('No lyrics available.',
                style: TextStyle(color: Colors.white70)));
      }

      final String displayLyrics = synced.isNotEmpty
          ? synced.map((l) => l.text).where((t) => t.isNotEmpty).join('\n\n')
          : plainLyrics ?? "";

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 60),
        child: SelectionArea(
          child: Text(
            displayLyrics,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.8,
              letterSpacing: 0.2,
            ),
          ),
        ),
      );
    });
  }
}

class _SimilarTab extends StatelessWidget {
  final StreamMusicController ctrl;
  const _SimilarTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingSimilar.value) {
        return const Center(
          child: LoadingWidget(color: Colors.white54),
        );
      }

      final artists = ctrl.similarArtists;
      if (artists.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline,
                  size: 60, color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 16),
              const Text(
                'No Similar Artists Found',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        itemCount: artists.length,
        itemBuilder: (_, i) => _SimilarArtistTile(artist: artists[i]),
      );
    });
  }
}

class _SimilarArtistTile extends StatelessWidget {
  final LastFmArtist artist;
  const _SimilarArtistTile({required this.artist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final ctrl = Get.find<StreamMusicController>();
        Get.closeAllBottomSheets();
        Navigator.pop(context);
        if (Get.currentRoute == Routes.JAMENDO_SEARCH) {
          ctrl.performSearch(artist.name);
        } else {
          Get.toNamed(Routes.JAMENDO_SEARCH, arguments: {'query': artist.name});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: artist.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: artist.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          title: Text(
            artist.name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 48,
        height: 48,
        color: Colors.white10,
        child: const Icon(Icons.person, color: Colors.white38),
      );
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
