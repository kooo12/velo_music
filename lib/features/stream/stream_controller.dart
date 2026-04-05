import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:velo/core/helper/loaders.dart';
import 'package:velo/core/models/jamendo/jamendo_album_model.dart';
import 'package:velo/core/models/jamendo/jamendo_genre_model.dart';
import 'package:velo/core/models/jamendo/jamendo_track_model.dart';
import 'package:velo/core/repository/genius_repository.dart';
import 'package:velo/core/repository/jamendo_repository.dart';
import 'package:velo/core/repository/lastfm_repository.dart';
import 'package:velo/core/models/song_model.dart';
import 'package:velo/core/models/lyric_model.dart';
import 'package:velo/core/services/audio_service.dart';
import 'package:velo/features/home/home_controller.dart';

class StreamMusicController extends GetxController {
  static const _pageSize = 20;

  final JamendoRepository _jamendo;
  final GeniusRepository _genius;
  final LastFmRepository _lastFm;

  StreamMusicController({
    JamendoRepository? jamendo,
    GeniusRepository? genius,
    LastFmRepository? lastFm,
  })  : _jamendo = jamendo ?? JamendoRepository(),
        _genius = genius ?? GeniusRepository(),
        _lastFm = lastFm ?? LastFmRepository();

  // Top Tracks
  final RxList<JamendoTrack> topTracks = <JamendoTrack>[].obs;
  final RxBool isLoadingTop = false.obs;
  final RxBool hasMoreTop = true.obs;
  int _topOffset = 0;

  // New Releases
  final RxList<JamendoAlbum> newReleases = <JamendoAlbum>[].obs;
  final RxBool isLoadingReleases = false.obs;
  final RxBool hasMoreReleases = true.obs;
  int _releasesOffset = 0;
  final RxString selectedNewReleaseGenre = 'All'.obs;
  final List<String> availableGenres = [
    'All',
    'Pop',
    'Rock',
    'Electronic',
    'Hip-Hop',
    'Jazz',
    'Classical',
    'Indie',
    'Metal',
    'Ambient'
  ];

  // Daily Mix
  final RxList<JamendoTrack> dailyMix = <JamendoTrack>[].obs;
  final RxBool isLoadingMix = false.obs;

  // Recommended
  final RxList<JamendoTrack> recommended = <JamendoTrack>[].obs;
  final RxBool isLoadingRec = false.obs;
  final RxBool hasMoreRec = true.obs;
  int _recOffset = 0;

  // Tags / Genres
  final RxList<JamendoGenre> trendingTags = <JamendoGenre>[].obs;
  final RxList<JamendoGenre> genres = <JamendoGenre>[].obs;

  // Error flags
  final RxBool hasErrorTop = false.obs;
  final RxBool hasErrorReleases = false.obs;
  final RxBool hasErrorRec = false.obs;

  // Lyrics
  final RxnString lyrics = RxnString();
  final RxList<LyricLine> syncedLyrics = <LyricLine>[].obs;
  final RxBool isLoadingLyrics = false.obs;
  final RxBool lyricsUnavailable = false.obs;

  // Similar Artists
  final RxList<LastFmArtist> similarArtists = <LastFmArtist>[].obs;
  final RxBool isLoadingSimilar = false.obs;

  final HomeController _homeCtrl = Get.find<HomeController>();

  bool get isPlaying {
    final currentSong = _homeCtrl.currentSong;
    if (currentSong == null || currentTrack.value == null) return false;
    if (!_homeCtrl.isPlaying) return false;

    if (currentSong.data == currentTrack.value!.audioUrl) return true;

    if (currentSong.data.contains(currentTrack.value!.name) &&
        currentSong.data.contains(currentTrack.value!.artistName)) {
      return true;
    }

    return false;
  }

  bool get isLoadingPreview {
    final currentSong = _homeCtrl.currentSong;
    if (currentSong == null || currentTrack.value == null) return false;
    if (!_homeCtrl.isBuffering) return false;

    if (currentSong.data == currentTrack.value!.audioUrl) return true;

    if (currentSong.data.contains(currentTrack.value!.name) &&
        currentSong.data.contains(currentTrack.value!.artistName)) {
      return true;
    }

    return false;
  }

  final Rx<JamendoTrack?> currentTrack = Rx<JamendoTrack?>(null);

  // Search State
  final RxString searchInputQuery = ''.obs;
  final RxList<JamendoTrack> searchResults = <JamendoTrack>[].obs;
  final RxBool isSearching = false.obs;
  final RxnString selectedTag = RxnString();
  final RxList<JamendoGenre> localTrendingTags = <JamendoGenre>[].obs;
  final RxList<JamendoGenre> localGenres = <JamendoGenre>[].obs;
  final RxBool isLoadingTags = false.obs;
  final RxSet<String> downloadedTrackIds = <String>{}.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> loadAll() async {
    await Future.wait([
      _loadTopTracksInitial(),
      _loadNewReleasesInitial(),
      _loadRecommendedInitial(),
      _loadTags(),
      _loadDailyMix(),
    ]);
  }

  @override
  Future<void> refresh() async {
    _topOffset = 0;
    _releasesOffset = 0;
    _recOffset = 0;
    hasMoreTop.value = true;
    hasMoreReleases.value = true;
    hasMoreRec.value = true;
    topTracks.clear();
    newReleases.clear();
    recommended.clear();
    dailyMix.clear();
    await loadAll();
  }

  Future<void> _loadTopTracksInitial() async {
    if (isLoadingTop.value) return;
    isLoadingTop.value = true;
    hasErrorTop.value = false;
    try {
      final data = await _jamendo.getTopTracks(
        limit: _pageSize,
        offset: _topOffset,
      );
      topTracks.assignAll(data);
      _topOffset = data.length;
      hasMoreTop.value = data.length == _pageSize;
      _extractTrendingTags(data);
    } catch (e) {
      hasErrorTop.value = true;
      debugPrint('StreamMusicController._loadTopTracksInitial error: $e');
    } finally {
      isLoadingTop.value = false;
    }
  }

  void _extractTrendingTags(List<JamendoTrack> tracks) {
    final tagCounts = <String, int>{};
    for (final t in tracks) {
      for (final g in t.tagsGenres) {
        tagCounts[g] = (tagCounts[g] ?? 0) + 1;
      }
      for (final v in t.tagsVartags) {
        tagCounts[v] = (tagCounts[v] ?? 0) + 1;
      }
    }
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topDynamic = sortedTags
        .take(12)
        .map((e) => JamendoGenre(
              id: e.key,
              name: e.key,
              displayName: e.key.toUpperCase(),
            ))
        .toList();
    if (topDynamic.isNotEmpty) {
      trendingTags.assignAll(topDynamic);
      localTrendingTags.assignAll(topDynamic);
    } else {
      _jamendo.getTrendingTags(limit: 10).then((fallback) {
        trendingTags.assignAll(fallback);
        localTrendingTags.assignAll(fallback);
      });
    }
  }

  Future<void> loadMoreTopTracks() async {
    if (isLoadingTop.value || !hasMoreTop.value) return;
    isLoadingTop.value = true;
    try {
      final data = await _jamendo.getTopTracks(
        limit: _pageSize,
        offset: _topOffset,
      );
      topTracks.addAll(data);
      _topOffset += data.length;
      hasMoreTop.value = data.length == _pageSize;
    } catch (_) {
    } finally {
      isLoadingTop.value = false;
    }
  }

  Future<void> _loadNewReleasesInitial() async {
    if (isLoadingReleases.value) return;
    isLoadingReleases.value = true;
    hasErrorReleases.value = false;
    try {
      final tag = selectedNewReleaseGenre.value == 'All'
          ? null
          : selectedNewReleaseGenre.value.toLowerCase();
      final data = await _jamendo.getNewReleases(
        limit: _pageSize,
        offset: _releasesOffset,
        tags: tag,
      );
      newReleases.assignAll(data);
      _releasesOffset = data.length;
      hasMoreReleases.value = data.length == _pageSize;
    } catch (e) {
      hasErrorReleases.value = true;
      debugPrint('StreamMusicController._loadNewReleasesInitial error: $e');
    } finally {
      isLoadingReleases.value = false;
    }
  }

  Future<void> setGenre(String genre) async {
    if (selectedNewReleaseGenre.value == genre) return;
    selectedNewReleaseGenre.value = genre;
    _releasesOffset = 0;
    newReleases.clear();
    hasMoreReleases.value = true;
    await _loadNewReleasesInitial();
  }

  Future<void> loadMoreNewReleases() async {
    if (isLoadingReleases.value || !hasMoreReleases.value) return;
    isLoadingReleases.value = true;
    try {
      final tag = selectedNewReleaseGenre.value == 'All'
          ? null
          : selectedNewReleaseGenre.value.toLowerCase();
      final data = await _jamendo.getNewReleases(
        limit: _pageSize,
        offset: _releasesOffset,
        tags: tag,
      );
      newReleases.addAll(data);
      _releasesOffset += data.length;
      hasMoreReleases.value = data.length == _pageSize;
    } catch (_) {
    } finally {
      isLoadingReleases.value = false;
    }
  }

  Future<void> _loadDailyMix() async {
    if (isLoadingMix.value) return;
    isLoadingMix.value = true;
    try {
      // Create a personalized-feeling mix by fetching high-rated tracks with different offsets
      final data = await _jamendo.getRecommendedTracks(
        limit: 10,
        offset: 50, // Peeking deeper into recommendations for "mix" variety
      );
      dailyMix.assignAll(data..shuffle());
    } catch (e) {
      debugPrint('StreamMusicController._loadDailyMix error: $e');
    } finally {
      isLoadingMix.value = false;
    }
  }

  Future<void> _loadRecommendedInitial() async {
    if (isLoadingRec.value) return;
    isLoadingRec.value = true;
    hasErrorRec.value = false;
    try {
      final data = await _jamendo.getRecommendedTracks(
        limit: _pageSize,
        offset: _recOffset,
      );
      recommended.assignAll(data);
      _recOffset = data.length;
      hasMoreRec.value = data.length == _pageSize;
    } catch (e) {
      hasErrorRec.value = true;
      debugPrint('StreamMusicController._loadRecommendedInitial error: $e');
    } finally {
      isLoadingRec.value = false;
    }
  }

  Future<void> loadMoreRecommended() async {
    if (isLoadingRec.value || !hasMoreRec.value) return;
    isLoadingRec.value = true;
    try {
      final data = await _jamendo.getRecommendedTracks(
        limit: _pageSize,
        offset: _recOffset,
      );
      recommended.addAll(data);
      _recOffset += data.length;
      hasMoreRec.value = data.length == _pageSize;
    } catch (_) {
    } finally {
      isLoadingRec.value = false;
    }
  }

  Future<void> _loadTags() async {
    try {
      final results = await _jamendo.getTopGenres(limit: 20);
      genres.assignAll(results);
      localGenres.assignAll(results);
    } catch (e) {
      debugPrint('StreamMusicController._loadTags error: $e');
    }
  }

  bool isEnglishOnly(String text) {
    final RegExp englishRegex = RegExp(r"^[a-zA-Z0-9\s\-\.\,\!\?\(\)\[\]'&]*$");
    return englishRegex.hasMatch(text);
  }

  Future<void> fetchLyrics(String artist, String title) async {
    lyrics.value = null;
    syncedLyrics.clear();
    lyricsUnavailable.value = false;

    if (!isEnglishOnly(artist) || !isEnglishOnly(title)) {
      debugPrint('Skipping lyrics fetch: Non-English characters detected');
      lyricsUnavailable.value = true;
      isLoadingLyrics.value = false;
      return;
    }

    isLoadingLyrics.value = true;
    try {
      final result = await _genius.getLyrics(artist, title);

      if (result != null && result.isNotEmpty) {
        lyrics.value = result;
      } else {
        final synced = await _genius.getSyncedLyrics(artist, title);
        if (synced != null && synced.isNotEmpty) {
          syncedLyrics.assignAll(synced);
        }
      }

      if (syncedLyrics.isEmpty && lyrics.value == null) {
        lyricsUnavailable.value = true;
      }
    } catch (e) {
      debugPrint('StreamMusicController.fetchLyrics error: $e');
      if (syncedLyrics.isEmpty && lyrics.value == null) {
        lyricsUnavailable.value = true;
      }
    } finally {
      isLoadingLyrics.value = false;
    }
  }

  Future<void> fetchSimilarArtists(String artistName) async {
    similarArtists.clear();
    isLoadingSimilar.value = true;
    try {
      final result = await _lastFm.getSimilarArtists(artistName, limit: 12);
      similarArtists.assignAll(result);
    } catch (e) {
      debugPrint('StreamMusicController.fetchSimilarArtists error: $e');
    } finally {
      isLoadingSimilar.value = false;
    }
  }

  SongModel _mapTrackToSong(JamendoTrack track) {
    return SongModel(
      id: track.id.hashCode,
      title: track.name,
      artist: track.artistName,
      album: track.albumName,
      duration: track.duration * 1000,
      data: track.audioUrl,
      displayName: track.name,
      albumArtwork: track.imageUrl,
      isMusic: true,
      genre: track.tagsGenres.isNotEmpty ? track.tagsGenres.first : null,
      track: track.position,
      year: null,
      size: 0,
      jamendoWaveform: track.waveform,
    );
  }

  Future<Directory> _getMusicOutputDir() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final externalStorage = await getExternalStorageDirectory();
        if (externalStorage == null) {
          throw Exception('External storage directory is null');
        }

        final externalPath = externalStorage.path;
        final emulatedIndex = externalPath.indexOf('/emulated/0');

        if (emulatedIndex == -1) {
          throw Exception('Could not find emulated/0 in path: $externalPath');
        }

        final basePath =
            externalPath.substring(0, emulatedIndex + '/emulated/0'.length);
        final musicDir = Directory(p.join(
          basePath,
          'Music',
        ));

        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
          debugPrint('=>[YT Download] Created directory: ${musicDir.path}');
        }

        debugPrint(
            '=>[YT Download] Using public Music directory: ${musicDir.path}');
        return musicDir;
      } catch (e) {
        debugPrint(
            '=>[YT Download] Error accessing public Music directory: $e');
        rethrow;
      }
    } else {
      final base = await getApplicationDocumentsDirectory();
      final musicDir = Directory(p.join(
        base.path,
        'Music',
      ));

      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      debugPrint(
          '=>[YT Download] Using app documents directory: ${musicDir.path}');
      return musicDir;
    }
  }

  Future<void> playPreview(JamendoTrack track,
      {List<JamendoTrack>? contextList}) async {
    try {
      currentTrack.value = track;

      // On web, File/Directory operations are not supported — play the stream URL directly.
      if (kIsWeb) {
        final playlist = contextList ?? [track];
        final songList = playlist.map(_mapTrackToSong).toList();
        final currentSong = _mapTrackToSong(track);

        if (_homeCtrl.currentSong?.data == track.audioUrl) {
          await _homeCtrl.playPause();
          return;
        }
        await _homeCtrl.playSong(songList, currentSong);
        return;
      }

      final musicDir = await _getMusicOutputDir();
      final musicPath = musicDir.path;
      final fileName =
          '${track.artistName} - ${track.name}.mp3'.replaceAll('/', '_');
      final localFile = File('$musicPath/$fileName');
      final bool existsLocally = await localFile.exists();

      if (_homeCtrl.currentSong?.data ==
          (existsLocally ? localFile.path : track.audioUrl)) {
        await _homeCtrl.playPause();
        return;
      }

      final playlist = contextList ?? [track];
      final songList = await Future.wait(playlist.map((t) async {
        final song = _mapTrackToSong(t);
        final tFile = File(
            '$musicPath/${'${t.artistName} - ${t.name}.mp3'.replaceAll('/', '_')}');
        if (await tFile.exists()) {
          return song.copyWith(data: tFile.path);
        }
        return song;
      }));

      final currentSong = existsLocally
          ? _mapTrackToSong(track).copyWith(data: localFile.path)
          : _mapTrackToSong(track);

      await _homeCtrl.playSong(songList, currentSong);
    } catch (e) {
      debugPrint('StreamMusicController.playPreview error: $e');
    }
  }

  Future<void> stopPreview() async {
    if (isPlaying) {
      await _homeCtrl.playPause();
    }
    currentTrack.value = null;
  }

  final RxBool isDownloading = false.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxnString downloadingTrackId = RxnString();

  Future<void> downloadTrack(JamendoTrack track) async {
    if (kIsWeb) {
      AppLoader.customToast(message: 'Download is not supported on web.');
      return;
    }

    if (isDownloading.value) return;

    final url = track.audioDownloadUrl.isNotEmpty
        ? track.audioDownloadUrl
        : track.audioUrl;
    if (url.isEmpty) {
      AppLoader.customToast(
          message: 'No download URL available for this track.');
      return;
    }

    try {
      isDownloading.value = true;
      downloadingTrackId.value = track.id;
      downloadProgress.value = 0.0;

      final musicDir = await _getMusicOutputDir();
      final musicPath = musicDir.path;
      final fileName =
          '${track.artistName} - ${track.name}.mp3'.replaceAll('/', '_');
      final savePath = '$musicPath/$fileName';

      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress.value = received / total;
          }
        },
      );
      downloadedTrackIds.add(track.id);

      try {
        final audioService = Get.find<AudioPlayerService>();
        final file = File(savePath);
        final size = await file.length();

        final localSong = _mapTrackToSong(track).copyWith(
          data: savePath,
          size: size,
          album: track.albumName.isNotEmpty
              ? track.albumName
              : 'Jamendo Downloads',
        );

        audioService.addSongToLibrary(localSong);
      } catch (e) {
        debugPrint('Error adding to library: $e');
      }

      AppLoader.customToast(
          message: '${track.name} saved successfully to Music folder!');
    } catch (e) {
      debugPrint('Download error: $e');
      AppLoader.customToast(message: 'Could not download track.');
    } finally {
      isDownloading.value = false;
      downloadingTrackId.value = null;
      downloadProgress.value = 0.0;
    }
  }

  Future<void> refreshDownloadStatus(JamendoTrack track) async {
    if (kIsWeb) return;
    try {
      final musicDir = await _getMusicOutputDir();
      final musicPath = musicDir.path;
      final fileName =
          '${track.artistName} - ${track.name}.mp3'.replaceAll('/', '_');
      final localFile = File('$musicPath/$fileName');
      if (await localFile.exists()) {
        downloadedTrackIds.add(track.id);
      } else {
        downloadedTrackIds.remove(track.id);
      }
    } catch (_) {}
  }

  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }
    isSearching.value = true;
    selectedTag.value = null;
    searchInputQuery.value = query;
    try {
      final data = await _jamendo.searchTracks(query: query);
      searchResults.assignAll(data);
    } catch (e) {
      debugPrint('performSearch error: $e');
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> filterByTag(String tag) async {
    selectedTag.value = tag;
    searchInputQuery.value = '';
    isSearching.value = true;
    try {
      final data = await _jamendo.getTracksByTag(tag: tag);
      searchResults.assignAll(data);
    } catch (e) {
      debugPrint('filterByTag error: $e');
    } finally {
      isSearching.value = false;
    }
  }

  void clearSearch() {
    searchInputQuery.value = '';
    searchResults.clear();
    selectedTag.value = null;
  }

  Future<List<JamendoGenre>> getTrendingTags({int limit = 10}) {
    return _jamendo.getTrendingTags(limit: limit);
  }

  Future<List<JamendoGenre>> getTopGenres({int limit = 20}) {
    return _jamendo.getTopGenres(limit: limit);
  }
}
