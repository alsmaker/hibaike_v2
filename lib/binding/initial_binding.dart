import 'package:get/get.dart';
import 'package:hibaike_app/controller/bottom_index_controller.dart';
import 'package:hibaike_app/controller/connectivity_controller.dart';
import 'package:hibaike_app/controller/messaging_controller.dart';
import 'package:hibaike_app/controller/sign_controller.dart';

class InitBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(SignController());
    Get.put(BottomIndexController());
    Get.put(ConnectivityController());
    Get.put(MessagingController());
  }
}