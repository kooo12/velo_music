import 'package:get/get.dart';
import 'package:velo/features/radio/radio_controller.dart';

class RadioBinding implements Binding {
  @override
  List<Bind<dynamic>> dependencies() {
    Get.put(RadioController());

    return [];
  }
}
