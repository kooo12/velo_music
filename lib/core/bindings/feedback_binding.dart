import 'package:get/get.dart';
import 'package:velo/features/feedbacks/feedback_controller.dart';

class FeedbackBinding implements Binding {
  @override
  List<Bind<dynamic>> dependencies() {
    Get.put(FeedbackController());
    return [];
  }
}
