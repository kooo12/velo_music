import 'package:get/get.dart';
import 'package:velo/features/home/home_controller.dart';

class HomeBinding implements Binding {
  @override
  List<Bind<dynamic>> dependencies() {
    Get.put(HomeController(), permanent: true);
    return [];
  }
}
