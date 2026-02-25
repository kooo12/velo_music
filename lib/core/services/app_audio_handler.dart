import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'audio_service.dart' as svc;

class AppAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  late final svc.AudioPlayerService _player;
  late final StreamSubscription _songSub;
  late final StreamSubscription _playingSub;
  late final StreamSubscription _positionSub;
  late final StreamSubscription _playlistSub;
  late final StreamSubscription _loadingSub;

  Timer? _mediaItemUpdateTimer;
  Timer? _queueUpdateTimer;
  bool _isUpdatingMediaItem = false;
  bool _isUpdatingQueue = false;
  int _lastMediaItemId = -1;
  bool _isInitialized = false;

  AppAudioHandler() {
    if (_isInitialized) {
      debugPrint('AppAudioHandler already initialized, skipping...');
      return;
    }

    _player = Get.find<svc.AudioPlayerService>();
    _isInitialized = true;

    _emitPlaybackState(
      playing: _player.isPlaying.value,
      processingState: _player.isLoading.value
          ? AudioProcessingState.loading
          : AudioProcessingState.ready,
      position: Duration(milliseconds: _player.currentPosition.value.floor()),
    );

    _loadingSub = _player.isLoading.listen((bool loading) {
      if (loading) {
        final currentState = playbackState.value;
        _emitPlaybackState(
          playing: currentState.playing,
          processingState: AudioProcessingState.loading,
        );
      } else {
        final currentState = playbackState.value;
        if (currentState.processingState == AudioProcessingState.loading) {
          _emitPlaybackState(
            playing: currentState.playing,
            processingState: AudioProcessingState.ready,
          );
        }
      }
    });

    _songSub = _player.currentIndex.listen((int index) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _updateMediaItem(force: true);
      });
      _debouncedUpdateQueue();
    });

    _playlistSub = _player.currentPlaylist.listen((_) {
      _debouncedUpdateQueue();
    });

    _playingSub = _player.isPlaying.listen((bool playing) {
      final currentState = playbackState.value;
      if (playing &&
          currentState.processingState == AudioProcessingState.loading) {
        _emitPlaybackState(
          playing: playing,
          processingState: AudioProcessingState.ready,
        );
      } else {
        _emitPlaybackState(playing: playing);
      }

      if (playing) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _updateMediaItem(force: true);
        });
      }
    });

    _positionSub = _player.currentPosition.listen((double posMs) {
      final d = Duration(milliseconds: posMs.floor());

      final currentState = playbackState.value;
      final currentMediaItem = mediaItem.value;
      final duration = currentMediaItem?.duration ?? Duration.zero;

      playbackState.add(currentState.copyWith(
        updatePosition: d,
        bufferedPosition: duration > Duration.zero ? duration : Duration.zero,
      ));
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _updateMediaItem();
      _updateQueue();
    });
  }

  void debouncedUpdateMediaItem() {
    _mediaItemUpdateTimer?.cancel();
    _mediaItemUpdateTimer = Timer(const Duration(milliseconds: 200), () {
      _updateMediaItem();
    });
  }

  void _debouncedUpdateQueue() {
    _queueUpdateTimer?.cancel();
    _queueUpdateTimer = Timer(const Duration(milliseconds: 300), () {
      _updateQueue();
    });
  }

  Future<void> _updateMediaItem({bool force = false}) async {
    if (_isUpdatingMediaItem) {
      debugPrint('Media item update already in progress, skipping...');
      return;
    }

    final song = _player.currentSong;
    if (song == null) {
      if (_lastMediaItemId != -1) {
        mediaItem.add(null);
        _lastMediaItemId = -1;
      }
      return;
    }

    if (!force && _lastMediaItemId == song.id) {
      debugPrint('Media item already set for song ${song.id}, skipping update');
      return;
    }

    _isUpdatingMediaItem = true;
    try {
      Uri? artUri;
      try {
        final Uint8List? bytes = await _player.getAlbumArtwork(song.id);
        if (bytes != null && bytes.isNotEmpty) {
          artUri = Uri.dataFromBytes(bytes, mimeType: 'image/jpeg');
        } else if ((song.albumArtwork ?? '').isNotEmpty) {
          if (song.albumArtwork!.startsWith('http://') ||
              song.albumArtwork!.startsWith('https://')) {
            artUri = Uri.parse(song.albumArtwork!);
          } else {
            artUri = Uri.file(song.albumArtwork!);
          }
        }
      } catch (e) {
        debugPrint('Error loading artwork: $e');
      }

      final mediaItemObj = MediaItem(
        id: song.id.toString(),
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: Duration(milliseconds: song.duration),
        artUri: artUri,
        extras: {'path': song.data},
      );

      mediaItem.add(mediaItemObj);
      _lastMediaItemId = song.id;

      final currentState = playbackState.value;
      final currentPosition =
          Duration(milliseconds: _player.currentPosition.value.floor());

      _emitPlaybackState(
        playing: currentState.playing,
        processingState: AudioProcessingState.ready,
        position: currentPosition,
      );

      debugPrint(
          'Media item updated: ${song.title} (ID: ${song.id}) with duration: ${mediaItemObj.duration}');
    } catch (e) {
      debugPrint('Error updating media item: $e');
    } finally {
      _isUpdatingMediaItem = false;
    }
  }

  Future<void> _updateQueue() async {
    if (_isUpdatingQueue) {
      return;
    }

    _isUpdatingQueue = true;
    try {
      final playlist = _player.currentPlaylist;
      if (playlist.isEmpty) {
        queue.add([]);
        return;
      }

      final mediaItems = <MediaItem>[];
      for (final song in playlist) {
        Uri? artUri;
        try {
          final Uint8List? bytes = await _player.getAlbumArtwork(song.id);
          if (bytes != null && bytes.isNotEmpty) {
            artUri = Uri.dataFromBytes(bytes, mimeType: 'image/jpeg');
          } else if ((song.albumArtwork ?? '').isNotEmpty) {
            artUri = Uri.file(song.albumArtwork!);
          }
        } catch (_) {}

        mediaItems.add(MediaItem(
          id: song.id.toString(),
          title: song.title,
          artist: song.artist,
          album: song.album,
          duration: Duration(milliseconds: song.duration),
          artUri: artUri,
          extras: {'path': song.data},
        ));
      }

      queue.add(mediaItems);
      debugPrint('Queue updated with ${mediaItems.length} items');
    } catch (e) {
      debugPrint('Error updating queue: $e');
    } finally {
      _isUpdatingQueue = false;
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    queue.add(newQueue);
  }

  void _emitPlaybackState({
    required bool playing,
    AudioProcessingState? processingState,
    Duration? position,
  }) {
    final currentState = playbackState.value;
    final effectiveProcessingState =
        processingState ?? currentState.processingState;

    final currentPosition = position ??
        Duration(milliseconds: _player.currentPosition.value.floor());

    final currentMediaItem = mediaItem.value;
    final duration = currentMediaItem?.duration ?? Duration.zero;

    final controls = <MediaControl>[
      MediaControl.skipToPrevious,
      if (playing) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
      // MediaControl.stop,
    ];

    playbackState.add(PlaybackState(
      controls: controls,
      playing: playing,
      processingState: effectiveProcessingState,
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      updatePosition: currentPosition,
      bufferedPosition: duration > Duration.zero ? duration : Duration.zero,
      speed: 1.0,
      shuffleMode: _player.shuffleEnabled.value
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      repeatMode: () {
        switch (_player.repeatMode.value) {
          case svc.RepeatModeAS.one:
            return AudioServiceRepeatMode.one;
          case svc.RepeatModeAS.all:
            return AudioServiceRepeatMode.all;
          case svc.RepeatModeAS.off:
            return AudioServiceRepeatMode.none;
        }
      }(),
    ));
  }

  Future<void> removeNotification() async {
    await stop();
  }

  // ================= Controls mapping =================
  @override
  Future<void> play() async {
    try {
      if (!_player.isPlaying.value) {
        final song = _player.currentSong;
        if (song != null) {
          if (_lastMediaItemId != song.id) {
            await _updateMediaItem();
          }

          final currentState = playbackState.value;
          if (currentState.processingState != AudioProcessingState.ready) {
            _emitPlaybackState(
              playing: false,
              processingState: AudioProcessingState.ready,
            );
          }
        }

        await _player.play();
      }
    } catch (e) {
      debugPrint('Error in play(): $e');
      _emitPlaybackState(
        playing: false,
        processingState: AudioProcessingState.error,
      );
    }
  }

  @override
  Future<void> pause() async {
    try {
      if (_player.isPlaying.value) {
        await _player.pause();
      }
    } catch (e) {
      debugPrint('Error in pause(): $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('Error in stop(): $e');
    }
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seekTo(position);
    } catch (e) {
      debugPrint('Error in seek(): $e');
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      await _player.next();
    } catch (e) {
      debugPrint('Error in skipToNext(): $e');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      await _player.previous();
    } catch (e) {
      debugPrint('Error in skipToPrevious(): $e');
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    try {
      final playlist = _player.currentPlaylist;
      if (index >= 0 && index < playlist.length) {
        await _player.playAtIndex(playlist, index);
      }
    } catch (e) {
      debugPrint('Error in skipToQueueItem(): $e');
    }
  }

  void close() {
    _mediaItemUpdateTimer?.cancel();
    _queueUpdateTimer?.cancel();
    _songSub.cancel();
    _playingSub.cancel();
    _positionSub.cancel();
    _playlistSub.cancel();
    _loadingSub.cancel();
  }
}
