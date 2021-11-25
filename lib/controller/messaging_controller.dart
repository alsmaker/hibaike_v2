import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class MessagingController extends GetxController {
  static MessagingController get to => Get.find();

  final Rxn<RemoteMessage> message = Rxn<RemoteMessage>();

  @override
  void onInit() {
    initialize();
  }

  Future<bool> initialize() async {
    // Firebase 초기화부터 해야 FirebaseMessaging 를 사용할 수 있다.
    //await Firebase.initializeApp();

    // Android 에서는 별도의 확인 없이 리턴되지만, requestPermission()을 호출하지 않으면 수신되지 않는다.
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );

    // Android용 새 Notification Channel
    const AndroidNotificationChannel androidNotificationChannel = AndroidNotificationChannel(
      'hibaike_notification_channel', // 임의의 id
      'High Importance Notifications', // 설정에 보일 채널명
      'This channel is used for important notifications.', // 설정에 보일 채널 설명
      importance: Importance.max,
    );

    // Notification Channel을 디바이스에 생성
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);

    FirebaseMessaging.onMessage.listen((RemoteMessage rm) {
      message.value = rm;
      RemoteNotification notification = rm.notification;
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('app opened with touching notifications');
      List<String> argumentList = [message.data['bikeId'], message.data['peerId'], message.data['peerNickname']];
      Get.toNamed('/chat', arguments: argumentList);
    });

    return true;
  }
}