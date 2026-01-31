import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonus/core/constants/app_colors.dart';
import 'package:sonus/core/constants/app_text_theme.dart';
import 'package:sonus/core/constants/appbar_theme.dart';
import 'package:sonus/core/constants/checkbox_theme.dart';
import 'package:sonus/core/constants/chip_theme.dart';
import 'package:sonus/core/constants/elevated_button_theme.dart';
import 'package:sonus/core/constants/text_field_theme.dart';

class ThemeController extends GetxController {
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

  @override
  void onInit() {
    super.onInit();
    _themes = [appThemeData];
  }

  applyNextTheme() {
    (_activeThemeIndex.value + 1) < _themes.length
        ? _activeThemeIndex.value++
        : _activeThemeIndex.value = 0;
    Get.changeTheme(activeTheme);
  }

  setDarkMode(bool status) {
    if (status) {
      Get.changeThemeMode(ThemeMode.dark);
    } else {
      Get.changeThemeMode(ThemeMode.light);
    }
    _isDarkMode.value = status;
  }
}
