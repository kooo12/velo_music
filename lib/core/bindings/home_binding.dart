import 'package:get/get.dart';
import 'package:velo/core/repository/jamendo_repository.dart';
import 'package:velo/features/home/home_controller.dart';
import 'package:velo/features/stream/stream_controller.dart';

class HomeBinding implements Binding {
  @override
  List<Bind<dynamic>> dependencies() {
    Get.put(HomeController(), permanent: true);
    Get.put(JamendoRepository(), permanent: true);
    Get.put(StreamMusicController(), permanent: true);
    return [];
  }
}
