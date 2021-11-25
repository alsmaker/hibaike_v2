import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:elastic_client/elastic_client.dart' as elastic;
import 'package:hibaike_app/component/phone_number_format.dart';
import 'package:hibaike_app/controller/bottom_index_controller.dart';
import 'package:hibaike_app/controller/page_index_controller.dart';
import 'package:hibaike_app/controller/sign_controller.dart';
import 'package:hibaike_app/model/shop_data.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyPage extends StatefulWidget {
  @override
  _NearbyPageState createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> with WidgetsBindingObserver{
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  //Completer<GoogleMapController> _controller = Completer();
  GoogleMapController _controller;
  String apiKey = 'AIzaSyAgkR2a33agDSGR2adz2KK-aZ5A_MEbBnw'; // google places api key
  Position position;
  LatLng currentPosition;
  CameraPosition cameraPosition;
  var lat, lng;
  bool isLoading = true;
  ShopData shopData;

  SignController signCtrl = Get.find();
  BottomIndexController indexCtrl = Get.find();

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  MarkerId latestSelectedMarker = MarkerId('');
  CustomInfoWindowController _customInfoWindowController =
    CustomInfoWindowController();

  BitmapDescriptor normalPinIcon, selectedPinIcon;

  bool isBottomSheetOpen = false;

  @override
  void initState() {
    checkGPAvailability();
    WidgetsBinding.instance.addObserver(this);

    //bringShopDataFromFireStore();

    setCustomMapPin();

    super.initState();
  }

  void setCustomMapPin() async {
    ImageConfiguration configuration = ImageConfiguration();
    normalPinIcon = await BitmapDescriptor.fromAssetImage(
        //ImageConfiguration(devicePixelRatio: 2.5),
        ImageConfiguration(),
        "asset/marker_orange.png");
    selectedPinIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5),
        "asset/marker_blue.png");
  }

  @override
  void dispose() {
    _customInfoWindowController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      resumeGoogleMap();
    }
  }

  resumeGoogleMap() async{
    print('resume google map');
    //final GoogleMapController controller = await _controller.future;
    //controller.setMapStyle("[]");
    _controller.setMapStyle("[]]");
  }

  void checkGPAvailability() async {
    bool serviceEnabled;
    LocationPermission permission;

    print('sync test 1');

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('location services are disabled');
      return;
    }

    print('sync test 2');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      print(
          'Location permission are permently denied, we cannot request permissions');
      return;
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        print('Location permissions are denied (actual value: $permission).');
        return;
      }
    }

    print('sync test 3');

    await getUserCurrentPosition();

    print('sync test');
  }

  loadRegistryDataFromElastic() async{
    String username = 'elastic';
    String password = 'uDsjx72rmX14gR5jz0TJ0PMM';
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final transport = elastic.HttpTransport(url: "https://i-o-optimized-deployment.es.asia-northeast3.gcp.elastic-cloud.com:9243",
        authorization: basicAuth);
    final client = elastic.Client(transport);

    LatLngBounds bounds = await _controller.getVisibleRegion();
    var top = bounds.northeast.latitude;
    var bottom = bounds.southwest.latitude;
    var left = bounds.southwest.longitude;
    var right = bounds.northeast.longitude;
    int limit = 10;

    print('top = $top, bottom = $bottom, left = $left, right = $right');

    String queryString = '{"bool": {"must": {"match_all": {}},"filter": {"geo_bounding_box": {"shopLocation": {"top_left": {"lat": $top,"lon": $left},"bottom_right": {"lat": $bottom,"lon": $right}}}}}}';
    Map queryMap = json.decode(queryString);

    var response = await client.search(
      index: 'shops',
      type: '_doc',
      query: queryMap,
      limit: limit,
      source: true,
    );

    if(response.hits.length >=  limit)
      Fluttertoast.showToast(msg: '최대 10개 등록소까지 표시됩니다');

    response.hits.forEach((doc) {
      print(doc.doc['name']);
      var mapJson = Map<String, dynamic>.from(doc.doc);
      ShopData shopData = ShopData.fromJson(mapJson);

      var _marker = Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(shopData.shopLocation.lat, shopData.shopLocation.lon),
          icon: doc.id==latestSelectedMarker.value
              ? selectedPinIcon
              : normalPinIcon,
          consumeTapEvents: true,
          infoWindow: InfoWindow(
            title: '테스트테스트'
          ),
          onTap: () {
            print('marker tab');
            // _customInfoWindowController.addInfoWindow(
            //     Container(
            //       decoration: BoxDecoration(
            //           color: Colors.white,
            //           borderRadius: BorderRadius.circular(30),
            //           border: Border.all(
            //               color: Colors.blue,
            //               width: 2.0
            //           )
            //       ),
            //       child: Padding(
            //         padding: const EdgeInsets.only(left: 3, right: 5, top: 5, bottom: 5),
            //         child: Row(
            //           mainAxisAlignment: MainAxisAlignment.center,
            //           children: [
            //             Container(
            //                 padding: const EdgeInsets.all(4.0),//I used some padding without fixed width and height
            //                 decoration: new BoxDecoration(
            //                   shape: BoxShape.circle,// You can use like this way or like the below line
            //                   //borderRadius: new BorderRadius.circular(30.0),
            //                   color: Colors.blue,
            //                 ),
            //                 child: new Icon(Icons.two_wheeler_outlined, size: 15.0, color: Colors.white)),
            //             SizedBox(
            //               width: 8.0,
            //             ),
            //             Expanded(
            //               child: Text(
            //                   shopData.shopName,
            //                   style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //       //width: double.infinity,
            //       // height: double.infinity,
            //     ),
            //     LatLng(shopData.shopLocation.lat, shopData.shopLocation.lon)
            // );

            setState(() {
              if(latestSelectedMarker != null && latestSelectedMarker.value.length != 0
                  && markers.containsKey(latestSelectedMarker)) {
                Marker _marker = markers[latestSelectedMarker];
                markers[latestSelectedMarker] =
                    _marker.copyWith(iconParam: normalPinIcon);
              }
              latestSelectedMarker = MarkerId(doc.id);
              Marker _marker = markers[latestSelectedMarker];
              markers[latestSelectedMarker] = _marker.copyWith(
                  iconParam: selectedPinIcon);

              scaffoldKey.currentState.showBottomSheet((context) {
                //return bottomSheetWidget(shopData);
                return bottomSheet(shopData);
              });
            });
          });

      setState(() {
        markers[MarkerId(doc.id)] = _marker;
      });

    });
  }

  bringShopDataFromFireStore() async {
    //List<ShopData> shopList = [];
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('shops').get();

    snapshot.docs.forEach((doc) {
      shopData = ShopData.fromJson(doc.data());
    });

    // markers.add(Marker(
    //     markerId: MarkerId('1'),
    //     position: LatLng(shopData.shopLocation.lat.toDouble(),
    //         shopData.shopLocation.lon.toDouble()),
    //     consumeTapEvents: true,
    //     onTap: () {
    //       print('marker tab');
    //       setState(() {
    //         scaffoldKey.currentState.showBottomSheet((context) {
    //           //return BottomSheetWidget(
    //           return bottomSheetWidget(shopData);
    //         });
    //       });
    //     }));

    setState(() {

    });

    print('shop data test');
  }

  getUserCurrentPosition () async {
    position = await Geolocator.getCurrentPosition();
    print('my position is lat = ${position.latitude}, lng = ${position
        .longitude}');


    setState(() {
      lat = position.latitude;
      lng = position.longitude;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        BottomIndexController.to.currentIndex(0);
        Get.offAllNamed('/');
        return;
      },
      child: Scaffold(
        key: scaffoldKey,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          //title: Text,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              indexCtrl.currentIndex(0);
              Get.offAllNamed('/');
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
              color: Colors.black
          ),
          title: Container(
            padding: EdgeInsets.only(top: 6, bottom: 6, left: 8),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 2.0, spreadRadius: 0.4)
              ],
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey,),
                SizedBox(width: 10,),
                Text('상호검색', style: TextStyle(color: Colors.grey, fontSize: 15),)
              ],
            ),

            // child: TextField(
            //   decoration: InputDecoration(
            //       filled: true,
            //       fillColor: Colors.white,
            //       border: InputBorder.none,
            //       prefixIcon: Icon(Icons.search),
            //       contentPadding:
            //           const EdgeInsets.only(left: 10.0, bottom: 0.0, top: 0.0),
            //       enabledBorder: OutlineInputBorder(
            //         borderRadius: BorderRadius.all(Radius.circular(4)),
            //         borderSide: BorderSide(color: Colors.transparent)
            //       ),
            //       focusedBorder: OutlineInputBorder(
            //         borderRadius: BorderRadius.all(Radius.circular(4)),
            //         borderSide: BorderSide(width: 2, color: Colors.grey),
            //       ),
            //       hintText: '상호 검색',
            //       hintStyle: TextStyle(color: Colors.grey)),
            // ),
          ),
        ),
        body: isLoading
            ? Center(
          child: CircularProgressIndicator(),
        )
            : Stack(
              children: [
                GoogleMap(
          mapType: MapType.normal,
          markers: Set<Marker>.of(markers.values),//Set.from(shopMarkers),
          initialCameraPosition: CameraPosition(
                //target: LatLng(37.49639442929692, 127.04438769057595),
                target: LatLng(lat, lng),
                zoom: 15,
          ),
          onMapCreated: (GoogleMapController controller) {
                //_controller.complete(controller);
                _controller = controller;
                _customInfoWindowController.googleMapController = controller;
                // getAddrFromLocation();
          },
          myLocationEnabled: true,
          zoomControlsEnabled: false,
          minMaxZoomPreference: MinMaxZoomPreference(11, 20),
          onCameraMoveStarted: _onCameraMoveStarted,
          onCameraMove: _onCameraMove,
          onCameraIdle: _onCameraIdle,
        ),
                CustomInfoWindow(
                  controller: _customInfoWindowController,
                  // height: 75,
                   width: 150,
                  //width: double.infinity,
                  offset: 33,
                ),
              ],
            ),
      ),
    );
  }

  _onCameraMoveStarted() {
    //print('camera move start');
  }

  _onCameraMove(CameraPosition position) async{
    cameraPosition = position;
    //print("camera moving");
    //LatLngBounds bounds = await _controller.getVisibleRegion();
    //print(bounds);

    _customInfoWindowController.onCameraMove();
  }

  _onCameraIdle() {
    print('camera idle');
    markers.clear();
    loadRegistryDataFromElastic();
  }

  Widget bottomSheet(ShopData shopData) {
    final phoneNumberDisplayFormat = PhoneNumberDisplayFormatter();
    return DraggableScrollableSheet(
      initialChildSize: 0.24,
      //_initialSheetChildSize,
      maxChildSize: 0.8,
      minChildSize: 0.1,
      expand: false,
      // builder: (context, scrollController) => ListView.builder(
      //     controller: scrollController,
      //     itemCount: 50,
      //     itemBuilder: (BuildContext context, int index) {
      //       //ListTiles...},
      //       return Text('text');
      //     }),
      builder: (context, scrollController) {
        double thumbnailSize = MediaQuery.of(context).size.height * 0.14;
        return Container(
          padding: EdgeInsets.only(left: 15, right: 15, top: 5),
          height: MediaQuery.of(context).size.height*0.5,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
          ),
          child: ListView(
            controller: scrollController,
            //mainAxisAlignment: MainAxisAlignment.center,
            //mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: 7,
                  margin: EdgeInsets.only(top: 5, bottom: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey[350],
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        PageIndexController pageIndexController = Get.put(PageIndexController());
                        pageIndexController.chageIndex(0);
                        Get.toNamed('/nearby/photo_view', arguments: shopData.imageList);
                      },
                      child: Stack(
                        children: [
                          Material(
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
                              imageUrl: shopData.imageList[0],
                              width: thumbnailSize,
                              height: thumbnailSize,
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.all(
                              Radius.circular(5.0),
                            ),
                            clipBehavior: Clip.hardEdge,
                          ),
                          Positioned(
                            bottom: 5,
                              right: 5,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(8),),
                                  color: Colors.white
                                ),
                                child: Text('+${shopData.imageList.length.toString()}',
                                style: TextStyle(fontWeight: FontWeight.bold),),
                              )
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 15),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                              child: Text(shopData.shopName, style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),)
                          ),
                          SizedBox(height: 15,),
                          if (shopData.isOpenPhoneNumber)
                            InkWell(
                              onTap: () async {
                                if (await canLaunch('tel:${shopData.phoneNumber}')) {
                                  await launch('tel:${shopData.phoneNumber}');
                                } else {
                                  print('cannot launch');
                                  throw 'Could not launch ';
                                }
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.phone_iphone,
                                    size: 15,
                                  ),
                                  SizedBox(width: 10,),
                                  Text(
                                    //shopData.phoneNumber,
                                    phoneNumberDisplayFormat.getPhoneNumberFormat(shopData.phoneNumber),
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.local_phone, size: 15,),
                              SizedBox(width: 10,),
                              Text(
                                phoneNumberDisplayFormat.getPhoneNumberFormat(shopData.contact),
                                //shopData.contact,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(),

              Container(
                //padding: EdgeInsets.only(top: 10, bottom: 20),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(top: 15, bottom: 15),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(4),
                                margin: EdgeInsets.only(right: 7),
                                child: Text(
                                  '지번',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.all(Radius.circular(4)),
                                ),
                              ),
                              if (shopData.address.length > 0) Expanded(
                                child: Text(
                                  shopData.address +
                                      ' ' +
                                      shopData.addressDetail,
                                  style: TextStyle(
                                      fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  maxLines: 2,
                                ),
                              ) else Expanded(child: Container()),
                              if (shopData.address.length > 0) InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                        text: shopData.address + ' ' + shopData.addressDetail));
                                    Fluttertoast.showToast(msg: '주소가 복사되었습니다');
                                  },
                                  child: Icon(
                                    Icons.content_copy,
                                    size: 18,
                                  ))
                            ],
                          ),
                          SizedBox(height: 10,),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(4),
                                margin: EdgeInsets.only(right: 7),
                                child: Text(
                                  '도로명',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.all(Radius.circular(4)),
                                ),
                              ),
                              if (shopData.roadAddress.length > 0) Expanded(
                                child: Text(
                                  shopData.roadAddress +
                                      ' ' +
                                      shopData.addressDetail,
                                  style: TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  maxLines: 2,
                                ),
                              ) else Expanded(child: Container()),
                              if (shopData.roadAddress.length > 0) InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                        text: shopData.roadAddress + ' ' + shopData.addressDetail,));
                                    Fluttertoast.showToast(msg: '주소가 복사되었습니다');
                                  },
                                  child: Icon(
                                    Icons.content_copy,
                                    size: 18,
                                  ))
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(),

                    // 오일 타입
                    Container(
                      padding: EdgeInsets.only(top: 10, bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('취급오일', style: TextStyle(fontSize: 15, color: Colors.grey),),
                              Icon(Icons.navigate_next, color: Colors.grey,),
                            ],
                          ),
                          SizedBox(height: 10,),
                          Text(
                            shopData.oilType,
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                    Container(
                      padding: EdgeInsets.only(top: 10, bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('보유진단기', style: TextStyle(fontSize: 15, color: Colors.grey),),
                              Icon(Icons.navigate_next, color: Colors.grey,),
                            ],
                          ),
                          SizedBox(height: 10,),
                          Text(shopData.diagnosticDevice,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            maxLines: 2,),
                        ],
                      ),
                    ),
                    Divider(),

                    Container(
                      padding: EdgeInsets.only(top: 10, bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('매장상세정보', style: TextStyle(fontSize: 15, color: Colors.grey),),
                              Icon(Icons.navigate_next, color: Colors.grey,),
                            ],
                          ),
                          SizedBox(height: 10,),
                          Text(
                            shopData.comment,
                            style: TextStyle(fontSize: 16,),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}