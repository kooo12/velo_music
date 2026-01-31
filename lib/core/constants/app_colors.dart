import 'package:flutter/material.dart';

class AppColors {
  // App theme Colors
  static const Color primary = Color(0xFF235696);
  static const Color secondary = Color.fromARGB(255, 73, 103, 255);

  // Background colors
  static const Color light = Color(0xFFF6F6F6);
  static const Color dark = Color(0xFF272727);
  static const Color primaryBackground = Color(0xFFF3F5FF);

  // Text colors
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textWhite = Colors.white;

  // Button colors
  static const Color buttonPrimary = Color(0xFF4b68ff);
  static const Color buttonSecondary = Color(0xFF6C757D);
  static const Color buttonDisabled = Color(0xFFC4C4C4);

  // Error and validation colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color.fromARGB(255, 18, 210, 28);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  // Neutral Shades
  static const Color black = Color(0xFF232323);
  static const Color darknessGrey = Color.fromARGB(255, 47, 47, 47);
  static const Color darkerGrey = Color(0xFF4F4F4F);
  static const Color darkGrey = Color(0xFF939393);
  static const Color grey = Color(0xFFE0E0E0);
  static const Color softGrey = Color(0xFFF4F4F4);
  static const Color lightGrey = Color(0xFFF9F9F9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color blue = Color(0xFF0797FF);
  static const Color yellow = Color(0xFFFFD600);
  static const Color green = Color.fromARGB(255, 0, 208, 80);

  // Tick color
  static const Color tickOrange = Color(0xFFF86943);

  // Music Player Colors
  static const Color musicPrimary = Color(0xFF0F1035); // Deep Navy
  static const Color musicSecondary = Color(0xFF365486); // Sapphire Blue
  static const Color musicAccent = Color(0xFF7FC7D9); // Mist Blue
  static const Color musicDark = Color(0xFF0F1035);
  static const Color musicLight = Color(0xFFF1F5F9);
  static const Color musicGradientStart = Color(0xFF0F1035);
  static const Color musicGradientEnd = Color(0xFF365486);
  static const Color musicCard = Color(0xFFFFFFFF);
  static const Color musicCardDark = Color(0xFF0F1035);
  static const Color musicText = Color(0xFFFFFFFF);
  static const Color musicTextLight = Color(0xFF7FC7D9);
  static const Color musicBackground = Color(0xFFF1F5F9);
  static const Color musicBackgroundDark = Color(0xFF020617);
  static const Color musicDiscoveryStart = Color(0xFF365486);
  static const Color musicDiscoveryEnd = Color(0xFF7FC7D9);

  static List<Color> primaryGradientColors = [
    musicGradientStart,
    musicGradientEnd,
  ];

  static List<Color> darkGradientColors = [
    darkerGrey,
    darknessGrey,
    darknessGrey,
    dark
  ];
}
