import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonus/core/constants/app_colors.dart';
import 'package:sonus/features/queue/queue_controller.dart';

class QueuePage extends GetView<QueueController> {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _glassButton(
                          icon: Icons.keyboard_arrow_down,
                          onTap: () => Get.back()),
                      const SizedBox(width: 12),
                      Text('Now Playing Queue'.tr,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      GestureDetector(
                        onTap: controller.clearAll,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.18)),
                          ),
                          child: Text('Clear All'.tr,
                              style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.queue.isEmpty) {
                      return Center(
                        child: Text('Queue is empty'.tr,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7))),
                      );
                    }

                    return ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      itemCount: controller.queue.length,
                      onReorder: controller.move,
                      proxyDecorator: (child, index, animation) {
                        return Material(
                            color: Colors.transparent, child: child);
                      },
                      itemBuilder: (context, index) {
                        final song = controller.queue[index];
                        final isCurrent =
                            index == controller.currentIndex.value;
                        return Container(
                          key: ValueKey(song.id),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.14)),
                          ),
                          child: ListTile(
                            onTap: () => controller.playAt(index),
                            leading: CircleAvatar(
                              backgroundColor: isCurrent
                                  ? AppColors.musicPrimary
                                  : Colors.white.withOpacity(0.2),
                              child: Icon(
                                  isCurrent
                                      ? Icons.equalizer
                                      : Icons.music_note,
                                  color: Colors.white),
                            ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7)),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white70),
                                  onPressed: () => controller.removeAt(index),
                                ),
                                const Icon(Icons.drag_handle,
                                    color: Colors.white60),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
