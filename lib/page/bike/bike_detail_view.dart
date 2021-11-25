import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hibaike_app/component/data_time_format.dart';
import 'package:hibaike_app/component/dynamic_link_service.dart';
import 'package:hibaike_app/controller/page_index_controller.dart';
import 'package:hibaike_app/controller/sign_controller.dart';
import 'package:hibaike_app/model/bike_data.dart';
import 'package:hibaike_app/model/report_data.dart';
import 'package:hibaike_app/model/users.dart';
import 'package:intl/intl.dart';
import 'package:share/share.dart';

class BikeDetailView extends StatefulWidget {
  BikeDetailView({Key key}) : super(key: key);

  @override
  _BikeDetailViewState createState() => _BikeDetailViewState();
}

class _BikeDetailViewState extends State<BikeDetailView>
    with TickerProviderStateMixin {

  final BikeData bikeData = Get.arguments;
  final DateTimeFormatter dateTimeFormatter = DateTimeFormatter();
  SignController _signController = Get.find();
  final numberFormatter = NumberFormat('#,###');
  Users owner;

  AnimationController _colorAnimationController;
  AnimationController _textAnimationController;
  Animation _colorTween, _iconColorTween;
  Animation<Offset> _transTween;

  final DynamicLinkService _dynamicLinkService = DynamicLinkService();

  @override
  void initState() {
    bringOwnerInfo();

    _colorAnimationController =
        AnimationController(vsync: this, duration: Duration(seconds: 0));
    _colorTween = ColorTween(begin: Colors.transparent,
        end: Colors.white)
    //end: Color(0xFFee4c4f))
        .animate(_colorAnimationController);
    _iconColorTween = ColorTween(begin: Colors.white, end: Colors.black)
        .animate(_colorAnimationController);


    _textAnimationController =
        AnimationController(vsync: this, duration: Duration(seconds: 0));

    _transTween = Tween(begin: Offset(-10, 40), end: Offset(-10, 0))
        .animate(_textAnimationController);

    super.initState();
  }

  bringOwnerInfo() async{
    CollectionReference userRef = FirebaseFirestore.instance.collection('users');
    DocumentSnapshot snapshot = await userRef.doc(bikeData.ownerUid).get();
    owner =  Users.fromJson(snapshot.data());
  }

  bool _scrollListener(ScrollNotification scrollInfo) {
    if (scrollInfo.metrics.axis == Axis.vertical) {
      print('scroll info = ${scrollInfo.metrics.pixels}');
      print('width = ${MediaQuery.of(context).size.width}, height = ${MediaQuery.of(context).size.height}');
      _colorAnimationController.animateTo(scrollInfo.metrics.pixels / 300);

      _textAnimationController.animateTo(
          (scrollInfo.metrics.pixels - 300) / 50);
      return true;
    }
  }

  openShareSheet(BuildContext context) async {
    final RenderBox box = context.findRenderObject();

    //String text = 'test text';

    Uri uri = await _dynamicLinkService.makeBikeDynamicLink(bikeData);
    //String subject = uri.toString();

    //String subject = 'https://youtube.com';
    String text = uri.toString();

    await Share.share(text,
        //subject: subject,
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);

  }

  Widget _imageSlider() {
    Get.put(PageIndexController());
    return InkWell(
      onTap: () {
        Get.toNamed('/bike/list_view/detail_view/photo_view', arguments: bikeData.imageList);
      },
      child: Stack(
        children: [
          CarouselSlider(
            items: bikeData.imageList.map((i) {
              return Builder(
                builder: (BuildContext context) {
                  print(MediaQuery.of(context).size.width);
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    //margin: EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5)
                    ),
                    child: CachedNetworkImage(
                      imageUrl: i,
                      placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  );
                },
              );
            }).toList(),
            options: CarouselOptions(
                initialPage: Get.find<PageIndexController>().index.value,
                autoPlay: false,
                enlargeCenterPage: false,
                enableInfiniteScroll: false,
                aspectRatio: 1.0,
                viewportFraction: 1.0,
                onPageChanged: (index, reason) {
                  //setState(() {
                  Get.find<PageIndexController>().chageIndex(index);
                  //});
                }
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: bikeData.imageList.map((url) {
                int index = bikeData.imageList.indexOf(url);
                return Obx(()=>Container(
                  width: 10.0,
                  height: 10.0,
                  margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Get.find<PageIndexController>().index.value == index
                        ? Color.fromRGBO(255, 255, 255, 0.8)
                        : Color.fromRGBO(80, 80, 80, 0.6),
                  ),
                ));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownerInfo() {
    double thumbnailSize = 50;
    return SafeArea(
        child: _signController.currentUser.value.uid != bikeData.ownerUid
          ? Container(
                height: 70,
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.black12)),
                ),
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(bikeData.ownerUid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                          //child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)));
                          child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.red)));
                    } else {
                      return Row(
                        children: [
                          Container(
                            padding: EdgeInsets.only(left: 10, right: 10),
                            child: Material(
                              child: CachedNetworkImage(
                                placeholder: (context, url) => Container(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.0,
                                    //valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                  ),
                                  width: thumbnailSize,
                                  height: thumbnailSize,
                                  padding: EdgeInsets.all(10.0),
                                ),
                                imageUrl: snapshot.data['profile_image_url'],
                                width: thumbnailSize,
                                height: thumbnailSize,
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(25.0),
                              ),
                              clipBehavior: Clip.hardEdge,
                            ),
                          ),
                          /*
                          CircleAvatar(
                           radius: 23,
                            backgroundImage:
                                ((snapshot.data['profile_image_url'] == null) ||
                                        (snapshot.data['profile_image_url'] ==
                                            ''))
                                    ? NetworkImage(
                                        'https://i.stack.imgur.com/l60Hf.png')
                                    : NetworkImage(
                                        snapshot.data['profile_image_url']),
                          ),

                           */
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  snapshot.data['nick_name'],
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  height: 6,
                                ),
                                Text(
                                  bikeData.locationLevel1,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            child: Container(
                              //color: Colors.black.withOpacity(0.7),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 11.0),
                              child: Text(
                                '채팅으로 거래하기',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                  color: Colors.black),
                            ),
                            onTap: () {
                              if (_signController.currentUser == null) {
                                // todo : 로그인이 되어 있는 상태에서만 채팅 가능
                                print('must go to signin page');
                                Get.toNamed('/sign_in');
                              } else {
                                List<String> argumentList = [
                                  bikeData.key,
                                  bikeData.ownerUid,
                                  _signController.currentUser.value.nickName
                                ];
                                Get.toNamed('/chat', arguments: argumentList);
                              }
                            },
                          )
                        ],
                      );
                    }
                  },
                ),
              )
            : Container(height: 0,)

    );
  }

  Widget _bikeInfo() {
    return Container(
      //padding: EdgeInsets.fromLTRB(5.0, 15.0, 5.0, 0),

      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.fromLTRB(10.0, 15.0, 0, 0.0),
                    child: Text(
                      bikeData.manufacturer + ' ' + bikeData.model,
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 7,),
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.fromLTRB(10.0, 0, 0, 5.0),
                    child: Text(
                      bikeData.birthYear.toString() + '년식' + ' · ' + numberFormatter.format(bikeData.mileage) + 'Km',
                      style: TextStyle(color: Colors.black54, fontSize: 15,),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.only(right: 10, top: 15),
                child: Text(
                  '${numberFormatter.format(bikeData.amount)}만원',
                  style: TextStyle(
                      color: Theme.of(context).highlightColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              )
            ],
          ),
          SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 0, 0, 10.0),
            child: Row(
              children: [
                Row(children: [
                  Icon(Icons.place_outlined, color: Colors.black54, size: 17,),
                  Text(bikeData.locationLevel0 + ' ' + bikeData.locationLevel1 + ' ' + bikeData.locationLevel2,
                    style: TextStyle(color: Colors.black54, fontSize: 15,),),
                ],),
                SizedBox(width: 25,),
                Row(children: [
                  Icon(Icons.access_time, color: Colors.black54, size: 16,),
                  Text(' '+dateTimeFormatter.bikeDateTime(bikeData.createdTime),
                    style: TextStyle(color: Colors.black54, fontSize: 15,),),
                ],),
              ],
            ),
          ),
          Divider(height: 10,),

          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10.0, 0, 10.0),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.start,
              alignment: WrapAlignment.start,
              spacing: 7.0,
              runSpacing: 10.0,
              children: [
                Container(
                  //width: 30,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7.0),
                    //alignment: Alignment.center,
                    decoration: BoxDecoration(
                      //color: Colors.white,
                      border: Border.all(color: Colors.red, width: 1.2),
                      // set border width
                      borderRadius: BorderRadius.all(
                          Radius.circular(30.0)), // set rounded corner radius
                      //boxShadow: [BoxShadow(blurRadius: 10,color: Colors.black,offset: Offset(1,3))]// make rounded corner of border
                    ),
                    child: Text(bikeData.displacement.toString() + 'cc')),
                Container(
                  //width: 30,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7.0),
                    //alignment: Alignment.center,
                    decoration: BoxDecoration(
                      //color: Colors.white,
                      border: Border.all(color: Colors.red, width: 1.2),
                      // set border width
                      borderRadius: BorderRadius.all(
                          Radius.circular(30.0)), // set rounded corner radius
                      //boxShadow: [BoxShadow(blurRadius: 10,color: Colors.black,offset: Offset(1,3))]// make rounded corner of border
                    ),
                    child: Text(bikeData.type)),
                Container(
                  //width: 30,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7.0),
                    //alignment: Alignment.center,
                    decoration: BoxDecoration(
                      //color: Colors.red,
                      border: Border.all(color: Colors.red, width: 1.2),
                      // set border width
                      borderRadius: BorderRadius.all(
                          Radius.circular(30.0)), // set rounded corner radius
                      //boxShadow: [BoxShadow(blurRadius: 10,color: Colors.black,offset: Offset(1,3))]// make rounded corner of border
                    ),
                    child: Text(bikeData.fuelType)),
                Container(
                  //width: 30,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7.0),
                    //alignment: Alignment.center,
                    decoration: BoxDecoration(
                      //color: Colors.white,
                      border: Border.all(color: Colors.red, width: 1.2),
                      // set border width
                      borderRadius: BorderRadius.all(
                          Radius.circular(30.0)), // set rounded corner radius
                      //boxShadow: [BoxShadow(blurRadius: 10,color: Colors.black,offset: Offset(1,3))]// make rounded corner of border
                    ),
                    child: Text('자동')),
                bikeData.isTuned == "TUNED"
                    ? Container(
                        //width: 30,
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 7.0),
                        //alignment: Alignment.center,
                        decoration: BoxDecoration(
                          //color: Colors.white,
                          border: Border.all(color: Colors.red, width: 1.2),
                          // set border width
                          borderRadius: BorderRadius.all(Radius.circular(
                              30.0)), // set rounded corner radius
                          //boxShadow: [BoxShadow(blurRadius: 10,color: Colors.black,offset: Offset(1,3))]// make rounded corner of border
                        ),
                        child: Text('튜닝'))
                    : SizedBox(),
                bikeData.possibleAS == "POSSIBLE"
                    ? Container(
                      //width: 30,
                        padding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 7.0),
                        //alignment: Alignment.center,
                        decoration: BoxDecoration(
                          //color: Colors.white,
                          border: Border.all(color: Colors.red, width: 1.2),
                          // set border width
                          borderRadius: BorderRadius.all(Radius.circular(
                              30.0)), // set rounded corner radius
                          //boxShadow: [BoxShadow(blurRadius: 10,color: Colors.black,offset: Offset(1,3))]// make rounded corner of border
                        ),
                        child: Text('A/S'))
                    : SizedBox()
              ],
            ),
          ),
          Divider(height: 10,),
          SizedBox(height: 10,),
          Container(
            padding: EdgeInsets.all(10.0),
            alignment: Alignment.topLeft,
            child: Text(
              bikeData.comment,
              style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                height: 1.4,
                letterSpacing: 1
              ),
            ),
          )

        ],
      ),

    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*
      appBar: AppBar(
        title: Text(
          bikeData.model,
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.black, //change your color here
        ),
      ),
      */
      backgroundColor: Color(0xFFEEEEEE),
      body: NotificationListener(
        onNotification: _scrollListener,
        child: Container(
          height: double.infinity,
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    _imageSlider(),
                    _bikeInfo(),
                  ],
                ),
              ),
              Container(
                height: 80,
                child: AnimatedBuilder(
                  animation: _colorAnimationController,
                  builder: (context, child) => AppBar(
                    backgroundColor: _colorTween.value,
                    elevation: 0,
                    titleSpacing: 0.0,
                    title: Transform.translate(
                      offset: _transTween.value,
                      child: Text(
                        bikeData.model,
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                    iconTheme: IconThemeData(
                      color: _iconColorTween.value,
                    ),
                    backwardsCompatibility: false,
                    systemOverlayStyle: SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness:Brightness.light,
                      statusBarBrightness: Brightness.dark
                    ),
                    actions: <Widget>[
                      IconButton(
                        icon: Icon(
                          Icons.share,
                        ),
                        onPressed: () {
                          openShareSheet(context);
                        },
                      ),
                      bikeData.ownerUid != _signController.currentUser.value.uid
                      ? IconButton(
                        icon: Obx(
                          () => _signController.currentUser.value.watchList.contains(bikeData.key)
                            ? Icon(Icons.favorite, color: Colors.red,)
                              : Icon(Icons.favorite_border)
                        ),
                        onPressed: () {
                          _signController.updateWatchList(bikeData.key);
                        },
                      )
                      : Container(),
                      PopupMenuButton(
                        offset: Offset(0, 45),
                        shape: ShapeBorder.lerp(
                            RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(5))),
                            RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(5))),
                            0),
                        icon: Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: Text("신고하기"),
                            value: 1,
                          )
                        ],
                        onSelected: (int value) {
                          Get.toNamed('/bike/list_view/detail_view/report', arguments: bikeData.key);
                        },
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _ownerInfo(),
    );
  }
}

class ReportBike extends StatefulWidget {
  final String bikeId = Get.arguments;

  @override
  _ReportBikeState createState() => _ReportBikeState(bikeId: bikeId);
}

class _ReportBikeState extends State<ReportBike> {
  String bikeId;
  _ReportBikeState({this.bikeId});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final SignController signController = Get.find();

  @override
  void initState() {

    super.initState();
  }

  registerReport() async {
    DateTime now = DateTime.now();
    String docId = now.millisecondsSinceEpoch.toString();
    String createdTime = now.toIso8601String();
    await FirebaseFirestore.instance.collection('report').doc(docId).set(
        ReportData(
                reporter: signController.currentUser.value.nickName,
                bikeId: bikeId,
                title: titleController.text,
                content: contentController.text,
                createdTime: createdTime)
            .toJson());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('매물신고하기', style: TextStyle(
            color: Colors.black)),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: Colors.black
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide(width: 1, color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide(width: 2, color: Colors.red),
                    ),
                    hintText: '제목을 입력해주세요',
                    hintStyle: TextStyle(color: Colors.grey)),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 20,),
              TextField(
                controller: contentController,
                decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide(width: 1, color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide(width: 2, color: Colors.red),
                    ),
                    hintText: '내용을 입력해주세요',
                    hintStyle: TextStyle(color: Colors.grey)),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                minLines: 15,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: InkWell(
          onTap: () async {
            await registerReport();
            Get.back();
          },
          child: Container(
            height: 65,
            //padding: EdgeInsets.only(bottom: 15, top: 15),
            decoration: BoxDecoration(
              color: Colors.black
            ),
            child: Center(
              child: Text(
                '등록하기',
                style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}