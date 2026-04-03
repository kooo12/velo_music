import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:velo/core/config/app_config.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:velo/core/helper/loaders.dart';

class FeedbackController extends GetxController {
  final themeCtrl = Get.find<ThemeController>();

  static String get formspreeId => AppConfig.formspreeId;
  static String get apiEndpoint => AppConfig.formspreeApiEndpoint;

  final feedbackTextController = TextEditingController();
  final RxInt selectedRating = 0.obs;
  final RxString selectedRatingTitle = ''.obs;
  final RxString selectedCategory = 'Other'.obs;
  final RxBool isSubmitting = false.obs;

  final List<String> categories = ['Bug', 'Feature', 'Other'];
  final List<Map<String, String>> ratingOptions = [
    {'emoji': '😞', 'title': 'Terrible'},
    {'emoji': '😐', 'title': 'Bad'},
    {'emoji': '😊', 'title': 'Good'},
    {'emoji': '🤩', 'title': 'Very Good'},
    {'emoji': '🔥', 'title': 'Excellent'},
  ];

  void setRating(int rating) {
    selectedRating.value = rating;
    selectedRatingTitle.value = ratingOptions[rating - 1]['title']!;
  }

  void setCategory(String category) {
    selectedCategory.value = category;
  }

  bool get isValid =>
      selectedRating.value > 0 && feedbackTextController.text.trim().isNotEmpty;

  void submitFeedback() async {
    if (selectedRating.value == 0) {
      AppLoader.customToast(message: 'Please choose your experience'.tr);
      return;
    }
    if (feedbackTextController.text.trim().isEmpty) {
      AppLoader.customToast(message: 'Please write your feedback'.tr);
      return;
    }

    isSubmitting.value = true;

    var result = await sendViaFormspree(
        experience: selectedRatingTitle.value,
        about: selectedCategory.value,
        feedback: feedbackTextController.text);

    isSubmitting.value = false;

    if (result['success']) {
      selectedRating.value = 0;
      selectedRatingTitle.value = '';
      feedbackTextController.clear();

      Get.back();
      Get.snackbar(
        'Success'.tr,
        'Thank you for your feedback!'.tr,
        snackPosition: SnackPosition.top,
        backgroundColor: themeCtrl.currentAppTheme.value.gradientColors.last,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Failed'.tr,
        'Failed! ${result['message']}'.tr,
        snackPosition: SnackPosition.top,
        backgroundColor: themeCtrl.currentAppTheme.value.gradientColors.last,
        colorText: Colors.white,
      );
    }
  }

  Future<Map<String, dynamic>> sendViaFormspree({
    required String experience,
    required String about,
    required String feedback,
  }) async {
    try {
      var packageInfo = await PackageInfo.fromPlatform();

      final response = await http.post(
        Uri.parse('https://formspree.io/f/$formspreeId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'Experience': experience,
          'About': about,
          'Feedback Message': feedback,
          'Version': packageInfo.version,
          'Build Number': packageInfo.buildNumber,
          'Package Name': packageInfo.packageName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Thank you for your feedback!',
        };
      } else {
        String errorMessage = 'Failed to send feedback. Please try again.';
        try {
          if (response.headers['content-type']?.contains('application/json') ??
              false) {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['error'] ?? errorMessage;
          }
        } catch (e) {
          return {'error': false, 'message': errorMessage};
        }
        return {'error': false, 'message': errorMessage};
      }
    } catch (e) {
      return {'error': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  @override
  void onClose() {
    feedbackTextController.dispose();
    super.onClose();
  }
}
