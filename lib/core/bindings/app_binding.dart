import 'package:get/get.dart';
import 'package:velo/core/controllers/app_controller.dart';
import 'package:velo/core/controllers/language_controller.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:velo/core/services/fcm_service.dart';
import 'package:velo/core/services/network_manager.dart';
import 'package:velo/core/services/playlist_service.dart';
import 'package:velo/core/services/sleep_timer_service.dart';
import 'package:velo/features/notifications/service/notification_handler_service.dart';
import 'package:velo/features/notifications/service/notification_settings_service.dart';
import 'package:velo/features/promoted_apps/service/promoted_apps_service.dart';
import 'package:velo/core/services/remote_config_service.dart';
import 'package:velo/features/storage_manager/service/storage_service.dart';
import 'package:velo/core/services/version_control_service.dart';
import 'package:velo/features/notifications/controller/notification_settings_controller.dart';
import 'package:velo/features/promoted_apps/controller/promoted_apps_controller.dart';

class AppBinding implements Binding {
  @override
  List<Bind<dynamic>> dependencies() {
    Get.put(ThemeController(), permanent: true);
    Get.put(AppController(), permanent: true);
    Get.put(NetworkManager(), permanent: true);
    Get.put(StorageService(), permanent: true);
    Get.put(LanguageController(), permanent: true);
    Get.put(PlaylistService(), permanent: true);
    // Get.put(AppAudioHandler(), permanent: true);
    Get.put(FCMService(), permanent: true);
    Get.put(NotificationSettingsService(), permanent: true);
    Get.put(NotificationHandlerService(), permanent: true);
    Get.put(NotificationSettingsController(), permanent: true);
    Get.put(SleepTimerService(), permanent: true);
    Get.put(RemoteConfigService(), permanent: true);
    Get.put(VersionControlService(), permanent: true);
    Get.put(PromotedAppsService(), permanent: true);
    Get.put(PromotedAppsController(), permanent: true);

    return [];
  }
}
