import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonus/core/services/storage_service.dart';
import 'package:sonus/features/storage_manager/storage_controller.dart';

class StorageManagerPage extends StatelessWidget {
  const StorageManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<StorageService>()) {
      Get.put(StorageService());
    }
    final controller = Get.put(StorageController(Get.find<StorageService>()));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Storage',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Obx(() => TextButton.icon(
                            onPressed: controller.isScanning.value
                                ? null
                                : controller.scanAllSongsAndDetectFolders,
                            icon: controller.isScanning.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.search, color: Colors.white),
                            label: Text(
                              controller.isScanning.value
                                  ? 'Scanning...'
                                  : 'Scan Device',
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.folder_special,
                                      color: Colors.white70),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Scan Folders',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: controller.addFolder,
                                    icon: const Icon(Icons.add,
                                        color: Colors.white),
                                    label: const Text('Add',
                                        style: TextStyle(color: Colors.white)),
                                    style: TextButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withOpacity(0.08),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Obx(() {
                                  final items = controller.scanFolders;
                                  if (items.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        'No folders selected. Add folders to scan for music.',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    );
                                  }
                                  return ListView.separated(
                                    itemCount: items.length,
                                    separatorBuilder: (_, __) => Divider(
                                        color: Colors.white.withOpacity(0.1)),
                                    itemBuilder: (context, index) {
                                      final path = items[index];
                                      return Row(
                                        children: [
                                          const Icon(Icons.folder,
                                              color: Colors.white70, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              path,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          // Check if folder is protected
                                          if (!controller
                                              .isProtectedFolder(path))
                                            IconButton(
                                              tooltip: 'Remove',
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.white70),
                                              onPressed: () async {
                                                await controller
                                                    .removeFolder(path);
                                              },
                                            )
                                          else
                                            const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Icon(
                                                Icons.lock,
                                                color: Colors.white38,
                                                size: 18,
                                              ),
                                            )
                                        ],
                                      );
                                    },
                                  );
                                }),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // const Spacer(),
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton.icon(
                  //     onPressed: () async {
                  //       await controller.save();
                  //     },
                  //     icon: const Icon(Icons.save_outlined),
                  //     label: const Text('Save'),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.white.withOpacity(0.15),
                  //       foregroundColor: Colors.white,
                  //       shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(14)),
                  //       padding: const EdgeInsets.symmetric(vertical: 14),
                  //     ),
                  //   ),
                  // )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
