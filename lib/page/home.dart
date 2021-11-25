import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hibaike_app/component/dynamic_link_service.dart';
import 'package:hibaike_app/controller/bottom_index_controller.dart';
import 'package:hibaike_app/controller/sign_controller.dart';
import 'package:hibaike_app/model/model.dart';
import 'package:hibaike_app/page/bike/storeModels.dart';

class Home extends StatefulWidget {

  const Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver{
  SignController signCtrl = Get.find();
  BottomIndexController indexCtrl = Get.find();
  int currentIndex = 0;

  final DynamicLinkService _dynamicLinkService = DynamicLinkService();
  Timer _timerLink;

  @override
  void initState() {
    super.initState();
    //initDynamicLinks();
    WidgetsBinding.instance.addObserver(this);
    // _dynamicLinkService.retrieveDynamicLink(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _timerLink = new Timer(
        const Duration(milliseconds: 1000),
            () {
          _dynamicLinkService.retrieveDynamicLink(context);
        },
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_timerLink != null) {
      _timerLink.cancel();
    }
    super.dispose();
  }

  void initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
          final Uri deepLink = dynamicLink?.link;

          if (deepLink != null) {
            Navigator.pushNamed(context, deepLink.path);
          }
        }, onError: (OnLinkErrorException e) async {
      print('onLinkError');
      print(e.message);
    });

    final PendingDynamicLinkData data =
      await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      Navigator.pushNamed(context, deepLink.path);
    }
  }

  Widget mainCarouselSlider() {

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            child: CarouselSlider(
                items: [
                  InkWell(
                    onTap: () {
                      Get.toNamed('/bike/list_view');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          fit: BoxFit.fill,
                          image: CachedNetworkImageProvider(
                              'https://firebasestorage.googleapis.com/v0/b/hibaike-app.appspot.com/o/resource%2Fpages%2Fbike_image.jpg?alt=media&token=e0e44325-4efd-4e53-b721-ae39031c552d'
                          ),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Get.toNamed('/tips');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.fill,
                            image: CachedNetworkImageProvider(
                              'https://firebasestorage.googleapis.com/v0/b/hibaike-app.appspot.com/o/resource%2Fpages%2Ftip_image.jpg?alt=media&token=6392b067-2257-4a32-a32e-181ff1b71a8a'
                            ),
                          ),
                      ),
                      //child:
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Get.toNamed('/nearby');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          fit: BoxFit.fill,
                          image: CachedNetworkImageProvider(
                              'https://firebasestorage.googleapis.com/v0/b/hibaike-app.appspot.com/o/resource%2Fpages%2Fnearby_image.jpg?alt=media&token=6156044b-110d-48ef-a64d-4ed501cf2daa'
                          ),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Get.toNamed('/nearby');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          fit: BoxFit.fill,
                          image: CachedNetworkImageProvider(
                              'https://firebasestorage.googleapis.com/v0/b/hibaike-app.appspot.com/o/resource%2Fpages%2Fstructure_change.png?alt=media&token=2df5dbc5-63aa-4d61-8079-884f686e3653'
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                options: CarouselOptions(
                    initialPage: 0,//Get.find<PageIndexController>().index.value,
                    autoPlay: true,
                    autoPlayInterval: Duration(milliseconds: 5000),
                    enlargeCenterPage: false,
                    enableInfiniteScroll: true,
                    aspectRatio: 2.2,
                    viewportFraction: 1,
                    onPageChanged: (index, reason) {
                      setState(() {
                        currentIndex = index;
                      });
                    }
                ),
            ),
          ),
          Positioned(
            bottom: 10,
              right: 10,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.all(Radius.circular(10))
                ),
                child: Text('${(currentIndex+1).toString()}/4',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),),
              ),
          )
        ],
      ),
    );
  }

  Widget bikeTradeWidget() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            child: Text('중고바이크', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
          ),
          SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  if(signCtrl.isSignIn.value == true)
                    Get.toNamed("/bike/list_view");
                  else
                    Get.toNamed('/sign_in');
                },
                child: Container(
                  alignment: Alignment.center,
                  width: MediaQuery.of(context).size.width * 0.44,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(5))
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Buy Your Bike', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),),
                      SizedBox(height: 15,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('바이크찾기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.2),),
                          SizedBox(width: 16,),
                          Icon(Icons.sports_motorsports_outlined, color: Colors.white,),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  if(!signCtrl.isSignIn.value) {
                    Get.toNamed('/sign_in');
                    return;
                  }
                  FirebaseFirestore.instance
                      .collection('bikes')
                      .where('ownerUid', isEqualTo: signCtrl.currentUser.value.uid)
                      .get()
                      .then((snap) => {
                    if(snap.size >= 3) {
                      if(signCtrl.currentUser.value.grade == 'business'
                          && signCtrl.currentUser.value.shopId.length > 0) {
                        Get.toNamed('/bike/register')
                      } else
                        Get.toNamed("/shop/register_entry")
                    }
                    else
                      Get.toNamed("/bike/register")
                  });
                },
                child: Container(
                  alignment: Alignment.center,
                  width: MediaQuery.of(context).size.width * 0.44,
                  height: 100,
                  decoration: BoxDecoration(
                      color: Theme.of(context).highlightColor,
                      borderRadius: BorderRadius.all(Radius.circular(5))
                  ),
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sell My Bike',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '내차팔기',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 1.2),
                        ),
                        SizedBox(
                          width: 16,
                        ),
                        Icon(
                          Icons.bike_scooter_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ),
            ]
          ),
        ],
      ),
    );
  }

  Widget tipsWidget() {
    return Container(
      padding: EdgeInsets.only(left: 15, right: 15, top: 10),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 17),
            child: Row(
              children: [
                Text('거래팁', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 15),
            child: Row(
              children: [
                Icon(Icons.fact_check_outlined, size: 20, color: Colors.red,),
                SizedBox(width: 7,),
                Expanded(
                    child: Text('이전등록시 필요서류와 절차는?',
                      style: TextStyle(
                          color: Colors.black54,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    )),
                InkWell(
                  onTap: () {
                    Get.toNamed('/tips', arguments: 0);
                  },
                  child: Image.asset('asset/read_more.png', width: 85, height: 22,),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Get.toNamed('/tips', arguments: 1);
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.calculate_outlined, size: 22, color: Colors.red,),
                  SizedBox(width: 7,),
                  Expanded(
                      child: Text('취등록세 계산기',
                        style: TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      )),
                  InkWell(
                    onTap: () {
                      Get.toNamed('/tips', arguments: 1);
                    },
                    child: Image.asset('asset/read_more.png', width: 85, height: 22,),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget structuralChangeWidget() {
    return Row(
      children: [
        Expanded(
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.only(left: 15, right: 15),
            height: 75,
            margin: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
                color: Colors.cyan[300],
              borderRadius: BorderRadius.all(Radius.circular(5))
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('머플러 구조변경,', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17),),
                      SizedBox(height: 6,),
                      Text('신고대상과 저렴한 서류대행 알아보기', style: TextStyle(color: Colors.black, fontSize: 12),),
                    ],
                  ),
                ),
                Image.asset('asset/go_icon.png', width: 70, height: 42,)
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('하이바이크', style: TextStyle(color: Colors.black,fontWeight: FontWeight.w800),),),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            mainCarouselSlider(),
            SizedBox(height: 15,),
            Divider(thickness: 5, color: Colors.grey[100],),
            SizedBox(height: 15,),
            bikeTradeWidget(),
            SizedBox(height: 15,),
            Divider(thickness: 5, color: Colors.grey[100],),
            SizedBox(height: 15,),
            structuralChangeWidget(),
            SizedBox(height: 15,),
            Divider(thickness: 5, color: Colors.grey[100],),
            SizedBox(height: 15,),
            tipsWidget(),
            Divider(thickness: 5, color: Colors.grey[100],),
            Container(
              padding: EdgeInsets.only(left: 15, right: 15, top: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('엔진오일교체, 고장수리는 어디서??', style: TextStyle(color: Colors.black54),),
                        SizedBox(height: 10,),
                        Row(
                          children: [
                            Icon(Icons.place_outlined, color: Colors.black, size: 20,),
                            SizedBox(width: 5,),
                            Text('우리동네 바이크샵 찾기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    // padding: EdgeInsets.all(5),
                    // decoration: BoxDecoration(
                    //     border: Border.all(color: Colors.black),
                    //     borderRadius: BorderRadius.all(Radius.circular(5))
                    // ),
                    child: Column(
                      children: [
                        Image.asset('asset/map_icon1.png', width: 50, height: 58,),
                        //Text('지도로보기', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(),
            ElevatedButton(
                onPressed: () async {
                  StoreModels models = new StoreModels();
                  List<Model> modelMap = await models.loadJson();

                  print(modelMap);

                  modelMap.forEach((element) {
                    String manufacturer = element.company;
                    List<ModelElement> modelList = element.model;
                    FirebaseFirestore.instance
                        .collection('models')
                        .doc(manufacturer)
                        .set({'manufacturer': element.company}).then((value) {
                      modelList.forEach((element) {
                        FirebaseFirestore.instance
                            .collection('models')
                            .doc(manufacturer)
                            .collection('model')
                            .doc(element.name.replaceAll('/', ''))
                            .set({
                          'name': element.name,
                          'displacement': element.displacement,
                          'fuel': element.fuel,
                          'type': element.type
                        });
                      });
                    });
                  });
                },
                child: Text('test')),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: indexCtrl.currentIndex.value,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          indexCtrl.changePageIndex(index);
          switch(index) {
            case 0:
              Get.toNamed('/');
              break;
            case 1:
              Get.toNamed('/nearby');
              break;
            case 2:
              if(signCtrl.isSignIn.value == true)
                Get.toNamed('/chat_room');
              else
                Get.toNamed('/sign_in');
              break;
            case 3:
              Get.toNamed('/tips');
              break;
            case 4:
              if(signCtrl.isSignIn.value == true)
                Get.toNamed('/my');
              else
                Get.toNamed('/sign_in');
          //Get.toNamed('/signUp/saveProfile');
          }
        },
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '홈'),
          BottomNavigationBarItem(
              icon: Icon(Icons.place_outlined),
              activeIcon: Icon(Icons.place),
              label: '주변'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_outlined),
              activeIcon: Icon(Icons.chat),
              label: '채팅'),
          BottomNavigationBarItem(
              icon: Icon(Icons.help_outline),
              activeIcon: Icon(Icons.help),
              label: '거래팁'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              activeIcon: Icon(Icons.account_circle),
              label: signCtrl.isSignIn.value ? 'my' : '로그인'),
        ],
      ),
      ),
    );
  }
}
