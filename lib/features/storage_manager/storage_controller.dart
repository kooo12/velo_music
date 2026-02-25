import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:sonus/core/helper/loaders.dart';
import 'package:sonus/core/services/audio_service.dart';
import 'package:sonus/core/services/storage_service.dart';

class StorageController extends GetxController {
  StorageController(this._storageService);

  final StorageService _storageService;
  final RxList<String> scanFolders = <String>[].obs;
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final RxBool isScanning = false.obs;

  static const List<String> protectedFolders = [
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Music'
  ];

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final saved = await _storageService.loadScanFolders();
    if (saved.isEmpty) {
      final defaults = await _getDefaultFolders();
      scanFolders.assignAll(defaults);
      await _storageService.saveScanFolders(defaults);
    } else {
      scanFolders.assignAll(saved);
    }
  }

  Future<List<String>> _getDefaultFolders() async {
    final defaults = <String>[];

    final pathsToCheck = <String>[
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0',
      '/sdcard/Music',
      '/sdcard/Download',
      '/storage/emulated/0/Android/media',
    ];

    for (final path in pathsToCheck) {
      if (await _directoryExists(path)) {
        defaults.add(path);
      }
    }

    if (defaults.isEmpty) {
      defaults.addAll(await _detectStoragePaths());
    }

    return defaults;
  }

  Future<bool> _directoryExists(String path) async {
    try {
      final directory = Directory(path);
      return await directory.exists();
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> _detectStoragePaths() async {
    final detected = <String>[];

    try {
      final externalStorage = await _findExternalStorageRoot();
      if (externalStorage != null) {
        final musicPath = '$externalStorage/Music';
        if (await _directoryExists(musicPath)) {
          detected.add(musicPath);
        }

        final downloadPath = '$externalStorage/Download';
        if (await _directoryExists(downloadPath)) {
          detected.add(downloadPath);
        }
      }
    } catch (e) {
      debugPrint('Error detecting storage paths: $e');
    }

    return detected;
  }

  Future<String?> _findExternalStorageRoot() async {
    final possibleRoots = [
      '/storage/emulated/0',
      '/sdcard',
      '/storage/sdcard0',
    ];

    for (final root in possibleRoots) {
      if (await _directoryExists(root)) {
        return root;
      }
    }

    return null;
  }

  Future<void> addFolder() async {
    try {
      String? path;

      if (Platform.isAndroid) {
        path = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Select music folder',
          lockParentWindow: true,
        );
      } else {
        path = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Select music folder',
        );
      }

      if (path != null && path.isNotEmpty) {
        if (scanFolders.contains(path)) {
          AppLoader.customToast(
            message: 'This folder is already in your scan list',
          );
          return;
        }

        final directory = Directory(path);
        if (await directory.exists()) {
          scanFolders.add(path);
          await _storageService.saveScanFolders(scanFolders);

          _reloadSongs();

          AppLoader.customToast(
            message: 'Folder added successfully',
          );
        } else {
          AppLoader.customToast(
            message: 'Selected folder does not exist or is not accessible',
          );
        }
      }
    } catch (e) {
      debugPrint('Error adding folder: $e');
      AppLoader.customToast(
        message:
            'Failed to add folder. Please try selecting a different folder',
      );
    }
  }

  Future<void> removeFolder(String path) async {
    try {
      if (isProtectedFolder(path)) {
        AppLoader.customToast(
          message: 'This folder cannot be removed',
        );
        return;
      }

      scanFolders.remove(path);
      await _storageService.saveScanFolders(scanFolders);

      _reloadSongs();

      AppLoader.customToast(
        message: 'Folder removed successfully',
      );
    } catch (e) {
      debugPrint('Error removing folder: $e');
      AppLoader.customToast(
        message: 'Failed to remove folder',
      );
    }
  }

  Future<void> save() async {
    try {
      await _storageService.saveScanFolders(scanFolders);

      _reloadSongs();

      AppLoader.customToast(
        message: 'Scan folders updated successfully',
      );
    } catch (e) {
      debugPrint('Error saving folders: $e');
      AppLoader.customToast(
        message: 'Failed to save folders',
      );
    }
  }

  Future<void> scanAllSongsAndDetectFolders() async {
    if (isScanning.value) {
      AppLoader.customToast(message: 'Scan already in progress');
      return;
    }

    try {
      isScanning.value = true;
      AppLoader.customToast(message: 'Scanning device for music...');

      if (!Get.isRegistered<AudioPlayerService>()) {
        AppLoader.customToast(message: 'Audio service not available');
        return;
      }

      final audioService = Get.find<AudioPlayerService>();
      if (!audioService.hasPermission.value) {
        AppLoader.customToast(message: 'Please grant audio permission first');
        return;
      }

      final allSongs = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        ignoreCase: true,
      );

      debugPrint('Found ${allSongs.length} total audio files');

      final Set<String> detectedFolders = {};

      for (final song in allSongs) {
        final songPath = song.data;
        if (songPath.isNotEmpty) {
          final file = File(songPath);
          final directory = file.parent;
          final dirPath = directory.path;

          detectedFolders.add(dirPath);

          final parent = directory.parent;
          if (parent.path != dirPath && parent.path != '/') {
            detectedFolders.add(parent.path);
          }
        }
      }

      debugPrint('Detected ${detectedFolders.length} unique folders');

      final musicFolders = <String>[];
      for (final folderPath in detectedFolders) {
        final songsInFolder = allSongs.where((song) {
          return song.data.startsWith(folderPath);
        }).length;

        if (songsInFolder > 0) {
          musicFolders.add(folderPath);
        }
      }

      musicFolders.sort((a, b) {
        final countA = allSongs.where((s) => s.data.startsWith(a)).length;
        final countB = allSongs.where((s) => s.data.startsWith(b)).length;
        return countB.compareTo(countA);
      });

      final foldersToAdd = musicFolders.take(20).toList();

      int addedCount = 0;
      for (final folderPath in foldersToAdd) {
        if (!scanFolders.contains(folderPath) &&
            !protectedFolders.contains(folderPath)) {
          if (await _directoryExists(folderPath)) {
            scanFolders.add(folderPath);
            addedCount++;
          }
        }
      }

      await _storageService.saveScanFolders(scanFolders);

      _reloadSongs();

      AppLoader.customToast(
        message:
            'Scan complete! Added $addedCount music folder${addedCount != 1 ? 's' : ''}',
      );
    } catch (e) {
      debugPrint('Error scanning songs: $e');
      AppLoader.customToast(
        message: 'Failed to scan device: $e',
      );
    } finally {
      isScanning.value = false;
    }
  }

  void _reloadSongs() {
    try {
      if (Get.isRegistered<AudioPlayerService>()) {
        final audioService = Get.find<AudioPlayerService>();
        if (audioService.hasPermission.value) {
          debugPrint('Reloading songs after folder change...');
          audioService.loadSongs(skipPermissionCheck: true).catchError((e) {
            debugPrint('Error reloading songs: $e');
          });
        } else {
          debugPrint('Permission not granted, skipping song reload');
        }
      }
    } catch (e) {
      debugPrint('Error in _reloadSongs: $e');
    }
  }

  bool isProtectedFolder(String path) {
    if (protectedFolders.contains(path)) {
      return true;
    }

    final lowerPath = path.toLowerCase();
    if (lowerPath.contains('music')) {
      return true;
    }
    return false;
  }
}
