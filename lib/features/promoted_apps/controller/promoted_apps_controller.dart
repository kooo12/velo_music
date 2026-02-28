import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:velo/core/services/remote_config_service.dart';
import '../service/promoted_apps_service.dart';

class PromotedAppsController extends GetxController {
  final PromotedAppsService _promotedAppsService =
      Get.find<PromotedAppsService>();

  final RxBool _shouldShowGiftbox = false.obs;
  final RxBool _isShaking = false.obs;

  RxBool get shouldShowGiftboxRx => _shouldShowGiftbox;
  bool get shouldShowGiftbox => _shouldShowGiftbox.value;
  bool get isShaking => _isShaking.value;
  RxInt get badgeCount => _promotedAppsService.badgeCount;
  bool get isLoading => _promotedAppsService.isLoading;
  List get promotedApps => _promotedAppsService.promotedApps;

  @override
  void onInit() {
    super.onInit();
    _setupReactiveListener();
    _initialize();
  }

  void _setupReactiveListener() {
    try {
      if (Get.isRegistered<RemoteConfigService>()) {
        final remoteConfigService = Get.find<RemoteConfigService>();
        ever(remoteConfigService.giftboxEnabled, (bool enabled) {
          debugPrint('Giftbox enabled state changed reactively: $enabled');
          _shouldShowGiftbox.value = enabled;

          if (enabled) {
            _promotedAppsService.fetchPromotedApps();
            _startShakeAnimation();
          } else {
            _promotedAppsService.promotedApps.clear();
          }
        });
      }
    } catch (e) {
      debugPrint('Error setting up reactive listener: $e');
    }
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(seconds: 3));

    final shouldShow = await _promotedAppsService.shouldShowGiftbox();
    _shouldShowGiftbox.value = shouldShow;

    debugPrint('Giftbox visibility check: $shouldShow');

    if (_shouldShowGiftbox.value) {
      await _promotedAppsService.fetchPromotedApps();
      _startShakeAnimation();
      debugPrint(
          'Giftbox enabled - fetched ${_promotedAppsService.promotedApps.length} apps');
    } else {
      debugPrint(
          'Giftbox disabled - check Remote Config: show_giftbox_icon and giftbox_apps_enabled');
      Future.delayed(const Duration(seconds: 5), () async {
        final retryShouldShow = await _promotedAppsService.shouldShowGiftbox();
        if (retryShouldShow != _shouldShowGiftbox.value) {
          _shouldShowGiftbox.value = retryShouldShow;
          if (retryShouldShow) {
            await _promotedAppsService.fetchPromotedApps();
            _startShakeAnimation();
            debugPrint(
                'Giftbox enabled on retry - fetched ${_promotedAppsService.promotedApps.length} apps');
          }
        }
      });
    }
  }

  void _startShakeAnimation() {
    if (_promotedAppsService.badgeCount.value > 0) {
      _animateShake();
    }
  }

  void _animateShake() {
    if (_promotedAppsService.badgeCount.value == 0) {
      _isShaking.value = false;
      return;
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (_promotedAppsService.badgeCount.value > 0) {
        _isShaking.value = true;

        Future.delayed(const Duration(milliseconds: 500), () {
          _isShaking.value = false;
          _animateShake();
        });
      }
    });
  }

  Future<void> refreshGiftboxVisibility() async {
    _shouldShowGiftbox.value = await _promotedAppsService.shouldShowGiftbox();

    if (_shouldShowGiftbox.value) {
      await _promotedAppsService.fetchPromotedApps();
      _startShakeAnimation();
    }
  }

  void openAppList() {
    _promotedAppsService.markAppsAsViewed();
    _isShaking.value = false;
  }

  Future<void> refreshApps() async {
    await _promotedAppsService.refresh();
    _startShakeAnimation();
  }
}
