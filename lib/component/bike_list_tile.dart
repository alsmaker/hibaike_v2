import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hibaike_app/component/data_time_format.dart';
import 'package:hibaike_app/controller/sign_controller.dart';
import 'package:hibaike_app/model/bike_data.dart';
import 'package:intl/intl.dart';

class BikeListTile extends StatefulWidget {
  final BikeData bikeData;
  const BikeListTile({Key key, this.bikeData}) : super(key: key);

  @override
  _BikeListTileState createState() => _BikeListTileState();
}

class _BikeListTileState extends State<BikeListTile> {
  int currentIndex = 0;

  Widget _thumnail() {
    SignController signController = Get.find();
    List<String> carouselImageList;
    int remainNumberOfImages = 0;

    if(widget.bikeData.imageList.length > 3) {
      carouselImageList =
          List.generate(3, (index) => widget.bikeData.imageList[index]);
      remainNumberOfImages = widget.bikeData.imageList.length - 3;
    }
    else
      carouselImageList = List.from(widget.bikeData.imageList);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            child: CarouselSlider(
              items: carouselImageList.map((i) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      //margin: EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        //color: Colors.grey.withOpacity(0.5),

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
                  initialPage: 0,//Get.find<PageIndexController>().index.value,
                  autoPlay: false,
                  enlargeCenterPage: false,
                  enableInfiniteScroll: false,
                  aspectRatio: 1.0,
                  viewportFraction: 1.0,
                  onPageChanged: (index, reason) {
                    setState(() {
                      currentIndex = index;
                    });
                  }
              ),
            ),
          ),
          widget.bikeData.ownerUid != signController.currentUser.value.uid
              ? Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                      child: Obx(
                        () => signController.currentUser.value.watchList
                                .contains(widget.bikeData.key)
                            ? Icon(
                                Icons.favorite,
                                size: 25,
                                color: Colors.red,
                              )
                            : Icon(
                                Icons.favorite_border,
                                size: 25,
                                color: Colors.white,
                              ),
                      ),
                      onTap: () {
                        setState(() {
                          signController.updateWatchList(widget.bikeData.key);
                        });
                      }),
                )
              : Container(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: carouselImageList.map((url) {
                    int index = carouselImageList.indexOf(url);
                    return Container(
                      width: 10.0,
                      height: 10.0,
                      margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentIndex == index
                            ? Color.fromRGBO(255, 255, 255, 0.8)
                            : Color.fromRGBO(150, 150, 150, 0.6),
                      ),
                    );
                  }).toList(),
                ),
                remainNumberOfImages > 0
                    ? Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        margin: EdgeInsets.only(left: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: Colors.grey,
                        ),
                        child: Text(
                          '+${remainNumberOfImages.toString()}',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailInfo() {
    final formatter = NumberFormat('#,###');
    final dateTimeFormtter = DateTimeFormatter();
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 7, 14, 23),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8),bottomRight: Radius.circular(8)),
          //border: Border(left: BorderSide(color: Colors.grey)),
        ),
        // border: Border.),
        child: Row(
          children: [
            Expanded(

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.bikeData.manufacturer +
                            ' ' +
                            widget.bikeData.model,
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      Row(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.place_outlined, color: Colors.black45, size: 15,),
                              SizedBox(width: 3,),
                              Text(widget.bikeData.locationLevel2),
                            ],
                          ),
                          SizedBox(width: 8,),
                          Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.black45, size: 14,),
                              SizedBox(width: 3,),
                              Text(dateTimeFormtter.bikeDateTime(widget.bikeData.createdTime)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 3,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.bikeData.birthYear.toString()+'년식 · '+ formatter.format(widget.bikeData.mileage)+'km', style: TextStyle(fontSize: 15, color: Colors.black.withOpacity(0.8))),
                      Container(
                        child: Text(formatter.format(widget.bikeData.amount) + '만원',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).highlightColor)),
                      )
                    ],
                  ),
                ],
              ),
            ),
            //Expanded(child: null),

          ],
        ),
      ),

    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          _thumnail(),
          _detailInfo(),
        ],
      ),
    );
  }
}