import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:velo/core/models/song_model.dart' as models;
import 'package:velo/features/storage_manager/service/storage_service.dart';
import 'package:permission_handler/permission_handler.dart';

enum RepeatModeAS { off, all, one }

class AudioPlayerService extends GetxService {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final RxList<models.SongModel> _allSongs = <models.SongModel>[].obs;
  final Rx<models.SongModel?> _currentSong = Rx<models.SongModel?>(null);
  final RxBool _isPlaying = false.obs;
  final RxBool _isLoading = false.obs;
  final RxInt _currentIndex = 0.obs;
  final RxDouble _currentPosition = 0.0.obs;
  final RxDouble _totalDuration = 0.0.obs;
  final RxBool _hasPermission = false.obs;
  final RxBool _isBuffering = false.obs;

  final RxList<models.SongModel> _currentPlaylist = <models.SongModel>[].obs;
  final RxString _playlistType = 'all'.obs;

  final RxBool _shuffleEnabled = false.obs;
  final Rx<RepeatModeAS> _repeatMode = RepeatModeAS.off.obs;
  final Set<int> _playedIndices = <int>{};

  bool _isRequestingPermissions = false;

  final RxBool _hasAttemptedLoad = false.obs;

  final Map<int, Future<Uint8List?>> _pendingArtworkQueries = {};
  bool _isPluginInitialized = false;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<SequenceState?>? _sequenceStateSubscription;
  StreamSubscription<ProcessingState>? _processingStateSubscription;

  // Getters -------
  RxList<models.SongModel> get allSongs => _allSongs;
  RxBool get isPlaying => _isPlaying;
  RxBool get isLoading => _isLoading;
  RxBool get isBuffering => _isBuffering;
  RxBool get hasAttemptedLoad => _hasAttemptedLoad;
  models.SongModel? get currentSong => _currentSong.value;
  RxInt get currentIndex => _currentIndex;
  RxDouble get currentPosition => _currentPosition;
  RxDouble get totalDuration => _totalDuration;
  RxBool get hasPermission => _hasPermission;
  AudioPlayer get audioPlayer => _audioPlayer;

  RxList<models.SongModel> get currentPlaylist => _currentPlaylist;
  RxString get playlistType => _playlistType;
  RxBool get shuffleEnabled => _shuffleEnabled;
  Rx<RepeatModeAS> get repeatMode => _repeatMode;

  set currentSong(models.SongModel? song) => _currentSong.value = song;

  // models.SongModel? get currentSong {
  //   if (_allSongs.isEmpty || _currentIndex.value >= _allSongs.length) {
  //     return null;
  //   }
  //   return _allSongs[_currentIndex.value];
  // }

  @override
  void onInit() {
    super.onInit();
    _setupAudioPlayer();
    Future.delayed(const Duration(milliseconds: 500), () {
      _initializePlugin();
    });
  }

  Future<void> _initializePlugin() async {
    if (kIsWeb) {
      _isPluginInitialized = true;
      return;
    }
    try {
      await _audioQuery.permissionsStatus();
      _isPluginInitialized = true;
      debugPrint('[AudioService] on_audio_query plugin initialized');
    } catch (e) {
      debugPrint('[AudioService] Plugin initialization check failed: $e');
      _isPluginInitialized = true;
    }
  }

  @override
  void onClose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _sequenceStateSubscription?.cancel();
    _processingStateSubscription?.cancel();

    _audioPlayer.dispose();
    super.onClose();
  }

  void _setupAudioPlayer() {
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      _isPlaying.value = state.playing;
    });
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      _currentPosition.value = position.inMilliseconds.toDouble();
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        var correctedDuration = duration.inMilliseconds.toDouble();

        _totalDuration.value = correctedDuration;

        final currentSong = _currentSong.value;
        if (currentSong != null) {
          if (correctedDuration > 0) {
            final updatedDuration = correctedDuration.toInt();
            debugPrint(
                'Updating song duration from ${currentSong.duration}ms to ${updatedDuration}ms for: ${currentSong.title}');

            final updatedSong = models.SongModel(
              id: currentSong.id,
              title: currentSong.title,
              artist: currentSong.artist,
              album: currentSong.album,
              duration: updatedDuration,
              data: currentSong.data,
              displayName: currentSong.displayName,
              genre: currentSong.genre,
              track: currentSong.track,
              year: currentSong.year,
              size: currentSong.size,
              isMusic: currentSong.isMusic,
              albumArtwork: currentSong.albumArtwork,
            );

            final playlistIndex =
                _currentPlaylist.indexWhere((s) => s.id == currentSong.id);
            if (playlistIndex != -1) {
              _currentPlaylist[playlistIndex] = updatedSong;
            }

            final allSongsIndex =
                _allSongs.indexWhere((s) => s.id == currentSong.id);
            if (allSongsIndex != -1) {
              _allSongs[allSongsIndex] = updatedSong;
            }

            _currentSong.value = updatedSong;

            debugPrint('Song duration updated successfully');
          }
        }
      }
    });

    _sequenceStateSubscription =
        _audioPlayer.sequenceStateStream.listen((sequenceState) {
      if (sequenceState != null) {
        debugPrint(
            'AudioService._setupAudioPlayer: Sequence state changed to ${sequenceState.currentIndex}');
        // _currentIndex.value = sequenceState.currentIndex;
      }
    });

    _processingStateSubscription =
        _audioPlayer.processingStateStream.listen((state) async {
      _isBuffering.value = state == ProcessingState.buffering ||
          state == ProcessingState.loading;
      if (state == ProcessingState.completed) {
        await _handleTrackCompleted();
      }
    });
  }

  Future<bool> checkPermissionStatusOnly() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      bool hasPermission = false;
      try {
        hasPermission = await _audioQuery.permissionsStatus();
      } catch (e) {
        debugPrint('Error checking permission status: $e');
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          hasPermission = await _audioQuery.permissionsStatus();
        } catch (e2) {
          debugPrint('Second permission check failed: $e2');
          _hasPermission.value = false;
          return false;
        }
      }

      _hasPermission.value = hasPermission;
      return hasPermission;
    } catch (e) {
      debugPrint('Error in checkPermissionStatusOnly: $e');
      _hasPermission.value = false;
      return false;
    }
  }

  Future<void> checkPermissions() async {
    if (_isRequestingPermissions) {
      debugPrint('Permission request already in progress, skipping...');
      return;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      bool hasPermission = false;
      try {
        hasPermission = await _audioQuery.permissionsStatus();
      } catch (e) {
        debugPrint('Error checking permission status: $e');
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          hasPermission = await _audioQuery.permissionsStatus();
        } catch (e2) {
          debugPrint('Second permission check failed: $e2');
          _hasPermission.value = false;
          return;
        }
      }

      if (!hasPermission) {
        if (_isRequestingPermissions) {
          return;
        }

        _isRequestingPermissions = true;
        try {
          await Future.delayed(const Duration(milliseconds: 500));

          if (!_isPluginInitialized) {
            await _initializePlugin();
            await Future.delayed(const Duration(milliseconds: 300));
          }

          try {
            hasPermission = await _audioQuery.permissionsRequest();

            if (Platform.isAndroid) {
              final status = await Permission.notification.status;
              if (!status.isGranted) {
                await Permission.notification.request();
              }
            }
          } on PlatformException catch (e) {
            if (e.code == 'UninitializedPluginProviderException' ||
                e.message?.contains('UninitializedPluginProvider') == true) {
              debugPrint(
                  '[AudioService] Plugin not initialized during permission request, initializing...');
              await _initializePlugin();
              await Future.delayed(const Duration(milliseconds: 500));
              try {
                hasPermission = await _audioQuery.permissionsRequest();
              } catch (e2) {
                debugPrint(
                    '[AudioService] Permission request failed after initialization: $e2');
                hasPermission = false;
              }
            } else {
              debugPrint('[AudioService] Permission request failed: $e');
              hasPermission = false;
            }
          }

          await Future.delayed(const Duration(milliseconds: 1000));
        } catch (e) {
          debugPrint('Error requesting permissions: $e');
          _hasPermission.value = false;
          return;
        } finally {
          _isRequestingPermissions = false;
        }
      }

      _hasPermission.value = hasPermission;
      if (hasPermission) {
        if (kIsWeb) {
          loadSongs();
        } else if (Platform.isAndroid) {
          loadSongs();
        } else if (Platform.isIOS) {
          loadSongsForIOS();
        }
      }
    } catch (e) {
      debugPrint('Error in checkPermissions: $e');
      _hasPermission.value = false;
      _isRequestingPermissions = false;
    }
  }

  // Future<void> requestPermissions() async {
  //   if (_isRequestingPermissions) {
  //     debugPrint('Permission request already in progress, skipping...');
  //     return;
  //   }

  //   try {
  //     await Future.delayed(const Duration(milliseconds: 500));

  //     bool hasPermission = false;
  //     try {
  //       hasPermission = await _audioQuery.permissionsStatus();
  //     } catch (e) {
  //       debugPrint('Error checking permission status: $e');
  //       await Future.delayed(const Duration(milliseconds: 500));
  //       try {
  //         hasPermission = await _audioQuery.permissionsStatus();
  //       } catch (e2) {
  //         debugPrint('Second permission status check failed: $e2');
  //         _hasPermission.value = false;
  //         return;
  //       }
  //     }

  //     if (!hasPermission) {
  //       if (_isRequestingPermissions) {
  //         return;
  //       }

  //       _isRequestingPermissions = true;
  //       try {
  //         await Future.delayed(const Duration(milliseconds: 800));

  //         if (!_isPluginInitialized) {
  //           await _initializePlugin();
  //           await Future.delayed(const Duration(milliseconds: 300));
  //         }

  //         try {
  //           hasPermission = await _audioQuery.permissionsRequest();
  //         } on PlatformException catch (e) {
  //           if (e.code == 'UninitializedPluginProviderException' ||
  //               e.message?.contains('UninitializedPluginProvider') == true) {
  //             debugPrint(
  //                 '[AudioService] Plugin not initialized during permission request, initializing...');
  //             await _initializePlugin();
  //             await Future.delayed(const Duration(milliseconds: 500));
  //             try {
  //               hasPermission = await _audioQuery.permissionsRequest();
  //             } catch (e2) {
  //               debugPrint(
  //                   '[AudioService] Permission request failed after initialization: $e2');
  //               hasPermission = false;
  //             }
  //           } else {
  //             debugPrint('[AudioService] Permission request failed: $e');
  //             hasPermission = false;
  //           }
  //         }

  //         await Future.delayed(const Duration(milliseconds: 1500));
  //       } catch (e) {
  //         debugPrint('Error requesting permissions: $e');
  //         _hasPermission.value = false;
  //         return;
  //       } finally {
  //         _isRequestingPermissions = false;
  //       }
  //     }

  //     _hasPermission.value = hasPermission;

  //     if (_hasPermission.value) {
  //       if (Platform.isAndroid) {
  //         await loadSongs();
  //       } else if (Platform.isIOS) {
  //         loadSongsForIOS();
  //       }
  //     } else {
  //       debugPrint('Audio permissions denied by user');
  //     }
  //   } catch (e) {
  //     debugPrint('Error in requestPermissions: $e');
  //     _hasPermission.value = false;
  //     _isRequestingPermissions = false;
  //   }
  // }

  Future<void> loadSongs({bool skipPermissionCheck = false}) async {
    if (!skipPermissionCheck && !_hasPermission.value && !kIsWeb) {
      await checkPermissions();
      return;
    }

    if (skipPermissionCheck && !_hasPermission.value && !kIsWeb) {
      debugPrint('Cannot load songs: permission not granted');
      return;
    }

    try {
      _isLoading.value = true;
      _hasAttemptedLoad.value = true;
      debugPrint('Loading music files...');

      if (kIsWeb) {
        var demoSongs = <models.SongModel>[
          models.SongModel(
            id: 1,
            title: 'အ‌ငွေ့အသက်များ',
            artist: 'Ah Boy, ချမ်းမြေ့မောင်ချို',
            album: 'Demo Album',
            duration: 180000,
            data: 'assets/demo_songs/အ‌ငွေ့အသက်များ.mp3',
            displayName: 'အ‌ငွေ့အသက်များ - Ah Boy, ချမ်းမြေ့မောင်ချို.mp3',
            albumArtwork:
                'https://images.unsplash.com/photo-1514525253361-b8748b43a24a?w=800&q=80',
            genre: null,
            track: null,
            year: null,
            size: 0,
            isMusic: true,
          ),
          models.SongModel(
            id: 2,
            title: 'Myi Tho Pin So Say Kar Mu',
            artist: 'Htet Thiri',
            album: 'Demo Album',
            duration: 180000,
            data: 'assets/demo_songs/Myi Tho Pin So Say Kar Mu.mp3',
            displayName: 'Myi Tho Pin So Say Kar Mu - Htet Thiri.mp3',
            albumArtwork:
                'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800&q=80',
            genre: null,
            track: null,
            year: null,
            size: 0,
            isMusic: true,
          ),
          models.SongModel(
            id: 3,
            title: 'Loop (သံသရာ)',
            artist: 'MAY',
            album: 'Demo Album',
            duration: 180000,
            data: 'assets/demo_songs/MAY - Loop  သံသရာ.mp3',
            displayName: 'MAY - Loop (သံသရာ).mp3',
            albumArtwork:
                'https://images.unsplash.com/photo-1493225255756-d9584f8606e9?w=800&q=80',
            genre: null,
            track: null,
            year: null,
            size: 0,
            isMusic: true,
          ),
          models.SongModel(
            id: 4,
            title: 'အသဲကွဲသီချင်းသစ်',
            artist: 'May',
            album: 'Demo Album',
            duration: 180000,
            data: 'assets/demo_songs/May - အသဲကွဲသီချင်းသစ်.mp3',
            displayName: 'May - အသဲကွဲသီချင်းသစ်.mp3',
            albumArtwork:
                'https://images.unsplash.com/photo-1459749411177-042180ce673c?w=800&q=80',
            genre: null,
            track: null,
            year: null,
            size: 0,
            isMusic: true,
          ),
        ];

        _allSongs.value = demoSongs;
        _currentPlaylist.value = List.from(demoSongs);
        _playlistType.value = 'all';
        debugPrint('Loaded ${demoSongs.length} demo music files');
      } else {
        final allSongs = await _audioQuery.querySongs(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          ignoreCase: true,
        );

        debugPrint('Found ${allSongs.length} total audio files');

        final scanFolders = await Get.find<StorageService>().loadScanFolders();
        bool filterByFolders = scanFolders.isNotEmpty;

        final musicSongs = allSongs
            .where((song) => _isValidMusicFile(song))
            .where((song) {
              if (!filterByFolders) {
                return true;
              }
              return scanFolders.any((f) => song.data.startsWith(f));
            })
            .map((song) => models.SongModel(
                  id: song.id,
                  title: song.title,
                  artist: song.artist ?? 'Unknown Artist',
                  album: song.album ?? 'Unknown Album',
                  duration: song.duration ?? 0,
                  data: song.data,
                  displayName: song.displayName,
                  genre: song.genre,
                  track: song.track,
                  year: null,
                  size: song.size,
                  isMusic: song.isMusic ?? true,
                ))
            .toList();

        _allSongs.value = musicSongs;
        _currentPlaylist.value = List.from(musicSongs);
        _playlistType.value = 'all';
        debugPrint('Loaded ${musicSongs.length} music files');
      }
    } catch (e) {
      debugPrint('Error loading songs: $e');
      _allSongs.clear();
      _hasAttemptedLoad.value = true;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadSongsForIOS({bool skipPermissionCheck = false}) async {
    if (!skipPermissionCheck && !_hasPermission.value) {
      await checkPermissions();
      return;
    }

    if (skipPermissionCheck && !_hasPermission.value) {
      debugPrint('Cannot load songs: permission not granted');
      return;
    }

    try {
      _isLoading.value = true;
      _hasAttemptedLoad.value = true;
      debugPrint('Loading music files...');

      final fileSongs = await scanMusicFolderFromDocumentsIOS();

      _allSongs.value = fileSongs;
      _currentPlaylist.value = List.from(fileSongs);
      _playlistType.value = 'all';
      debugPrint(
          'Loaded ${fileSongs.length} music files in IOS document directory');
    } catch (e) {
      debugPrint('Error loading songs: $e');
      _allSongs.clear();
      _hasAttemptedLoad.value = true;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> _extractMetadataFromFile(String filePath) async {
    final fileName = p.basenameWithoutExtension(filePath);
    final metadata = <String, dynamic>{
      'title': fileName,
      'artist': 'Unknown Artist',
      'album': 'Downloaded',
      'duration': 0,
      'albumArtwork': null,
    };

    try {
      final tempPlayer = AudioPlayer();
      try {
        await tempPlayer.setFilePath(filePath);

        await Future.delayed(const Duration(milliseconds: 100));

        final duration = tempPlayer.duration;
        if (duration != null && duration.inMilliseconds > 0) {
          metadata['duration'] = duration.inMilliseconds;
        }

        _parseMetadataFromFilename(fileName, metadata);
      } finally {
        await tempPlayer.dispose();
      }
    } catch (e) {
      debugPrint('[iOS Scan] Error extracting metadata from $filePath: $e');
      _parseMetadataFromFilename(fileName, metadata);
    }

    return metadata;
  }

  void _parseMetadataFromFilename(
      String fileName, Map<String, dynamic> metadata) {
    final dashPattern = RegExp(r'^(.+?)\s*-\s*(.+?)(?:\s*-\s*(.+))?$');
    final dashMatch = dashPattern.firstMatch(fileName);
    if (dashMatch != null) {
      metadata['artist'] = dashMatch.group(1)?.trim() ?? 'Unknown Artist';
      metadata['title'] = dashMatch.group(2)?.trim() ?? fileName;
      if (dashMatch.group(3) != null) {
        metadata['album'] = dashMatch.group(3)?.trim() ?? 'Downloaded';
      }
      return;
    }

    final bracketPattern = RegExp(r'^(.+?)\s*[\[\(](.+?)[\]\)]');
    final bracketMatch = bracketPattern.firstMatch(fileName);
    if (bracketMatch != null) {
      metadata['title'] = bracketMatch.group(1)?.trim() ?? fileName;
      metadata['artist'] = bracketMatch.group(2)?.trim() ?? 'Unknown Artist';
      return;
    }

    final byPattern = RegExp(r'^(.+?)\s+[Bb]y\s+(.+)$');
    final byMatch = byPattern.firstMatch(fileName);
    if (byMatch != null) {
      metadata['title'] = byMatch.group(1)?.trim() ?? fileName;
      metadata['artist'] = byMatch.group(2)?.trim() ?? 'Unknown Artist';
      return;
    }

    metadata['title'] = fileName;
  }

  Future<List<models.SongModel>> scanMusicFolderFromDocumentsIOS() async {
    final List<models.SongModel> songs = [];

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory(p.join(docsDir.path, 'Music'));

      if (!await musicDir.exists()) {
        debugPrint('[iOS Scan] Music folder does not exist');
        return songs;
      }

      final files = musicDir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((file) {
        final ext = p.extension(file.path).toLowerCase();
        return ext == '.m4a' || ext == '.mp3' || ext == '.aac';
      }).toList();

      debugPrint(
          '[iOS Scan] Found ${files.length} audio files, extracting metadata...');

      for (final file in files) {
        try {
          final stat = await file.stat();

          final metadata = await _extractMetadataFromFile(file.path);

          songs.add(
            models.SongModel(
              id: file.path.hashCode,
              title: metadata['title'] as String? ??
                  p.basenameWithoutExtension(file.path),
              artist: metadata['artist'] as String? ?? 'Unknown Artist',
              album: metadata['album'] as String? ?? 'Downloaded',
              duration: metadata['duration'] as int? ?? 0,
              albumArtwork: metadata['albumArtwork'] as String?,
              data: file.path,
              displayName: p.basename(file.path),
              genre: null,
              track: null,
              year: null,
              size: stat.size,
              isMusic: true,
            ),
          );
        } catch (e) {
          debugPrint('[iOS Scan] Error processing file ${file.path}: $e');
          final stat = await file.stat();
          songs.add(
            models.SongModel(
              id: file.path.hashCode,
              title: p.basenameWithoutExtension(file.path),
              artist: 'Unknown Artist',
              album: 'Downloaded',
              duration: 0,
              data: file.path,
              displayName: p.basename(file.path),
              genre: null,
              track: null,
              year: null,
              size: stat.size,
              isMusic: true,
            ),
          );
        }
      }

      debugPrint(
          '[iOS Scan] Successfully scanned ${songs.length} songs with metadata');
      return songs;
    } catch (e) {
      debugPrint('[iOS Scan] Error: $e');
      return songs;
    }
  }

  bool _isValidMusicFile(SongModel song) {
    final duration = song.duration ?? 0;
    final path = song.data.toLowerCase();
    final title = song.title.toLowerCase();
    final originalPath = song.data;

    if (!_isMusicFile(path)) {
      debugPrint(
          '=>[AudioService] Rejected (invalid extension): ${song.title} (path: $originalPath)');
      return false;
    }

    if (_isNotificationSound(path, title, duration)) {
      debugPrint(
          '=>[AudioService] Rejected (notification): ${song.title} (duration: ${duration}ms)');
      return false;
    }

    if (duration > 0 && duration < 30000) {
      debugPrint(
          '=>[AudioService] Rejected (short duration: ${duration}ms): ${song.title}');
      return false;
    }

    debugPrint(
        '=>[AudioService] Allowed: ${song.title} (duration: ${duration}ms)');
    return true;
  }

  bool _isNotificationSound(String path, String title, int duration) {
    final notificationPaths = [
      '/system/media/audio/notifications',
      '/system/media/audio/alarms',
      '/system/media/audio/ringtones',
      '/system/media/audio/ui',
    ];

    final notificationKeywords = [
      'notification',
      'alarm',
      'ringtone',
      'beep',
      'chime',
      'ding',
      'ping',
      'tone',
      'alert',
      'bell',
      'buzz',
      'click',
      'pop',
      'system',
      'ui_',
      'camera_',
      'lock',
      'unlock',
      'shutter'
    ];

    if (duration > 0 && duration < 10000) return true;

    for (final notifPath in notificationPaths) {
      if (path.contains(notifPath)) return true;
    }

    for (final keyword in notificationKeywords) {
      if (title.contains(keyword)) return true;
    }

    return false;
  }

  bool _isMusicFile(String path) {
    final musicExtensions = [
      '.mp3',
      '.m4a',
      '.aac',
      '.wav',
      '.flac',
      '.ogg',
      '.wma',
      '.mp4',
      '.3gp',
      '.amr',
      '.opus'
    ];

    for (final ext in musicExtensions) {
      if (path.endsWith(ext)) return true;
    }

    return false;
  }

  Future<void> playSong(List<models.SongModel> songList, models.SongModel song,
      {String playlistType = 'all'}) async {
    try {
      debugPrint(
          'AudioService.playSong: Looking for song ${song.title} (id: ${song.id}) in ${songList.length} songs, duration: ${song.duration}ms');

      bool playlistChanged = _currentPlaylist.value.length != songList.length;
      if (!playlistChanged) {
        for (int i = 0;
            i < songList.length && i < _currentPlaylist.value.length;
            i++) {
          if (_currentPlaylist.value[i].id != songList[i].id) {
            playlistChanged = true;
            break;
          }
        }
      }

      if (playlistChanged) {
        _currentPlaylist.value = List.from(songList);
        debugPrint(
            'AudioService.playSong: Updated current playlist to ${songList.length} songs');
      } else {
        debugPrint(
            'AudioService.playSong: Playlist unchanged, skipping update to prevent refresh');
      }

      _playlistType.value = playlistType;

      var playlistIndex = songList.indexWhere((s) => s.id == song.id);
      debugPrint(
          'AudioService.playSong: Found song at playlist index $playlistIndex');

      if (playlistIndex == -1) {
        debugPrint(
            'AudioService.playSong: Song not found in provided playlist, searching in allSongs...');
        final allSongsIndex = _allSongs.indexWhere((s) => s.id == song.id);
        if (allSongsIndex != -1) {
          debugPrint(
              'AudioService.playSong: Found song in allSongs at index $allSongsIndex, using allSongs as playlist');
          await playAtIndex(_allSongs, allSongsIndex);
          return;
        } else {
          debugPrint(
              'AudioService.playSong: Song not found in allSongs either!');
        }
      }

      if (playlistIndex != -1) {
        await playAtIndex(songList, playlistIndex);
      } else {
        debugPrint(
            'AudioService.playSong: Song not found in current playlist!');
      }
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
  }

  Future<void> playAtIndex(List<models.SongModel> songList, int index) async {
    try {
      if (index < 0 || index >= songList.length) {
        debugPrint(
            'AudioService.playAtIndex: Invalid index $index (songs length: ${songList.length})');
        return;
      }

      debugPrint(
          'AudioService.playAtIndex: Setting currentIndex from ${_currentIndex.value} to $index');

      _currentIndex.value = index;
      _currentSong.value = songList[index];
      _playedIndices.add(index);

      debugPrint(
          'AudioService.playAtIndex: currentIndex is now ${_currentIndex.value}');
      debugPrint(
          'AudioService.playAtIndex: currentSong is now ${_currentSong.value?.title}');

      if (_currentPlaylist.value != songList) {
        _currentPlaylist.value = List.from(songList);
        debugPrint(
            'AudioService.playAtIndex: Updated current playlist to ${songList.length} songs');
      }

      final song = songList[index];
      debugPrint(
          'AudioService.playAtIndex: Playing song: ${song.title} by ${song.artist} ${song.duration} (playlist index: $index)');

      if (song.data.startsWith('http')) {
        await _audioPlayer.setUrl(song.data);
      } else if (song.data.startsWith('assets/')) {
        await _audioPlayer.setAsset(song.data);
      } else {
        await _audioPlayer.setFilePath(song.data);
      }

      await Future.delayed(const Duration(milliseconds: 50));

      _audioPlayer.play();

      debugPrint(
          'AudioService.playAtIndex: Successfully started playing ${song.title}');
    } catch (e) {
      debugPrint('Error playing song at index $index: $e');
    }
  }

  Future<void> _handleTrackCompleted() async {
    try {
      if (_repeatMode.value == RepeatModeAS.one) {
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.play();
        return;
      }

      final playlist = _currentPlaylist;
      if (playlist.isEmpty) {
        return;
      }

      if (_shuffleEnabled.value) {
        final int length = playlist.length;
        if (_repeatMode.value == RepeatModeAS.all) {
          final next = _pickRandomIndex(length, exclude: _currentIndex.value);
          await playAtIndex(playlist, next);
          return;
        } else {
          if (_playedIndices.length >= length) {
            await stop();
            return;
          }
          final next = _pickRandomUnplayedIndex(length);
          if (next == null) {
            await stop();
            return;
          }
          await playAtIndex(playlist, next);
          return;
        }
      }

      final isLast = _currentIndex.value >= playlist.length - 1;
      if (!isLast) {
        await next();
      } else {
        if (_repeatMode.value == RepeatModeAS.all) {
          await playAtIndex(playlist, 0);
        } else {
          await stop();
        }
      }
    } catch (e) {
      debugPrint('Error handling completion: $e');
    }
  }

  int _pickRandomIndex(int length, {int? exclude}) {
    final now = DateTime.now();
    final rand = (now.microsecondsSinceEpoch ^ now.millisecondsSinceEpoch);
    int seeded = rand % length;
    if (length <= 1) return 0;
    int idx = seeded;
    if (exclude != null && length > 1 && idx == exclude) {
      idx = (idx + 1) % length;
    }
    return idx;
  }

  int? _pickRandomUnplayedIndex(int length) {
    if (_playedIndices.length >= length) return null;
    int idx = DateTime.now().microsecondsSinceEpoch % length;
    for (int attempts = 0; attempts < length; attempts++) {
      final candidate = (idx + attempts) % length;
      if (!_playedIndices.contains(candidate)) return candidate;
    }
    for (int i = 0; i < length; i++) {
      if (!_playedIndices.contains(i)) return i;
    }
    return null;
  }

  void setShuffleEnabled(bool enabled) {
    _shuffleEnabled.value = enabled;
    _playedIndices.clear();
    if (enabled && _currentPlaylist.isNotEmpty) {
      _playedIndices.add(_currentIndex.value);
    }
  }

  void setRepeatMode(RepeatModeAS mode) {
    _repeatMode.value = mode;
  }

  Future<void> play() async {
    try {
      if (currentSong != null) {
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error playing: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('Error pausing: $e');
    }
  }

  Future<void> playPause() async {
    if (_isPlaying.value) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> next() async {
    try {
      debugPrint("=== NEXT SONG DEBUG ===");
      debugPrint("_currentIndex.value: ${_currentIndex.value}");
      debugPrint("_currentPlaylist.length: ${_currentPlaylist.length}");
      debugPrint("_currentSong: ${_currentSong.value?.title}");

      if (_currentPlaylist.isEmpty) {
        debugPrint("Current playlist is empty, cannot play next");
        return;
      }

      if (_shuffleEnabled.value) {
        final int length = _currentPlaylist.length;
        if (_repeatMode.value == RepeatModeAS.off &&
            _playedIndices.length >= length) {
          debugPrint("Shuffle OFF repeat: all played, stopping");
          await stop();
          return;
        }
        final nextIndex = (_repeatMode.value == RepeatModeAS.off)
            ? (_pickRandomUnplayedIndex(length) ??
                _pickRandomIndex(length, exclude: _currentIndex.value))
            : _pickRandomIndex(length, exclude: _currentIndex.value);
        debugPrint("Shuffle next => $nextIndex");
        await playAtIndex(_currentPlaylist, nextIndex);
      } else {
        if (_currentIndex.value < _currentPlaylist.length - 1) {
          debugPrint("Playing next song at index ${_currentIndex.value + 1}");
          await playAtIndex(_currentPlaylist, _currentIndex.value + 1);
        } else {
          if (_repeatMode.value == RepeatModeAS.all) {
            debugPrint("Looping to first song (index 0)");
            await playAtIndex(_currentPlaylist, 0);
          } else {
            debugPrint("Reached end of list, stopping");
            await stop();
          }
        }
      }
      debugPrint("=== END NEXT SONG DEBUG ===");
    } catch (e) {
      debugPrint('Error playing next song: $e');
    }
  }

  Future<void> previous() async {
    try {
      debugPrint("=== PREVIOUS SONG DEBUG ===");
      debugPrint("_currentIndex.value: ${_currentIndex.value}");
      debugPrint("_currentPlaylist.length: ${_currentPlaylist.length}");
      debugPrint("_currentSong: ${_currentSong.value?.title}");

      if (_currentPlaylist.isEmpty) {
        debugPrint("Current playlist is empty, cannot play previous");
        return;
      }

      if (_shuffleEnabled.value) {
        final int length = _currentPlaylist.length;
        final prevIndex =
            _pickRandomIndex(length, exclude: _currentIndex.value);
        debugPrint("Shuffle previous => $prevIndex");
        await playAtIndex(_currentPlaylist, prevIndex);
      } else {
        if (_currentIndex.value > 0) {
          debugPrint(
              "Playing previous song at index ${_currentIndex.value - 1}");
          await playAtIndex(_currentPlaylist, _currentIndex.value - 1);
        } else {
          if (_repeatMode.value == RepeatModeAS.all) {
            debugPrint(
                "Looping to last song (index ${_currentPlaylist.length - 1})");
            await playAtIndex(_currentPlaylist, _currentPlaylist.length - 1);
          } else {
            debugPrint("At start of list, stopping");
            await stop();
          }
        }
      }
      debugPrint("=== END PREVIOUS SONG DEBUG ===");
    } catch (e) {
      debugPrint('Error playing previous song: $e');
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('Error seeking: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping: $e');
    }
  }

  Future<Uint8List?> getAlbumArtwork(int songId,
      {int size = 200, bool highQuality = false}) async {
    if (kIsWeb) return null;
    try {
      final song = _allSongs.firstWhereOrNull((s) => s.id == songId);

      if (song == null) {
        debugPrint('[AudioService] Song not found for songId: $songId');
        return null;
      }

      if (song.albumArtwork != null &&
          (song.albumArtwork!.startsWith('http://') ||
              song.albumArtwork!.startsWith('https://'))) {
        return null;
      }

      if (song.albumArtwork != null && song.albumArtwork!.isNotEmpty) {
        try {
          final isAsset = song.albumArtwork!.startsWith('assets/');
          if (!kIsWeb && !isAsset) {
            final artworkFile = File(song.albumArtwork!);
            if (await artworkFile.exists()) {
              debugPrint(
                  '[AudioService] Loading artwork from local file: ${song.albumArtwork}');
              final bytes = await artworkFile.readAsBytes();
              if (bytes.isNotEmpty) {
                return bytes;
              } else {
                debugPrint(
                    '[AudioService] Artwork file is empty: ${song.albumArtwork}');
              }
            } else {
              debugPrint(
                  '[AudioService] Artwork file does not exist: ${song.albumArtwork}');
            }
          }
        } catch (e) {
          debugPrint(
              '[AudioService] Error reading artwork file ${song.albumArtwork}: $e');
        }
      }

      if (!_isPluginInitialized) {
        await _initializePlugin();
      }

      if (_pendingArtworkQueries.containsKey(songId)) {
        debugPrint(
            '[AudioService] Artwork query already pending for songId: $songId, reusing existing query');
        return await _pendingArtworkQueries[songId]!;
      }

      final effectiveSize = highQuality ? 800 : size;

      final clampedSize = effectiveSize.clamp(50, 2000);

      final queryFuture = _queryArtworkSafely(songId, clampedSize);
      _pendingArtworkQueries[songId] = queryFuture;

      try {
        final result = await queryFuture;
        return result;
      } finally {
        Future.delayed(const Duration(milliseconds: 100), () {
          _pendingArtworkQueries.remove(songId);
        });
      }
    } catch (e) {
      debugPrint('[AudioService] Error getting artwork for songId $songId: $e');
      _pendingArtworkQueries.remove(songId);
      return null;
    }
  }

  Future<Uint8List?> _queryArtworkSafely(int songId, int size) async {
    if (kIsWeb) return null;
    try {
      await Future.delayed(const Duration(milliseconds: 50));

      return await _audioQuery.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: size,
      );
    } on PlatformException catch (e) {
      if (e.code == 'UninitializedPluginProviderException' ||
          e.message?.contains('UninitializedPluginProvider') == true) {
        debugPrint(
            '[AudioService] Plugin not initialized for artwork query, initializing...');
        await _initializePlugin();
        try {
          await Future.delayed(const Duration(milliseconds: 200));
          return await _audioQuery.queryArtwork(
            songId,
            ArtworkType.AUDIO,
            format: ArtworkFormat.JPEG,
            size: size,
          );
        } catch (e2) {
          debugPrint(
              '[AudioService] Artwork query failed after initialization: $e2');
          return null;
        }
      } else if (e.code == 'IllegalStateException' ||
          e.message?.contains('Reply already submitted') == true) {
        debugPrint(
            '[AudioService] Reply already submitted for artwork query (race condition), returning null');
        return null;
      }
      rethrow;
    } catch (e) {
      if (e.toString().contains('Reply already submitted') ||
          e.toString().contains('IllegalStateException')) {
        debugPrint('[AudioService] Reply already submitted error caught: $e');
        return null;
      }
      rethrow;
    }
  }

  String? getArtworkUrl(int songId) {
    try {
      if (_currentSong.value != null && _currentSong.value!.id == songId) {
        final artwork = _currentSong.value!.albumArtwork;
        if (artwork != null &&
            (artwork.startsWith('http://') || artwork.startsWith('https://'))) {
          return artwork;
        }
      }

      final song = _allSongs.firstWhereOrNull((s) => s.id == songId);
      if (song != null &&
          song.albumArtwork != null &&
          (song.albumArtwork!.startsWith('http://') ||
              song.albumArtwork!.startsWith('https://'))) {
        return song.albumArtwork;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  List<models.SongModel> searchSongs(String query) {
    if (query.isEmpty) return _allSongs;

    return _allSongs.where((song) {
      return song.title.toLowerCase().contains(query.toLowerCase()) ||
          song.artist.toLowerCase().contains(query.toLowerCase()) ||
          song.album.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<models.SongModel> getSongsByArtist(String artist) {
    return _allSongs.where((song) => song.artist == artist).toList();
  }

  List<models.SongModel> getSongsByAlbum(String album) {
    return _allSongs.where((song) => song.album == album).toList();
  }

  List<String> getAllArtists() {
    return _allSongs.map((song) => song.artist).toSet().toList()..sort();
  }

  List<String> getAllAlbums() {
    return _allSongs.map((song) => song.album).toSet().toList()..sort();
  }

  Future<void> reloadSongs() async {
    if (kIsWeb) {
      await loadSongs();
    } else if (Platform.isAndroid) {
      await loadSongs();
    } else if (Platform.isIOS) {
      loadSongsForIOS();
    }
  }

  void setPlaylist(List<models.SongModel> playlist, String type) {
    _currentPlaylist.value = List.from(playlist);
    _playlistType.value = type;
    debugPrint('Playlist set: $type with ${playlist.length} songs');
  }

  String getPlaylistInfo() {
    return '${_playlistType.value}: ${_currentPlaylist.length} songs';
  }

  void clearQueue() {
    _currentPlaylist.clear();
    _currentIndex.value = 0;
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _currentPlaylist.length) return;
    final wasBeforeCurrent = index < _currentIndex.value;
    _currentPlaylist.removeAt(index);
    if (_currentPlaylist.isEmpty) {
      _currentIndex.value = 0;
      return;
    }
    if (wasBeforeCurrent) {
      _currentIndex.value =
          (_currentIndex.value - 1).clamp(0, _currentPlaylist.length - 1);
    } else if (_currentIndex.value >= _currentPlaylist.length) {
      _currentIndex.value = _currentPlaylist.length - 1;
    }
  }

  void moveInQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _currentPlaylist.length) return;
    if (newIndex < 0 || newIndex >= _currentPlaylist.length) return;
    final item = _currentPlaylist.removeAt(oldIndex);
    _currentPlaylist.insert(newIndex, item);
    if (_currentIndex.value == oldIndex) {
      _currentIndex.value = newIndex;
    } else if (oldIndex < _currentIndex.value &&
        newIndex >= _currentIndex.value) {
      _currentIndex.value -= 1;
    } else if (oldIndex > _currentIndex.value &&
        newIndex <= _currentIndex.value) {
      _currentIndex.value += 1;
    }
  }

  void addSongToLibrary(models.SongModel song) {
    // Check if it already exists by data (file path) or id
    final existingIndex =
        _allSongs.indexWhere((s) => s.id == song.id || s.data == song.data);
    if (existingIndex == -1) {
      _allSongs.add(song);
      debugPrint(
          '[AudioService] Manually added song to library: ${song.title}');

      // If we are currently in "all" playlist, update it
      if (_playlistType.value == 'all') {
        _currentPlaylist.add(song);
      }
    }
  }
}
