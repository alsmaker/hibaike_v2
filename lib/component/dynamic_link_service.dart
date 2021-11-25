import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hibaike_app/model/bike_data.dart';

class DynamicLinkService {
  Future<Uri> makeBikeDynamicLink(BikeData bikeData) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
        uriPrefix: 'https://hibaike.kr/share',
        link: Uri.parse('https://hibaike.kr/share/?id=${bikeData.key}'),
        androidParameters: AndroidParameters(
          packageName: 'com.project.hibaike_app',
          //minimumVersion: 0,
        ),
        iosParameters: IosParameters(
          bundleId: 'com.project.hibaike-app',
          //minimumVersion: '0',
          appStoreId: '123456789',
        ),
        socialMetaTagParameters: SocialMetaTagParameters(
          title: bikeData.manufacturer + bikeData.model,
          //description: ,
          imageUrl: Uri.parse(bikeData.imageList[0]),
        ),
    );

    Uri dynamicUrl = await parameters.buildUrl();

    final ShortDynamicLink shortenedLink = await DynamicLinkParameters.shortenUrl(
      dynamicUrl,
      DynamicLinkParametersOptions(shortDynamicLinkPathLength: ShortDynamicLinkPathLength.unguessable),
    );
    return shortenedLink.shortUrl;
  }

  Future<void> retrieveDynamicLink(BuildContext context) async {
    //await Future.delayed(Duration(seconds: 3));
    try {
      final PendingDynamicLinkData data =
          await FirebaseDynamicLinks.instance.getInitialLink();
      final Uri deepLink = data?.link;

      if (deepLink != null) {
        String strUrl = deepLink.toString();

        List<dynamic> splitList = strUrl.split('?');
        Map<String, dynamic> _newMaps = {};

        for (var i = 1; i < splitList.length; i++) {
          _newMaps[splitList[i].split('=')[0]] = splitList[i].split('=')[1];
        }
        if (_newMaps.containsKey('id')) {
          String bikeId = _newMaps['id'];
          FirebaseFirestore.instance
              .collection('bikes')
              .doc(bikeId)
              .get()
              .then((DocumentSnapshot documentSnapshot) {
            BikeData bikeData = BikeData.fromJson(documentSnapshot.data());
            Get.toNamed('/bike/list_view/detail_view', arguments: bikeData);
          });
        }
      }

      FirebaseDynamicLinks.instance.onLink(
          onSuccess: (PendingDynamicLinkData dynamicLink) async {
        String strUrl = dynamicLink.link.toString();

        List<dynamic> splitList = strUrl.split('?');
        Map<String, dynamic> _newMaps = {};

        for (var i = 1; i < splitList.length; i++) {
          _newMaps[splitList[i].split('=')[0]] = splitList[i].split('=')[1];
        }
        if (_newMaps.containsKey('id')) {
          String bikeId = _newMaps['id'];
          FirebaseFirestore.instance
              .collection('bikes')
              .doc(bikeId)
              .get()
              .then((DocumentSnapshot documentSnapshot) {
            BikeData bikeData = BikeData.fromJson(documentSnapshot.data());
            Get.toNamed('/bike/list_view/detail_view', arguments: bikeData);
          });
        }
      });
    } catch (e) {
      print(e.toString());
    }
  }
}