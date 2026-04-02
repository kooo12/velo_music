import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velo/core/constants/app_colors.dart';
import 'package:velo/core/models/jamendo/jamendo_track_model.dart';
import 'package:velo/core/repository/jamendo_repository.dart';
import 'package:velo/features/stream/stream_controller.dart';
import 'package:velo/features/stream/widgets/jamendo_track_detail_sheet.dart';
import 'package:velo/widgets/loading_widget.dart';
import 'package:velo/core/controllers/theme_controller.dart';

class JamendoListScreen extends StatefulWidget {
  const JamendoListScreen({super.key});

  @override
  State<JamendoListScreen> createState() => _JamendoListScreenState();
}

class _JamendoListScreenState extends State<JamendoListScreen> {
  late final StreamMusicController _ctrl;
  late final JamendoRepository _repo;
  late final ThemeController _themeCtrl;
  final ScrollController _scrollController = ScrollController();

  final String title = Get.arguments?['title'] as String? ?? 'List';
  final String type = Get.arguments?['type'] as String? ?? '';
  final String albumId = Get.arguments?['id'] as String? ?? '';

  final RxList<JamendoTrack> _tracks = <JamendoTrack>[].obs;
  final RxBool _isLoading = true.obs;
  final RxBool _isLoadingMore = false.obs;
  final RxBool _hasError = false.obs;
  final RxBool _hasMore = true.obs;
  int _offset = 0;
  static const int _limit = 30;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<StreamMusicController>();
    _repo = Get.find<JamendoRepository>();
    _themeCtrl = Get.find<ThemeController>();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore.value &&
        _hasMore.value &&
        type != 'album') {
      _loadMore();
    }
  }

  Future<void> _loadData() async {
    _isLoading.value = true;
    _hasError.value = false;
    _offset = 0;
    _hasMore.value = true;
    try {
      List<JamendoTrack> data =
          await _fetchTracks(offset: _offset, limit: _limit);
      _tracks.assignAll(data);
      if (data.length < _limit || type == 'album') {
        _hasMore.value = false;
      }
    } catch (_) {
      _hasError.value = true;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadMore() async {
    _isLoadingMore.value = true;
    try {
      _offset += _limit;
      List<JamendoTrack> data =
          await _fetchTracks(offset: _offset, limit: _limit);
      if (data.isEmpty) {
        _hasMore.value = false;
      } else {
        _tracks.addAll(data);
        if (data.length < _limit) {
          _hasMore.value = false;
        }
      }
    } catch (_) {
      // Potentially handle error for load more
    } finally {
      _isLoadingMore.value = false;
    }
  }

  Future<List<JamendoTrack>> _fetchTracks(
      {required int offset, required int limit}) async {
    if (type == 'album') {
      return await _repo.getAlbumTracks(albumId);
    } else if (type == 'top') {
      return await _repo.getTopTracks(limit: limit, offset: offset);
    } else if (type == 'recommended') {
      return await _repo.getRecommendedTracks(limit: limit, offset: offset);
    } else if (type == 'newreleases') {
      return await _repo.getNewReleaseTracks(limit: limit, offset: offset);
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        final gradientColors = _themeCtrl.currentAppTheme.value.gradientColors;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: SafeArea(
            child: Obx(() {
              if (_isLoading.value && _tracks.isEmpty) {
                return const Center(
                    child: LoadingWidget(color: AppColors.white));
              }
              if (_hasError.value && _tracks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Error loading tracks.',
                          style: TextStyle(color: Colors.white70)),
                      TextButton(
                          onPressed: _loadData,
                          child: const Text('Retry',
                              style: TextStyle(color: Colors.white))),
                    ],
                  ),
                );
              }
              if (_tracks.isEmpty) {
                return const Center(
                    child: Text('No tracks found.',
                        style: TextStyle(color: Colors.white70)));
              }
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                itemCount: _tracks.length + (_hasMore.value ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == _tracks.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child:
                          Center(child: LoadingWidget(color: Colors.white54)),
                    );
                  }
                  return _TrackListItem(
                    track: _tracks[i],
                    contextList: _tracks.toList(),
                    ctrl: _ctrl,
                  );
                },
              );
            }),
          ),
        );
      }),
    );
  }
}

class _TrackListItem extends StatelessWidget {
  final JamendoTrack track;
  final List<JamendoTrack> contextList;
  final StreamMusicController ctrl;

  const _TrackListItem(
      {required this.track, required this.contextList, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => JamendoTrackDetailSheet.show(context, track),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: track.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.white10,
                  child: const Icon(Icons.music_note, color: Colors.white38),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artistName,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Obx(() {
              final isCurrent = ctrl.currentTrack.value?.id == track.id;
              final playing = isCurrent && ctrl.isPlaying;
              final loading = isCurrent && ctrl.isLoadingPreview;
              return GestureDetector(
                onTap: () => ctrl.playPreview(track, contextList: contextList),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: LoadingWidget(color: AppColors.white),
                      )
                    : Icon(
                        playing ? Icons.pause_circle : Icons.play_circle,
                        color: AppColors.white.withOpacity(0.5),
                        size: 32,
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
