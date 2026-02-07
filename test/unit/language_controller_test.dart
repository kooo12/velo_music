import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonus/core/controllers/language_controller.dart';
import 'package:sonus/core/controllers/theme_controller.dart';
import 'package:sonus/core/translations/app_translations.dart';

class MockThemeController extends Mock implements ThemeController {}

void main() {
  late LanguageController languageController;
  late MockThemeController mockThemeController;

  setUp(() async {
    Get.testMode = true;
    mockThemeController = MockThemeController();

    Get.put<ThemeController>(mockThemeController);

    SharedPreferences.setMockInitialValues({});

    languageController = LanguageController();
    await languageController.init();
  });

  tearDown(() {
    Get.reset();
  });

  group('LanguageController tests', () {
    test('Initial loading state', () async {
      expect(languageController.isLoading, false);
    });

    test('changeLanguage should update locale and persist', () async {
      final testLang = AppTranslation.langs[1];
      final testLocale = AppTranslation.locales[1];

      await languageController.changeLanguage(testLang);

      expect(languageController.selectedLanguage, testLang);
      expect(languageController.currentLocale, testLocale);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('language'), testLang);
    });

    test('changeMode should call ThemeController and persist', () async {
      when(() => mockThemeController.setDarkMode(any())).thenReturn(null);

      await languageController.changeMode(true);

      verify(() => mockThemeController.setDarkMode(true)).called(1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('greyMode'), true);
    });

    test('nextLanguage should cycle forward', () async {
      expect(languageController.currentLangIndex.value, 0);

      languageController.nextLanguage();
      expect(languageController.currentLangIndex.value, 1);

      languageController.nextLanguage();
      expect(languageController.currentLangIndex.value, 0);
    });

    test('previousLanguage should cycle backward', () async {
      expect(languageController.currentLangIndex.value, 0);

      languageController.previousLanguage();
      expect(languageController.currentLangIndex.value,
          AppTranslation.langs.length - 1);
    });
  });
}
