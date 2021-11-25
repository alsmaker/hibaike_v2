// To parse this JSON data, do
//
//     final reportData = reportDataFromJson(jsonString);

import 'dart:convert';

ReportData reportDataFromJson(String str) => ReportData.fromJson(json.decode(str));

String reportDataToJson(ReportData data) => json.encode(data.toJson());

class ReportData {
  ReportData({
    this.reporter,
    this.bikeId,
    this.title,
    this.content,
    this.createdTime,
  });

  String reporter;
  String bikeId;
  String title;
  String content;
  String createdTime;

  factory ReportData.fromJson(Map<String, dynamic> json) => ReportData(
    reporter: json["reporter"],
    bikeId: json["bike_id"],
    title: json["title"],
    content: json["content"],
    createdTime: json["created_time"],
  );

  Map<String, dynamic> toJson() => {
    "reporter": reporter,
    "bike_id": bikeId,
    "title": title,
    "content": content,
    "created_time": createdTime,
  };
}

ReportErrorModel reportErrorModelFromJson(String str) => ReportErrorModel.fromJson(json.decode(str));

String reportErrorModelToJson(ReportErrorModel data) => json.encode(data.toJson());

class ReportErrorModel {
  ReportErrorModel({
    this.reporter,
    this.title,
    this.content,
    this.createdTime,
  });

  String reporter;
  String title;
  String content;
  String createdTime;

  factory ReportErrorModel.fromJson(Map<String, dynamic> json) => ReportErrorModel(
    reporter: json["reporter"],
    title: json["title"],
    content: json["content"],
    createdTime: json["created_time"],
  );

  Map<String, dynamic> toJson() => {
    "reporter": reporter,
    "title": title,
    "content": content,
    "created_time": createdTime,
  };
}

RequestModelData requestModelDataFromJson(String str) => RequestModelData.fromJson(json.decode(str));

String requestModelDataToJson(RequestModelData data) => json.encode(data.toJson());

class RequestModelData {
  RequestModelData({
    this.reporter,
    this.content,
    this.createdTime,
  });

  String reporter;
  String content;
  String createdTime;

  factory RequestModelData.fromJson(Map<String, dynamic> json) => RequestModelData(
    reporter: json["reporter"],
    content: json["content"],
    createdTime: json["created_time"],
  );

  Map<String, dynamic> toJson() => {
    "reporter": reporter,
    "content": content,
    "created_time": createdTime,
  };
}

RequestAllianceData requestAllianceDataFromJson(String str) => RequestAllianceData.fromJson(json.decode(str));

String requestAllianceDataToJson(RequestAllianceData data) => json.encode(data.toJson());

class RequestAllianceData {
  RequestAllianceData({
    this.reporter,
    this.title,
    this.content,
    this.createdTime,
  });

  String reporter;
  String title;
  String content;
  String createdTime;

  factory RequestAllianceData.fromJson(Map<String, dynamic> json) => RequestAllianceData(
    reporter: json["reporter"],
    title: json["title"],
    content: json["content"],
    createdTime: json["created_time"],
  );

  Map<String, dynamic> toJson() => {
    "reporter": reporter,
    "title": title,
    "content": content,
    "created_time": createdTime,
  };
}

