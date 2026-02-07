import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sonus/core/repository/appstate_repository.dart';
import 'package:sonus/core/controllers/theme_controller.dart';

class AppController extends GetxController {
  //Initialised properties  --------------------------------------
  final AppStateRepository repository = AppStateRepository();
  AppController();
  final themeCtrl = Get.find<ThemeController>();

  RxString? version = "".obs;
  RxString? buildNumber = "".obs;

  @override
  onInit() async {
    debugPrint("App controller init...");
    await getVersion();
    super.onInit();
    setup().catchError((e, stackTrace) {
      debugPrint('AppController setup error: $e');
      debugPrint('Stack trace: $stackTrace');
    });
  }

//Get version no
  Future<void> getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version!.value = packageInfo.version;
    buildNumber!.value = packageInfo.buildNumber;
  }

  //Getters -------------------------------------------------------
  get runtime => repository.getProperty(AppStateRepository.RuntimeKey) ?? 0;

  //Setters -------------------------------------------------------

  set runtime(value) => repository.runtime = value;
  //Public Methods ( Functions) -----------------------------------

  Future<void> setup() async {
    await repository.fetchProperty();
    await increaseRuntime();
  }

  Future<void> updateTheme() async {
    var darkMode = (repository.getProperty("darkmode") ?? false);
    if (darkMode) {
      themeCtrl.setDarkMode(true);
    }

    return;
  }

  Future<void> increaseRuntime() async {
    await repository.updateProperty(AppStateRepository.RuntimeKey, ++runtime);
    return;
  }
}
