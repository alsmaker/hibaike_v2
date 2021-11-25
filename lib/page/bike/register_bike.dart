import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:hibaike_app/component/currency_input_formmatter.dart';
import 'package:hibaike_app/component/db_manager.dart';
import 'package:hibaike_app/controller/bike_data_controller.dart';
import 'package:hibaike_app/controller/multi_image_controller.dart';
import 'package:hibaike_app/controller/sign_controller.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:progress_indicators/progress_indicators.dart';



class RegisterBike extends StatefulWidget {
  @override
  _RegisterBikeState createState() => _RegisterBikeState();
}

class _RegisterBikeState extends State<RegisterBike> {

  List<Asset> images = <Asset>[];
  final _yearCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  final MultiImageController _multiImgCtrl = Get.put(MultiImageController());
  final BikeDataController _bikeDataCtrl = Get.put(BikeDataController());

  FocusNode yearFocus, mileageFocus, amountFocus;

  @override
  void initState() {
    _yearCtrl.addListener(() {
      _bikeDataCtrl.setBirthYear(_yearCtrl.text);
    });
    _mileageCtrl.addListener(() {
      _bikeDataCtrl.setMilage(_mileageCtrl.text);
    });
    _amountCtrl.addListener(() {
      _bikeDataCtrl.setAmount(_amountCtrl.text);
    });
    _commentCtrl.addListener(() {
      _bikeDataCtrl.setComment(_commentCtrl.text);
    });

    yearFocus = FocusNode();
    mileageFocus = FocusNode();
    amountFocus = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _mileageCtrl.dispose();
    _amountCtrl.dispose();

    yearFocus.dispose();
    mileageFocus.dispose();
    amountFocus.dispose();

    super.dispose();
  }

  Widget imageHeader() {
    int maxCount = 10;
    return GestureDetector(
      child: Container(
        width: 75,
        //height: 30,
        alignment: Alignment.center,
        margin: EdgeInsets.fromLTRB(0, 10.0, 10.0, 10.0),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.all(Radius.circular(5.0))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: Colors.grey, size: 30,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${_multiImgCtrl.imageLength}',
                  style: TextStyle(color: _multiImgCtrl.imageLength.value==0 ? Colors.grey : Colors.red),),

                Text('/$maxCount', style: TextStyle(color: Colors.grey),)
              ],
            ),
          ],
        ),
      ),
      onTap: (){
        _multiImgCtrl.getMultiImage(maxCount, true);
      },
    );
  }

  Widget imageThumbnail(int index) {
    return FutureBuilder<String>(
        future: _multiImgCtrl.loadImageData(index),
        builder: (context, AsyncSnapshot<String> snapshot) {
          if(!snapshot.hasData) {
            return Container(
                width: 75,
                //alignment: Alignment.center,
                margin: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                ),
                child: Center(child: CircularProgressIndicator())
            );
          }
          else
            return Stack(
              children: [
                Container(
                  width: 75,
                  //alignment: Alignment.center,
                  margin: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    image: DecorationImage(
                        fit: BoxFit.cover,
                        image: MemoryImage(_multiImgCtrl.images[index])
                    ),
                  ),
                  //child: Image.memory(_multiImgCtrl.images[index], fit: BoxFit.cover,),
                ),
                Positioned(
                  right: 3,
                  top: 3,
                  child: GestureDetector(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                    onTap: () {
                      _multiImgCtrl.removeAtImg(index);
                    },
                  ),
                ),
              ],
            );
        }
    );
  }

  bool bikeFieldValidate() {
    if(_multiImgCtrl.images.length == 0 || _multiImgCtrl.images == null) {
      Fluttertoast.showToast(msg: '바이크 사진 한장 이상 등록 필수입니다');
      return false;
    }
    if(_bikeDataCtrl.manufacturer.value.length == 0 || _bikeDataCtrl.manufacturer.value == null) {
      Fluttertoast.showToast(msg: '제조사를 입력해주세요');
      return false;
    }
    if(_bikeDataCtrl.model.value.length == 0 || _bikeDataCtrl.model.value == null) {
      Fluttertoast.showToast(msg: '모델명을 입력해주세요');
      return false;
    }
    if(_bikeDataCtrl.locationLevel0.value.length == 0 || _bikeDataCtrl.locationLevel0.value == null) {
      Fluttertoast.showToast(msg: '판매지역을 입력해주세요');
      return false;
    }
    if(_yearCtrl.text.length == 0 || _yearCtrl.text == null) {
      Fluttertoast.showToast(msg: '연식을 입력해주세요');
      yearFocus.requestFocus();
      return false;
    }
    int intYear = int.parse(_yearCtrl.text);
    if(intYear > 2021 || intYear < 1970) {
      Fluttertoast.showToast(msg: "연식을 다시 한번 확인해 주세요");
      yearFocus.requestFocus();
      return false;
    }
    if(_mileageCtrl.text.length == 0 || _mileageCtrl.text == null) {
      Fluttertoast.showToast(msg: '주행거리를 입력해주세요');
      mileageFocus.requestFocus();
      return false;
    }
    if(_amountCtrl.text.length == 0 || _amountCtrl.text == null) {
      Fluttertoast.showToast(msg: '판매가격을 입력해주세요');
      amountFocus.requestFocus();
      return false;
    }

    return true;
  }

  void uploadBikeData() {
    String test = 'test';
    compute(uploadBike, test).then((value) => Fluttertoast.showToast(msg: 'success'));
  }

  @override
  Widget build(BuildContext context) {
    print(MediaQuery.of(context).size);
    return Scaffold(
      appBar: AppBar(
        title: Text('내바이크 등록', style: TextStyle(color: Colors.black),),
        iconTheme: IconThemeData(
            color: Colors.black
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.0),
          child: Column(
            children: [
              Obx(()=>Container(
                height: 115,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: ListView.builder(
                  //itemCount: _multiImgCtrl.images.length + 1, // +1 for header image
                  itemCount: _multiImgCtrl.imageLength.value + 1, // +1 for header image
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    if (index == 0)
                      return imageHeader();
                    else
                      return imageThumbnail(index-1);
                  },
                ),
              ),
              ),
              Divider(height: 10,),
              Obx(() {
                // 제조사와 모델이 선택이 되어 있지 않을때
                if ((_bikeDataCtrl.manufacturer.value == null) ||
                    (_bikeDataCtrl.model.value == null) ||
                    (_bikeDataCtrl.manufacturer.value.length == 0) ||
                    (_bikeDataCtrl.model.value.length == 0))
                  return InkWell(
                    child: Container(
                      padding: EdgeInsets.only(top: 15, bottom: 15),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('제조사/모델 선택', style: TextStyle(
                              color: Colors.grey),),
                          Icon(
                            Icons.arrow_forward_ios_rounded, color: Colors.grey,
                            size: 18,)
                        ],
                      ),
                    ),
                    onTap: () {
                      Get.toNamed("/manufacturer", arguments: '/bike/register');
                    },
                  );
                else
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            Get.toNamed("/manufacturer", arguments: '/bike/register');
                          },
                          child: Row(
                            children: [
                              Container(
                                  width: 80,
                                  child: Text('제조사', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),)
                              ),
                              Expanded(
                                child: Text(
                                    _bikeDataCtrl.manufacturer.value,
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded, color: Colors.black,
                                size: 18,)
                              ],
                          ),
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            Container(
                                width: 80,
                                child: Text('모델', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),)
                            ),
                            Expanded(
                              child: Text(
                                _bikeDataCtrl.model.value,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            Container(
                                width: 80,
                                child: Text('배기량', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),)
                            ),
                            Expanded(
                              child: Text(
                                '${_bikeDataCtrl.displacement.value.toString()}cc',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            Container(
                                width: 80,
                                child: Text('연료', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),)
                            ),
                            Expanded(
                              child: Text(
                                _bikeDataCtrl.fuelType.value,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            Container(
                                width: 80,
                                child: Text('타입', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),)
                            ),
                            Expanded(
                              child: Text(
                                _bikeDataCtrl.type.value,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
              },),
              Divider(height: 10,),
              Obx(() {
                if((_bikeDataCtrl.locationLevel0.value == null) ||
                    (_bikeDataCtrl.locationLevel0.value.length == 0) ||
                    (_bikeDataCtrl.locationLevel0.value == null) ||
                    (_bikeDataCtrl.locationLevel0.value.length == 0)) {
                  return InkWell(
                    child: Container(
                      height: 50,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '판매지역',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.grey,
                            size: 18,
                          )
                        ],
                      ),
                    ),
                    onTap: () {
                      Get.toNamed("/location", arguments: '/bike/register');
                    },
                  );
                }
                else {
                  return InkWell(
                    child: Container(
                      height: 50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_bikeDataCtrl.locationLevel0} ${_bikeDataCtrl.locationLevel1} ${_bikeDataCtrl.locationLevel2}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),),
                          Icon(
                            Icons.arrow_forward_ios_rounded, color: Colors.black,
                            size: 18,)
                        ],
                      ),
                    ),
                    onTap: () {
                      Get.toNamed("/location", arguments: '/register');
                    },
                  );
                }
              }),
              Divider(height: 10,),
              Container(
                height: 50,
                child: Row(
                  children: [
                    Container(
                        width: 80,
                        child: Text('연식', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),)
                    ),
                    Expanded(
                      child: TextField(
                        controller: _yearCtrl,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '예) 2021',
                            hintStyle: TextStyle(color: Colors.grey)
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        focusNode: yearFocus,
                        //showCursor: false,
                      ),
                    ),
                    Text('년'),
                  ],
                ),
              ),
              Container(
                height: 50,
                child: Row(
                  children: [
                    Container(
                        width: 80,
                        child: Text('주행거리', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),)
                    ),
                    Expanded(
                      child: TextField(
                        controller: _mileageCtrl,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '예) 30,000',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        focusNode: mileageFocus,
                        inputFormatters: [
                          CurrencyInputFormatter()
                        ],
                      ),
                    ),
                    Text('KM'),
                  ],
                ),
              ),
              Container(
                height: 50,
                child: Row(
                  children: [
                    Container(
                        width: 80,
                        child: Text('판매가격', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),)
                    ),
                    Expanded(
                      child: TextField(
                        controller: _amountCtrl,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '예) 1,500',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        focusNode: amountFocus,
                        inputFormatters: [
                          CurrencyInputFormatter()
                        ],
                      ),
                    ),
                    Text('만원'),
                  ],
                ),
              ),
              Divider(height: 10,),
              Container(
                padding: EdgeInsets.only(top: 10),
                //height: 50,
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      child: Text('튜닝사항', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
                    ),
                    Expanded(
                      child: Container(
                        //alignment: Alignment.center,
                        child: Row(
                          children: [
                            Obx(
                                  () => GestureDetector(
                                child: Container(
                                  width: (MediaQuery.of(context).size.width - 130) / 2,
                                  //height: 30,
                                  //margin: EdgeInsets.all(0),
                                  padding: EdgeInsets.all(7),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color:
                                    _bikeDataCtrl.isTuned.value == "TUNED"
                                        ? Colors.red
                                        : Colors.white,
                                    border: Border.all(
                                        color: Colors.red,
                                        // set border color
                                        width: 1.2), // set border width
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(
                                            30.0)), // set rounded corner radius
                                  ),
                                  child: Text(
                                    '있음',
                                    style: TextStyle(
                                      color:
                                      _bikeDataCtrl.isTuned.value == "TUNED"
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  _bikeDataCtrl.isTuned('TUNED');
                                },
                              ),
                            ),
                            SizedBox(width: 15,),
                            Obx(
                                  () => GestureDetector(
                                child: Container(
                                  width: (MediaQuery.of(context).size.width - 130) / 2,
                                  //margin: EdgeInsets.all(0),
                                  padding: EdgeInsets.all(7),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color:
                                    _bikeDataCtrl.isTuned.value == "NO_TUNED"
                                        ? Colors.red
                                        : Colors.white,
                                    border: Border.all(
                                        color: Colors.red,
                                        // set border color
                                        width: 1.2), // set border width
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(
                                            30.0)), // set rounded corner radius
                                  ),
                                  child: Text(
                                    '없음',
                                    style: TextStyle(
                                      color:
                                      _bikeDataCtrl.isTuned.value == "NO_TUNED"
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  _bikeDataCtrl.isTuned('NO_TUNED');
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15,),
              Container(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      child: Text('A/S', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
                    ),
                    Expanded(
                      child: Container(
                        //alignment: Alignment.center,
                        child: Row(
                          children: [
                            Obx(
                                  () => GestureDetector(
                                child: Container(
                                  width: (MediaQuery.of(context).size.width - 130) / 2,
                                  //margin: EdgeInsets.all(0),
                                  padding: EdgeInsets.all(7),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color:
                                    _bikeDataCtrl.possibleAS.value == "POSSIBLE"
                                        ? Colors.red
                                        : Colors.white,
                                    border: Border.all(
                                        color: Colors.red,
                                        // set border color
                                        width: 1.2), // set border width
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(
                                            30.0)), // set rounded corner radius
                                  ),
                                  child: Text(
                                    '가능',
                                    style: TextStyle(
                                      color:
                                      _bikeDataCtrl.possibleAS.value == "POSSIBLE"
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  _bikeDataCtrl.possibleAS('POSSIBLE');
                                },
                              ),
                            ),
                            SizedBox(width: 15,),
                            Obx(
                                  () => GestureDetector(
                                child: Container(
                                  width: (MediaQuery.of(context).size.width - 130) / 2,
                                  //margin: EdgeInsets.all(0),
                                  padding: EdgeInsets.all(7),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color:
                                    _bikeDataCtrl.possibleAS.value == "IMPOSSIBLE"
                                        ? Colors.red
                                        : Colors.white,
                                    border: Border.all(
                                        color: Colors.red,
                                        // set border color
                                        width: 1.2), // set border width
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(
                                            30.0)), // set rounded corner radius
                                  ),
                                  child: Text(
                                    '불가능',
                                    style: TextStyle(
                                      color:
                                      _bikeDataCtrl.possibleAS.value == "IMPOSSIBLE"
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  _bikeDataCtrl.possibleAS('IMPOSSIBLE');
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 10,),
              // comment
              Container(
                //height: 50,
                //child:
                //Expanded(
                child: TextField(
                  controller: _commentCtrl,
                  style: TextStyle(height: 1.3),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '내 바이크에 대한 설명을 작성해주세요\n운행용도, 튜닝사항, 사고유무 등등\n구매자에게 내 바이크를 어필해보세요',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  keyboardType: TextInputType.multiline,
                  //textInputAction: TextInputAction.next,
                  maxLines: null,
                  minLines: 10,
                  //showCursor: false,
                ),
                //),
              ),
            ],
          ),
        ),
      ),

      // 하단 : 등록 / 초기화 bottom navigation button
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.black12)),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
                child: GestureDetector(
                  child: Container(
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width / 3,
                    child: Text('초기화', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                  ),
                  onTap: () {
                    _multiImgCtrl.reset();
                    _bikeDataCtrl.reset();
                    _yearCtrl.text = '';
                    _mileageCtrl.text = '';
                    _amountCtrl.text = '';
                    _commentCtrl.text = '';

                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 10, 10),
                  child: GestureDetector(
                    child: Container(
                      alignment: Alignment.center,
                      child: Text('바이크등록', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      ),
                    ),
                    onTap: () {
                      if(bikeFieldValidate())
                        Get.toNamed('/register/progressStore');
                      //uploadBikeData();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String> uploadBike(String test) async {
  List<String> imgUrlList;
  DBManager dbManager = new DBManager();
  DateTime now = DateTime.now();

  imgUrlList = await dbManager.storeImageList(now);
  print('store image list and get image URLs');
  String result = await dbManager.storeBikeData(imgUrlList, now);
  print(result);

  return result;
}

class UploadProgress extends StatefulWidget{
  @override
  _UploadProgressState createState() => _UploadProgressState();
}

class _UploadProgressState extends State<UploadProgress> {
  SignController signController = Get.find();
  MultiImageController multiImageController = Get.find();

  @override
  initState() {
    int totalLength = 0;
    for(var i = 0 ; i < multiImageController.images.length ; i++) {
      print('image size = ${multiImageController.images[i].lengthInBytes}');
      if(multiImageController.images[i].lengthInBytes == 0) {
        multiImageController.removeAtImg(i);
      }
      totalLength += multiImageController.images[i].lengthInBytes;
    }
    multiImageController.totalLengthInByte.value = (totalLength * 1.05).toInt();
    super.initState();
  }

  // DB connect 과 사진 등록
  Future<String> registerBike() async{
    List<String> imgUrlList;
    DBManager dbManager = new DBManager();
    DateTime now = DateTime.now();

    imgUrlList = await dbManager.storeImageList(now);
    print('store image list and get image URLs');
    String result = await dbManager.storeBikeData(imgUrlList, now);
    print(result);

    //await signController.updateBikeList('bike-${now.millisecondsSinceEpoch}');

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Fluttertoast.showToast(msg: '등록중입니다. 잠시만 기다려주세요');
        return;
      },
      child: Scaffold(
        body: Center(
          child: FutureBuilder<dynamic>(
            future: registerBike(),
            builder: (context, AsyncSnapshot<dynamic> snapshot) {
              if(snapshot.hasError){
                print(snapshot.error);
              }

              if(snapshot.hasData){
                // 등록이 완료되면 홈화면으로 이동
                SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                  Get.offAllNamed('/');
                });

                return Container();
              }
              else
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Obx(
                        () => CircularPercentIndicator(
                          radius: 130.0,
                          //animation: true,
                          lineWidth: 15.0,
                          percent: (multiImageController.transferredByte.value /
                                      multiImageController
                                          .totalLengthInByte.value) <
                                  1
                              ? multiImageController.transferredByte.value /
                                  multiImageController.totalLengthInByte.value
                              : 1,
                          center: Text(
                            '${((multiImageController.transferredByte.value / multiImageController.totalLengthInByte.value) * 100).floor().toString()}%',
                            style: new TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20.0),
                          ),
                          circularStrokeCap: CircularStrokeCap.round,
                          backgroundColor: Colors.grey,
                          progressColor: Theme.of(context).highlightColor,
                        ),
                      ),
                      SizedBox(height: 15,),
                      JumpingDotsProgressIndicator(
                        fontSize: 20.0,
                      ),
                      SizedBox(height: 15,),
                      Text('바이크를 등록중입니다'),
                    ],
                  ),
                );
            },
          ),
        ),
      ),
    );
  }
}