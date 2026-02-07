import 'dart:ui';

import 'package:get/get.dart';

import 'en_US/en_us_translations.dart';
import 'my_MM/my_mm_translations.dart';

class AppTranslation extends Translations {
  static const locale = Locale('en', 'US');

  static const fallbackLocale = Locale('en', 'US');

  static final langs = [
    'English',
    'မြန်မာ',
  ];

  static final locales = [
    const Locale('en', 'US'),
    const Locale('my', 'MM'),
  ];

  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': enUs,
        'my_MM': mmMm,
      };
}
