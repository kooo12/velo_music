import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velo/features/notifications/service/notification_handler_service.dart';
import 'package:velo/features/notifications/service/notification_settings_service.dart';
import 'package:velo/features/notifications/controller/notification_settings_controller.dart';

class MockNotificationHandlerService extends Mock
    implements NotificationHandlerService {}

class MockNotificationSettingsService extends Mock
    implements NotificationSettingsService {}

void main() {
  late NotificationSettingsController controller;
  late MockNotificationHandlerService mockHandlerService;
  late MockNotificationSettingsService mockSettingsService;

  setUp(() {
    Get.testMode = true;
    mockHandlerService = MockNotificationHandlerService();
    mockSettingsService = MockNotificationSettingsService();

    when(() => mockSettingsService.pushNotificationsEnabled)
        .thenReturn(false.obs);
    when(() => mockSettingsService.notificationSound).thenReturn(false.obs);
    when(() => mockSettingsService.notificationVibration).thenReturn(false.obs);
    when(() => mockSettingsService.sleepTimerNotifications)
        .thenReturn(false.obs);
    when(() => mockSettingsService.quietHoursEnabled).thenReturn(false.obs);
    when(() => mockSettingsService.quietStartHour).thenReturn(22.obs);
    when(() => mockSettingsService.quietStartMinute).thenReturn(0.obs);
    when(() => mockSettingsService.quietEndHour).thenReturn(7.obs);
    when(() => mockSettingsService.quietEndMinute).thenReturn(0.obs);

    when(() => mockSettingsService.saveSettings()).thenAnswer((_) async => {});

    Get.put<NotificationHandlerService>(mockHandlerService);
    Get.put<NotificationSettingsService>(mockSettingsService);

    controller = NotificationSettingsController();
    controller.onInit();
  });

  tearDown(() {
    Get.reset();
  });

  group('NotificationSettingsController tests', () {
    test('Initial state should match service', () {
      expect(controller.pushNotificationsEnabled.value, false);
    });

    test('togglePushNotifications should update service and save', () {
      controller.togglePushNotifications(true);

      expect(controller.pushNotificationsEnabled.value, true);
      verify(() => mockSettingsService.saveSettings()).called(1);
    });

    test('toggleQuietHours should update service and save', () {
      controller.toggleQuietHours(true);

      expect(controller.quietHoursEnabled.value, true);
      verify(() => mockSettingsService.saveSettings()).called(1);
    });
  });
}
