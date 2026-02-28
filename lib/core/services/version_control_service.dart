// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/remote_config_service.dart';

class VersionControlService extends GetxService {
  static VersionControlService get instance =>
      Get.find<VersionControlService>();

  static const String KEY_MIN_REQUIRED_VERSION = 'min_required_version';
  static const String KEY_LATEST_VERSION = 'latest_version';
  static const String KEY_UPDATE_MESSAGE = 'update_message';
  static const String KEY_UPDATE_TITLE = 'update_title';
  static const String KEY_PLAY_STORE_URL = 'play_store_url';
  static const String KEY_APP_STORE_URL = 'app_store_url';
  static const String KEY_FORCE_UPDATE_ENABLED = 'force_update_enabled';

  // Observable values
  final RxBool _isChecking = false.obs;
  final RxString _currentVersion = ''.obs;
  final RxString _latestVersion = ''.obs;
  final RxString _minRequiredVersion = ''.obs;
  final RxBool _updateAvailable = false.obs;
  final RxBool _forceUpdateRequired = false.obs;

  bool get isChecking => _isChecking.value;
  String get currentVersion => _currentVersion.value;
  String get latestVersion => _latestVersion.value;
  String get minRequiredVersion => _minRequiredVersion.value;
  bool get updateAvailable => _updateAvailable.value;
  bool get forceUpdateRequired => _forceUpdateRequired.value;

  PackageInfo? _packageInfo;

  @override
  void onInit() {
    super.onInit();
    _initializeVersion();
  }

  Future<void> _initializeVersion() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _currentVersion.value = _packageInfo!.version;
      debugPrint('Current app version: ${_currentVersion.value}');
    } catch (e) {
      debugPrint('Error getting package info: $e');
    }
  }

  Future<UpdateStatus> checkForUpdate() async {
    try {
      _isChecking.value = true;

      if (_packageInfo == null) {
        await _initializeVersion();
      }

      if (!Get.isRegistered<RemoteConfigService>()) {
        debugPrint('Remote Config not initialized yet');
        _isChecking.value = false;
        return UpdateStatus.upToDate;
      }

      final remoteConfig = RemoteConfigService.instance;

      int attempts = 0;
      while (!remoteConfig.isInitialized && attempts < 5) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      if (!remoteConfig.isInitialized) {
        debugPrint('Remote Config not initialized after waiting');
        _isChecking.value = false;
        return UpdateStatus.upToDate;
      }

      _minRequiredVersion.value = remoteConfig.getString(
        KEY_MIN_REQUIRED_VERSION,
        defaultValue: _currentVersion.value,
      );

      _latestVersion.value = remoteConfig.getString(
        KEY_LATEST_VERSION,
        defaultValue: _currentVersion.value,
      );

      final forceUpdateEnabled = remoteConfig.getBool(
        KEY_FORCE_UPDATE_ENABLED,
        defaultValue: false,
      );

      debugPrint('Current version: ${_currentVersion.value}');
      debugPrint('Min required version: ${_minRequiredVersion.value}');
      debugPrint('Latest version: ${_latestVersion.value}');
      debugPrint('Force update enabled: $forceUpdateEnabled');

      final current = _parseVersion(_currentVersion.value);
      final minRequired = _parseVersion(_minRequiredVersion.value);
      final latest = _parseVersion(_latestVersion.value);

      if (forceUpdateEnabled && _compareVersions(current, minRequired) < 0) {
        _forceUpdateRequired.value = true;
        _updateAvailable.value = true;
        debugPrint('Force update required: Current < Min Required');
        _isChecking.value = false;
        return UpdateStatus.forceUpdate;
      }

      if (_compareVersions(current, latest) < 0) {
        _updateAvailable.value = true;
        _forceUpdateRequired.value = false;
        debugPrint('Optional update available: Current < Latest');
        _isChecking.value = false;
        return UpdateStatus.optionalUpdate;
      }

      _updateAvailable.value = false;
      _forceUpdateRequired.value = false;
      debugPrint('App is up to date');
      _isChecking.value = false;
      return UpdateStatus.upToDate;
    } catch (e) {
      debugPrint('Error checking for update: $e');
      _isChecking.value = false;
      return UpdateStatus.upToDate;
    }
  }

  Version _parseVersion(String versionString) {
    final versionPart = versionString.split('+').first;
    final parts = versionPart.split('.');

    return Version(
      major: parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0,
      minor: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      patch: parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
    );
  }

  int _compareVersions(Version v1, Version v2) {
    if (v1.major != v2.major) {
      return v1.major.compareTo(v2.major);
    }
    if (v1.minor != v2.minor) {
      return v1.minor.compareTo(v2.minor);
    }
    return v1.patch.compareTo(v2.patch);
  }

  String getUpdateMessage() {
    try {
      if (!Get.isRegistered<RemoteConfigService>()) {
        return 'A new version of the app is available. Please update to continue.';
      }

      final remoteConfig = RemoteConfigService.instance;
      final message = remoteConfig.getString(
        KEY_UPDATE_MESSAGE,
        defaultValue:
            'A new version of the app is available with bug fixes and improvements. Please update to get the best experience.',
      );

      return message;
    } catch (e) {
      debugPrint('Error getting update message: $e');
      return 'A new version of the app is available. Please update to continue.';
    }
  }

  String getUpdateTitle() {
    try {
      if (!Get.isRegistered<RemoteConfigService>()) {
        return 'Update Available';
      }

      final remoteConfig = RemoteConfigService.instance;
      final title = remoteConfig.getString(
        KEY_UPDATE_TITLE,
        defaultValue: 'Update Available',
      );

      return title;
    } catch (e) {
      debugPrint('Error getting update title: $e');
      return 'Update Available';
    }
  }

  Future<String> getPlayStoreUrl() async {
    try {
      if (!Get.isRegistered<RemoteConfigService>()) {
        return _getDefaultPlayStoreUrl();
      }

      final remoteConfig = RemoteConfigService.instance;
      final url = remoteConfig.getString(
        KEY_PLAY_STORE_URL,
        defaultValue: _getDefaultPlayStoreUrl(),
      );

      return url;
    } catch (e) {
      debugPrint('Error getting Play Store URL: $e');
      return _getDefaultPlayStoreUrl();
    }
  }

  Future<String> getAppStoreUrl() async {
    try {
      if (!Get.isRegistered<RemoteConfigService>()) {
        return _getDefaultAppStoreUrl();
      }

      final remoteConfig = RemoteConfigService.instance;
      final url = remoteConfig.getString(
        KEY_APP_STORE_URL,
        defaultValue: _getDefaultAppStoreUrl(),
      );

      return url;
    } catch (e) {
      debugPrint('Error getting App Store URL: $e');
      return _getDefaultAppStoreUrl();
    }
  }

  String _getDefaultPlayStoreUrl() {
    final packageName = _packageInfo?.packageName ?? 'com.ako.velo';
    return 'https://play.google.com/store/apps/details?id=$packageName';
  }

  String _getDefaultAppStoreUrl() {
    return 'https://apps.apple.com/app/id1234567890';
  }

  Future<void> launchAppStore() async {
    try {
      String url;
      if (defaultTargetPlatform == TargetPlatform.android) {
        url = await getPlayStoreUrl();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        url = await getAppStoreUrl();
      } else {
        debugPrint('App Store not available on this platform');
        return;
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('Launched app store: $url');
      } else {
        debugPrint('Could not launch app store: $url');
      }
    } catch (e) {
      debugPrint('Error launching app store: $e');
    }
  }
}

class Version {
  final int major;
  final int minor;
  final int patch;

  Version({
    required this.major,
    required this.minor,
    required this.patch,
  });

  @override
  String toString() => '$major.$minor.$patch';
}

enum UpdateStatus {
  upToDate,
  optionalUpdate,
  forceUpdate,
}
