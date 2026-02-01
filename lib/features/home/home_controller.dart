import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonus/core/helper/loaders.dart';
import 'package:sonus/core/models/playlist_model.dart';
import 'package:sonus/core/models/song_model.dart';
import 'package:sonus/core/services/audio_service.dart';
import 'package:sonus/core/services/playlist_service.dart';
import 'package:sonus/core/services/sleep_timer_service.dart';
import 'package:sonus/core/utils/theme_controller.dart';
import 'package:sonus/routhing/app_routes.dart';

import '../../core/helper/sleep_timer_dialog.dart';

enum RepeatMode { off, all, one }

class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final themeCtrl = Get.find<ThemeController>();

  // Services
  late final AudioPlayerService audioService;
  late final PlaylistService _playlistService;
  late final SleepTimerService _sleepTimerService;

  // Scroll controllers
  late final ScrollController allSongsScrollController;
  late final ScrollController artistsScrollController;
  late final ScrollController albumsScrollController;
  late final ScrollController playlistsScrollController;
  late final TextEditingController searchTextController;

  late TabController _tabController;

  final RxString currentView = 'home'.obs;
  final RxBool isLoading = false.obs;

  final RxString searchQuery = ''.obs;
  final RxList<String> recentSearches = <String>[].obs;

  final RxInt playlistsVersion = 0.obs;
  final RxBool isShuffleOn = false.obs;
  final Rx<RepeatMode> repeatMode = RepeatMode.off.obs;

  static const String _prefsKeyRecentSearches = 'recent_searches';
  final Map<String, Uint8List?> _artworkCache = {};

  final RxDouble _seekingPosition = 0.0.obs;
  final RxBool _isSeeking = false.obs;

  // Getter -------------------------------------------------------
  double get seekingPosition => _seekingPosition.value;
  bool get isSeeking => _isSeeking.value;
  bool get isPlaying => audioService.isPlaying.value;
  bool get isAudioLoading => audioService.isLoading.value;
  bool get hasAttemptedLoad => audioService.hasAttemptedLoad.value;
  int get currentSongIndex => audioService.currentIndex.value;
  double get currentPosition => _isSeeking.value
      ? _seekingPosition.value
      : audioService.currentPosition.value;

  double get totalDuration => audioService.totalDuration.value;
  bool get hasPermission => audioService.hasPermission.value;

  List<SongModel> get allSongs => audioService.allSongs;
  SongModel? get currentSong => audioService.currentSong;
  TabController get tabController => _tabController;

  PlaylistService get playlistService => _playlistService;
  List<SongModel> get likedSongs => _playlistService.likedSongs;
  List<SongModel> get recentlyPlayed => _playlistService.recentlyPlayed;
  List<SongModel> get currentPlayList => _playlistService.currentPlayList;
  List<PlaylistModel> get userPlaylists => _playlistService.userPlaylists;
  List<PlaylistModel> get allPlaylists => _playlistService.allPlaylists;

  set currentPlayList(List<SongModel> value) {
    _playlistService.currentPlayList = value;
  }

  SleepTimerService get sleepTimerService => _sleepTimerService;
  bool get isSleepTimerActive => _sleepTimerService.isActive;
  String get sleepTimerFormattedTime => _sleepTimerService.formattedTime;
  double get sleepTimerProgress => _sleepTimerService.progress;

  @override
  void onInit() async {
    _initializeServices();
    _tabController = TabController(length: 4, vsync: this);

    allSongsScrollController = ScrollController();
    artistsScrollController = ScrollController();
    albumsScrollController = ScrollController();
    playlistsScrollController = ScrollController();
    searchTextController = TextEditingController();
    _loadRecentSearches();
    super.onInit();
  }

  void _initializeServices() {
    try {
      audioService = Get.find<AudioPlayerService>();
      debugPrint('HomeController: Found existing AudioPlayerService instance');
    } catch (e) {
      audioService = Get.put(AudioPlayerService(), permanent: true);
      debugPrint('HomeController: Created new AudioPlayerService instance');
    }

    try {
      _playlistService = Get.find<PlaylistService>();
      debugPrint('HomeController: Found existing PlaylistService instance');
    } catch (e) {
      _playlistService = Get.put(PlaylistService(), permanent: true);
      debugPrint('HomeController: Created new PlaylistService instance');
    }

    try {
      _sleepTimerService = Get.find<SleepTimerService>();
      debugPrint('HomeController: Found existing SleepTimerService instance');
    } catch (e) {
      _sleepTimerService = Get.put(SleepTimerService(), permanent: true);
      debugPrint('HomeController: Created new SleepTimerService instance');
    }
  }

  // Music player controls
  Future<void> playPause() async {
    await audioService.playPause();
  }

  Future<void> nextSong() async {
    await audioService.next();
    if (currentSong != null) {
      await _playlistService.addToRecentlyPlayed(currentSong!);
      await _playlistService.incrementPlayCount(currentSong!);
    }
  }

  Future<void> previousSong() async {
    await audioService.previous();
    if (currentSong != null) {
      await _playlistService.addToRecentlyPlayed(currentSong!);
      await _playlistService.incrementPlayCount(currentSong!);
    }
  }

  Future<void> seekTo(double positionMs) async {
    await audioService.seekTo(Duration(milliseconds: positionMs.toInt()));
  }

  void updateSeekingPosition(double positionMs) {
    _isSeeking.value = true;
    _seekingPosition.value = positionMs.clamp(0.0, totalDuration);
  }

  Future<void> completeSeeking(double positionMs) async {
    final finalPosition = positionMs.clamp(0.0, totalDuration);
    _isSeeking.value = false;
    _seekingPosition.value = finalPosition;

    await seekTo(finalPosition);
    // await audioService.play();
  }

  void toggleShuffle() {
    isShuffleOn.value = !isShuffleOn.value;
    audioService.setShuffleEnabled(isShuffleOn.value);
  }

  void cycleRepeatMode() {
    switch (repeatMode.value) {
      case RepeatMode.off:
        repeatMode.value = RepeatMode.all;
        break;
      case RepeatMode.all:
        repeatMode.value = RepeatMode.one;
        break;
      case RepeatMode.one:
        repeatMode.value = RepeatMode.off;
        break;
    }
    switch (repeatMode.value) {
      case RepeatMode.off:
        audioService.setRepeatMode(RepeatModeAS.off);
        break;
      case RepeatMode.all:
        audioService.setRepeatMode(RepeatModeAS.all);
        break;
      case RepeatMode.one:
        audioService.setRepeatMode(RepeatModeAS.one);
        break;
    }
  }

  Future<void> playSong(List<SongModel> songList, SongModel song) async {
    try {
      debugPrint(
          'HomeController.playSong: Playing ${song.title} by ${song.artist}');

      if (song.data.isNotEmpty && !song.data.startsWith('http')) {
        final file = File(song.data);
        if (!file.existsSync()) {
          debugPrint(
              'HomeController.playSong: File does not exist: ${song.data}');

          AppLoader.customToast(
              message: 'Song file not found. Removed from recently played.');

          final isInRecentlyPlayed =
              _playlistService.recentlyPlayed.any((rp) => rp.id == song.id);

          if (isInRecentlyPlayed) {
            await _playlistService.removeFromRecentlyPlayed(song);
            debugPrint(
                'HomeController.playSong: Removed ${song.title} from recently played');
          }

          return;
        }
      }

      currentPlayList = songList;
      debugPrint('Current playlist: ${currentPlayList.length} songs');
      await audioService.playSong(songList, song);
      await _playlistService.addToRecentlyPlayed(song);
      await _playlistService.incrementPlayCount(song);
      debugPrint('HomeController.playSong: Completed playing ${song.title}');
    } catch (e) {
      debugPrint('HomeController.playSong: ERROR - $e');

      if (e.toString().toLowerCase().contains('file') ||
          e.toString().toLowerCase().contains('not found') ||
          e.toString().toLowerCase().contains('no such file')) {
        final isInRecentlyPlayed =
            _playlistService.recentlyPlayed.any((rp) => rp.id == song.id);

        if (isInRecentlyPlayed) {
          await _playlistService.removeFromRecentlyPlayed(song);
          AppLoader.customToast(
              message: 'Song file not found. Removed from recently played.');
          debugPrint(
              'HomeController.playSong: Removed ${song.title} from recently played due to error');
        }
      }
    }
  }

  void playAllSongs(List<SongModel> songs) {
    if (songs.isNotEmpty) {
      playSong(songs, songs.first);
    }
  }

  void shuffleAllSongs(List<SongModel> songs) {
    if (songs.isNotEmpty) {
      final shuffledSongs = List<SongModel>.from(songs)..shuffle();
      playSong(shuffledSongs, shuffledSongs.first);
    }
  }

  // Navigation
  void changeView(String view) {
    currentView.value = view;
    if (searchQuery.value.isNotEmpty) {
      updateSearchQuery('');
      searchTextController.clear();
    }
  }

  void titleTapAction(String view, String title) {
    changeView(view);
    if (title == 'All Songs') {
      tabController.index = 0;
    } else if (title == 'Playlists') {
      tabController.index = 3;
    } else if (title == 'All Artists') {
      tabController.index = 1;
    } else if (title == 'All Albums') {
      tabController.index = 2;
    }
  }

  void showPlaylistSongs(PlaylistModel playlist) {
    final playlistSongs = getPlaylistSongs(playlist.id);

    Get.toNamed(Routes.PLAYLISTSONGSCREEN, arguments: {
      'playlist': playlist,
      'playlistSongs': playlistSongs,
      'controller': this,
    });
  }

  Future<void> requestPermissions() async {
    await audioService.checkPermissions();
  }

  // Search functionality
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKeyRecentSearches) ?? <String>[];
      recentSearches.assignAll(list);
    } catch (_) {}
  }

  Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final List<String> next = List<String>.from(recentSearches);
    next.removeWhere((e) => e.toLowerCase() == trimmed.toLowerCase());
    next.insert(0, trimmed);
    if (next.length > 10) {
      next.removeRange(10, next.length);
    }
    recentSearches.assignAll(next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKeyRecentSearches, next);
    } catch (_) {}
  }

  Future<void> removeRecentSearch(String query) async {
    final List<String> next = List<String>.from(recentSearches)
      ..removeWhere((e) => e == query);
    recentSearches.assignAll(next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKeyRecentSearches, next);
    } catch (_) {}
  }

  Future<void> clearAllRecentSearches() async {
    recentSearches.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyRecentSearches);
    } catch (_) {}
  }

  List<SongModel> get searchResults {
    if (searchQuery.value.isEmpty) return allSongs;
    return audioService.searchSongs(searchQuery.value);
  }

  Future<PlaylistModel> createPlaylist({
    required String name,
    String? description,
    List<SongModel>? initialSongs,
    String? colorHex,
  }) async {
    return await _playlistService.createPlaylist(
      name: name,
      description: description,
      initialSongs: initialSongs,
      colorHex: colorHex,
    );
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _playlistService.deletePlaylist(playlistId);
  }

  Future<void> addSongToPlaylist(String playlistId, SongModel song) async {
    await _playlistService.addSongToPlaylist(playlistId, song);
    playlistsVersion.value++;
  }

  Future<void> removeSongFromPlaylist(String playlistId, SongModel song) async {
    await _playlistService.removeSongFromPlaylist(playlistId, song);
    playlistsVersion.value++;
  }

  // Update playlist details
  Future<void> updatePlaylistDetails({
    required String playlistId,
    required String name,
    String? description,
    String? colorHex,
  }) async {
    await _playlistService.updatePlaylistDetails(
      playlistId: playlistId,
      name: name,
      description: description,
      colorHex: colorHex,
    );
  }

  Future<void> toggleLikeSong(SongModel song) async {
    await _playlistService.toggleLikeSong(song);
  }

  bool isSongLiked(SongModel song) {
    return _playlistService.isSongLiked(song);
  }

  List<SongModel> getPlaylistSongs(String playlistId) {
    return _playlistService.getPlaylistSongs(playlistId);
  }

  void openFullPlayer(HomeController controller) {
    Get.toNamed(Routes.FULLSCREENPLAYER, arguments: {
      'controller': controller,
    });
  }

  void openLandscapeFullPlayer(HomeController controller) {
    Get.toNamed(Routes.FULLSCREENPLAYERLANDSCAPE, arguments: {
      'controller': controller,
    });
  }

  void openQueue() {
    Get.toNamed(Routes.QUEUE);
  }

  List<String> get allArtists => audioService.getAllArtists();

  List<String> get allAlbums => audioService.getAllAlbums();

  List<SongModel> getSongsByArtist(String artist) {
    return audioService.getSongsByArtist(artist);
  }

  List<SongModel> getSongsByAlbum(String album) {
    return audioService.getSongsByAlbum(album);
  }

  String formatTime(double milliseconds) {
    final duration = Duration(milliseconds: milliseconds.toInt());
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String? getArtworkUrl(int songId) {
    return audioService.getArtworkUrl(songId);
  }

  Future<Uint8List?> getAlbumArtwork(int songId,
      {bool highQuality = false}) async {
    final cacheKey = highQuality ? '${songId}_hq' : songId.toString();

    if (_artworkCache.containsKey(cacheKey)) {
      return _artworkCache[cacheKey];
    }

    final size = highQuality ? 300 : 120;
    final artwork = await audioService.getAlbumArtwork(songId, size: size);
    _artworkCache[cacheKey] = artwork;

    final maxCacheSize = highQuality ? 50 : 100;
    if (_artworkCache.length > maxCacheSize) {
      final oldestKey = _artworkCache.keys.first;
      _artworkCache.remove(oldestKey);
    }

    return artwork;
  }

  void startSleepTimer(int minutes) {
    _sleepTimerService.startTimer(minutes);
  }

  void restartSleepTimer() {
    _sleepTimerService.startTimer(_sleepTimerService.lastSelectedMinutes);
  }

  void stopSleepTimer() {
    _sleepTimerService.stopTimer();
  }

  void addTimeToSleepTimer(int minutes) {
    _sleepTimerService.addTime(minutes);
  }

  void showSleepTimerDialog() {
    Get.dialog(
      SleepTimerDialog(),
      barrierDismissible: true,
    );
  }

  @override
  void onClose() {
    allSongsScrollController.dispose();
    artistsScrollController.dispose();
    albumsScrollController.dispose();
    playlistsScrollController.dispose();
    searchTextController.dispose();
    super.onClose();
  }
}
