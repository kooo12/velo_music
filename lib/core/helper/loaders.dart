import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:velo/core/constants/app_colors.dart';
import 'package:velo/core/constants/sizes.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:velo/core/constants/constants.dart';

class AppLoader {
  static void openSavingLoading(String text, {bool dismissible = false}) {
    showDialog(
        barrierDismissible: dismissible,
        context: Get.context!,
        builder: (_) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final textWidth = (TextPainter(
                    text: TextSpan(
                      text: text.tr,
                      style: themeController.activeTheme.textTheme.titleLarge!
                          .copyWith(color: AppColors.white),
                    ),
                    maxLines: 1,
                    textDirection: TextDirection.ltr,
                  )..layout())
                      .size
                      .width +
                  150;

              final dialogWidth =
                  (textWidth < 100 ? 200 : textWidth).toDouble();
              // print("Dialog $dialogWidth");
              // print('Text $textWidth');

              return Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: dialogWidth,
                  child: Dialog(
                    backgroundColor: AppColors.black.withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.borderRadiusMd),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                          const SizedBox(
                            height: AppSizes.spaceBtwItems,
                          ),
                          Text(
                            text.tr,
                            style: themeController
                                .activeTheme.textTheme.titleLarge!
                                .copyWith(color: AppColors.white),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        });
    // showDialog(
    //   context: Get.context!,
    //   barrierDismissible: false,
    //   builder: (BuildContext context) {
    //     return Align(
    //       alignment: Alignment.center,
    //       child: Container(
    //         width: 200.0, // Set the width to your desired size
    //         child: Dialog(
    //           backgroundColor: Colors.grey[700], // Customize as needed
    //           shape: RoundedRectangleBorder(
    //             borderRadius: BorderRadius.circular(12.0),
    //           ),
    //           child: Padding(
    //             padding: EdgeInsets.all(20.0),
    //             child: Column(
    //               mainAxisSize: MainAxisSize.min,
    //               children: [
    //                  ModalCircularProgressIndicator(
    //                   valueColor: AlwaysStoppedAnimation<Color>(
    //                       Colors.blue), // Customize color as needed
    //                 ),
    //                 SizedBox(height: 15.0),
    //                 Text(
    //                   "Please wait ...",
    //                   style: TextStyle(
    //                       color: Colors.white,
    //                       fontSize: 16.0), // Customize text style
    //                 ),
    //               ],
    //             ),
    //           ),
    //         ),
    //       ),
    //     );
    //   },
    // );
  }

  static stopLoading() {
    Navigator.of(Get.overlayContext!).pop();
  }

  static hideSnackBar() =>
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
  static final themeController = Get.find<ThemeController>();

  static customToast({required String message, int duration = 1600}) {
    final ctx = Get.context!;
    final themeCtrl = Get.find<ThemeController>();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        elevation: 0,
        duration: Duration(milliseconds: duration),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: ResponsiveContext(ctx).isTabletLandscape ? 200 : 20,
          right: ResponsiveContext(ctx).isTabletLandscape ? 200 : 20,
        ),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: themeCtrl.currentAppTheme.value.gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.musicPrimary.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: themeController.activeTheme.textTheme.bodyMedium
                      ?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.fade,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // static successSnackBar({required title, message = '', duration = 3}) {
  //   Get.snackbar(title, message,
  //       isDismissible: true,
  //       shouldIconPulse: true,
  //       colorText: AppColors.white,
  //       backgroundColor: AppColors.blue,
  //       snackPosition: SnackPosition.bottom,
  //       duration: Duration(seconds: duration),
  //       margin: const EdgeInsets.all(10),
  //       icon: const Icon(
  //         Iconsax.check,
  //         color: AppColors.white,
  //       ));
  // }

  static warningSanckBar({required title, message = ''}) {
    Get.snackbar(title, message,
        isDismissible: true,
        shouldIconPulse: true,
        colorText: AppColors.white,
        backgroundColor: Colors.orange,
        snackPosition: SnackPosition.bottom,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(20),
        icon: const Icon(
          Iconsax.warning_2,
          color: AppColors.white,
        ));
  }

  static errorSanckBar({required title, message = ''}) {
    Get.snackbar(title, message,
        isDismissible: true,
        shouldIconPulse: true,
        colorText: AppColors.white,
        backgroundColor: Colors.red.shade600,
        snackPosition: SnackPosition.bottom,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(20),
        icon: const Icon(
          Iconsax.warning_2,
          color: AppColors.white,
        ));
  }
}
