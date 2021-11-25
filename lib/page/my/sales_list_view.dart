import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hibaike_app/controller/sign_controller.dart';
import 'package:hibaike_app/model/bike_data.dart';
import 'package:intl/intl.dart';

class SalesListView extends StatefulWidget {
  @override
  _SalesListViewState createState() => _SalesListViewState();
}

class _SalesListViewState extends State<SalesListView> {
  SignController signController = Get.find();

  double thumbnailSize = 85;

  Widget smallBikeTile(DocumentSnapshot ds) {
    print(ds.data());
    BikeData bikeData = BikeData.fromJson(ds.data());
    final formatter = NumberFormat('#,###');
    return Container(
      padding: EdgeInsets.only(left: 12, right: 5, top: 6, bottom: 6),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.only(right: 15),
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
                imageUrl: bikeData.imageList[0],
                width: thumbnailSize,
                height: thumbnailSize,
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(8.0),
              ),
              clipBehavior: Clip.hardEdge,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(bikeData.manufacturer + ' ' +bikeData.model, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
                SizedBox(height: 3,),
                Text(bikeData.birthYear.toString()+'년 ' + formatter.format(bikeData.mileage) +'km ' + bikeData.locationLevel2),
                SizedBox(height: 6,),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Get.toNamed('/bike/update', arguments: ds);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: MediaQuery.of(context).size.width * 0.25,
                        padding: EdgeInsets.symmetric(vertical: 7, horizontal: 15),
                        decoration: BoxDecoration(
                          color: Theme.of(context).highlightColor,
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                        child: Text('수정', style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                        ),),
                      ),
                    ),
                    SizedBox(width: 10,),
                    InkWell(
                      onTap: () {
                        Get.dialog(
                            Dialog(
                              child: Container(
                                padding: EdgeInsets.only(left: 20, right: 20, top: 30, bottom: 20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('거래가 완료되었나요?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                                    SizedBox(height: 10,),
                                    Text('거래가 완료되면 이 바이크와 관련된 채팅을 할수 없습니다.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                                    SizedBox(height: 20,),
                                    ElevatedButton(
                                      child: Text('거래완료'),
                                      onPressed: () async{
                                        FirebaseFirestore.instance.collection('sold_out_bikes').doc(bikeData.key).set(bikeData.toJson())
                                            .then((value) => FirebaseFirestore.instance.collection('bikes').doc(bikeData.key).delete());
                                        Get.back();
                                      },
                                    )
                                  ],
                                ),
                              ),
                            )
                        );

                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: MediaQuery.of(context).size.width * 0.25,
                        padding: EdgeInsets.symmetric(vertical: 7, horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                        child: Text('거래완료', style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                        ),),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                      child: Text("매물삭제"),
                      value: 1,
                    )
                  ],
            onSelected: (int value) {
                Get.dialog(
                  Dialog(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('거래매물을 삭제하시겠습니까?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),
                          Text('거래가 완료되었으면 거래완료 버튼을 눌러주세요.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),
                          ElevatedButton(
                            child: Text('매물삭제'),
                            onPressed: () async{
                              await FirebaseFirestore.instance.collection('bikes').doc(bikeData.key).delete();
                              Get.back();
                            },
                          )
                        ],
                      ),
                    ),
                  )
                );
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('판매목록',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bikes')
              .where('ownerUid',
              isEqualTo: signController.currentUser.value.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if(!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            else {
              return ListView.separated(
                itemBuilder: (context, int index) {
                  return smallBikeTile(snapshot.data.docs[index]);
                },
                separatorBuilder: (context, index) {
                  return Divider();
                },
                itemCount: snapshot.data.docs.length,
              );
            }
          }),
    );
  }
}