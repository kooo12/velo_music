import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velo/core/constants/app_colors.dart';
import 'package:velo/core/constants/app_text_theme.dart';
import 'package:velo/core/constants/appbar_theme.dart';
import 'package:velo/core/constants/checkbox_theme.dart';
import 'package:velo/core/constants/chip_theme.dart';
import 'package:velo/core/constants/elevated_button_theme.dart';
import 'package:velo/core/constants/text_field_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velo/core/models/app_theme.dart';

class ThemeController extends GetxController {
  static const String _themeKey = 'selected_theme_id';
  final _activeThemeIndex = 0.obs;

  final ThemeData appThemeData = ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.musicPrimary,
    secondaryHeaderColor: AppColors.darkGrey,
    highlightColor: AppColors.white,
    iconTheme: const IconThemeData(color: Colors.white),
    textTheme: AppTextTheme.darkTextTheme,
    appBarTheme: AppAppBarTheme.darkAppBarTheme,
    elevatedButtonTheme: AppElevatedButtonTheme.darkElevatedButtonTheme,
    inputDecorationTheme: AppTextFormFieldTheme.darkInputDecorationTheme,
    checkboxTheme: AppCheckboxTheme.darkCheckboxTheme,
    chipTheme: AppChipTheme.darkChipTheme,
    cardColor: Colors.black,
    cardTheme: const CardTheme(color: Colors.white),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: AppColors.darkGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: AppColors.darkGrey),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: AppColors.grey),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),
      menuStyle: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.dark),
      ),
      textStyle: AppTextTheme.darkTextTheme.bodyLarge,
    ),
    scaffoldBackgroundColor: AppColors.white,
    shadowColor: Colors.black,
  );

  final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    primaryColor: AppColors.primary,
    secondaryHeaderColor: AppColors.darkerGrey,
    highlightColor: AppColors.black,
    shadowColor: Colors.white,
    textTheme: AppTextTheme.darkTextTheme,
    appBarTheme: AppAppBarTheme.darkAppBarTheme,
    elevatedButtonTheme: AppElevatedButtonTheme.darkElevatedButtonTheme,
    inputDecorationTheme: AppTextFormFieldTheme.darkInputDecorationTheme,
    checkboxTheme: AppCheckboxTheme.darkCheckboxTheme,
    chipTheme: AppChipTheme.darkChipTheme,
    iconTheme: const IconThemeData(color: Colors.white),
    cardColor: Colors.black,
    cardTheme: const CardTheme(color: Colors.black),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: AppColors.darkGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: AppColors.darkGrey),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: AppColors.grey),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),
      menuStyle: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.darkerGrey),
      ),
      textStyle: AppTextTheme.darkTextTheme.bodyLarge,
    ),
  );

  var _themes = <ThemeData>[];
  final _isDarkMode = false.obs;

  ThemeData get activeTheme =>
      isDarkMode ? darkTheme : _themes[_activeThemeIndex.value];

  final Color menuColor = Colors.white;

  get isDarkMode => _isDarkMode.value;

  final RxList<AppTheme> appThemes = <AppTheme>[].obs;
  late Rx<AppTheme> currentAppTheme;

  @override
  void onInit() {
    super.onInit();
    _themes = [appThemeData];
    _populateThemes();
  }

  void _populateThemes() {
    appThemes.value = [
      AppTheme(
        id: 'forest_mist',
        name: 'Forest Mist'.tr,
        gradientColors: AppColors.forestMistGradient,
        isDark: true,
        themeData: darkTheme,
      ),
      AppTheme(
        id: 'ocean_blue',
        name: 'Ocean Blue'.tr,
        gradientColors: AppColors.oceanBlueGradient,
        isDark: false,
        themeData: appThemeData,
      ),
      AppTheme(
        id: 'dark_night',
        name: 'Dark Night'.tr,
        gradientColors: AppColors.darkNightGradient,
        isDark: true,
        themeData: darkTheme,
      ),
      AppTheme(
        id: 'purple_haze',
        name: 'Purple Haze'.tr,
        gradientColors: AppColors.purpleHazeGradient,
        isDark: true,
        themeData: darkTheme,
      ),
      AppTheme(
        id: 'sunset_vibes',
        name: 'Sunset Vibes'.tr,
        gradientColors: AppColors.sunsetVibesGradient,
        isDark: false,
        themeData: appThemeData,
      ),
      AppTheme(
        id: 'royal_gold',
        name: 'Royal Gold'.tr,
        gradientColors: AppColors.royalGoldGradient,
        isDark: true,
        themeData: darkTheme,
      ),
      AppTheme(
        id: 'crimson_tide',
        name: 'Crimson Tide'.tr,
        gradientColors: AppColors.crimsonTideGradient,
        isDark: true,
        themeData: darkTheme,
      ),
      AppTheme(
        id: 'midnight_green',
        name: 'Midnight Green'.tr,
        gradientColors: AppColors.midnightGreenGradient,
        isDark: true,
        themeData: darkTheme,
      ),
      AppTheme(
        id: 'aurora_borealis',
        name: 'Aurora Borealis'.tr,
        gradientColors: AppColors.auroraBorealisGradient,
        isDark: false,
        themeData: appThemeData,
      ),
      AppTheme(
        id: 'cherry_blossom',
        name: 'Cherry Blossom'.tr,
        gradientColors: AppColors.cherryBlossomGradient,
        isDark: false,
        themeData: appThemeData,
      ),
      AppTheme(
        id: 'electric_violet',
        name: 'Electric Violet'.tr,
        gradientColors: AppColors.electricVioletGradient,
        isDark: true,
        themeData: darkTheme,
      ),
    ];
    currentAppTheme = appThemes[0].obs;
  }

  void cycleTheme() {
    int currentIndex = appThemes.indexOf(currentAppTheme.value);
    int nextIndex = (currentIndex + 1) % appThemes.length;
    setTheme(appThemes[nextIndex]);
  }

  void setTheme(AppTheme theme, {bool save = true}) {
    currentAppTheme.value = theme;
    Get.changeTheme(theme.themeData);
    _isDarkMode.value = theme.isDark;

    if (save) {
      _saveTheme(theme.id);
    }
  }

  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeId = prefs.getString(_themeKey);

      if (savedThemeId != null && appThemes.isNotEmpty) {
        final savedTheme = appThemes.firstWhere(
          (t) => t.id == savedThemeId,
          orElse: () => appThemes[0],
        );
        setTheme(savedTheme, save: false);
        debugPrint('ThemeController loaded theme: ${savedTheme.name}');
      }
    } catch (e) {
      debugPrint('Error loading theme in ThemeController: $e');
    }
  }

  Future<void> _saveTheme(String themeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeId);
      debugPrint('Successfully saving theme: $themeId');
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  setDarkMode(bool status) {
    final theme = appThemes.firstWhere(
      (t) => t.isDark == status,
      orElse: () => appThemes[0],
    );
    setTheme(theme);
  }
}
