import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'audio_service.dart' as svc;
import 'app_audio_handler.dart';

class AppLifecycleManager extends GetxService with WidgetsBindingObserver {
  final svc.AudioPlayerService _audioPlayerService;
  final AppAudioHandler _audioHandler;

  bool _isInBackground = false;
  DateTime? _backgroundTime;
  Timer? _backgroundCheckTimer;
  StreamSubscription<bool>? _isPlayingSubscription;

  static const Duration _backgroundIdleTimeout = Duration(minutes: 5);

  AppLifecycleManager(this._audioPlayerService, this._audioHandler);

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _startBackgroundMonitoring();
    debugPrint(
        '[AppLifecycleManager] Initialized - will terminate app after $_backgroundIdleTimeout in background if not playing');
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopBackgroundMonitoring();
    _backgroundCheckTimer?.cancel();
    _isPlayingSubscription?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!Platform.isAndroid) return;

    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.hidden:
        _handleAppPaused();
        break;
    }
  }

  void _handleAppPaused() {
    _isInBackground = true;
    _backgroundTime = DateTime.now();
    debugPrint(
        '[AppLifecycleManager] App moved to background at $_backgroundTime');

    if (!_audioPlayerService.isPlaying.value) {
      _scheduleIdleCheck();
    }
  }

  void _handleAppResumed() {
    final wasInBackground = _isInBackground;
    _isInBackground = false;
    _backgroundTime = null;
    _backgroundCheckTimer?.cancel();

    if (wasInBackground) {
      debugPrint(
          '[AppLifecycleManager] App resumed from background - termination cancelled');
    }
  }

  void _handleAppDetached() {
    debugPrint('[AppLifecycleManager] App detached by system');
    _cleanupResources();
  }

  void _startBackgroundMonitoring() {
    _isPlayingSubscription = _audioPlayerService.isPlaying.listen((isPlaying) {
      if (isPlaying) {
        _backgroundCheckTimer?.cancel();
        debugPrint(
            '[AppLifecycleManager] Playback started - termination cancelled');
      } else if (_isInBackground) {
        _scheduleIdleCheck();
      }
    });
  }

  void _stopBackgroundMonitoring() {
    _isPlayingSubscription?.cancel();
    _isPlayingSubscription = null;
    _backgroundCheckTimer?.cancel();
  }

  void _scheduleIdleCheck() {
    _backgroundCheckTimer?.cancel();

    if (!_isInBackground) return;

    _backgroundCheckTimer = Timer(_backgroundIdleTimeout, () {
      _handleIdleTimeout();
    });

    debugPrint(
        '[AppLifecycleManager] Scheduled app termination in ${_backgroundIdleTimeout.inMinutes} minutes if still in background and not playing');
  }

  void _handleIdleTimeout() {
    if (!_isInBackground) {
      debugPrint('[AppLifecycleManager] App resumed - cancellation timeout');
      return;
    }

    if (_audioPlayerService.isPlaying.value) {
      debugPrint('[AppLifecycleManager] Still playing - termination cancelled');
      return;
    }

    debugPrint(
        '[AppLifecycleManager] Idle timeout reached - terminating app to save battery');
    _terminateApp();
  }

  Future<void> _terminateApp() async {
    try {
      await _cleanupAudioService();

      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('[AppLifecycleManager] Terminating app to save battery...');

      exit(0);
    } catch (e) {
      debugPrint('[AppLifecycleManager] Error during app termination: $e');
      exit(0);
    }
  }

  Future<void> _cleanupAudioService() async {
    try {
      await _audioHandler.stop();
      debugPrint('[AppLifecycleManager] Audio service stopped');
    } catch (e) {
      debugPrint('[AppLifecycleManager] Error stopping audio service: $e');
    }
  }

  void _cleanupResources() {
    _backgroundCheckTimer?.cancel();
    _backgroundCheckTimer = null;
  }
}
