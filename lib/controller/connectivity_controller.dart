import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:connectivity/connectivity.dart';

class ConnectivityController extends GetxController {
  @override
  void onInit() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if(result == ConnectivityResult.none) {
        Fluttertoast.showToast(
          msg: '네크워크 상태가 원할하지 않습니다. 연결을 확인해주세요',
          timeInSecForIosWeb: 3,
        );
      }
    });
    super.onInit();
  }
}