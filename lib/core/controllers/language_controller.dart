import 'dart:ui';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonus/core/translations/app_translations.dart';

class LanguageController extends GetxController {
  SharedPreferences? _prefs;
  final RxString _appVersion = ''.obs;

  final _isLoading = false.obs;
  final RxInt _currentLangIndex = 0.obs;

  get isLoading => _isLoading.value;

  Locale get currentLocale => AppTranslation.locales[_currentLangIndex.value];
  String get selectedLanguage => AppTranslation.langs[_currentLangIndex.value];
  RxInt get currentLangIndex => _currentLangIndex;
  String get appVersion => _appVersion.value;

  @override
  void onInit() {
    init();
    super.onInit();
  }

  Future<void> init({SharedPreferences? prefs}) async {
    _isLoading.value = true;
    if (prefs != null) {
      _prefs = prefs;
    } else {
      _prefs = await SharedPreferences.getInstance();
    }

    await _loadLanguagePreference();
    _isLoading.value = false;
  }

  Future<void> _loadLanguagePreference() async {
    String? lang = _prefs?.getString("language");
    if (lang != null && lang.isNotEmpty) {
      int index = AppTranslation.langs.indexOf(lang);
      if (index != -1) {
        _currentLangIndex.value = index;
        Get.updateLocale(AppTranslation.locales[index]);
      } else {
        _currentLangIndex.value = 0;
      }
    } else {
      _currentLangIndex.value = 0;
    }
  }

  Future<void> changeLanguage(String language) async {
    int index = AppTranslation.langs.indexOf(language);
    if (index != -1 && index != _currentLangIndex.value) {
      _currentLangIndex.value = index;
      Locale locale = AppTranslation.locales[index];
      Get.updateLocale(locale);
      await _prefs?.setString("language", language);
    }
  }

  void previousLanguage() {
    if (_currentLangIndex.value > 0) {
      changeLanguage(AppTranslation.langs[_currentLangIndex.value - 1]);
    } else {
      changeLanguage(AppTranslation.langs.last);
    }
  }

  void nextLanguage() {
    if (_currentLangIndex.value < AppTranslation.langs.length - 1) {
      changeLanguage(AppTranslation.langs[_currentLangIndex.value + 1]);
    } else {
      changeLanguage(AppTranslation.langs.first);
    }
  }
}
