import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonus/core/utils/theme_controller.dart';
import 'package:sonus/features/home/home_controller.dart';

class ProfileView extends GetView<HomeController> {
  ProfileView({super.key});

  final themeCtrl = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile'),
    );
  }
}
