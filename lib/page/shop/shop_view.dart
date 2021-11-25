import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hibaike_app/component/phone_number_format.dart';
import 'package:hibaike_app/controller/sign_controller.dart';
import 'package:hibaike_app/model/shop_data.dart';

class ShopViewPage extends StatefulWidget {
  @override
  _ShopViewPageState createState() => _ShopViewPageState();
}

class _ShopViewPageState extends State<ShopViewPage> {
  SignController signController = Get.find();
  ShopData shopData;

  @override
  void initState() {
    bringShopData();
    super.initState();
  }

  Future<ShopData> bringShopData() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('shops')
        .doc(signController.currentUser.value.shopId)
        .get();
    return shopData = ShopData.fromJson(snapshot.data());
  }

  Widget photosWidget() {
    return Column(
      children: [
        Row(
          children: [
            Text('매장사진', style: TextStyle(fontSize: 17, color: Colors.black54),),
            Icon(Icons.navigate_next, size: 22, color: Colors.black54,),
          ],
        ),
        Container(
          height: 115,
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
          child: ListView.builder(
            // todo
            itemCount: shopData.imageList.length,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              double thumbnailSize = 75;

              return Container(
                padding:
                EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
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
                    imageUrl: shopData.imageList[index],
                    width: thumbnailSize,
                    height: thumbnailSize,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(5.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget addressWidget() {
    return Column(
        children: [
          Row(
            children: [
              Text('매장주소', style: TextStyle(fontSize: 17, color: Colors.black54),),
              Icon(Icons.navigate_next, size: 22, color: Colors.black54,),
            ],
          ),
          SizedBox(height: 5,),
          Container(
              padding: EdgeInsets.only(top: 10, bottom: 10),
              child: Column(children: [
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
                    shopData.address.length > 0
                        ? Text(
                      shopData.address +
                          ' ' +
                          shopData.addressDetail,
                      style: TextStyle(fontSize: 16),
                    )
                        : Container(),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
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
                    shopData.roadAddress.length > 0
                        ? Expanded(
                      child: Text(
                        shopData.roadAddress +
                            ' ' +
                            shopData.addressDetail,
                        style: TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        maxLines: 2,
                      ),
                    )
                        : Container(),
                  ],
                ),
              ])),
        ]
    );
  }

  Widget contactWidget() {
    PhoneNumberDisplayFormatter phoneNumberDisplayFormatter = PhoneNumberDisplayFormatter();
    return Column(
      children: [
        Row(
          children: [
            Text('연락처', style: TextStyle(fontSize: 17, color: Colors.black54),),
            Icon(Icons.navigate_next, size: 22, color: Colors.black54,),
          ],
        ),
        SizedBox(height: 15,),
        Row(
          children: [
            Text('${phoneNumberDisplayFormatter.getPhoneNumberFormat(shopData.contact)}', style: TextStyle(fontSize: 18),),
          ],
        ),
        SizedBox(height: 8,),
        shopData.isOpenPhoneNumber
            ? Row(
          children: [
            Icon(Icons.check, color: Colors.red, size: 17,),
            SizedBox(width: 5),
            Text(
              '휴대폰 번호 공개',
              style: TextStyle(fontSize: 16),
            ),
          ],
        )
            : Row(
          children: [
            Icon(Icons.clear, color: Colors.red, size: 17,),
            SizedBox(width: 5),
            Text(
              '• 휴대폰 번호 비공개',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget diagnosticDeviceWidget() {
    return Column(
      children: [
        Row(
          children: [
            Text('진단기 보유 종류', style: TextStyle(fontSize: 17, color: Colors.black54),),
            Icon(Icons.navigate_next, size: 22, color: Colors.black54,),
          ],
        ),
        Container(
          padding: EdgeInsets.only(top: 15),
          alignment: Alignment.centerLeft,
            child: Text(shopData.diagnosticDevice, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),)),
      ],
    );
  }

  Widget oilTypeWidget() {
    return Column(
      children: [
        Row(
          children: [
            Text('취급오일 종류', style: TextStyle(fontSize: 17, color: Colors.black54),),
            Icon(Icons.navigate_next, size: 22, color: Colors.black54,),
          ],
        ),
        Container(
            padding: EdgeInsets.only(top: 15),
            alignment: Alignment.centerLeft,
            child: Text(shopData.oilType, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),)),
      ],
    );
  }

  Widget commentWidget() {
    return Column(
      children: [
        Row(
          children: [
            Text('매장소개', style: TextStyle(fontSize: 17, color: Colors.black54),),
            Icon(Icons.navigate_next, size: 22, color: Colors.black54,),
          ],
        ),
        Container(
            padding: EdgeInsets.only(top: 15),
            alignment: Alignment.centerLeft,
            child: Text(shopData.comment)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '마이샵',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(
          color: Colors.black, //change your color here
        ),
        actions: [
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
                        child: Text("매장정보삭제"),
                        value: 1,
                    )
                  ],
            onSelected: (int value) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  // return object of type Dialog
                  return AlertDialog(
                    content: new Text("매장정보를 삭제하면 주변 검색에서 내용이 영구적으로 삭제됩니다. 삭제 하시겠습니까?"),
                    actions: <Widget>[
                      new TextButton(
                        child: new Text("확인"),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('shops')
                              .doc(signController.currentUser.value.shopId)
                              .delete();
                          await FirebaseFirestore.instance
                          .collection('users').doc(signController.currentUser.value.uid).update(
                              {'shop_id': ''});
                          Get.offNamedUntil('/my', (route) => false);
                        },
                      ),
                      new TextButton(
                        child: new Text("취소"),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<ShopData>(
          future: bringShopData(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return Center(
                child: CircularProgressIndicator(),
              );
            else
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    children: [
                      photosWidget(),
                      Divider(),
                      SizedBox(height: 15,),
                      addressWidget(),
                      Divider(),
                      SizedBox(height: 15,),
                      contactWidget(),
                      SizedBox(height: 10,),
                      Divider(),
                      SizedBox(height: 15,),
                      diagnosticDeviceWidget(),
                      SizedBox(height: 15,),
                      Divider(),
                      SizedBox(height: 15,),
                      oilTypeWidget(),
                      SizedBox(height: 15,),
                      Divider(),
                      SizedBox(height: 15,),
                      commentWidget(),
                    ],
                  ),
                ),
              );
          }),
      bottomNavigationBar: SafeArea(
        child: InkWell(
          onTap: () {
            Get.toNamed('/shop/update', arguments: shopData);
          },
          child: Container(
            padding: EdgeInsets.only(top: 18, bottom: 18),
            //alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
                color: Colors.black
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('내용수정',style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),),
              ],
            ),
          ),
        ),
      ),
    );
  }
}