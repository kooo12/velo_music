import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonus/core/constants/app_colors.dart';
import 'package:sonus/core/helper/loaders.dart';
import 'package:sonus/core/models/playlist_model.dart';
import 'package:sonus/widgets/playlist_dialog/playlist_controllers/edit_playlist_controller.dart';

class EditPlaylistDialog extends StatelessWidget {
  final PlaylistModel playlist;
  final Function(String name, String description, String color)
      onUpdatePlaylist;

  const EditPlaylistDialog({
    super.key,
    required this.playlist,
    required this.onUpdatePlaylist,
  });

  @override
  Widget build(BuildContext context) {
    Get.put(EditPlaylistController(), tag: playlist.id);
    final controller = Get.find<EditPlaylistController>(tag: playlist.id);

    controller.playlist = playlist;
    if (controller.nameController.text.isEmpty) {
      controller.nameController.text = playlist.name;
      controller.descriptionController.text = playlist.description ?? '';
      controller.selectedColor.value =
          playlist.colorHex ?? AppColors.musicPrimary.value.toRadixString(16);
    }

    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: controller.scaleAnimation.value,
          child: FadeTransition(
            opacity: controller.fadeAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                // margin: const EdgeInsets.all(20),
                width: 400,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.musicPrimary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Edit Playlist'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: controller.closeDialog,
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: controller.nameController,
                              style: const TextStyle(color: Colors.white),
                              cursorColor: AppColors.white,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                hintText: 'Playlist name'.tr,
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.queue_music,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: controller.descriptionController,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 3,
                              cursorColor: AppColors.white,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                hintText: 'Description (optional)'.tr,
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.description,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Choose Color'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Obx(() => Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: controller.colorOptions.map((color) {
                                  final isSelected =
                                      controller.selectedColor.value ==
                                          color.value.toRadixString(16);
                                  return GestureDetector(
                                    onTap: () => controller.selectColor(color),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 3,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: color.withOpacity(0.5),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 20,
                                            )
                                          : null,
                                    ),
                                  );
                                }).toList(),
                              )),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: controller.closeDialog,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel'.tr,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _updatePlaylist(controller),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.musicPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Update'.tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _updatePlaylist(EditPlaylistController controller) async {
    if (controller.nameController.text.trim().isEmpty) {
      AppLoader.customToast(message: 'Please enter a playlist name');
      // Get.snackbar(
      //   'Error',
      //   'Please enter a playlist name',
      //   backgroundColor: Colors.red.withOpacity(0.8),
      //   colorText: Colors.white,
      // );
      return;
    }

    try {
      await onUpdatePlaylist(
        controller.nameController.text.trim(),
        controller.descriptionController.text.trim(),
        controller.selectedColor.value,
      );

      controller.closeDialog();
    } catch (e) {
      debugPrint("Error updating playlist : ${e.toString()}");
    }
  }
}
