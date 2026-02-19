import 'package:flutter/material.dart';

class AppTheme {
  final String id;
  final String name;
  final List<Color> gradientColors;
  final bool isDark;
  final ThemeData themeData;

  const AppTheme({
    required this.id,
    required this.name,
    required this.gradientColors,
    required this.isDark,
    required this.themeData,
  });
}
