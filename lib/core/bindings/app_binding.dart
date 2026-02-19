import 'package:get/get.dart';
import 'package:sonus/core/controllers/app_controller.dart';
import 'package:sonus/core/controllers/language_controller.dart';
import 'package:sonus/core/controllers/theme_controller.dart';
import 'package:sonus/core/services/audio_service.dart';
import 'package:sonus/core/services/fcm_service.dart';
import 'package:sonus/core/services/network_manager.dart';
import 'package:sonus/core/services/notification_handler_service.dart';
import 'package:sonus/core/services/notification_settings_service.dart';
import 'package:sonus/features/notifications/notification_settings_controller.dart';

class AppBinding implements Binding {
  @override
  List<Bind<dynamic>> dependencies() {
    Get.put(ThemeController(), permanent: true);
    Get.put(AppController(), permanent: true);
    Get.put(NetworkManager(), permanent: true);
    Get.put(LanguageController(), permanent: true);
    Get.put(AudioPlayerService(), permanent: true);
    Get.put(FCMService(), permanent: true);
    Get.put(NotificationSettingsService(), permanent: true);
    Get.put(NotificationHandlerService(), permanent: true);
    Get.put(NotificationSettingsController(), permanent: true);

    return [];
  }
}
