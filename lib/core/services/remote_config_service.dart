// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class RemoteConfigService extends GetxService {
  static RemoteConfigService get instance => Get.find<RemoteConfigService>();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable values
  final RxBool _isInitialized = false.obs;
  final RxBool _isLoading = false.obs;
  final RxString _lastFetchTime = ''.obs;
  final RxString _lastError = ''.obs;

  final RxBool _giftboxEnabled = false.obs;
  StreamSubscription<DocumentSnapshot>? _giftboxConfigSubscription;

  final RxBool _contactDeveloperEnabled = false.obs;
  StreamSubscription<DocumentSnapshot>? _contactDeveloperConfigSubscription;

  final RxString _developerProfileLink = ''.obs;

  // Version control keys
  static const String KEY_MIN_REQUIRED_VERSION = 'min_required_version';
  static const String KEY_LATEST_VERSION = 'latest_version';
  static const String KEY_UPDATE_MESSAGE = 'update_message';
  static const String KEY_UPDATE_TITLE = 'update_title';
  static const String KEY_PLAY_STORE_URL = 'play_store_url';
  static const String KEY_APP_STORE_URL = 'app_store_url';
  static const String KEY_FORCE_UPDATE_ENABLED = 'force_update_enabled';

  static const String KEY_SHOW_GIFTBOX_ICON = 'show_giftbox_icon';
  static const String KEY_GIFTBOX_APPS_ENABLED = 'giftbox_apps_enabled';

  static const String CONFIG_COLLECTION = 'app_config';
  static const String CONFIG_DOC_ID = 'giftbox_config';
  static const String CONTACT_DEVELOPER_CONFIG_DOC_ID =
      'contact_developer_config';

  bool get isInitialized => _isInitialized.value;
  bool get isLoading => _isLoading.value;
  String get lastFetchTime => _lastFetchTime.value;
  String get lastError => _lastError.value;

  RxBool get giftboxEnabled => _giftboxEnabled;
  bool get isGiftboxEnabled => _giftboxEnabled.value;

  RxBool get contactDeveloperEnabled => _contactDeveloperEnabled;
  bool get isContactDeveloperEnabled => _contactDeveloperEnabled.value;

  RxString get developerProfileLink => _developerProfileLink;
  String get currentDeveloperProfileLink => _developerProfileLink.value;

  @override
  void onInit() {
    super.onInit();
    _setupGiftboxConfigListener();
    _setupContactDeveloperConfigListener();
    Future.delayed(const Duration(seconds: 2), () {
      initialize().catchError((e) {
        debugPrint('Remote Config initialization failed: $e');
      });
    });
  }

  @override
  void onClose() {
    _giftboxConfigSubscription?.cancel();
    _contactDeveloperConfigSubscription?.cancel();
    super.onClose();
  }

  void _setupGiftboxConfigListener() {
    try {
      _giftboxConfigSubscription = _firestore
          .collection(CONFIG_COLLECTION)
          .doc(CONFIG_DOC_ID)
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data()!;
            final enabled = data['enabled'] as bool? ?? false;
            _giftboxEnabled.value = enabled;
            debugPrint('Giftbox config updated from Firestore: $enabled');
          } else {
            _giftboxEnabled.value = false;
            debugPrint(
                'Giftbox config document not found, using default: false');
          }
        },
        onError: (error) {
          debugPrint('Error listening to giftbox config: $error');
          _giftboxEnabled.value = false;
        },
      );

      _loadGiftboxConfigFromFirestore();
    } catch (e) {
      debugPrint('Error setting up giftbox config listener: $e');
    }
  }

  Future<void> _loadGiftboxConfigFromFirestore() async {
    try {
      final doc = await _firestore
          .collection(CONFIG_COLLECTION)
          .doc(CONFIG_DOC_ID)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final enabled = data['enabled'] as bool? ?? false;
        _giftboxEnabled.value = enabled;
        debugPrint('Loaded giftbox config from Firestore: $enabled');
      } else {
        await _firestore
            .collection(CONFIG_COLLECTION)
            .doc(CONFIG_DOC_ID)
            .set({'enabled': false}, SetOptions(merge: true));
        _giftboxEnabled.value = false;
        debugPrint('Created default giftbox config document');
      }
    } catch (e) {
      debugPrint('Error loading giftbox config from Firestore: $e');
      _giftboxEnabled.value = false;
    }
  }

  void _setupContactDeveloperConfigListener() {
    try {
      _contactDeveloperConfigSubscription = _firestore
          .collection(CONFIG_COLLECTION)
          .doc(CONTACT_DEVELOPER_CONFIG_DOC_ID)
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data()!;
            final enabled = data['enabled'] as bool? ?? false;
            final profileLink = data['profileLink'] as String? ?? '';
            _contactDeveloperEnabled.value = enabled;
            _developerProfileLink.value = profileLink;
            debugPrint(
                'Contact developer config updated from Firestore: enabled=$enabled, profileLink=$profileLink');
          } else {
            _contactDeveloperEnabled.value = false;
            _developerProfileLink.value = '';
            debugPrint(
                'Contact developer config document not found, using default: false');
          }
        },
        onError: (error) {
          debugPrint('Error listening to contact developer config: $error');
          _contactDeveloperEnabled.value = false;
        },
      );
      _loadContactDeveloperConfigFromFirestore();
    } catch (e) {
      debugPrint('Error setting up contact developer config listener: $e');
    }
  }

  Future<void> _loadContactDeveloperConfigFromFirestore() async {
    try {
      final doc = await _firestore
          .collection(CONFIG_COLLECTION)
          .doc(CONTACT_DEVELOPER_CONFIG_DOC_ID)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final enabled = data['enabled'] as bool? ?? false;
        final profileLink = data['profileLink'] as String? ?? '';
        _contactDeveloperEnabled.value = enabled;
        _developerProfileLink.value = profileLink;
        debugPrint(
            'Loaded contact developer config from Firestore: enabled=$enabled, profileLink=$profileLink');
      } else {
        await _firestore
            .collection(CONFIG_COLLECTION)
            .doc(CONTACT_DEVELOPER_CONFIG_DOC_ID)
            .set(
                {'enabled': false, 'profileLink': ''}, SetOptions(merge: true));
        _contactDeveloperEnabled.value = false;
        _developerProfileLink.value = '';
        debugPrint('Created default contact developer config document');
      }
    } catch (e) {
      debugPrint('Error loading contact developer config from Firestore: $e');
      _contactDeveloperEnabled.value = false;
    }
  }

  Future<void> initialize() async {
    try {
      _isLoading.value = true;

      await _remoteConfig.setDefaults({
        KEY_MIN_REQUIRED_VERSION: '1.0.0',
        KEY_LATEST_VERSION: '1.0.0',
        KEY_UPDATE_TITLE: 'Update Available',
        KEY_UPDATE_MESSAGE:
            'A new version of the app is available with bug fixes and improvements. Please update to get the best experience.',
        KEY_PLAY_STORE_URL:
            'https://play.google.com/store/apps/details?id=com.ako.velo',
        KEY_APP_STORE_URL: 'https://apps.apple.com/app/id1234567890',
        KEY_FORCE_UPDATE_ENABLED: 'false',
        KEY_SHOW_GIFTBOX_ICON: 'false',
        KEY_GIFTBOX_APPS_ENABLED: 'false',
      });

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 15),
          minimumFetchInterval: const Duration(seconds: 0),
        ),
      );

      _isInitialized.value = true;

      try {
        await fetchAndActivate();
        _lastError.value = '';
        debugPrint('Remote Config initialized and fetched successfully');
      } catch (fetchError) {
        _lastError.value = fetchError.toString();
        debugPrint(
            'Remote Config initialized with defaults. Fetch failed: $fetchError');
      }
    } catch (e) {
      _isInitialized.value = true;
      _lastError.value = e.toString();
      debugPrint('Error initializing Remote Config: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> fetchAndActivate() async {
    try {
      _isLoading.value = true;

      try {
        final updated = await _remoteConfig.fetchAndActivate().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint('Remote Config fetch timed out');
            return false;
          },
        );

        if (updated) {
          _lastFetchTime.value = DateTime.now().toString();
          _lastError.value = '';
          debugPrint(
              'Remote Config fetched and activated at ${_lastFetchTime.value}');
        } else {
          debugPrint(
              'Remote Config fetch completed, but no updates were applied');
        }

        return updated;
      } on FirebaseException catch (e) {
        if (e.code == 'internal' || e.code == 'unavailable') {
          debugPrint(
              'Remote Config service unavailable. Using default values.');
          _lastError.value = 'Service unavailable - using defaults';
          return false;
        } else {
          rethrow;
        }
      }
    } catch (e) {
      _lastError.value = e.toString();
      debugPrint('Error fetching Remote Config: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> forceFetch() async {
    try {
      _isLoading.value = true;
      await _remoteConfig.fetch();
      await _remoteConfig.activate();

      _lastFetchTime.value = DateTime.now().toString();
      _lastError.value = '';
      debugPrint('Remote Config force fetched at ${_lastFetchTime.value}');

      return true;
    } catch (e) {
      _lastError.value = e.toString();
      debugPrint('Error force fetching Remote Config: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Map<String, dynamic> getAllValues() {
    try {
      final allKeys = _remoteConfig.getAll();
      final values = <String, dynamic>{};

      for (final entry in allKeys.entries) {
        values[entry.key] = entry.value.asString();
      }

      return values;
    } catch (e) {
      debugPrint('Error getting all values: $e');
      return {};
    }
  }

  String getString(String key, {String defaultValue = ''}) {
    try {
      return _remoteConfig.getString(key);
    } catch (e) {
      debugPrint('Error getting string value for key $key: $e');
      return defaultValue;
    }
  }

  int getInt(String key, {int defaultValue = 0}) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      debugPrint('Error getting int value for key $key: $e');
      return defaultValue;
    }
  }

  bool getBool(String key, {bool defaultValue = false}) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      debugPrint('Error getting bool value for key $key: $e');
      return defaultValue;
    }
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    try {
      return _remoteConfig.getDouble(key);
    } catch (e) {
      debugPrint('Error getting double value for key $key: $e');
      return defaultValue;
    }
  }

  ValueSource getValueSource(String key) {
    try {
      return _remoteConfig.getValue(key).source;
    } catch (e) {
      debugPrint('Error getting value source for key $key: $e');
      return ValueSource.valueStatic;
    }
  }
}
