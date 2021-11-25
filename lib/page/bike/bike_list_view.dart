import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:hibaike_app/component/bike_list_tile.dart';
import 'package:hibaike_app/controller/load_bike_controller.dart';
import 'package:hibaike_app/model/manufacturer_model.dart';

class BikeListView extends StatefulWidget {
  BikeListView({Key key}) : super(key: key);

  @override
  _BikeListViewState createState() => _BikeListViewState();
}

class _BikeListViewState extends State<BikeListView> {
  final LoadBikeController controller = Get.put(LoadBikeController());

  @override
  Widget build(BuildContext context) {
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    //   statusBarColor: Colors.blue,
    //   statusBarIconBrightness: Brightness.dark,
    //   statusBarBrightness: Brightness.dark
    // ));
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:Brightness.dark,
            statusBarBrightness: Brightness.light
        ),
        child: SafeArea(
          child: CustomScrollView(
            controller: controller.scrollController,
            slivers: [
              SliverAppBar(
                iconTheme: IconThemeData(
                  color: Colors.black, //change your color here
                ),
                //backgroundColor: Colors.white,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                // backwardsCompatibility: false,
                // systemOverlayStyle: SystemUiOverlayStyle(
                //     statusBarColor: Colors.transparent,
                //     statusBarIconBrightness:Brightness.light,
                //     statusBarBrightness: Brightness.dark
                // ),
                title: Container(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "바이크",
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                      PopupMenuButton(
                        offset: Offset(0, 35),
                        shape: ShapeBorder.lerp(
                            RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5))),
                            RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5))),
                            0),
                        itemBuilder: (BuildContext context) {
                          return controller.sortingOptions.map((menu) {
                            print(menu);
                            var index = controller.sortingOptions.indexOf(menu);
                            if (index == controller.sortIndex.value)
                              return PopupMenuItem(
                                  value: index,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      SizedBox(
                                        width: 3,
                                      ),
                                      Text(menu),
                                    ],
                                  ));
                            else
                              return PopupMenuItem(
                                  value: index,
                                  child: Row(children: [
                                    SizedBox(
                                      width: 22,
                                    ),
                                    Text(menu)
                                  ]));
                          }).toList();
                        },
                        onSelected: (int value) {
                          controller.setSortIndex(value);
                        },
                        child: Obx(
                          () => Container(
                            padding: EdgeInsets.fromLTRB(8, 3, 1, 3),
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5)),
                                border: Border.all(color: Colors.black54)),
                            child: Row(
                              children: [
                                Text(
                                  controller
                                      .sortingOptions[controller.sortIndex.value],
                                  style: TextStyle(
                                      color: Colors.black54, fontSize: 12),
                                ),
                                Icon(
                                  Icons.expand_more,
                                  color: Colors.black54,
                                  size: 18,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      InkWell(
                        onTap: () {
                          Get.toNamed('/bike/list_view/filter',
                              arguments: controller);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Container(
                            width: 22,
                            height: 22,
                            child: SvgPicture.asset('asset/filter1.svg',
                                color: Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                floating: true,
                snap: true,
              ),

              GetBuilder<LoadBikeController>(builder: (controller) {
                print('list getbuilder');

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return GestureDetector(
                      onTap: () {
                        Get.toNamed('/bike/list_view/detail_view',
                            arguments: controller.bikeDataList[index]);
                      },
                      child: (controller == null ||
                              controller.bikeDataList.length == 0)
                          ? null
                          : BikeListTile(
                              bikeData: controller.bikeDataList[index]),
                    );
                  },
                      childCount: (controller == null ||
                              controller.bikeDataList.length == 0)
                          ? 0
                          : controller.bikeDataList.length),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class Filter extends StatefulWidget {
  @override
  _FilterState createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  LoadBikeController loadBikeController = Get.arguments;

  @override
  void initState() {
    super.initState();

    loadBikeController.setMilageText(loadBikeController.milageRange.value);
    loadBikeController.adjustAmountText(loadBikeController.amountRange.value);
  }

  Widget chipCompnayModelButton(String value) {
    return Container(
      width: 110,
      padding: EdgeInsets.all(0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
            color: Colors.grey, // set border color
            width: 1.2), // set border width
        borderRadius: BorderRadius.all(
            Radius.circular(30.0)), // set rounded corner radius
      ),
      child: Text(value, style: TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }

  Widget displacementFilter() {
    return Column(
      children: [
        Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: Text(
              '배기량',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            )),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(
              () => GestureDetector(
                onTap: () {
                  if (loadBikeController.displacementSwitch[0])
                    loadBikeController.displacementSwitch[0] = false;
                  else
                    loadBikeController.displacementSwitch[0] = true;
                },
                child: Container(
                  width: MediaQuery.of(context).size.width / 3 - 15,
                  //110,
                  //margin: EdgeInsets.all(0),
                  padding: EdgeInsets.all(7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Get.find<LoadBikeController>().displacementSwitch[0]
                        ? Colors.red
                        : Colors.white,
                    border: Border.all(
                        color:
                            Get.find<LoadBikeController>().displacementSwitch[0]
                                ? Colors.red
                                : Colors.red, // set border color
                        width: 1.2), // set border width
                    borderRadius: BorderRadius.all(
                        Radius.circular(30.0)), // set rounded corner radius
                    //boxShadow: [BoxShadow(blurRadius: 10,color: Colors.black,offset: Offset(1,3))]// make rounded corner of border
                  ),
                  child: Text(
                    "125cc이하",
                    style: TextStyle(
                      color:
                          Get.find<LoadBikeController>().displacementSwitch[0]
                              ? Colors.white
                              : Colors.black,
                      fontSize: 13,
                      fontWeight:
                          Get.find<LoadBikeController>().displacementSwitch[0]
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
            Obx(
              () => GestureDetector(
                onTap: () {
                  if (loadBikeController.displacementSwitch[1])
                    loadBikeController.displacementSwitch[1] = false;
                  else
                    loadBikeController.displacementSwitch[1] = true;
                },
                child: Container(
                  width: MediaQuery.of(context).size.width / 3 - 15,
                  //110,
                  //margin: EdgeInsets.all(0),
                  padding: EdgeInsets.all(7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Get.find<LoadBikeController>().displacementSwitch[1]
                        ? Colors.red
                        : Colors.white,
                    border: Border.all(
                        color:
                            Get.find<LoadBikeController>().displacementSwitch[1]
                                ? Colors.red
                                : Colors.red, // set border color
                        width: 1.2), // set border width
                    borderRadius: BorderRadius.all(
                        Radius.circular(30.0)), // set rounded corner radius
                    //boxShadow: [BoxShadow(blurRadius: 10,color: Colors.black,offset: Offset(1,3))]// make rounded corner of border
                  ),
                  child: Text(
                    "500cc이하",
                    style: TextStyle(
                      color:
                          Get.find<LoadBikeController>().displacementSwitch[1]
                              ? Colors.white
                              : Colors.black,
                      fontSize: 13,
                      fontWeight:
                          Get.find<LoadBikeController>().displacementSwitch[1]
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
            Obx(
              () => GestureDetector(
                onTap: () {
                  if (loadBikeController.displacementSwitch[2])
                    loadBikeController.displacementSwitch[2] = false;
                  else
                    loadBikeController.displacementSwitch[2] = true;
                },
                child: Container(
                  width: MediaQuery.of(context).size.width / 3 - 15,
                  //110,
                  //margin: EdgeInsets.all(0),
                  padding: EdgeInsets.all(7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Get.find<LoadBikeController>().displacementSwitch[2]
                        ? Colors.red
                        : Colors.white,
                    border: Border.all(
                        color:
                            Get.find<LoadBikeController>().displacementSwitch[2]
                                ? Colors.red
                                : Colors.red, // set border color
                        width: 1.2), // set border width
                    borderRadius: BorderRadius.all(
                        Radius.circular(30.0)), // set rounded corner radius
                    //boxShadow: [BoxShadow(blurRadius: 10,color: Colors.black,offset: Offset(1,3))]// make rounded corner of border
                  ),
                  child: Text(
                    "500cc이상",
                    style: TextStyle(
                      color:
                          Get.find<LoadBikeController>().displacementSwitch[2]
                              ? Colors.white
                              : Colors.black,
                      fontSize: 13,
                      fontWeight:
                          Get.find<LoadBikeController>().displacementSwitch[2]
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget amountFilter() {
    return Column(
      children: [
        Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: Text(
              '판매가격',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            )),
        Container(
          height: 17.0,
          alignment: Alignment.center,
          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: Obx(() => Text(
                loadBikeController.amountText.value,
                style: TextStyle(fontSize: 12, color: Colors.black),
              )),
        ),
        Obx(
          () => RangeSlider(
              divisions: 25,
              activeColor: Colors.black.withOpacity(0.8),
              inactiveColor: Colors.black12,
              min: 0,
              max: 2500,
              values: loadBikeController.amountRange.value,
              onChanged: (value) {
                loadBikeController.amountRange.value = value;
                loadBikeController.adjustAmountText(value);
              }),
        ),
      ],
    );
  }

  Widget mileageFilter() {
    return Column(
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: Text(
            '주행거리',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          //color: Colors.white,
        ),
        Container(
          height: 17.0,
          alignment: Alignment.center,
          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: Obx(() => Text(
                loadBikeController.milageText.value,
                style: TextStyle(fontSize: 12, color: Colors.black),
              )),
        ),
        Obx(
          () => RangeSlider(
              divisions: 13,
              activeColor: Colors.black.withOpacity(0.8),
              inactiveColor: Colors.black12,
              min: 0,
              max: 130000,
              values: loadBikeController.milageRange.value,
              onChanged: (value) {
                loadBikeController.milageRange.value = value;
                loadBikeController.setMilageText(value);
              }),
        ),
      ],
    );
  }

  Widget modelListFilter() {
    return Column(
      children: [
        InkWell(
          onTap: () {
            if ((loadBikeController.filterManufacturerModel.length) < 5)
              Get.toNamed('/bike/list_view/filter/manufacturer_pick',
                  arguments: loadBikeController);
            else
              Fluttertoast.showToast(
                  msg: '제조사와 모델명은 5개까지 선택이 가능합니다. 선택된 항목 삭제후 시도해주세요');
          },
          child: Obx(
            () => Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Row(
                children: [
                  Text(
                    '모델선택',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    width: 7,
                  ),
                  Text(
                    '(${loadBikeController.filterManufacturerModel.length.toString()}/5)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        Obx(
          () => Container(
            alignment: Alignment.centerLeft,
            height: 30,
            child: ListView.builder(
              itemCount: loadBikeController.filterManufacturerModel.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    loadBikeController.filterManufacturerModel.remove(
                        loadBikeController.filterManufacturerModel[index]);
                  },
                  child: Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 8, 0),
                    padding: EdgeInsets.symmetric(horizontal: 11.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      /*border: Border.all(
                            color: Colors.grey, // set border color
                            width: 1.2), // set border width*/
                      borderRadius: BorderRadius.all(
                          Radius.circular(30.0)), // set rounded corner radius
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(loadBikeController.filterManufacturerModel[index],
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
              scrollDirection: Axis.horizontal,
            ),
          ),
        ),
      ],
    );
  }

  Widget typeListFilter() {
    return Column(
      children: [
        InkWell(
          onTap: () {
            if ((loadBikeController.filterTypes.length) < 5)
              Get.toNamed('/bike/list_view/filter/type_pick',
                  arguments: loadBikeController);
            else
              Fluttertoast.showToast(
                  msg: '타입은 5개까지 선택이 가능합니다. 선택된 항목 삭제후 시도해주세요');
          },
          child: Obx(
                () => Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Row(
                children: [
                  Text(
                    '타입선택',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    width: 7,
                  ),
                  Text(
                    '(${loadBikeController.filterTypes.length.toString()}/5)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        Obx(
              () => Container(
            alignment: Alignment.centerLeft,
            height: 30,
            child: ListView.builder(
              itemCount: loadBikeController.filterTypes.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    loadBikeController.filterTypes.remove(
                        loadBikeController.filterTypes[index]);
                  },
                  child: Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 8, 0),
                    padding: EdgeInsets.symmetric(horizontal: 11.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      /*border: Border.all(
                            color: Colors.grey, // set border color
                            width: 1.2), // set border width*/
                      borderRadius: BorderRadius.all(
                          Radius.circular(30.0)), // set rounded corner radius
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(loadBikeController.filterTypes[index],
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
              scrollDirection: Axis.horizontal,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Get.put(LoadBikeController());
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Colors.black,
          ),
          onPressed: () {
            Get.back();
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '필터',
          style: TextStyle(color: Colors.black),
        ),
        backwardsCompatibility: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:Brightness.dark,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // paddingSymmetric(horizontal: 30),
              displacementFilter(),
              Divider(
                height: 30,
              ),
              modelListFilter(),
              Divider(
                height: 30,
              ),
              typeListFilter(),
              Divider(
                height: 30,
              ),
              amountFilter(),
              Divider(
                height: 30,
              ),
              mileageFilter(),
            ],
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.3,
            child: FloatingActionButton.extended(
              onPressed: () {
                loadBikeController.resetFilter();
              },
              heroTag: 'reset',
              label: Text(
                '초기화',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.red,
            ),
          ),
          SizedBox(
            width: 20,
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.4,
            child: FloatingActionButton.extended(
                onPressed: () {
                  loadBikeController.makeElasticQuery();
                  //Get.until((route) => Get.currentRoute == '/view/filter');
                  Get.back();
                },
                heroTag: 'filter',
                label: Text(
                  '검색',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.black),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class SelectManufacturerInFilter extends StatefulWidget {
  @override
  _SelectManufacturerInFilterState createState() =>
      _SelectManufacturerInFilterState();
}

class _SelectManufacturerInFilterState
    extends State<SelectManufacturerInFilter> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('제조사 선택'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: FutureBuilder(
            future: FirebaseFirestore.instance.collection('models').get(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                return ListView.separated(
                    itemBuilder: (context, index) {
                      String manufacturer =
                          snapshot.data.docs[index]['manufacturer'];
                      return InkWell(
                        onTap: () {
                          Get.toNamed('/bike/list_view/filter/model_pick',
                              arguments: manufacturer);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            manufacturer,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, int index) => const Divider(),
                    itemCount: snapshot.data.docs.length);
              }
            }),
      ),
    );
  }
}

class SelectModelsInFilter extends StatefulWidget {
  @override
  _SelectModelsInFilterState createState() => _SelectModelsInFilterState();
}

class _SelectModelsInFilterState extends State<SelectModelsInFilter> {
  String manufacturer = Get.arguments;
  LoadBikeController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$manufacturer'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('models')
                .doc(manufacturer)
                .collection('model')
                .get(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                return SafeArea(
                  child: ListView.separated(
                      itemBuilder: (context, index) {
                        String name = snapshot.data.docs[index]['name'];
                        return InkWell(
                          onTap: () {
                            if (controller.filterManufacturerModel
                                .contains(name)) {
                              controller.filterManufacturerModel.remove(name);
                            } else {
                              if (controller.filterManufacturerModel.length < 5)
                                controller.filterManufacturerModel.add(name);
                              else
                                Fluttertoast.showToast(
                                    msg: '제조사/ 모델명은 5개까지 선택이 가능합니다');
                            }
                            //controller.filterManufacturerModel.add(manufacturer);
                            // BikeDataController controller = Get.find();
                            // controller.manufacturer.value = manufacturer;
                            // controller.model.value = name;
                            // controller.displacement.value = snapshot.data.docs[index]['displacement'];
                            // controller.fuelType.value = snapshot.data.docs[index]['fuel'];
                            // controller.type.value = snapshot.data.docs[index]['type'];
                            // Get.offNamedUntil('/bike/register', (route) => true);
                          },
                          child: Obx(
                            () => Container(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  controller.filterManufacturerModel
                                          .contains(name)
                                      ? Icon(
                                          Icons.check,
                                          color: Colors.red,
                                          size: 17,
                                        )
                                      : Container()
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, int index) => const Divider(),
                      itemCount: snapshot.data.docs.length),
                );
              }
            }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.until((route) => Get.currentRoute == '/bike/list_view/filter');
        },
        label: Text(
          '선택완료',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).highlightColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class SelectTypeInFilter extends StatefulWidget {
  @override
  _SelectTypeInFilterState createState() =>
      _SelectTypeInFilterState();
}

class _SelectTypeInFilterState
    extends State<SelectTypeInFilter> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('타입 선택'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: FutureBuilder(
            future: FirebaseFirestore.instance.collection('type').get(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                return ListView.separated(
                    itemBuilder: (context, index) {
                      String type = snapshot.data.docs[index]['type'];
                      String docId = snapshot.data.docs[index].id;
                      return InkWell(
                        onTap: () {
                          Get.toNamed('/bike/list_view/filter/sub_type_pick',
                              arguments: [docId, type]);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            type,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, int index) => const Divider(),
                    itemCount: snapshot.data.docs.length);
              }
            }),
      ),
    );
  }
}

class SelectSubTypeInFilter extends StatefulWidget {
  @override
  _SelectSubTypeInFilterState createState() => _SelectSubTypeInFilterState();
}

class _SelectSubTypeInFilterState extends State<SelectSubTypeInFilter> {
  String docId = Get.arguments[0];
  String type = Get.arguments[1];
  LoadBikeController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$type'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('type')
                .doc(docId)
                .collection('sub_type')
                .get(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                return SafeArea(
                  child: ListView.separated(
                      itemBuilder: (context, index) {
                        String name = snapshot.data.docs[index]['sub_type'];
                        return InkWell(
                          onTap: () {
                            if (controller.filterTypes
                                .contains(name)) {
                              controller.filterTypes.remove(name);
                            } else {
                              if (controller.filterTypes.length < 5)
                                controller.filterTypes.add(name);
                              else
                                Fluttertoast.showToast(
                                    msg: '타입은 5개까지 선택이 가능합니다');
                            }
                            //controller.filterManufacturerModel.add(manufacturer);
                            // BikeDataController controller = Get.find();
                            // controller.manufacturer.value = manufacturer;
                            // controller.model.value = name;
                            // controller.displacement.value = snapshot.data.docs[index]['displacement'];
                            // controller.fuelType.value = snapshot.data.docs[index]['fuel'];
                            // controller.type.value = snapshot.data.docs[index]['type'];
                            // Get.offNamedUntil('/bike/register', (route) => true);
                          },
                          child: Obx(
                                () => Container(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  controller.filterTypes
                                      .contains(name)
                                      ? Icon(
                                    Icons.check,
                                    color: Colors.red,
                                    size: 17,
                                  )
                                      : Container()
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, int index) => const Divider(),
                      itemCount: snapshot.data.docs.length),
                );
              }
            }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.until((route) => Get.currentRoute == '/bike/list_view/filter');
        },
        label: Text(
          '선택완료',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).highlightColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

List<ManufacturerNModel> parseModelSpec(String companyJson) {
  final parsed = json.decode(companyJson).cast<Map<String, dynamic>>();
  return parsed
      .map<ManufacturerNModel>((json) => ManufacturerNModel.fromJson(json))
      .toList();
}

class FilterCompanyList extends StatelessWidget {
  final LoadBikeController controller = Get.arguments;

  Future<List<ManufacturerNModel>> loadJson() async {
    print('load json func()');
    String jsonString =
        await rootBundle.loadString('assets/json/bike_model.json');
    print('loadjson \n' + jsonString);

    return compute(parseModelSpec, jsonString);
  }

  Widget companyListView(List<ManufacturerNModel> company) {
    print(company.length);
    return ListView.separated(
      itemCount: company.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          title: Text(company[index].manufacturer),
          onTap: () {
            Get.to(FilterModelList(
              company: company[index].manufacturer,
              model: company[index].modelNSpec,
              controller: controller,
            ));
          },
        );
      },
      separatorBuilder: (context, index) {
        return Divider();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('제조사'),
      ),
      body: Center(
        child: FutureBuilder<List<ManufacturerNModel>>(
          future: loadJson(),
          builder: (context, snapshot) {
            //print(snapshot.data);
            if (snapshot.hasError) print(snapshot.error);

            if (snapshot.hasData) {
              print(snapshot.data);
              final List<ManufacturerNModel> company = snapshot.data;
              return companyListView(company);
            } else
              return Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class FilterModelList extends StatelessWidget {
  final String company;
  final List<ModelNSpec> model;
  final LoadBikeController controller;

  FilterModelList(
      {Key key,
      @required this.company,
      @required this.model,
      @required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("모델명선택"),
      ),
      body: ListView.separated(
        itemCount: model.length,
        itemBuilder: (context, int index) {
          return ListTile(
            title: Text(model[index].name),
            onTap: () {
              //controller.companyModel.add(model[index].name, "model");
              controller.filterManufacturerModel.add(model[index].name);
              Get.until((route) => Get.currentRoute == '/view/filter');
            },
          );
        },
        separatorBuilder: (context, index) {
          return Divider();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            controller.filterManufacturerModel.add(company);
            Get.until((route) => Get.currentRoute == '/view/filter');
          },
          label: Text(company + ' 전체선택')),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
