// To parse this JSON data, do
//
//     final users = usersFromJson(jsonString);

import 'dart:convert';

Users usersFromJson(String str) => Users.fromJson(json.decode(str));

String usersToJson(Users data) => json.encode(data.toJson());

class Users {
  Users({
    this.globalUSNumber,
    this.localKoreaNumber,
    this.nickName,
    this.grade,
    this.shopId,
    this.uid,
    this.profileImageUrl,
    this.watchList,
    this.pushToken,
  });

  String globalUSNumber;
  String localKoreaNumber;
  String nickName;
  String grade;
  String shopId;
  String uid;
  String profileImageUrl;
  List<String> watchList;
  String pushToken;

  factory Users.fromJson(Map<String, dynamic> json) => Users(
    globalUSNumber: json["us_phone_number"],
    localKoreaNumber: json["korea_phone_number"],
    nickName: json["nick_name"],
    grade: json["grade"],
    uid: json["uid"],
    shopId: json["shop_id"] != null ? json["shop_id"] : '',
    profileImageUrl: json["profile_image_url"],
    watchList: json["watch_list"] != null ? List<String>.from(json["watch_list"].map((x) => x)) : [],
    pushToken: json["push_token"],
  );

  Map<String, dynamic> toJson() => {
    "us_phone_number": globalUSNumber,
    "korea_phone_number": localKoreaNumber,
    "nick_name": nickName,
    "grade": grade,
    "shop_id": shopId,
    "uid": uid,
    "profile_image_url": profileImageUrl,
    "watch_list": List<dynamic>.from(watchList.map((x) => x)),
    "push_token": pushToken,
  };
}