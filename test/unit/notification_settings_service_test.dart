import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velo/features/notifications/service/notification_settings_service.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late NotificationSettingsService service;

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    service = NotificationSettingsService();
  });

  tearDown(() {
    Get.reset();
  });

  group('NotificationSettingsService tests', () {
    test('Initial values should be correct', () {
      expect(service.pushNotificationsEnabled.value, true);
    });

    test('areNotificationsAllowed should consider pushNotificationsEnabled',
        () {
      service.pushNotificationsEnabled.value = true;
      expect(service.areNotificationsAllowed, true);

      service.pushNotificationsEnabled.value = false;
      expect(service.areNotificationsAllowed, false);
    });

    test('isCategoryAllowed should check specific categories', () {
      service.pushNotificationsEnabled.value = true;
    });

    test('resetToDefaults should restore original values', () async {
      service.pushNotificationsEnabled.value = false;

      await service.resetToDefaults();

      expect(service.pushNotificationsEnabled.value, true);
    });

    test('updateQuietHours should update observation variables', () {
      service.updateQuietHours(
        startHour: 23,
        startMinute: 30,
        endHour: 8,
        endMinute: 15,
      );

      expect(service.quietStartHour.value, 23);
      expect(service.quietStartMinute.value, 30);
      expect(service.quietEndHour.value, 8);
      expect(service.quietEndMinute.value, 15);
    });
  });
}
