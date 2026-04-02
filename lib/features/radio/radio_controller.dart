import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velo/core/models/radio_station.dart';
import 'package:velo/core/services/audio_service.dart';
import 'package:velo/core/services/radio_service.dart';

class RadioController extends GetxController {
  final RadioService _radioService = RadioService();
  final AudioPlayer _radioPlayer = AudioPlayer();

  final RxList<RadioStation> stations = <RadioStation>[].obs;
  final RxList<RadioStation> filteredStations = <RadioStation>[].obs;
  final RxList<RadioStation> featuredStations = <RadioStation>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString error = ''.obs;

  final RxInt currentIndex = 0.obs;
  final RxBool isPlaying = false.obs;
  final RxBool isOverlayVisible = false.obs;
  final RxBool isOverlayExpanded = false.obs;
  final RxString searchQuery = ''.obs;

  final RxString selectedCountry = 'Myanmar'.obs;
  int _currentOffset = 0;
  final int _limit = 40;

  final List<Map<String, String>> availableCountries = [
    {'name': 'Myanmar', 'flag': '🇲🇲'},
    {'name': 'United States', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'name': 'Thailand', 'flag': '🇹🇭'},
    {'name': 'Singapore', 'flag': '🇸🇬'},
    {'name': 'Japan', 'flag': '🇯🇵'},
  ];

  @override
  void onInit() {
    super.onInit();
    _setupAudioPlayer();
    _pauseMainMusic();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCountry = prefs.getString('last_radio_country');
    if (savedCountry != null &&
        availableCountries.any((c) => c['name'] == savedCountry)) {
      selectedCountry.value = savedCountry;
    }
    fetchStations(fromCache: true);
  }

  void _pauseMainMusic() {
    try {
      if (Get.isRegistered<AudioPlayerService>()) {
        final audioService = Get.find<AudioPlayerService>();
        if (audioService.isPlaying.value) {
          audioService.audioPlayer.pause();
          debugPrint('Main music paused for Radio');
        }
      }
    } catch (e) {
      debugPrint('Error pausing main music: $e');
    }
  }

  void _setupAudioPlayer() {
    _radioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
    });
  }

  Future<void> fetchStations({bool fromCache = true}) async {
    debugPrint('RadioController: Fetching stations... (fromCache: $fromCache)');
    _currentOffset = 0;

    if (fromCache) {
      final cached = await _radioService.getCachedStations();
      if (cached.isNotEmpty) {
        stations.assignAll(cached);
        _updateFeaturedAndFiltered();
        isLoading.value = false;
        return;
      }
    }

    isLoading.value = true;
    error.value = '';
    try {
      List<RadioStation> fetched;
      if (selectedCountry.value == 'Myanmar') {
        fetched =
            await _radioService.getMyanmarStations(limit: _limit, offset: 0);
      } else {
        fetched = await _radioService.getStationsByCountry(
            selectedCountry.value,
            limit: _limit,
            offset: 0);
      }

      stations.assignAll(fetched);
      _updateFeaturedAndFiltered();

      if (fetched.isNotEmpty) {
        await _radioService.cacheStations(fetched);
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMoreStations() async {
    if (isLoadingMore.value) return;
    isLoadingMore.value = true;
    _currentOffset += _limit;

    try {
      List<RadioStation> fetched;
      if (selectedCountry.value == 'Myanmar') {
        fetched = await _radioService.getMyanmarStations(
            limit: _limit, offset: _currentOffset);
      } else {
        fetched = await _radioService.getStationsByCountry(
            selectedCountry.value,
            limit: _limit,
            offset: _currentOffset);
      }

      if (fetched.isNotEmpty) {
        stations.addAll(fetched);
        _applySearchFilter();
      }
    } catch (e) {
      debugPrint('Error fetching more stations: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _updateFeaturedAndFiltered() {
    // Sort by votes for featured section (top 10)
    final sortedByVotes = List<RadioStation>.from(stations)
      ..sort((a, b) => (b.votes ?? 0).compareTo(a.votes ?? 0));
    featuredStations.assignAll(sortedByVotes.take(10).toList());

    _applySearchFilter();
  }

  void onStationSelected(int index, {bool fromFeatured = false}) async {
    final list = fromFeatured ? featuredStations : filteredStations;
    if (index >= 0 && index < list.length) {
      final station = list[index];
      final mainIndex = stations.indexOf(station);
      if (mainIndex != -1) {
        currentIndex.value = mainIndex;
      }

      isOverlayVisible.value = true;
      isOverlayExpanded.value = true;

      try {
        await _radioPlayer.stop();
        await _setRadioUrl(station.urlResolved ?? station.url);
        _pauseMainMusic();
        _radioPlayer.play();
      } catch (e) {
        debugPrint('Radio playback error: $e');
      }
    }
  }

  Future<void> _setRadioUrl(String url) async {
    await _radioPlayer.setUrl(
      url,
      headers: {'User-Agent': 'VeloMusicPlayer/1.0 (Mobile; Android; iOS)'},
    );
  }

  Future<void> togglePlay() async {
    if (stations.isEmpty) return;

    if (isPlaying.value) {
      await _radioPlayer.pause();
    } else {
      _pauseMainMusic();
      await _radioPlayer.play();
    }
  }

  Future<void> stop() async {
    await _radioPlayer.pause();
    isPlaying.value = false;
    isOverlayVisible.value = false;
    isOverlayExpanded.value = false;
  }

  Future<void> nextStation() async {
    if (currentIndex.value < stations.length - 1) {
      final nextIdx = currentIndex.value + 1;
      currentIndex.value = nextIdx;
      final station = stations[nextIdx];
      await _radioPlayer.stop();
      await _setRadioUrl(station.urlResolved ?? station.url);
      _radioPlayer.play();
    }
  }

  Future<void> prevStation() async {
    if (currentIndex.value > 0) {
      final prevIdx = currentIndex.value - 1;
      currentIndex.value = prevIdx;
      final station = stations[prevIdx];
      await _radioPlayer.stop();
      await _setRadioUrl(station.urlResolved ?? station.url);
      _radioPlayer.play();
    }
  }

  @override
  void onClose() {
    _radioPlayer.dispose();
    super.onClose();
  }

  void changeCountry(String countryName) async {
    if (selectedCountry.value == countryName) return;
    selectedCountry.value = countryName;

    await stop();
    stations.clear();
    fetchStations(fromCache: false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_radio_country', countryName);
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
    _applySearchFilter();
  }

  void _applySearchFilter() {
    if (searchQuery.isEmpty) {
      filteredStations.assignAll(stations);
    } else {
      final q = searchQuery.toLowerCase();
      filteredStations.assignAll(stations.where((s) =>
          s.name.toLowerCase().contains(q) ||
          (s.tags?.toLowerCase().contains(q) ?? false)));
    }
  }

  void toggleOverlay() {
    isOverlayExpanded.value = !isOverlayExpanded.value;
  }
}
