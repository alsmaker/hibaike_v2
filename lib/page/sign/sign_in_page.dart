import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hibaike_app/controller/sign_controller.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final SignController signCtrl = Get.find();
  final TextEditingController _phoneNumCtrl = TextEditingController();
  final TextEditingController _pinNumCtrl = TextEditingController();

  @override
  void initState() {
    signCtrl.initializeSignCtrl();
    _bringPhoneNumber();
    _phoneNumCtrl.addListener(() {
      signCtrl.localKoreaNumber = _phoneNumCtrl.text;
    });
    _pinNumCtrl.addListener(() {
      signCtrl.smsCode = _pinNumCtrl.text;
    });
    super.initState();
  }

  void _bringPhoneNumber() async {
    if(Platform.isAndroid)
      _phoneNumCtrl.text = await signCtrl.bringPhoneNumByAutoFill();
  }

  @override
  void dispose() {
    _phoneNumCtrl.removeListener(() { });
    _pinNumCtrl.removeListener(() { });

    _phoneNumCtrl.dispose();
    _pinNumCtrl.dispose();
    super.dispose();
  }

  flushTextFields() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      _phoneNumCtrl.clear();
      _pinNumCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('로그인', style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.black, //change your color here
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            child: Column(
              children: [
                Obx(() =>
                    Container(
                      padding: EdgeInsets.only(left: 15),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          border: Border.all(color: Colors.black12)),
                      child: TextField(
                        controller: _phoneNumCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        enabled:
                        signCtrl.enablePhoneNumberField.value ? true : false,
                        style: TextStyle(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(0),
                            border: InputBorder.none,
                            hintText: '전화번호입력',
                            hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ),
                SizedBox(height: 15,),
                Obx(() =>
                    GestureDetector(
                      child: Container(
                        alignment: Alignment.center,
                        height: 50,
                        decoration: BoxDecoration(
                            color: signCtrl.enablePhoneNumberField.value
                                ? Colors.black
                                : Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.all(Radius.circular(4))),
                        child: Text(
                          '휴대폰 번호로 인증하기',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      onTap: () async {
                        print('tab verify phone number');
                        if (signCtrl.enablePhoneNumberField.value == true) {
                          await signCtrl.verifyPhoneNumber();
                        }
                      },
                    ),
                ),
                SizedBox(height: 35,),
                Obx(
                  () => Container(
                    padding: EdgeInsets.only(left: 15),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        border: Border.all(color: Colors.black12)),
                    child: TextField(
                      maxLength: 6,
                      controller: _pinNumCtrl,
                      keyboardType: Platform.isAndroid ? TextInputType.number : TextInputType.text,
                      textInputAction: TextInputAction.done,
                      enabled:
                          signCtrl.enablePinNumberField.value,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(0),
                        border: InputBorder.none,
                        hintText: '인증번호입력',
                        hintStyle: TextStyle(color: Colors.grey),
                        counterText: "",
                      ),
                    ),
                  ),
                ),
                Obx(() {
                  if(signCtrl.enablePhoneNumberField.value == false) {
                    return Column(
                      children: [
                        SizedBox(height: 7,),
                        Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('${signCtrl.timerSecond.value}', style: TextStyle(color: Theme.of(context).highlightColor),),
                              Text(' / 60', style: TextStyle(fontWeight: FontWeight.bold),),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  else {
                    if(signCtrl.flushTextField) {
                      flushTextFields();
                      signCtrl.flushTextField = false;
                    }
                    return Container();
                  }
                }),
                SizedBox(height: 15,),
                Obx(() =>
                    GestureDetector(
                      child: Container(
                        alignment: Alignment.center,
                        height: 50,
                        decoration: BoxDecoration(
                            color: signCtrl.enablePinNumberField.value ? Colors
                                .red : Colors.red.withOpacity(0.5),
                            borderRadius: BorderRadius.all(Radius.circular(4))
                        ),
                        child: Text('동의하고 시작하기', style: TextStyle(color: Colors
                            .white, fontWeight: FontWeight.bold),),
                      ),
                      onTap: () async{
                        if (signCtrl.enablePinNumberField.value)
                           await signCtrl.signInWithPhoneNumber();
                        // _phoneNumCtrl.text = '';
                        // _pinNumCtrl.text = '';
                      },
                    ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}