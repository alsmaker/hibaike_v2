import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:hibaike_app/component/storage_manager.dart';
import 'package:hibaike_app/controller/bottom_index_controller.dart';
import 'package:hibaike_app/model/users.dart';
import 'package:sms_autofill/sms_autofill.dart';

class SignController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  CollectionReference ref = FirebaseFirestore.instance.collection('users');
  RxString _verificationId = ''.obs;
  RxBool isSignIn = false.obs;
  RxBool isFirebaseSignIn = false.obs;
  String globalUSNumber;
  String localKoreaNumber;
  String nickName;
  String uid;

  // most important
  Rx<Users> currentUser = Users().obs;

  // for used to sms auto fill
  String smsCode = '';
  final SmsAutoFill _smsAutoFill = SmsAutoFill();

  // for used to profile image
  File profileImageFile;
  FirebaseStorageManager _firebaseStorageManager = FirebaseStorageManager();

  // for used to timer
  var _timer;
  RxInt timerSecond = 0.obs;

  // for sign in
  RxBool enablePhoneNumberField = true.obs;
  RxBool enablePinNumberField = false.obs;
  bool flushTextField = false;
  // for sign up
  RxBool enableRegister = false.obs;

  @override
  void onInit() {
    FirebaseMessaging.instance.getToken();
    FirebaseAuth.instance.authStateChanges().listen((User user) {
      print('authStateChanges called');
      if(user == null) {
        print('User is currently sign out');
        isFirebaseSignIn.value = false;
        isSignIn.value = false;
      }
      else {
        isFirebaseSignIn.value = true;
        print(user.phoneNumber);
        bringUserDataByPhoneNum(user.phoneNumber, user);
      }
    });

    initializeSignCtrl();

    super.onInit();
  }

  void initializeSignCtrl() {
    globalUSNumber = '';
    localKoreaNumber = '';
    smsCode = '';

    enablePhoneNumberField(true);
    enablePinNumberField(false);
    enableRegister(false);

    if(_timer != null) {
      _timer.cancel();
      _timer = null;
    }

    timerSecond.value = 0;

    profileImageFile = null;
  }

  bringUserDataByPhoneNum(String phoneNumber, User user) async {
    QuerySnapshot snapshot = await ref.where('us_phone_number', isEqualTo: phoneNumber).get();

    // firestore 에 등록이 되어 있는 경우에는 current user 로딩하고 custom 로그인 처리
    if(snapshot.docs.length != 0) {
      print('firebase sign in + custom sign in success');

      currentUser.value = Users.fromJson(snapshot.docs[0].data());

      // push token 변경이 있는지 확인
      String pushToken = await FirebaseMessaging.instance.getToken();
      print('push token : $pushToken');
      if(currentUser.value.pushToken == null || pushToken != currentUser.value.pushToken)
        FirebaseFirestore.instance.collection('users').doc(currentUser.value.uid).update(
            {'push_token': pushToken,});

      isSignIn.value = true;
    }
    // firestore 에 등록이 되어 있지 않으면 닉네임,프로필 사진 등록 화면으로 이동
    else {
      //signOut();
      print('firebase sign in, but custom sign in is fail');
      uid = user.uid;
      globalUSNumber = user.phoneNumber;
      localKoreaNumber = globalUSNumber.replaceFirst('+82', '0');
      isSignIn.value = false;
      Get.toNamed('/sign_up');
    }
  }

  // 사용자 최초 등록
  Future<String> registerUserToDatabase() async{
    List<String> defaultWatchList = [];
    String downloadUrl = '';

    if(profileImageFile != null) {
      downloadUrl = await _firebaseStorageManager.updateProfileImage(
          uid, "profile", profileImageFile);

      if(downloadUrl.length == 0) {
        Fluttertoast.showToast(msg: '프로필 사진등록에 실패하였습니다');
      }
    }

    // push token setting
    String pushToken = await FirebaseMessaging.instance.getToken();
    print('push token : $pushToken');

    await FirebaseFirestore.instance.collection('users').doc(uid).set(Users(
      globalUSNumber: globalUSNumber,
      localKoreaNumber: localKoreaNumber,
      nickName: nickName,
      grade: "individual",
      uid: uid,
      profileImageUrl: downloadUrl,
      shopId: '',
      watchList: defaultWatchList,
      pushToken: pushToken,
    ).
    toJson());

    isSignIn.value = true;

    // 데이터베이스 등록 후 current user data 세팅
    if(currentUser.value.uid == null) {
      DocumentSnapshot snapshot = await ref.doc(uid).get();

      if(snapshot.data().length == 0) {
        print('cannot reload : user data is not stored in firestore');
      }

      currentUser.value = Users.fromJson(snapshot.data());
    }

    return 'USER_REGISTRATION_DONE';
  }

  updateUserDataByPhoneNumber(String phoneNumber) async {
    QuerySnapshot snapshot = await ref.where('us_phone_number', isEqualTo: phoneNumber).get();

    if(snapshot.docs.length != 0) {
      currentUser.value = Users.fromJson(snapshot.docs[0].data());
      isSignIn.value = true;
    }
    else {
      signOut();
      isSignIn.value = false;
    }
  }

  reloadUserDataByUid() async{
    if(currentUser != null) {
      DocumentSnapshot snapshot = await ref.doc(currentUser.value.uid).get();

      if(snapshot.data().length == 0) {
        print('cannot reload : user data is not in database');
      }

      currentUser.value = Users.fromJson(snapshot.data());
    }
  }

  updateWatchList(String bikeKey) {
    bool isInWatchList = currentUser.value.watchList.contains(bikeKey);

    if(isInWatchList) {
      print('remove bike in watch list');
      FirebaseFirestore.instance.collection('users').doc(
          currentUser.value.uid)
          .update({
        'watch_list': FieldValue.arrayRemove([bikeKey])
      });

      //currentUser.value.watchList.remove(bikeKey);
      reloadUserDataByUid();
    }
    else {
      print('add bike in watch list');
      FirebaseFirestore.instance.collection('users').doc(
          currentUser.value.uid)
          .update({
        'watch_list': FieldValue.arrayUnion([bikeKey])
      });
      //currentUser.value.watchList.add(bikeKey);
      reloadUserDataByUid();
    }
  }

  Future<void> updateUserGrade(String grade) async {
    await FirebaseFirestore.instance.collection('users').doc(currentUser.value.uid)
        .update({'grade': grade});

    reloadUserDataByUid();
  }

  Future<void> updateShopId(String shopId) async {
    await FirebaseFirestore.instance.collection('users').doc(currentUser.value.uid)
        .update({'shop_id': shopId});

    reloadUserDataByUid();
  }

  Future<void> updateBikeList(String bikeId) async {
    await FirebaseFirestore.instance.collection('users').doc(
        currentUser.value.uid)
        .update({
      'bike_list': FieldValue.arrayUnion([bikeId])
    });

    reloadUserDataByUid();
  }

  Future<bool> checkNickNameInDatabase(String value) async {
    var snapshot = await ref.where("nick_name", isEqualTo: value).get();

    print('nickname doc.size = ${snapshot.size}');

    if (snapshot.size == 1)
      return true;
    else if (snapshot.size == 0)
      return false;
    else {
      print('duplicate nick registered');// size가 2이상이면 문제임
      return false;
    }
  }

  Future<bool> checkIdInDatabase() async {
    var snapshot = await ref.where("us_phone_number", isEqualTo: globalUSNumber).get();

    print('phone number(id) doc.size = ${snapshot.size}');

    if (snapshot.size == 1)
      return true;
    else if (snapshot.size == 0)
      return false;
    else {
      print('duplicate id registered'); // size가 2이상이면 문제임
      return false;
    }
  }

  void _updateProfileImageUrl(String downloadUrl) {
    ref.doc(currentUser.value.uid).update({"profile_image_url": downloadUrl});
  }



  Future<void> updateNickname(String nickname) async{
    print(nickname);
    await ref.doc(currentUser.value.uid).update({
      'nick_name': nickname
    });

    updateUserDataByPhoneNumber(currentUser.value.globalUSNumber);
  }

  Future<String> replaceProfileImage(File newImageFile) async {
    String downloadUrl;
    if(newImageFile != null) {
      // UploadTask task = _firebaseStorageManager.uploadProfileImage(
      //     currentUser.value.uid, "profile", newImageFile);
      // task.snapshotEvents.listen((event) async{
      //   if(event.bytesTransferred == event.totalBytes) {
      //     downloadUrl = await event.ref.getDownloadURL();
      //     _updateProfileImageUrl(downloadUrl);
      //     bringUserDataByPhoneNum(currentUser.value.USPhoneNumber);
      //   }
      // });
      downloadUrl = await _firebaseStorageManager.updateProfileImage(
          currentUser.value.uid, "profile", newImageFile);

      if(downloadUrl.length == 0) {
        Fluttertoast.showToast(msg: '프로필 사진등록에 실패하였습니다');
      }

      _updateProfileImageUrl(downloadUrl);
      updateUserDataByPhoneNumber(currentUser.value.globalUSNumber);
    }
    else {
      _updateProfileImageUrl('');
    }

    print('update profile image done');

    //return downloadUrl;
    return 'done';
  }

  Future<String> bringPhoneNumByAutoFill() async{
    globalUSNumber = await _smsAutoFill.hint;
    if(globalUSNumber != null && globalUSNumber.length != 0)
      localKoreaNumber = globalUSNumber.replaceAll('+82', '0');
    return localKoreaNumber;
  }

  verifyPhoneNumber() async{
    // 폰번호를 직접 입력하는 경우에 대한 validate
    //if(globalUSNumber == null || globalUSNumber.length == 0) {
    if(globalUSNumber != localKoreaNumber.replaceFirst('0', '+82')) {
      if(localKoreaNumber.length != 0) {
        if(localKoreaNumber.startsWith('0')) {
          globalUSNumber = localKoreaNumber.replaceFirst('0', '+82');
        }
      }
    }

    // 폰번호 입력창 & 휴대폰 번호로 인증하기 버튼 disable
    enablePhoneNumberField(false);
    // timer start
    smsTimer();

    PhoneVerificationCompleted verificationCompleted =
        (PhoneAuthCredential credential) async {
      await _auth.signInWithCredential(credential);
      print('firebase auth verification completed');

      bool isExist = await checkIdInDatabase();
      // todo : 1. check phone number in database
      if(isExist) {
        print('ID is in database');
        signInWithPhoneNumber();
        Future.delayed(Duration(milliseconds: 1000));
        // kill timer
        _timer.cancel();
        timerSecond(0);
        // go to home page
        BottomIndexController bottomIdxCtrl = Get.find();
        bottomIdxCtrl.changePageIndex(0);
        Get.toNamed('/');
      }
      else {
        print('ID is not in database');
        Future.delayed(Duration(milliseconds: 1000));
        // kill timer
        _timer.cancel();
        timerSecond(0);
        // 회원가입 회면으로 이동
        Get.toNamed('/sign_up');
      }
    };

    PhoneVerificationFailed verificationFailed =
        (FirebaseAuthException authException) {
      print("exception ${authException.message}");
      Fluttertoast.showToast(
        msg: '핸드폰 번호 인증에 실패하였습니다. 전화번호 확인후 다시 시도해 주세요',
        gravity: ToastGravity.BOTTOM,
      );
      flushTextField = true;
      initializeSignCtrl();
    };

    PhoneCodeSent codeSent =
        (String verificationId, [int forceResendingToken]) async {
      _verificationId(verificationId);
      enablePinNumberField(true);
      print('firebase auth phone code sect : verification id : $_verificationId');
    };

    PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      _verificationId(verificationId);
      Fluttertoast.showToast(
        msg: '인증시간이 초과되었습니다. 전화번호 입력후 다시 시도해 주세요',
        gravity: ToastGravity.BOTTOM,
      );
      flushTextField = true;
      initializeSignCtrl();
    };

    try {
      await _auth.verifyPhoneNumber(
          phoneNumber: globalUSNumber,
          verificationCompleted: verificationCompleted,
          verificationFailed: verificationFailed,
          codeSent: codeSent,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
    }
    catch(e) {
      print(e.toString());
      print(e.printError());
      Fluttertoast.showToast(msg: '2. 번호인증에 실패하였습니다');
    }
  }

  signInWithPhoneNumber() async{
    if(_verificationId != null) {
      try {
        final AuthCredential credential = PhoneAuthProvider.credential(
            verificationId: _verificationId.value,
            smsCode: smsCode);

        final User user = (await _auth.signInWithCredential(credential)).user;

        print('Successfully signed in UID : ${user.uid}');
        uid = user.uid;

        bool isExist = await checkIdInDatabase();
        // todo : 1. check phone number in database
        if(isExist) {
          print('ID is in database');
          //signInWithPhoneNumber();
          Future.delayed(Duration(milliseconds: 1000));
          // kill timer
          _timer.cancel();
          timerSecond(0);
          // go to home page
          BottomIndexController bottomIdxCtrl = Get.find();
          bottomIdxCtrl.changePageIndex(0);
          Get.toNamed('/');
        }
        else {
          print('ID is not in database');
          Future.delayed(Duration(milliseconds: 1000));
          // kill timer
          _timer.cancel();
          timerSecond(0);
          // 회원가입 회면으로 이동
          Get.toNamed('/sign_up');
        }
      } catch (e) {
        print('Failed to sign in' + e.toString());
        Fluttertoast.showToast
          (msg: '인증번호가 올바르지 않습니다. 다시 시도해주세요');
        initializeSignCtrl();
      }
    }
    else {
      Fluttertoast.showToast
        (msg: '인증코드가 올바르지 않습니다');
      initializeSignCtrl();
    }
  }

  void signOut() {
    _auth.signOut();
    enablePhoneNumberField(true);
    //localKoreaNumber = '';
  }

  void withDrawAccount() async {
    await _auth.currentUser.delete();
  }

  void smsTimer() {

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if(timerSecond.value < 60)
        timerSecond.value++;
      else
        customTimeOut();
    });
  }

  void customTimeOut() {
    Fluttertoast.showToast(msg: '인증시간이 초과되었습니다. 전화번호를 확인하고 다시 한번 시도해주세요');
    flushTextField = true;
    initializeSignCtrl();
  }
}