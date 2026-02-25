import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sonus/core/services/audio_service.dart' as svc;

class AppAudioSession extends GetxService {
  Future<void> configure() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    session.becomingNoisyEventStream.listen((_) {
      try {
        final player = Get.find<svc.AudioPlayerService>();
        player.pause();
      } catch (e) {
        debugPrint('Error pausing on becoming noisy: $e');
      }
    });

    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        try {
          final player = Get.find<svc.AudioPlayerService>();
          player.pause();
        } catch (e) {
          debugPrint('Error pausing on interruption: $e');
        }
      } else {
        try {
          final player = Get.find<svc.AudioPlayerService>();
          player.play();
        } catch (e) {
          debugPrint('Error resuming on interruption end: $e');
        }
      }
    });
  }
}
