import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:hibaike_app/controller/bottom_index_controller.dart';
import 'package:hibaike_app/controller/sign_controller.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nickNameCtrl = TextEditingController();
  SignController signCtrl = Get.find();
  BottomIndexController idxCtrl = Get.find();

  @override
  void initState() {
    _nickNameCtrl.addListener(() {
      signCtrl.nickName = _nickNameCtrl.text;
    });
    super.initState();
  }

  Future<File> _cropImage(pickedFile) async {
    File croppedFile = await ImageCropper.cropImage(
        sourcePath: pickedFile.path,
        aspectRatioPresets: Platform.isAndroid
            ? [
          CropAspectRatioPreset.square,
          //CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          //CropAspectRatioPreset.ratio4x3,
          //CropAspectRatioPreset.ratio16x9
        ]
            : [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
          //CropAspectRatioPreset.ratio3x2,
          //CropAspectRatioPreset.ratio4x3,
          //CropAspectRatioPreset.ratio5x3,
          //CropAspectRatioPreset.ratio5x4,
          //CropAspectRatioPreset.ratio7x5,
          //CropAspectRatioPreset.ratio16x9
        ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true),
        iosUiSettings: IOSUiSettings(
          title: 'Cropper',
        ));
    return croppedFile;
  }

  Future<File> selectImage() async {
    PickedFile pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);

    if(pickedFile == null) return null;

    return await _cropImage(pickedFile);
  }

  Widget registerUserDataWithDialog() {
    return FutureBuilder(
        future: signCtrl.registerUserToDatabase(),
        builder: (context, snapshot) {
          if(snapshot.hasData) {
            SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
              idxCtrl.changePageIndex(0);
              Get.offNamedUntil(
                  '/', (route) => false);
            });
            return Container();
          }
          else
            return Center(child: CircularProgressIndicator());
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Fluttertoast.showToast(msg: '회원가입에 중단되었습니다. 원할한 사용을 위해 회원가입을 다시 진행해보세요');
        BottomIndexController bottomIndexController = Get.find();
        bottomIndexController.changePageIndex(0);
        Get.offAllNamed('/');
        return;
      },
      child: Scaffold(
        appBar: AppBar(title: Text('회원가입'),),
        body: SingleChildScrollView(
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.fromLTRB(15, 50, 15, 0),
            child: Column(
              //mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  child: Stack(
                    children: [
                      // Material(
                      //   child: CachedNetworkImage(
                      //     placeholder: (context, url) => Container(
                      //       child: CircularProgressIndicator(
                      //         strokeWidth: 1.0,
                      //         //valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                      //         valueColor: AlwaysStoppedAnimation<Color>(
                      //             Colors.red),
                      //       ),
                      //       width: 30.0,
                      //       height: 30.0,
                      //       padding: EdgeInsets.all(0.0),
                      //     ),
                      //     // imageUrl: ((signCtrl.currentUser.value.profileImageUrl != null) &&
                      //     //     (signCtrl.currentUser.value.profileImageUrl.length != 0))
                      //     //     ? signCtrl.currentUser.value.profileImageUrl
                      //     //     : 'https://i.stack.imgur.com/l60Hf.png',
                      //     imageUrl: 'https://i.stack.imgur.com/l60Hf.png',
                      //     width: 100.0,
                      //     height: 100.0,
                      //     fit: BoxFit.cover,
                      //   ),
                      //   borderRadius: BorderRadius.all(Radius.circular(100.0)),
                      //   clipBehavior: Clip.hardEdge,
                      // ),
                      Container(
                        width: 100,
                        height: 100,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100.0),
                          child: signCtrl.profileImageFile!=null ?
                          Image.file(signCtrl.profileImageFile)
                              :Image.network('https://i.stack.imgur.com/l60Hf.png',
                            fit: BoxFit.cover,),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.black12),
                              shape: BoxShape.circle,
                              color: Colors.white
                          ),
                          child: Icon(Icons.camera_alt, color: Colors.grey, size: 18,),
                        ),),
                    ],
                  ),
                  onTap: () async {
                    signCtrl.profileImageFile = await selectImage();
                    setState(() {});
                  },
                ),
                SizedBox(height: 40,),
                Row(children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.only(left: 15),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          border: Border.all(color: Colors.black12)),
                      child: TextField(
                        controller: _nickNameCtrl,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        style: TextStyle(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(0),
                            border: InputBorder.none,
                            hintText: '닉네임 (2~10글자 )',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  InkWell(
                    child: Container(
                      alignment: Alignment.center,
                      height: 50,
                      width: 100,
                      decoration: BoxDecoration(
                          color: Theme.of(context).highlightColor,
                          borderRadius: BorderRadius.all(Radius.circular(4))),
                      child: Text(
                        '중복확인',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    onTap: () async {
                      if(_nickNameCtrl.text.length<2) {
                        Fluttertoast.showToast(msg: '닉네임은 2글자 이상 입력해주세요');
                        return;
                      }
                      if(_nickNameCtrl.text.length>10) {
                        Fluttertoast.showToast(msg: '닉네임은 10글자 이하로 입력해주세요');
                        return;
                      }
                      // 데이터베이트 검색 & 중복확인
                      print(_nickNameCtrl.text);
                      bool isExist = await signCtrl
                          .checkNickNameInDatabase(_nickNameCtrl.text);
                      if (isExist) {
                        Fluttertoast.showToast(
                            msg: "동일한 닉네임이 있습니다. 다른 닉네임을 입력해주세요",
                            gravity: ToastGravity.BOTTOM);
                        _nickNameCtrl.text = '';
                      } else {
                        signCtrl.enableRegister(true);
                      }
                    },
                  ),
                ]
                ),
                SizedBox(
                  height: 15,
                ),
                Obx(() => GestureDetector(
                    child: Container(
                      alignment: Alignment.center,
                      height: 50,
                      decoration: BoxDecoration(
                          color: signCtrl.enableRegister.value ?
                          Theme.of(context).primaryColor :
                          Theme.of(context).primaryColor.withOpacity(0.3),
                          borderRadius: BorderRadius.all(Radius.circular(4))),
                      child: Text(
                        '회원가입',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    onTap: () async {
                      if (signCtrl.enableRegister.value == true) {
                          Get.dialog(
                            registerUserDataWithDialog()
                          );
                            // Dialog(
                            //   backgroundColor: Colors.transparent,
                            //   child: StatefulBuilder(builder:
                            //       (BuildContext context, StateSetter setState) {
                            //       return FutureBuilder<String>(
                            //         future: signCtrl.registerUserToDatabase(),
                            //         builder: (BuildContext context,
                            //             AsyncSnapshot<String> snapshot) {
                            //           if (!snapshot.hasData) {
                            //             return Center(
                            //               child: CircularProgressIndicator(),
                            //             );
                            //           } else {
                            //             idxCtrl.changePageIndex(0);
                            //             Get.offNamedUntil(
                            //                 '/', (route) => false);
                            //             return Container();
                            //           }
                            //         },
                            //       );
                            //   }),
                            // ),

                        }
                    }
                ),),
              ],
            ),
          ),
        ),
      ),
    );
  }
}