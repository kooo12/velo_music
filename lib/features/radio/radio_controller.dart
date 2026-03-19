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
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  final RxInt currentIndex = 0.obs;
  final RxBool isPlaying = false.obs;

  final RxString selectedCountry = 'Myanmar'.obs;

  final List<Map<String, String>> availableCountries = [
    {'name': 'Myanmar', 'flag': '🇲🇲'},
    {'name': 'United States', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'name': 'Thailand', 'flag': '🇹🇭'},
    {'name': 'Singapore', 'flag': '🇸🇬'},
    {'name': 'Japan', 'flag': '🇯🇵'},
    // {'name': 'South Korea', 'flag': '🇰🇷'},
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

    if (fromCache) {
      final cached = await _radioService.getCachedStations();
      if (cached.isNotEmpty) {
        debugPrint(
            'RadioController: Loaded ${cached.length} stations from cache');
        stations.assignAll(cached);
        isLoading.value = false;
        if (currentIndex.value == 0 && !isPlaying.value) {
          await _setRadioUrl(stations[0].urlResolved ?? stations[0].url);
        }
      } else {
        debugPrint('RadioController: Cache is empty, showing loader');
        isLoading.value = true;
      }
    } else {
      isLoading.value = true;
    }

    error.value = '';
    try {
      debugPrint('RadioController: Starting background API fetch...');
      List<RadioStation> fetchedStations = [];
      if (selectedCountry.value == 'Myanmar') {
        fetchedStations = await _radioService.getMyanmarStations();
      } else {
        fetchedStations =
            await _radioService.getStationsByCountry(selectedCountry.value);
      }
      if (fetchedStations.isNotEmpty) {
        debugPrint(
            'RadioController: API fetch successful, found ${fetchedStations.length} stations');

        stations.assignAll(fetchedStations);
        // print(stations.map((s) => s.toJson()));
        stations.refresh();

        await _radioService.cacheStations(fetchedStations);
        debugPrint('RadioController: Cache updated with fresh API data');

        if (currentIndex.value == 0 && !isPlaying.value) {
          await _setRadioUrl(stations[0].urlResolved ?? stations[0].url);
        }
      } else {
        debugPrint('RadioController: API returned empty list');
      }
    } catch (e) {
      if (stations.isEmpty) {
        error.value = e.toString();
      }
      debugPrint('RadioController: Background API sync failed: $e');
    } finally {
      isLoading.value = false;
      debugPrint('RadioController: Fetch process finished');
    }
  }

  void onStationSwiped(int index) async {
    if (index >= 0 && index < stations.length) {
      currentIndex.value = index;
      final station = stations[index];
      final primaryUrl = station.url;
      final fallbackUrl = station.urlResolved ?? station.url;

      try {
        await _radioPlayer.stop();
        await _setRadioUrl(primaryUrl);
        if (isPlaying.value) {
          _radioPlayer.play();
        }
      } catch (e) {
        // if (fallbackUrl != null) {
        debugPrint('Primary URL failed, trying fallback: $fallbackUrl');
        try {
          await _setRadioUrl(fallbackUrl);
          if (isPlaying.value) {
            _radioPlayer.play();
          }
          return;
        } catch (e2) {
          debugPrint('Fallback URL also failed: $e2');
          debugPrint('Radio playback error: $e');
          // AppLoader.customToast(
          //     message:
          //         'This station is currently unreachable. Please try another one.');

          // Get.snackbar(
          //   'Stream Unavailable',
          //   'This station is currently unreachable. Please try another one.',
          //   snackPosition: SnackPosition.bottom,
          //   backgroundColor: Colors.redAccent.withOpacity(0.8),
          //   colorText: Colors.white,
          // );
        }
        // }
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
  }

  Future<void> nextStation() async {
    if (currentIndex.value < stations.length - 1) {
      onStationSwiped(currentIndex.value + 1);
    }
  }

  Future<void> prevStation() async {
    if (currentIndex.value > 0) {
      onStationSwiped(currentIndex.value - 1);
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_radio_country', countryName);

    stations.clear();
    currentIndex.value = 0;
    fetchStations(fromCache: false);
  }
}
