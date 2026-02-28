import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/promoted_app_model.dart';
import '../../../core/services/remote_config_service.dart';

class PromotedAppsService extends GetxService {
  static PromotedAppsService get instance => Get.find<PromotedAppsService>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<PromotedApp> _promotedApps = <PromotedApp>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _lastError = ''.obs;
  final RxInt _badgeCount = 0.obs;

  List<PromotedApp> get promotedApps => _promotedApps;
  bool get isLoading => _isLoading.value;
  String get lastError => _lastError.value;
  RxInt get badgeCount => _badgeCount;

  static const String _keyLastViewedTimestamp = 'promoted_apps_last_viewed';
  static const String _keyBadgeCount = 'promoted_apps_badge_count';
  static const String _keyViewedAppIds = 'promoted_apps_viewed_ids';

  static const String clicksCollection = 'promoted_app_clicks';
  static const String analyticsCollection = 'promoted_app_analytics';

  @override
  void onInit() {
    super.onInit();
    _loadBadgeCount();
  }

  Future<bool> shouldShowGiftbox() async {
    try {
      if (!Get.isRegistered<RemoteConfigService>()) {
        debugPrint('RemoteConfigService not registered');
        return false;
      }

      final remoteConfig = RemoteConfigService.instance;

      if (remoteConfig.isGiftboxEnabled) {
        debugPrint('Giftbox enabled from Firestore config (admin toggle)');
      }
      return remoteConfig.isGiftboxEnabled;
    } catch (e) {
      debugPrint('Error checking giftbox visibility: $e');
      return false;
    }
  }

  Future<void> fetchPromotedApps() async {
    try {
      _isLoading.value = true;
      _lastError.value = '';

      final querySnapshot = await _firestore.collection('promoted_apps').get();

      final apps = querySnapshot.docs
          .map((doc) => PromotedApp.fromFirestore(doc))
          .where((app) => app.isActive)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      _promotedApps.value = apps;

      await _updateBadgeCount(apps);
      await cacheApps(apps);

      debugPrint(
          'Fetched ${apps.length} promoted apps (from ${querySnapshot.docs.length} total)');
    } on FirebaseException catch (e) {
      _lastError.value = e.message ?? 'Error fetching apps';
      debugPrint('Firestore error fetching promoted apps: $e');

      await _loadCachedApps();
    } catch (e) {
      _lastError.value = e.toString();
      debugPrint('Error fetching promoted apps: $e');

      await _loadCachedApps();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadCachedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('promoted_apps_cache');

      if (cachedJson != null) {
        debugPrint('Loaded promoted apps from cache');
      }
    } catch (e) {
      debugPrint('Error loading cached apps: $e');
    }
  }

  Future<void> cacheApps(List<PromotedApp> apps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appIds = apps.map((app) => app.id).toList();
      await prefs.setStringList('promoted_apps_cache_ids', appIds);
      debugPrint('Cached ${apps.length} promoted apps');
    } catch (e) {
      debugPrint('Error caching apps: $e');
    }
  }

  Future<void> _updateBadgeCount(List<PromotedApp> apps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastViewedTimestamp = prefs.getInt(_keyLastViewedTimestamp) ?? 0;
      final viewedAppIds = prefs.getStringList(_keyViewedAppIds) ?? [];

      int newCount = 0;
      for (final app in apps) {
        if (!viewedAppIds.contains(app.id)) {
          newCount++;
        } else if (app.createdAt != null) {
          final appCreatedTime = app.createdAt!.millisecondsSinceEpoch;
          if (appCreatedTime > lastViewedTimestamp) {
            newCount++;
          }
        }
      }

      _badgeCount.value = newCount;
      await prefs.setInt(_keyBadgeCount, newCount);

      debugPrint('Badge count updated: $newCount');
    } catch (e) {
      debugPrint('Error updating badge count: $e');
    }
  }

  Future<void> _loadBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_keyBadgeCount) ?? 0;
      _badgeCount.value = count;
      debugPrint('Loaded badge count: $count');
    } catch (e) {
      debugPrint('Error loading badge count: $e');
    }
  }

  Future<void> markAppsAsViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      final appIds = _promotedApps.map((app) => app.id).toList();

      await prefs.setInt(_keyLastViewedTimestamp, now);
      await prefs.setStringList(_keyViewedAppIds, appIds);

      _badgeCount.value = 0;
      await prefs.setInt(_keyBadgeCount, 0);

      debugPrint('Marked ${appIds.length} apps as viewed');
    } catch (e) {
      debugPrint('Error marking apps as viewed: $e');
    }
  }

  Future<void> trackClick(String appId, String appName) async {
    try {
      String userId = 'anonymous';
      final now = DateTime.now();

      final clickData = {
        'appId': appId,
        'appName': appName,
        'userId': userId,
        'userEmail': userId,
        'clickedAt': Timestamp.fromDate(now),
        'platform': defaultTargetPlatform.toString(),
        'date':
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      };

      try {
        await _firestore.collection(clicksCollection).add(clickData);
        debugPrint('Click saved to Firestore for app: $appName');
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          debugPrint(
              'Permission denied saving click - continuing without Firestore tracking');
        } else {
          debugPrint('Firestore error saving click: ${e.code} - ${e.message}');
        }
      }

      debugPrint('Tracked click for app: $appName (ID: $appId)');
    } catch (e) {
      debugPrint('Error tracking click: $e');
    }
  }

  Future<void> refresh() async {
    await fetchPromotedApps();
  }

  Future<void> initialize() async {
    final shouldShow = await shouldShowGiftbox();
    if (shouldShow) {
      await fetchPromotedApps();
    }
  }
}
