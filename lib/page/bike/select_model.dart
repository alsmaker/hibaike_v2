import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hibaike_app/controller/bike_data_controller.dart';

class SelectManufacturer extends StatefulWidget {
  @override
  _SelectManufacturerState createState() => _SelectManufacturerState();
}

class _SelectManufacturerState extends State<SelectManufacturer> {
  String returnRoute = Get.arguments;
  List<String> argumentsList=[];

  @override
  void initState() {
    argumentsList.add(returnRoute);
    super.initState();
  }

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
                    String manufacturer = snapshot.data.docs[index]['manufacturer'];
                    return InkWell(
                      onTap: () {
                        argumentsList.add(manufacturer);
                        Get.toNamed('/model', arguments: argumentsList);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(manufacturer,
                          style: TextStyle(fontWeight: FontWeight.bold),),
                      ),
                    );
                  },
                  separatorBuilder: (context, int index) => const Divider(),
                  itemCount: snapshot.data.docs.length);
            }
          }
        ),
      ),
    );
  }
}

class SelectModel extends StatefulWidget {
  @override
  _SelectModelState createState() => _SelectModelState();
}

class _SelectModelState extends State<SelectModel> {
  List<String> argumentsList = Get.arguments;
  String manufacturer;
  String returnRoute;

  @override
  void initState() {
    returnRoute = argumentsList[0];
    manufacturer = argumentsList[1];
    super.initState();
  }

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
                            BikeDataController controller = Get.find();
                            controller.manufacturer.value = manufacturer;
                            controller.model.value = name;
                            controller.displacement.value = snapshot.data.docs[index]['displacement'];
                            controller.fuelType.value = snapshot.data.docs[index]['fuel'];
                            controller.type.value = snapshot.data.docs[index]['type'];
                            Navigator.popUntil(context, ModalRoute.withName(returnRoute));
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(name,
                              style: TextStyle(fontWeight: FontWeight.bold),),
                          ),
                        );
                      },
                      separatorBuilder: (context, int index) => const Divider(),
                      itemCount: snapshot.data.docs.length),
                );
              }
            }
        ),
      ),
    );
  }
}