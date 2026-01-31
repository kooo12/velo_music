import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonus/core/constants/app_colors.dart';

class CreatePlaylistController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  late AnimationController animationController;
  late Animation<double> scaleAnimation;
  late Animation<double> fadeAnimation;

  final RxString selectedColor =
      AppColors.musicPrimary.value.toRadixString(16).obs;

  final List<Color> colorOptions = [
    AppColors.musicPrimary,
    AppColors.musicSecondary,
    AppColors.musicAccent,
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
  ];

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutBack,
    ));
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ));
    animationController.forward();
  }

  @override
  void onClose() {
    animationController.dispose();
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  void selectColor(Color color) {
    selectedColor.value = color.value.toRadixString(16);
  }

  void closeDialog() {
    animationController.reverse().then((_) {
      Get.back();
    });
    Navigator.of(Get.overlayContext!).pop();
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
