import 'package:get/get.dart';
import 'package:sonus/features/queue/queue_controller.dart';

class QueueBinding implements Binding {
  @override
  List<Bind<dynamic>> dependencies() {
    Get.put(QueueController());
    return [];
  }
}
